//
//  PassengerDashboardViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-01.
//

import Foundation
import Combine
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

@MainActor
final class PassengerDashboardViewModel: ObservableObject {

    // Published state
    @Published var userName: String = ""
    @Published var selectedTrip: TripTab

    init() {
        self.selectedTrip = Calendar.current.component(.hour, from: Date()) < 12 ? .morning : .evening
    }

    // Accepted enrollment per session
    @Published var morningService: EnrolledService? = nil
    @Published var eveningService: EnrolledService? = nil

    // Active trip state per session
    @Published var morningTrip: TripModel? = nil
    @Published var eveningTrip: TripModel? = nil

    // Attendance records per session (for the relevant date)
    @Published var morningAttendance: AttendanceModel? = nil
    @Published var eveningAttendance: AttendanceModel? = nil

    @Published var isLoading: Bool = false
    @Published var isMarkingAttendance: Bool = false

    // Enums

    enum TripTab { case morning, evening }

    // Computed properties

    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var activeService: Bool {
        selectedTrip == .morning ? morningService != nil : eveningService != nil
    }

    var currentService: EnrolledService? {
        selectedTrip == .morning ? morningService : eveningService
    }

    var currentTrip: TripModel? {
        selectedTrip == .morning ? morningTrip : eveningTrip
    }

    // Only treat a trip as active/completed when it belongs to TODAY
    var isTripActive: Bool {
        guard let trip = currentTrip, trip.status == "active" else { return false }
        return Calendar.current.isDateInToday(trip.tripDate)
    }
    var isTripCompleted: Bool {
        guard let trip = currentTrip, trip.status == "completed" else { return false }
        return Calendar.current.isDateInToday(trip.tripDate)
    }

    // Attendance window
    private enum AttendanceWindowState {
        case morningWindowAvailable
        case morningWindowLocked
        case eveningWindowAvailable
        case eveningWindowLocked
        case tomorrowMorningAvailable
        case outsideWindow
    }

    private var attendanceWindowState: AttendanceWindowState {
        let inMorningWindow = Calendar.current.component(.hour, from: Date()) < 12
        switch selectedTrip {
        case .morning:
            if inMorningWindow {
                let isPassed = (morningTrip?.currentStopIndex ?? 0) > 3
                if isPassed || isTripCompleted { return .morningWindowLocked }
                return .morningWindowAvailable
            }
            // Evening time on morning tab — unlock tomorrow only if today's evening trip completed
            let eveningDone = eveningTrip != nil
                && eveningTrip!.status == "completed"
                && Calendar.current.isDateInToday(eveningTrip!.tripDate)
            return eveningDone ? .tomorrowMorningAvailable : .outsideWindow
        case .evening:
            if !inMorningWindow {
                let isPassed = (eveningTrip?.currentStopIndex ?? 0) > 3
                if isPassed || isTripCompleted { return .eveningWindowLocked }
                return .eveningWindowAvailable
            }
            return .outsideWindow
        }
    }

    // Flat properties used by the View — no nested enum exposed
    var isAttendanceOutsideWindow: Bool { attendanceWindowState == .outsideWindow }
    var isAttendanceLocked: Bool {
        attendanceWindowState == .morningWindowLocked || attendanceWindowState == .eveningWindowLocked
    }
    var isAttendanceTomorrow: Bool { attendanceWindowState == .tomorrowMorningAvailable }
    var attendanceSectionTitle: String { isAttendanceTomorrow ? "Tomorrow's Attendance" : "Today's Attendance" }

    var canChangeAttendance: Bool {
        switch attendanceWindowState {
        case .morningWindowAvailable, .eveningWindowAvailable, .tomorrowMorningAvailable: return true
        default: return false
        }
    }

