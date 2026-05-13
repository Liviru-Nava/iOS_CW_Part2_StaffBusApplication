//
//  PassengerCostTrackingViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import Combine
import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum TripSession: String, CaseIterable, Identifiable {
    case morning = "Morning"
    case evening = "Evening"
    case both    = "Both"
    var id: String { rawValue }
}

enum PaymentStatus {
    case paid, unpaid, pending
}

// Represents a single active enrolled service card shown at the top of the cost tracking screen
struct ServiceRegistration: Identifiable {
    let id: String
    let joinRequestId: String
    let driverId: String
    let routeName: String
    let pickup: String
    let destination: String
    let session: TripSession
    let monthlyFee: Double
    let daysElapsed: Int
    let totalDays: Int
    var currentMonthPaid: Bool
    var amountThisMonth: Double
    let passengerName: String
}

struct MonthlyRecord: Identifiable {
    let id: UUID
    let monthLabel: String
    let monthDate: Date
    let routeName: String
    let pickup: String
    let destination: String
    let session: TripSession
    let amount: Double
    let isPaid: Bool
    let isGracePeriod: Bool
    let joinRequestId: String
    let driverId: String
}

@MainActor
final class PassengerCostTrackingViewModel: ObservableObject {

    @Published var services: [ServiceRegistration] = []
    @Published var monthlyRecords: [MonthlyRecord] = []
    @Published var sessionFilter: TripSession? = nil
    @Published var sortByAmount: Bool = false
    @Published var showUnpaidOnly: Bool = false
    @Published var showPaymentSheet: Bool = false
    @Published var selectedServiceForPayment: ServiceRegistration? = nil
    @Published var isLoadingServices: Bool = false
    @Published var paymentError: String? = nil
    @Published var paymentSuccessMessage: String? = nil

    private var currentPassengerId: String? { Auth.auth().currentUser?.uid }

    nonisolated(unsafe) private var _enrollmentListener: ListenerRegistration?

    deinit { _enrollmentListener?.remove() }

    var hasService: Bool { !services.isEmpty }

    // Legacy single service accessor kept for views that reference it
    var service: ServiceRegistration? { services.first }

    var filteredRecords: [MonthlyRecord] {
        var records = monthlyRecords
        if let filter = sessionFilter { records = records.filter { $0.session == filter } }
        if showUnpaidOnly { records = records.filter { !$0.isPaid } }
        if sortByAmount { records = records.sorted { $0.amount > $1.amount } }
        return records
    }

    func startListening() {
        guard let passengerId = currentPassengerId else { return }
        isLoadingServices = true
        _enrollmentListener?.remove()
        _enrollmentListener = JoinRequestService.shared.listenForPassengerRequests(passengerId: passengerId) { [weak self] allRequests in
            guard let self else { return }
            Task { @MainActor in
                await self.processEnrollments(allRequests, passengerId: passengerId)
            }
        }
    }

    private func processEnrollments(_ requests: [JoinRequestModel], passengerId: String) async {
        let acceptedRequests = requests.filter { $0.status == "accepted" }

        let currentMonthYear = Self.currentMonthYearString()
        let currentMonthLabel = Self.currentMonthLabel()

        let calendar = Calendar.current
        let now = Date()
        let daysElapsed = calendar.component(.day, from: now)
        let totalDaysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30

        var builtServices: [ServiceRegistration] = []

        for req in acceptedRequests {
            guard let docId = req.id else { continue }

            let route = try? await RouteService.shared.fetchRoute(routeId: req.routeId)
            let routeName = route.map { "\($0.startLocation.locationName) → \($0.endLocation.locationName)" } ?? "Route"

            let sessionType: TripSession
            let fee: Double
            switch req.session {
            case "Morning": sessionType = .morning; fee = route?.morningPrice ?? 0
            case "Evening": sessionType = .evening; fee = route?.eveningPrice ?? 0
            default:        sessionType = .both;    fee = route?.bothTripsPrice ?? 0
            }

            // Check if this month is already paid by looking for a payment record
            let alreadyPaidThisMonth = await checkIfPaidForMonth(
                passengerId: passengerId,
                joinRequestId: docId,
                monthYear: currentMonthYear
            )

            let userRecord = try? await UserService.shared.fetchUser(userId: passengerId)
            let passengerName = userRecord?.fullName ?? "Passenger"

            builtServices.append(ServiceRegistration(
                id:               docId,
                joinRequestId:    docId,
                driverId:         req.driverId,
                routeName:        routeName,
                pickup:           req.pickupStop,
                destination:      req.dropoffStop,
                session:          sessionType,
                monthlyFee:       fee,
                daysElapsed:      daysElapsed,
                totalDays:        totalDaysInMonth,
                currentMonthPaid: alreadyPaidThisMonth,
                amountThisMonth:  fee,
                passengerName:    passengerName
            ))
        }

        self.services = builtServices

        // Load payment history for the monthly records section
        await loadPaymentHistory(passengerId: passengerId)

        self.isLoadingServices = false
    }

