//
//  PassengerEnrolledServicesViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

// Domain types (unchanged — used by the View)

enum EnrolledSessionType {
    case morning
    case evening
    case both
}

struct EnrolledSessionInfo {
    let startTime: String
    let endTime: String
    let driverName: String
    let vehicleBrand: String
    let vehicleType: String
    let licensePlate: String
}

struct EnrolledService: Identifiable {
    let id: String
    let routeId: String
    let routeName: String
    let routeStart: String
    let routeEnd: String
    let session: EnrolledSessionType
    let morning: EnrolledSessionInfo?
    let evening: EnrolledSessionInfo?
    let monthlyFee: Double
    var isActive: Bool
    var cancelledDate: Date? = nil
}

// ViewModel

@MainActor
final class PassengerEnrolledServicesViewModel: ObservableObject {

    @Published var activeServices: [EnrolledService] = []
    @Published var pastServices:   [EnrolledService] = []
    @Published var isLoading: Bool = false
    @Published var loadError: String? = nil

    @Published var showingPast: Bool = false
    @Published var serviceToCancel: EnrolledService? = nil
    @Published var sessionToCancel: EnrolledSessionType? = nil
    @Published var showCancelAlert: Bool = false
    @Published var showCancelOptions: Bool = false

    // nonisolated storage so deinit can safely remove the listener
    nonisolated(unsafe) private var _listenerBox: ListenerRegistration?

    deinit {
        _listenerBox?.remove()
    }

    var hasMorningActive: Bool {
        activeServices.contains { $0.session == .morning || $0.session == .both }
    }

    var hasEveningActive: Bool {
        activeServices.contains { $0.session == .evening || $0.session == .both }
    }

    func sessionLabel(_ session: EnrolledSessionType) -> String {
        switch session {
        case .morning: return "Morning Only"
        case .evening: return "Evening Only"
        case .both:    return "Morning & Evening"
        }
    }

    func cancelAlertMessage() -> String {
        guard let service = serviceToCancel else { return "" }
        switch sessionToCancel {
        case .morning:
            return "Cancel your morning enrollment for \(service.routeName)? This cannot be undone."
        case .evening:
            return "Cancel your evening enrollment for \(service.routeName)? This cannot be undone."
        default:
            return "Cancel your entire enrollment for \(service.routeName)? This cannot be undone."
        }
    }

    func requestCancel(service: EnrolledService, session: EnrolledSessionType) {
        serviceToCancel = service
        sessionToCancel = session
        showCancelAlert = true
    }

    func requestCancelOptions(service: EnrolledService) {
        serviceToCancel = service
        showCancelOptions = true
    }

    func handleCancelChoice(_ session: EnrolledSessionType) {
        sessionToCancel = session
        handleCancel()
    }

    func handleCancel() {
        guard let serviceBeingCancelled = serviceToCancel else { return }
        let sessionBeingCancelled = sessionToCancel      // capture before state is cleared

        Task {
            do {
                try await JoinRequestService.shared.cancelEnrollment(requestId: serviceBeingCancelled.id)

                // determine which session label to remove
                let calendarSessionLabel: String
                switch sessionBeingCancelled {
                case .morning: calendarSessionLabel = "Morning"
                case .evening: calendarSessionLabel = "Evening"
                default:       calendarSessionLabel = "Both"
                }

                EventKitManager.shared.removeCalendarEventsForRoute(
                    routeId: serviceBeingCancelled.routeId,
                    sessionLabel: calendarSessionLabel
                )

            } catch {
                loadError = "Could not cancel enrollment. Please try again."
            }
        }

        serviceToCancel = nil
        sessionToCancel = nil
        showCancelAlert = false
        showCancelOptions = false
    }

    // Firebase loading
    func startListening() {
        guard let passengerId = Auth.auth().currentUser?.uid else {
            print("[EnrolledServicesVM] No authenticated user — cannot load enrollments")
            return
        }
        isLoading = true
        _listenerBox?.remove()
        _listenerBox = JoinRequestService.shared.listenForPassengerRequests(passengerId: passengerId) { [weak self] allRequests in
            guard let self else { return }
            Task { @MainActor in
                await self.processRequests(allRequests)
            }
        }
    }