    var attendanceWindowMessage: String {
        switch attendanceWindowState {
        case .morningWindowAvailable:
            return isTripActive
                ? "Update before your driver reaches your stop"
                : "Mark your attendance for today's morning trip"
        case .morningWindowLocked:
            return "Attendance locked \u{2014} bus has passed your stop or trip is completed"
        case .eveningWindowAvailable:
            return isTripActive
                ? "Update before your driver reaches your stop"
                : "Mark your attendance for today's evening trip"
        case .eveningWindowLocked:
            return "Attendance locked \u{2014} bus has passed your stop or trip is completed"
        case .tomorrowMorningAvailable:
            return "Mark your attendance for tomorrow's morning trip"
        case .outsideWindow where selectedTrip == .morning:
            return "Morning attendance is only available 12:00 AM \u{2013} 11:59 AM"
        default:
            return "Evening attendance is only available 12:00 PM \u{2013} 11:59 PM"
        }
    }

    var currentAttendanceDate: Date {
        if isAttendanceTomorrow {
            return Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        }
        return Calendar.current.startOfDay(for: Date())
    }

    var currentAttendance: AttendanceModel? {
        if isAttendanceOutsideWindow { return nil }
        return selectedTrip == .morning ? morningAttendance : eveningAttendance
    }

    var noServiceTitle: String {
        selectedTrip == .morning ? "No Morning Service" : "No Evening Service"
    }

    var noServiceSubtitle: String {
        selectedTrip == .morning
            ? "You haven't registered for a morning route yet."
            : "You haven't registered for an evening route yet."
    }

    // Private state

    private var passengerId: String = ""
    private var morningRequestId: String = ""
    private var eveningRequestId: String = ""
    private var morningDriverId: String = ""
    private var eveningDriverId: String = ""

    nonisolated(unsafe) private var _enrollmentListener: ListenerRegistration?
    nonisolated(unsafe) private var _morningTripListener: ListenerRegistration?
    nonisolated(unsafe) private var _eveningTripListener: ListenerRegistration?
    nonisolated(unsafe) private var _morningAttendanceListener: ListenerRegistration?
    nonisolated(unsafe) private var _eveningAttendanceListener: ListenerRegistration?

    deinit {
        _enrollmentListener?.remove()
        _morningTripListener?.remove()
        _eveningTripListener?.remove()
        _morningAttendanceListener?.remove()
        _eveningAttendanceListener?.remove()
    }

    // Start all listeners

    func startListening() {
        guard let user = Auth.auth().currentUser else { return }
        passengerId = user.uid

        // Load user name
        Task {
            if let userModel = try? await UserService.shared.fetchUser(userId: user.uid) {
                self.userName = userModel.fullName.isEmpty ? "Passenger" : userModel.fullName
            }
        }

        isLoading = true
        _enrollmentListener?.remove()
        _enrollmentListener = JoinRequestService.shared.listenForPassengerRequests(passengerId: user.uid) { [weak self] allRequests in
            guard let self else { return }
            Task { @MainActor in
                await self.processEnrollments(allRequests)
            }
        }
    }

    // Process enrollment changes

    private func processEnrollments(_ requests: [JoinRequestModel]) async {
        let accepted = requests.filter { $0.status == "accepted" }
        print("🔵 [PassengerDashboardVM] processEnrollments — \(accepted.count) accepted requests")

        var morning: EnrolledService? = nil
        var evening: EnrolledService? = nil
        var morningReqId = ""
        var eveningReqId = ""
        var morningDrvId = ""
        var eveningDrvId = ""

        for req in accepted {
            guard let docId = req.id else { continue }
            print("🔵 [PassengerDashboardVM] Building service for req: \(docId) driverId: \(req.driverId) session: \(req.session)")
            let service = await buildEnrolledService(from: req, docId: docId)
            guard let service else { continue }

            switch service.session {
            case .morning:
                morning = service; morningReqId = docId; morningDrvId = req.driverId
            case .evening:
                evening = service; eveningReqId = docId; eveningDrvId = req.driverId
            case .both:
                morning = service; morningReqId = docId; morningDrvId = req.driverId
                evening = service; eveningReqId = docId; eveningDrvId = req.driverId
            }
        }

        self.morningService   = morning
        self.eveningService   = evening
        self.morningRequestId = morningReqId
        self.eveningRequestId = eveningReqId
        self.morningDriverId  = morningDrvId
        self.eveningDriverId  = eveningDrvId
        self.isLoading = false

        print("🟢 [PassengerDashboardVM] morning=\(morning != nil) morningDriverId=\(morningDrvId)")
        print("🟢 [PassengerDashboardVM] evening=\(evening != nil) eveningDriverId=\(eveningDrvId)")

        // Wire trip listeners using the driverId from the joinRequest
        if !morningDrvId.isEmpty {
            attachTripListener(driverId: morningDrvId, session: "Morning", requestId: morningReqId)
        }
        if !eveningDrvId.isEmpty && eveningDrvId != morningDrvId {
            attachTripListener(driverId: eveningDrvId, session: "Evening", requestId: eveningReqId)
        } else if !eveningDrvId.isEmpty && eveningDrvId == morningDrvId {
            attachTripListener(driverId: eveningDrvId, session: "Evening", requestId: eveningReqId)
        }
    }

