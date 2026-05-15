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
    let driverId: String
    let routeName: String
    let routeStart: String
    let routeEnd: String
    let session: EnrolledSessionType
    let morning: EnrolledSessionInfo?
    let evening: EnrolledSessionInfo?
    let monthlyFee: Double
    var isActive: Bool
    var cancelledDate: Date? = nil
    var activeDays: [String] = []
}

@MainActor
final class PassengerEnrolledServicesViewModel: ObservableObject {

    @Published var activeServices: [EnrolledService] = []
    @Published var pastServices: [EnrolledService] = []
    @Published var isLoading: Bool = false
    @Published var loadError: String? = nil

    @Published var showingPast: Bool = false
    @Published var serviceToCancel: EnrolledService? = nil
    @Published var showCancelAlert: Bool = false

    @Published var selectedPastEnrollmentDateRangeFilter: PastEnrollmentDateRangeFilter = .allTime

    enum PastEnrollmentDateRangeFilter: String, CaseIterable, Identifiable {
        case allTime   = "All Time"
        case today     = "Today"
        case thisWeek  = "This Week"
        case thisMonth = "This Month"
        var id: String { rawValue }
    }

    nonisolated(unsafe) private var _listenerBox: ListenerRegistration?

    deinit { _listenerBox?.remove() }

    // Published so RouteDetailView can observe all three flags via onChange
    // without requiring Equatable conformance on the EnrolledService array
    @Published var hasBothEnrollmentActive: Bool = false
    @Published var hasMorningActive: Bool = false
    @Published var hasEveningActive: Bool = false

    func sessionLabel(_ session: EnrolledSessionType) -> String {
        switch session {
        case .morning: return "Morning Only"
        case .evening: return "Evening Only"
        case .both:    return "Morning & Evening"
        }
    }

    func cancelAlertMessage() -> String {
        guard let service = serviceToCancel else { return "" }
        switch service.session {
        case .morning:
            return "Cancel your morning enrollment for \(service.routeName)? This cannot be undone."
        case .evening:
            return "Cancel your evening enrollment for \(service.routeName)? This cannot be undone."
        case .both:
            return "Cancel your entire enrollment for \(service.routeName)? Both morning and evening sessions will be removed. This cannot be undone."
        }
    }

    // Called when the passenger taps cancel on any service
    // For "Both" enrollments this always cancels the whole service — no partial removal
    func requestCancel(service: EnrolledService) {
        serviceToCancel = service
        showCancelAlert = true
    }