    private func processRequests(_ requests: [JoinRequestModel]) async {
        var active: [EnrolledService] = []
        var past:   [EnrolledService] = []

        for req in requests {
            guard let docId = req.id else { continue }

            // Fetch route + driver to populate the card
            let service = await buildEnrolledService(from: req, docId: docId)
            guard let service else { continue }

            if req.status == "accepted" {
                active.append(service)
            } else if req.status == "cancelled" || req.status == "rejected" {
                var pastService = service
                pastService = EnrolledService(
                    id: service.id,
                    routeId: service.routeId,
                    routeName: service.routeName,
                    routeStart: service.routeStart,
                    routeEnd: service.routeEnd,
                    session: service.session,
                    morning: service.morning,
                    evening: service.evening,
                    monthlyFee: service.monthlyFee,
                    isActive: false,
                    cancelledDate: Date()
                )
                past.append(pastService)
            }
        }

        self.activeServices = active
        self.pastServices   = past.sorted { ($0.cancelledDate ?? .distantPast) > ($1.cancelledDate ?? .distantPast) }
        self.isLoading = false
        print("[EnrolledServicesVM] Updated — \(active.count) active, \(past.count) past")
    }

    private func buildEnrolledService(from req: JoinRequestModel, docId: String) async -> EnrolledService? {
        // Fetch route
        guard let route = try? await RouteService.shared.fetchRoute(routeId: req.routeId) else {
            print("[EnrolledServicesVM] Could not fetch route \(req.routeId)")
            return nil
        }

        // Fetch driver
        let driver = try? await DriverService.shared.fetchDriver(driverId: req.driverId)

        let driverName   = driver?.fullName ?? "Driver"
        let vehicleBrand = driver?.busInformation.busName ?? "Bus"
        let vehicleType  = driver?.busInformation.busType ?? "Bus"
        let plateNumber  = driver?.busInformation.plateNumber ?? "—"

        // Schedule times
        let morningEntry = route.scheduleEntries.first
        let eveningEntry = route.scheduleEntries.count >= 2 ? route.scheduleEntries[1] : nil

        func timeLabel(_ date: Date) -> String {
            let f = DateFormatter()
            f.dateFormat = "hh:mm a"
            f.locale = Locale(identifier: "en_US_POSIX")
            return f.string(from: date)
        }

        let morningInfo: EnrolledSessionInfo? = morningEntry.map {
            EnrolledSessionInfo(
                startTime:    timeLabel($0.scheduledDepartureTime),
                endTime:      timeLabel($0.scheduledArrivalTime ?? $0.scheduledDepartureTime),
                driverName:   driverName,
                vehicleBrand: vehicleBrand,
                vehicleType:  vehicleType,
                licensePlate: plateNumber
            )
        }

        let eveningInfo: EnrolledSessionInfo? = eveningEntry.map {
            EnrolledSessionInfo(
                startTime:    timeLabel($0.scheduledDepartureTime),
                endTime:      timeLabel($0.scheduledArrivalTime ?? $0.scheduledDepartureTime),
                driverName:   driverName,
                vehicleBrand: vehicleBrand,
                vehicleType:  vehicleType,
                licensePlate: plateNumber
            )
        }

        let sessionType: EnrolledSessionType
        let sessionFee: Double
        switch req.session {
        case "Morning":
            sessionType = .morning
            sessionFee  = route.morningPrice ?? 0
        case "Evening":
            sessionType = .evening
            sessionFee  = route.eveningPrice ?? 0
        default:
            sessionType = .both
            sessionFee  = route.bothTripsPrice ?? 0
        }

        return EnrolledService(
            id:         docId,
            routeId: req.routeId,
            routeName:  "\(route.startLocation.locationName) → \(route.endLocation.locationName)",
            routeStart: req.pickupStop,
            routeEnd:   req.dropoffStop,
            session:    sessionType,
            morning:    sessionType == .both || sessionType == .morning ? morningInfo : nil,
            evening:    sessionType == .both || sessionType == .evening ? eveningInfo : nil,
            monthlyFee: sessionFee,
            isActive:   req.status == "accepted"
        )
    }
}