    // Trip listeners

    private func attachTripListener(driverId: String, session: String, requestId: String) {
        guard !driverId.isEmpty else {
            print("🔴 [PassengerDashboardVM] attachTripListener called with empty driverId — skipping")
            return
        }

        print("🔵 [PassengerDashboardVM] Attaching trip listener — driverId: \(driverId) session: \(session)")

        let listener = TripService.shared.listenForActiveTrip(driverId: driverId, session: session) { [weak self] trip in
            guard let self else { return }
            Task { @MainActor in
                let previousTrip = session == "Morning" ? self.morningTrip : self.eveningTrip
                if session == "Morning" {
                    self.morningTrip = trip
                } else {
                    self.eveningTrip = trip
                }
                print("🟢 [PassengerDashboardVM] Trip update (\(session)): \(trip?.status ?? "nil") id: \(trip?.id ?? "nil")")
                self.handleTripStateChange(trip: trip, previous: previousTrip, session: session, requestId: requestId)
            }
        }
        if session == "Morning" {
            _morningTripListener?.remove()
            _morningTripListener = listener
        } else {
            _eveningTripListener?.remove()
            _eveningTripListener = listener
        }

        // Attach attendance listener using the passenger's routeId from the joinRequest
        Task {
            if let doc = try? await Firestore.firestore().collection("joinRequests").document(requestId).getDocument(),
               let routeId = doc.data()?["routeId"] as? String, !routeId.isEmpty {
                attachAttendanceListener(
                    passengerId: passengerId,
                    routeId: routeId,
                    session: session,
                    requestId: requestId
                )
            }
        }
    }

    private func handleTripStateChange(trip: TripModel?, previous: TripModel?, session: String, requestId: String) {
        guard let trip else { return }
        let wasNil = previous == nil
        let justStarted = wasNil && trip.status == "active"
        let justCompleted = (previous?.status == "active") && trip.status == "completed"

        if justStarted {
            NotificationManager.shared.scheduleNotification(
                title: "🚌 Your Bus Has Departed!",
                body: "\(session) trip has started. Open the app to track live location.",
                actionType: "TRIP_START",
                isTripAlert: true
            )
        }

        if justCompleted {
            NotificationManager.shared.scheduleNotification(
                title: "Trip Completed",
                body: "Your \(session.lowercased()) trip is done. Mark your attendance for tomorrow!",
                actionType: "TRIP_END",
                isTripAlert: true
            )
            // Schedule a next-morning reminder notification
            scheduleAttendanceReminder(session: session)
        }
    }

    // Attendance listeners

    private func attachAttendanceListener(passengerId: String, routeId: String, session: String, requestId: String) {
        let targetDate = AttendanceService.relevantDate()
        let listener = AttendanceService.shared.listenForAttendance(
            passengerId: passengerId,
            routeId: routeId,
            session: session,
            date: targetDate
        ) { [weak self] record in
            guard let self else { return }
            Task { @MainActor in
                if session == "Morning" {
                    self.morningAttendance = record
                } else {
                    self.eveningAttendance = record
                }
            }
        }
        if session == "Morning" {
            _morningAttendanceListener?.remove()
            _morningAttendanceListener = listener
        } else {
            _eveningAttendanceListener?.remove()
            _eveningAttendanceListener = listener
        }
    }

    // Mark attendance