    private func checkIfPaidForMonth(passengerId: String, joinRequestId: String, monthYear: String) async -> Bool {
        let snapshot = try? await Firestore.firestore()
            .collection("payments")
            .whereField("passengerId", isEqualTo: passengerId)
            .whereField("joinRequestId", isEqualTo: joinRequestId)
            .whereField("monthYear", isEqualTo: monthYear)
            .getDocuments()
        return (snapshot?.documents.isEmpty == false)
    }

    private func loadPaymentHistory(passengerId: String) async {
        guard let paymentRecords = try? await PaymentService.shared.fetchPassengerPayments(passengerId: passengerId) else { return }

        // Also load any accepted enrollments to generate "unpaid" history entries for past months
        // For simplicity we only show months for which there is a payment record
        let calendar = Calendar.current
        let now = Date()

        let historyRecords: [MonthlyRecord] = paymentRecords.map { payment in
            let parsedDate = Self.parsedDate(from: payment.monthYear) ?? payment.paidAt

            let session: TripSession
            switch payment.sessionLabel {
            case "Morning": session = .morning
            case "Evening": session = .evening
            default:        session = .both
            }

            // Find matching service for route/pickup info
            let matchingService = services.first { $0.joinRequestId == payment.joinRequestId }

            return MonthlyRecord(
                id:          UUID(),
                monthLabel:  payment.monthLabel,
                monthDate:   parsedDate,
                routeName:   matchingService?.routeName ?? "Route",
                pickup:      matchingService?.pickup ?? "",
                destination: matchingService?.destination ?? "",
                session:     session,
                amount:      payment.amountPaid,
                isPaid:      true,
                isGracePeriod: false,
                joinRequestId: payment.joinRequestId,
                driverId:      payment.driverId
            )
        }

        self.monthlyRecords = historyRecords.sorted { $0.monthDate > $1.monthDate }
    }

    // Simulates a payment for a service card shown at the top
    func initiatePayment(for service: ServiceRegistration) {
        selectedServiceForPayment = service
        showPaymentSheet = true
    }

    func confirmPayment() {
        guard let service = selectedServiceForPayment,
              let passengerId = currentPassengerId else {
            showPaymentSheet = false
            return
        }

        let currentMonthYear  = Self.currentMonthYearString()
        let currentMonthLabel = Self.currentMonthLabel()
        let paymentDate       = Date()

        Task {
            do {
                try await PaymentService.shared.recordPayment(
                    passengerId:            passengerId,
                    passengerName:          service.passengerName,
                    driverId:               service.driverId,
                    joinRequestDocumentId:  service.joinRequestId,
                    sessionLabel:           service.session.rawValue,
                    monthLabel:             currentMonthLabel,
                    monthYear:              currentMonthYear,
                    amountPaid:             service.monthlyFee
                )

                // Update the service card to show paid status immediately
                if let index = self.services.firstIndex(where: { $0.id == service.id }) {
                    self.services[index] = ServiceRegistration(
                        id: service.id, joinRequestId: service.joinRequestId, driverId: service.driverId,
                        routeName: service.routeName, pickup: service.pickup, destination: service.destination,
                        session: service.session, monthlyFee: service.monthlyFee,
                        daysElapsed: service.daysElapsed, totalDays: service.totalDays,
                        currentMonthPaid: true, amountThisMonth: service.amountThisMonth,
                        passengerName: service.passengerName
                    )
                }

                // Immediately inject the new record into monthlyRecords so the history section
                // updates without waiting for the Firestore round-trip
                let newHistoryRecord = MonthlyRecord(
                    id:            UUID(),
                    monthLabel:    currentMonthLabel,
                    monthDate:     paymentDate,
                    routeName:     service.routeName,
                    pickup:        service.pickup,
                    destination:   service.destination,
                    session:       service.session,
                    amount:        service.monthlyFee,
                    isPaid:        true,
                    isGracePeriod: false,
                    joinRequestId: service.joinRequestId,
                    driverId:      service.driverId
                )
                // Prepend so it appears at the top of the history list (most recent first)
                self.monthlyRecords.insert(newHistoryRecord, at: 0)

                // Also reload from Firestore to pick up any records from other devices
                await self.loadPaymentHistory(passengerId: passengerId)

                self.paymentSuccessMessage = "Payment of Rs. \(Int(service.monthlyFee)) confirmed for \(currentMonthLabel)."

            } catch {
                self.paymentError = "Payment could not be processed. Please try again."
            }

            self.showPaymentSheet = false
            self.selectedServiceForPayment = nil
        }
    }

    func dismissPaymentSheet() {
        showPaymentSheet = false
        selectedServiceForPayment = nil
    }

    // Helpers

    static func currentMonthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    static func currentMonthLabel() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    static func parsedDate(from monthYear: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.date(from: monthYear)
    }
}