    func handleCancel() {
        guard let serviceBeingCancelled = serviceToCancel else { return }

        Task {
            do {
                // Always cancel the entire enrollment document
                // Partial session removal from a "Both" enrollment is not supported
                try await JoinRequestService.shared.cancelEntireEnrollment(requestId: serviceBeingCancelled.id)

                let calendarSessionLabel: String
                switch serviceBeingCancelled.session {
                case .morning: calendarSessionLabel = "Morning"
                case .evening: calendarSessionLabel = "Evening"
                case .both:    calendarSessionLabel = "Both"
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
        showCancelAlert = false
    }

    var pastServicesFilteredByDateRange: [EnrolledService] {
        let calendar = Calendar.current
        let now = Date()
        switch selectedPastEnrollmentDateRangeFilter {
        case .allTime:
            return pastServices
        case .today:
            return pastServices.filter { calendar.isDateInToday($0.cancelledDate ?? .distantPast) }
        case .thisWeek:
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return pastServices }
            return pastServices.filter { ($0.cancelledDate ?? .distantPast) >= weekStart }
        case .thisMonth:
            guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start else { return pastServices }
            return pastServices.filter { ($0.cancelledDate ?? .distantPast) >= monthStart }
        }
    }

    var pastServicesGroupedByDate: [(String, [EnrolledService])] {
        let fmt = DateFormatter(); fmt.dateStyle = .medium
        var dict: [String: [EnrolledService]] = [:]
        for service in pastServicesFilteredByDateRange {
            let key: String
            if let d = service.cancelledDate {
                if Calendar.current.isDateInToday(d) { key = "Today" }
                else if Calendar.current.isDateInYesterday(d) { key = "Yesterday" }
                else { key = fmt.string(from: d) }
            } else { key = "Unknown Date" }
            dict[key, default: []].append(service)
        }
        return dict.sorted { a, b in
            guard let da = a.value.first?.cancelledDate, let db = b.value.first?.cancelledDate else { return false }
            return da > db
        }
    }

    func startListening() {
        guard let passengerId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        _listenerBox?.remove()
        _listenerBox = JoinRequestService.shared.listenForPassengerRequests(passengerId: passengerId) { [weak self] allRequests in
            guard let self else { return }
            Task { @MainActor in await self.processRequests(allRequests) }
        }
    }

    private func processRequests(_ requests: [JoinRequestModel]) async {
        var active: [EnrolledService] = []
        var past: [EnrolledService] = []

        for req in requests {
            guard let docId = req.id else { continue }
            if req.status == "accepted" {
                if let service = await buildEnrolledService(from: req, docId: docId) {
                    active.append(service)
                }
            } else if req.status == "cancelled" || req.status == "rejected" {
                if let service = await buildEnrolledService(from: req, docId: docId) {
                    var pastService = service
                    pastService = EnrolledService(
                        id: service.id, routeId: service.routeId, driverId: service.driverId,
                        routeName: service.routeName, routeStart: service.routeStart, routeEnd: service.routeEnd,
                        session: service.session, morning: service.morning, evening: service.evening,
                        monthlyFee: service.monthlyFee, isActive: false, cancelledDate: Date()
                    )
                    past.append(pastService)
                }
            }
        }

        self.activeServices = active
        self.hasBothEnrollmentActive = active.contains { $0.session == .both }
        self.hasMorningActive = active.contains { $0.session == .morning || $0.session == .both }
        self.hasEveningActive = active.contains { $0.session == .evening || $0.session == .both }
        self.pastServices = past.sorted { ($0.cancelledDate ?? .distantPast) > ($1.cancelledDate ?? .distantPast) }
        self.isLoading = false
    }

    private func buildEnrolledService(from req: JoinRequestModel, docId: String) async -> EnrolledService? {
        guard let route = try? await RouteService.shared.fetchRoute(routeId: req.routeId) else { return nil }
        let driver = try? await DriverService.shared.fetchDriver(driverId: req.driverId)

        let driverName   = driver?.fullName ?? "Driver"
        let vehicleBrand = driver?.busInformation.busName ?? "Bus"
        let vehicleType  = driver?.busInformation.busType ?? "Bus"
        let plateNumber  = driver?.busInformation.plateNumber ?? "—"

        func timeLabel(_ date: Date) -> String {
            let f = DateFormatter(); f.dateFormat = "hh:mm a"; f.locale = Locale(identifier: "en_US_POSIX")
            return f.string(from: date)
        }

        let morningEntry = route.scheduleEntries.first
        let eveningEntry = route.scheduleEntries.count >= 2 ? route.scheduleEntries[1] : nil

        let morningInfo: EnrolledSessionInfo? = morningEntry.map {
            EnrolledSessionInfo(startTime: timeLabel($0.scheduledDepartureTime),
                                endTime: timeLabel($0.scheduledArrivalTime ?? $0.scheduledDepartureTime),
                                driverName: driverName, vehicleBrand: vehicleBrand,
                                vehicleType: vehicleType, licensePlate: plateNumber)
        }
        let eveningInfo: EnrolledSessionInfo? = eveningEntry.map {
            EnrolledSessionInfo(startTime: timeLabel($0.scheduledDepartureTime),
                                endTime: timeLabel($0.scheduledArrivalTime ?? $0.scheduledDepartureTime),
                                driverName: driverName, vehicleBrand: vehicleBrand,
                                vehicleType: vehicleType, licensePlate: plateNumber)
        }

        let sessionType: EnrolledSessionType
        let sessionFee: Double
        switch req.session {
        case "Morning": sessionType = .morning; sessionFee = route.morningPrice ?? 0
        case "Evening": sessionType = .evening; sessionFee = route.eveningPrice ?? 0
        default:        sessionType = .both;    sessionFee = route.bothTripsPrice ?? 0
        }

        return EnrolledService(
            id: docId, routeId: req.routeId, driverId: req.driverId,
            routeName: "\(route.startLocation.locationName) → \(route.endLocation.locationName)",
            routeStart: req.pickupStop, routeEnd: req.dropoffStop,
            session: sessionType,
            morning: (sessionType == .both || sessionType == .morning) ? morningInfo : nil,
            evening: (sessionType == .both || sessionType == .evening) ? eveningInfo : nil,
            monthlyFee: sessionFee, isActive: req.status == "accepted",
            activeDays: Set(route.scheduleEntries.flatMap { $0.activeDays }).sorted()
        )
    }
}