    func markAttendance(status: String) {
        let session = selectedTrip == .morning ? "Morning" : "Evening"
        let requestId = selectedTrip == .morning ? morningRequestId : eveningRequestId
        guard !passengerId.isEmpty, !requestId.isEmpty else { return }

        isMarkingAttendance = true
        Task {
            do {
                // Fetch the routeId from the joinRequest document
                var routeId = ""
                if let doc = try? await Firestore.firestore()
                    .collection("joinRequests").document(requestId).getDocument(),
                   let fetchedRouteId = doc.data()?["routeId"] as? String {
                    routeId = fetchedRouteId
                }
                guard !routeId.isEmpty else {
                    print("🔴 [PassengerDashboardVM] Could not resolve routeId for requestId: \(requestId)")
                    self.isMarkingAttendance = false
                    return
                }
                let targetDate = AttendanceService.relevantDate()
                try await AttendanceService.shared.markAttendance(
                    passengerId: passengerId,
                    routeId: routeId,
                    requestId: requestId,
                    session: session,
                    date: targetDate,
                    status: status
                )
                print("🟢 [PassengerDashboardVM] Marked \(session) attendance: \(status)")
            } catch {
                print("🔴 [PassengerDashboardVM] Attendance error: \(error.localizedDescription)")
            }
            self.isMarkingAttendance = false
        }
    }

    // Attendance reminder notification

    private func scheduleAttendanceReminder(session: String) {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = session == "Morning" ? 6 : 14
        components.minute = 30

        let content = UNMutableNotificationContent()
        content.title = "Mark Your Attendance"
        content.body = "Don't forget to confirm your \(session.lowercased()) trip attendance for today!"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "attendance_reminder_\(session)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("🔴 [PassengerDashboardVM] Reminder scheduling error: \(error.localizedDescription)")
            } else {
                print("🟢 [PassengerDashboardVM] \(session) reminder scheduled for tomorrow")
            }
        }
    }

    // Build EnrolledService from JoinRequestModel

    private func buildEnrolledService(from req: JoinRequestModel, docId: String) async -> EnrolledService? {
        guard let route = try? await RouteService.shared.fetchRoute(routeId: req.routeId) else { return nil }
        let driver = try? await DriverService.shared.fetchDriver(driverId: req.driverId)

        let driverName   = driver?.fullName ?? "Driver"
        let vehicleBrand = driver?.busInformation.busName ?? "Bus"
        let vehicleType  = driver?.busInformation.busType ?? "Bus"
        let plateNumber  = driver?.busInformation.plateNumber ?? "—"

        func timeLabel(_ date: Date) -> String {
            let f = DateFormatter(); f.dateFormat = "hh:mm a"
            f.locale = Locale(identifier: "en_US_POSIX"); return f.string(from: date)
        }

        let morningEntry = route.scheduleEntries.first
        let eveningEntry = route.scheduleEntries.count >= 2 ? route.scheduleEntries[1] : nil

        let morningInfo: EnrolledSessionInfo? = morningEntry.map {
            EnrolledSessionInfo(startTime: timeLabel($0.scheduledDepartureTime),
                                endTime:   timeLabel($0.scheduledArrivalTime ?? $0.scheduledDepartureTime),
                                driverName: driverName, vehicleBrand: vehicleBrand,
                                vehicleType: vehicleType, licensePlate: plateNumber)
        }
        let eveningInfo: EnrolledSessionInfo? = eveningEntry.map {
            EnrolledSessionInfo(startTime: timeLabel($0.scheduledDepartureTime),
                                endTime:   timeLabel($0.scheduledArrivalTime ?? $0.scheduledDepartureTime),
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
            id: docId,
            routeName:  "\(route.startLocation.locationName) → \(route.endLocation.locationName)",
            routeStart: req.pickupStop,
            routeEnd:   req.dropoffStop,
            session:    sessionType,
            morning:    sessionType == .both || sessionType == .morning ? morningInfo : nil,
            evening:    sessionType == .both || sessionType == .evening ? eveningInfo : nil,
            monthlyFee: sessionFee,
            isActive:   true
        )
    }
}
