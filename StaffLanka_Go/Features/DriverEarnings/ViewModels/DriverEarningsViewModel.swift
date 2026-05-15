//
//  DriverEarningsViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class DriverEarningsViewModel: ObservableObject {

    struct PassengerPaymentRecord: Identifiable {
        let id = UUID()
        let joinRequestDocumentId: String
        let passengerUserId: String
        let passengerFullName: String
        let passengerPhoneNumber: String
        let boardingStopName: String
        let dropOffStopName: String
        let routeServiceType: TripSession
        let monthlyFeeAmount: Int
        let hasPassengerPaid: Bool
    }

    struct MonthChip: Identifiable {
        let id: String
        let monthYear: String
        let displayLabel: String
        let isCurrentMonth: Bool
    }

    @Published var availableMonthChips: [MonthChip] = []
    @Published var selectedMonthYear: String = ""
    @Published var listOfPassengerPaymentStatuses: [PassengerPaymentRecord] = []
    @Published var isLoading: Bool = false

    nonisolated(unsafe) private var _acceptedPassengersListener: ListenerRegistration?

    deinit { _acceptedPassengersListener?.remove() }

    var totalEarningsForSelectedMonth: Int {
        listOfPassengerPaymentStatuses.reduce(0) { $0 + $1.monthlyFeeAmount }
    }

    var totalCollectedAmountForSelectedMonth: Int {
        listOfPassengerPaymentStatuses.filter { $0.hasPassengerPaid }.reduce(0) { $0 + $1.monthlyFeeAmount }
    }

    var totalPendingAmountForSelectedMonth: Int {
        listOfPassengerPaymentStatuses.filter { !$0.hasPassengerPaid }.reduce(0) { $0 + $1.monthlyFeeAmount }
    }

    var numberOfPaidPassengers: Int {
        Set(listOfPassengerPaymentStatuses.filter { $0.hasPassengerPaid }.map { $0.passengerUserId }).count
    }

    var numberOfUnpaidPassengers: Int {
        Set(listOfPassengerPaymentStatuses.filter { !$0.hasPassengerPaid }.map { $0.passengerUserId }).count
    }

    var totalPassengerCount: Int {
        Set(listOfPassengerPaymentStatuses.map { $0.passengerUserId }).count
    }

    func startListening() {
        guard let driverId = Auth.auth().currentUser?.uid else { return }
        buildAvailableMonthChips()
        if selectedMonthYear.isEmpty { selectedMonthYear = currentMonthYearString() }
        isLoading = true
        attachAcceptedPassengersListener(driverId: driverId)
    }

    func buildAvailableMonthChips() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonthYear = currentMonthYearString()
        let yearMonthFormatter = DateFormatter(); yearMonthFormatter.dateFormat = "yyyy-MM"
        let displayFormatter   = DateFormatter(); displayFormatter.dateFormat = "MMM yyyy"

        var chips: [MonthChip] = []
        for offset in 0..<12 {
            guard let date = calendar.date(byAdding: .month, value: -offset, to: now) else { continue }
            let monthYear    = yearMonthFormatter.string(from: date)
            let displayLabel = displayFormatter.string(from: date)
            chips.append(MonthChip(id: monthYear, monthYear: monthYear, displayLabel: displayLabel, isCurrentMonth: monthYear == currentMonthYear))
        }
        availableMonthChips = chips
    }

    func selectMonth(_ monthYear: String) {
        guard monthYear != selectedMonthYear else { return }
        selectedMonthYear = monthYear
        guard let driverId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        Task {
            if let snapshot = try? await Firestore.firestore()
                .collection("joinRequests")
                .whereField("driverId", isEqualTo: driverId)
                .whereField("status", isEqualTo: "accepted")
                .getDocuments() {
                await buildPaymentRecords(from: snapshot.documents, driverId: driverId, monthYear: monthYear)
            } else {
                isLoading = false
            }
        }
    }

    // Converts a "yyyy-MM" string back to a Date for the DatePicker binding
    func dateFromMonthYearString(_ monthYearString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: "\(monthYearString)-01")
    }

    // Converts a Date to a "yyyy-MM" string for use as the filter key
    func monthYearStringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    private func attachAcceptedPassengersListener(driverId: String) {
        _acceptedPassengersListener?.remove()
        _acceptedPassengersListener = Firestore.firestore()
            .collection("joinRequests")
            .whereField("driverId", isEqualTo: driverId)
            .whereField("status", isEqualTo: "accepted")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("[DriverEarningsVM] Listener error: \(error.localizedDescription)")
                    Task { @MainActor in self.isLoading = false }
                    return
                }
                guard let documents = snapshot?.documents else { return }
                let capturedMonth = self.selectedMonthYear
                Task { @MainActor in
                    await self.buildPaymentRecords(from: documents, driverId: driverId, monthYear: capturedMonth)
                }
            }
    }

    private func buildPaymentRecords(from documents: [QueryDocumentSnapshot], driverId: String, monthYear: String) async {
        let paidJoinRequestIds = await fetchPaidJoinRequestIds(driverId: driverId, monthYear: monthYear)

        var records: [PassengerPaymentRecord] = []

        for document in documents {
            let data = document.data()
            let docId           = document.documentID
            let passengerUserId = data["passengerId"]    as? String ?? docId
            let passengerName   = data["passengerName"]  as? String ?? "Unknown"
            let passengerPhone  = data["passengerPhone"] as? String ?? ""
            let pickupStop      = data["pickupStop"]     as? String ?? ""
            let dropoffStop     = data["dropoffStop"]    as? String ?? ""
            let sessionLabel    = data["session"]        as? String ?? "Both"

            let sessionType: TripSession
            switch sessionLabel {
            case "Morning": sessionType = .morning
            case "Evening": sessionType = .evening
            default:        sessionType = .both
            }

            var feeAmount = 0
            if let routeId = data["routeId"] as? String,
               let route = try? await RouteService.shared.fetchRoute(routeId: routeId) {
                switch sessionType {
                case .morning: feeAmount = Int(route.morningPrice ?? 0)
                case .evening: feeAmount = Int(route.eveningPrice ?? 0)
                case .both:    feeAmount = Int(route.bothTripsPrice ?? 0)
                }
            }

            let isPaid = paidJoinRequestIds.contains(docId)

            records.append(PassengerPaymentRecord(
                joinRequestDocumentId: docId,
                passengerUserId:       passengerUserId,
                passengerFullName:     passengerName,
                passengerPhoneNumber:  passengerPhone,
                boardingStopName:      pickupStop,
                dropOffStopName:       dropoffStop,
                routeServiceType:      sessionType,
                monthlyFeeAmount:      feeAmount,
                hasPassengerPaid:      isPaid
            ))
        }

        self.listOfPassengerPaymentStatuses = records.sorted {
            if $0.hasPassengerPaid != $1.hasPassengerPaid { return !$0.hasPassengerPaid }
            return $0.passengerFullName < $1.passengerFullName
        }
        self.isLoading = false
    }

    private func fetchPaidJoinRequestIds(driverId: String, monthYear: String) async -> Set<String> {
        guard let snapshot = try? await Firestore.firestore()
            .collection("payments")
            .whereField("driverId", isEqualTo: driverId)
            .whereField("monthYear", isEqualTo: monthYear)
            .getDocuments() else { return [] }

        let ids = snapshot.documents.compactMap { $0.data()["joinRequestId"] as? String }
        return Set(ids)
    }

    private func currentMonthYearString() -> String {
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
}
