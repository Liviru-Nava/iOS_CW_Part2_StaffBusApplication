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

    @Published var userName: String = ""
    @Published var selectedTrip: TripTab

    init() {
        self.selectedTrip = Calendar.current.component(.hour, from: Date()) < 12 ? .morning : .evening
    }

    @Published var morningService: EnrolledService? = nil
    @Published var eveningService: EnrolledService? = nil

    @Published var morningTrip: TripModel? = nil
    @Published var eveningTrip: TripModel? = nil

    @Published var morningAttendance: AttendanceModel? = nil
    @Published var eveningAttendance: AttendanceModel? = nil

    @Published var isLoading: Bool = false
    @Published var isMarkingAttendance: Bool = false

    enum TripTab { case morning, evening }

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

    var isTripActive: Bool {
        guard let trip = currentTrip, trip.status == "active" else { return false }
        return Calendar.current.isDateInToday(trip.tripDate)
    }

    var isTripCompleted: Bool {
        guard let trip = currentTrip, trip.status == "completed" else { return false }
        return Calendar.current.isDateInToday(trip.tripDate)
    }

    //Returns true if today's weekday abbreviation (e.g. "Mon", "Tue") is in the
    //service's activeDays list.  When activeDays is empty we assume all days operate.
    private func todayIsOperatingDay(for service: EnrolledService?) -> Bool {
        guard let service = service, !service.activeDays.isEmpty else { return true }
        let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let weekdayIndex = Calendar.current.component(.weekday, from: Date()) - 1 // 1-based → 0-based
        let todayAbbrev = weekdaySymbols[weekdayIndex]
        return service.activeDays.contains(todayAbbrev)
    }

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
            // If today is not an operating day for the morning service, show nothing.
            // Exception: if the evening trip was just completed today we allow marking
            // tomorrow's morning attendance regardless of today's day status.
            let eveningDone = eveningTrip != nil
                && eveningTrip!.status == "completed"
                && Calendar.current.isDateInToday(eveningTrip!.tripDate)

            if !todayIsOperatingDay(for: morningService) {
                // Still allow "tomorrow morning" marking after evening trip ends
                return eveningDone ? .tomorrowMorningAvailable : .outsideWindow
            }

            if inMorningWindow {
                let isPassed = (morningTrip?.currentStopIndex ?? 0) > 3
                if isPassed || isTripCompleted { return .morningWindowLocked }
                return .morningWindowAvailable
            }
            return eveningDone ? .tomorrowMorningAvailable : .outsideWindow

        case .evening:
            // If today is not an operating day for the evening service, hide attendance.
            if !todayIsOperatingDay(for: eveningService) { return .outsideWindow }

            if !inMorningWindow {
                let isPassed = (eveningTrip?.currentStopIndex ?? 0) > 3
                if isPassed || isTripCompleted { return .eveningWindowLocked }
                return .eveningWindowAvailable
            }
            return .outsideWindow
        }
    }

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
            // Check if the service doesn't operate today
            let service = morningService
            if let service = service, !service.activeDays.isEmpty, !todayIsOperatingDay(for: service) {
                let daysLabel = service.activeDays.joined(separator: ", ")
                return "No morning service today — this route operates on: \(daysLabel)"
            }
            return "Morning attendance is only available 12:00 AM \u{2013} 11:59 AM"
        default:
            let service = eveningService
            if let service = service, !service.activeDays.isEmpty, !todayIsOperatingDay(for: service) {
                let daysLabel = service.activeDays.joined(separator: ", ")
                return "No evening service today — this route operates on: \(daysLabel)"
            }
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

    private var passengerId: String = ""
    private var morningRequestId: String = ""
    private var eveningRequestId: String = ""
    private var morningDriverId: String = ""
    private var eveningDriverId: String = ""

    private var cachedMorningRouteStops: [String] = []
    private var cachedEveningRouteStops: [String] = []
    private var hasAlreadyFiredMorningPickupProximityAlert: Bool = false
    private var hasAlreadyFiredMorningDropoffProximityAlert: Bool = false
    private var hasAlreadyFiredEveningPickupProximityAlert: Bool = false
    private var hasAlreadyFiredEveningDropoffProximityAlert: Bool = false
    private let proximityAlertThresholdInMinutes: Int = 5
    private let simulationTotalDurationSeconds: Double = 90.0

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

    func startListening() {
        guard let user = Auth.auth().currentUser else { return }
        passengerId = user.uid

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

    private func processEnrollments(_ requests: [JoinRequestModel]) async {
        let acceptedRequests = requests.filter { $0.status == "accepted" }
        print("[PassengerDashboardVM] processEnrollments — \(acceptedRequests.count) accepted requests")

        var morningBuiltService: EnrolledService? = nil
        var eveningBuiltService: EnrolledService? = nil
        var resolvedMorningRequestId = ""
        var resolvedEveningRequestId = ""
        var resolvedMorningDriverId = ""
        var resolvedEveningDriverId = ""

        for singleRequest in acceptedRequests {
            guard let documentId = singleRequest.id else { continue }
            let builtService = await buildEnrolledService(from: singleRequest, docId: documentId)
            guard let builtService else { continue }

            switch builtService.session {
            case .morning:
                morningBuiltService = builtService
                resolvedMorningRequestId = documentId
                resolvedMorningDriverId = singleRequest.driverId
            case .evening:
                eveningBuiltService = builtService
                resolvedEveningRequestId = documentId
                resolvedEveningDriverId = singleRequest.driverId
            case .both:
                morningBuiltService = builtService
                resolvedMorningRequestId = documentId
                resolvedMorningDriverId = singleRequest.driverId
                eveningBuiltService = builtService
                resolvedEveningRequestId = documentId
                resolvedEveningDriverId = singleRequest.driverId
            }
        }

        self.morningService = morningBuiltService
        self.eveningService = eveningBuiltService
        self.morningRequestId = resolvedMorningRequestId
        self.eveningRequestId = resolvedEveningRequestId
        self.morningDriverId = resolvedMorningDriverId
        self.eveningDriverId = resolvedEveningDriverId
        self.isLoading = false

        if !resolvedMorningDriverId.isEmpty {
            await prefetchAndCacheRouteStops(requestId: resolvedMorningRequestId, session: "Morning")
            attachTripListener(driverId: resolvedMorningDriverId, session: "Morning", requestId: resolvedMorningRequestId)
        }
        if !resolvedEveningDriverId.isEmpty && resolvedEveningDriverId != resolvedMorningDriverId {
            await prefetchAndCacheRouteStops(requestId: resolvedEveningRequestId, session: "Evening")
            attachTripListener(driverId: resolvedEveningDriverId, session: "Evening", requestId: resolvedEveningRequestId)
        } else if !resolvedEveningDriverId.isEmpty && resolvedEveningDriverId == resolvedMorningDriverId {
            await prefetchAndCacheRouteStops(requestId: resolvedEveningRequestId, session: "Evening")
            attachTripListener(driverId: resolvedEveningDriverId, session: "Evening", requestId: resolvedEveningRequestId)
        }
    }

    private func prefetchAndCacheRouteStops(requestId: String, session: String) async {
        do {
            let joinRequestDocument = try await Firestore.firestore()
                .collection("joinRequests")
                .document(requestId)
                .getDocument()

            guard let documentData = joinRequestDocument.data(),
                  let routeId = documentData["routeId"] as? String,
                  !routeId.isEmpty else { return }

            let fetchedRouteModel = try await RouteService.shared.fetchRoute(routeId: routeId)
            let orderedStopNames = buildOrderedStopNamesFromRouteModel(routeModel: fetchedRouteModel, sessionLabel: session)

            if session == "Morning" {
                cachedMorningRouteStops = orderedStopNames
                hasAlreadyFiredMorningPickupProximityAlert = false
                hasAlreadyFiredMorningDropoffProximityAlert = false
            } else {
                cachedEveningRouteStops = orderedStopNames
                hasAlreadyFiredEveningPickupProximityAlert = false
                hasAlreadyFiredEveningDropoffProximityAlert = false
            }

            print("[PassengerDashboardVM] Cached \(orderedStopNames.count) stops for \(session) session.")
        } catch {
            print("[PassengerDashboardVM] Failed to prefetch route stops for \(session): \(error.localizedDescription)")
        }
    }

    private func buildOrderedStopNamesFromRouteModel(routeModel: RouteModel, sessionLabel: String) -> [String] {
        let startStopName = routeModel.startName ?? routeModel.startLocation.locationName
        let endStopName = routeModel.endName ?? routeModel.endLocation.locationName
        let intermediateStopNames = routeModel.routeStops
            .sorted(by: { $0.stopOrder < $1.stopOrder })
            .map(\.stopName)

        var orderedStopNames = [startStopName] + intermediateStopNames + [endStopName]

        if sessionLabel == "Evening" {
            orderedStopNames.reverse()
        }

        return orderedStopNames
    }

    private func attachTripListener(driverId: String, session: String, requestId: String) {
        guard !driverId.isEmpty else { return }

        print("[PassengerDashboardVM] Attaching trip listener — driverId: \(driverId) session: \(session)")

        let tripListener = TripService.shared.listenForActiveTrip(driverId: driverId, session: session) { [weak self] updatedTrip in
            guard let self else { return }
            Task { @MainActor in
                let previousTripState = session == "Morning" ? self.morningTrip : self.eveningTrip

                if session == "Morning" {
                    self.morningTrip = updatedTrip
                } else {
                    self.eveningTrip = updatedTrip
                }

                print("[PassengerDashboardVM] Trip update (\(session)): \(updatedTrip?.status ?? "nil") stopIndex: \(updatedTrip?.currentStopIndex ?? -1)")
                self.handleTripStateChange(trip: updatedTrip, previous: previousTripState, session: session, requestId: requestId)
            }
        }

        if session == "Morning" {
            _morningTripListener?.remove()
            _morningTripListener = tripListener
        } else {
            _eveningTripListener?.remove()
            _eveningTripListener = tripListener
        }

        Task {
            if let joinRequestDoc = try? await Firestore.firestore().collection("joinRequests").document(requestId).getDocument(),
               let routeId = joinRequestDoc.data()?["routeId"] as? String, !routeId.isEmpty {
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
        let currentPassengerId = passengerId

        if let activeTripUpdate = trip, activeTripUpdate.status == "active" {
            let tripJustBecameActive = previous == nil || previous?.status != "active"

            if tripJustBecameActive {
                resetProximityAlertFlagsForSession(session: session)
                NotificationManager.shared.scheduleNotification(
                    title: "Your Bus Has Departed",
                    body: "\(session) trip has started. Open the app to track the live location.",
                    actionType: "TRIP_START",
                    isTripAlert: true,
                    explicitUserId: currentPassengerId
                )
            }

            let currentStopIndex = activeTripUpdate.currentStopIndex ?? 0
            evaluateProximityAlertForSession(
                session: session,
                currentStopIndex: currentStopIndex,
                passengerId: currentPassengerId
            )
        }

        if let completedTripUpdate = trip, completedTripUpdate.status == "completed",
           previous?.status == "active" {
            NotificationManager.shared.scheduleNotification(
                title: "Trip Completed",
                body: "Your \(session.lowercased()) trip has ended. Have a great day!",
                actionType: "TRIP_END",
                isTripAlert: true,
                explicitUserId: currentPassengerId
            )
            scheduleAttendanceReminder(session: session)
        }
    }

    private func evaluateProximityAlertForSession(session: String, currentStopIndex: Int, passengerId: String) {
        guard let enrolledService = (session == "Morning" ? morningService : eveningService) else { return }

        let cachedStopsForSession = session == "Morning" ? cachedMorningRouteStops : cachedEveningRouteStops
        guard !cachedStopsForSession.isEmpty else { return }

        let passengerPickupStopName = enrolledService.routeStart
        let passengerDropOffStopName = enrolledService.routeEnd

        let safeCurrentStopIndex = min(currentStopIndex, cachedStopsForSession.count - 1)

        let indexOfPassengerPickupStop = cachedStopsForSession.firstIndex(of: passengerPickupStopName)
            ?? cachedStopsForSession.count - 1
        let indexOfPassengerDropOffStop = cachedStopsForSession.firstIndex(of: passengerDropOffStopName)
            ?? cachedStopsForSession.count - 1

        let passengerHasAlreadyBeenPickedUp = safeCurrentStopIndex > indexOfPassengerPickupStop

        let indexOfPassengerRelevantStop = passengerHasAlreadyBeenPickedUp
            ? indexOfPassengerDropOffStop
            : indexOfPassengerPickupStop

        let numberOfStopsRemainingUntilPassengerRelevantStop = max(
            indexOfPassengerRelevantStop - safeCurrentStopIndex,
            0
        )

        let totalNumberOfStopsInRoute = max(cachedStopsForSession.count - 1, 1)
        let minutesPerStop = (simulationTotalDurationSeconds / 60.0) / Double(totalNumberOfStopsInRoute)
        let estimatedMinutesUntilPassengerRelevantStop = Int(
            Double(numberOfStopsRemainingUntilPassengerRelevantStop) * minutesPerStop
        )

        print("[PassengerDashboardVM] Proximity check (\(session)) — stopIndex: \(safeCurrentStopIndex), stopsUntilRelevant: \(numberOfStopsRemainingUntilPassengerRelevantStop), estMins: \(estimatedMinutesUntilPassengerRelevantStop), pickedUp: \(passengerHasAlreadyBeenPickedUp)")

        let hasAlreadyFiredPickup = session == "Morning"
            ? hasAlreadyFiredMorningPickupProximityAlert
            : hasAlreadyFiredEveningPickupProximityAlert
        let hasAlreadyFiredDropoff = session == "Morning"
            ? hasAlreadyFiredMorningDropoffProximityAlert
            : hasAlreadyFiredEveningDropoffProximityAlert

        if !passengerHasAlreadyBeenPickedUp
            && !hasAlreadyFiredPickup
            && estimatedMinutesUntilPassengerRelevantStop <= proximityAlertThresholdInMinutes
            && estimatedMinutesUntilPassengerRelevantStop >= 0 {

            if session == "Morning" {
                hasAlreadyFiredMorningPickupProximityAlert = true
            } else {
                hasAlreadyFiredEveningPickupProximityAlert = true
            }

            NotificationManager.shared.scheduleNotification(
                title: "Bus Approaching Your Pickup Stop",
                body: "Your bus is approximately \(estimatedMinutesUntilPassengerRelevantStop) minute\(estimatedMinutesUntilPassengerRelevantStop == 1 ? "" : "s") away from \(passengerPickupStopName). Please be ready.",
                actionType: "BUS_APPROACHING_PICKUP",
                isTripAlert: true,
                explicitUserId: passengerId
            )
        }

        if passengerHasAlreadyBeenPickedUp
            && !hasAlreadyFiredDropoff
            && estimatedMinutesUntilPassengerRelevantStop <= proximityAlertThresholdInMinutes
            && estimatedMinutesUntilPassengerRelevantStop >= 0 {

            if session == "Morning" {
                hasAlreadyFiredMorningDropoffProximityAlert = true
            } else {
                hasAlreadyFiredEveningDropoffProximityAlert = true
            }

            NotificationManager.shared.scheduleNotification(
                title: "Approaching Your Drop-off Stop",
                body: "Your destination \(passengerDropOffStopName) is approximately \(estimatedMinutesUntilPassengerRelevantStop) minute\(estimatedMinutesUntilPassengerRelevantStop == 1 ? "" : "s") away. Prepare to alight.",
                actionType: "BUS_APPROACHING_DROPOFF",
                isTripAlert: true,
                explicitUserId: passengerId
            )
        }
    }

    private func resetProximityAlertFlagsForSession(session: String) {
        if session == "Morning" {
            hasAlreadyFiredMorningPickupProximityAlert = false
            hasAlreadyFiredMorningDropoffProximityAlert = false
        } else {
            hasAlreadyFiredEveningPickupProximityAlert = false
            hasAlreadyFiredEveningDropoffProximityAlert = false
        }
    }

    private func attachAttendanceListener(passengerId: String, routeId: String, session: String, requestId: String) {
        let targetDate = AttendanceService.relevantDate()
        let attendanceListener = AttendanceService.shared.listenForAttendance(
            passengerId: passengerId,
            routeId: routeId,
            session: session,
            date: targetDate
        ) { [weak self] fetchedRecord in
            guard let self else { return }
            Task { @MainActor in
                if session == "Morning" {
                    self.morningAttendance = fetchedRecord
                } else {
                    self.eveningAttendance = fetchedRecord
                }
            }
        }

        if session == "Morning" {
            _morningAttendanceListener?.remove()
            _morningAttendanceListener = attendanceListener
        } else {
            _eveningAttendanceListener?.remove()
            _eveningAttendanceListener = attendanceListener
        }
    }

    func markAttendance(status: String) {
        let sessionLabel = selectedTrip == .morning ? "Morning" : "Evening"
        let activeRequestId = selectedTrip == .morning ? morningRequestId : eveningRequestId
        guard !passengerId.isEmpty, !activeRequestId.isEmpty else { return }

        isMarkingAttendance = true
        Task {
            do {
                var resolvedRouteId = ""
                if let joinRequestDoc = try? await Firestore.firestore()
                    .collection("joinRequests").document(activeRequestId).getDocument(),
                   let fetchedRouteId = joinRequestDoc.data()?["routeId"] as? String {
                    resolvedRouteId = fetchedRouteId
                }
                guard !resolvedRouteId.isEmpty else {
                    print("[PassengerDashboardVM] Could not resolve routeId for requestId: \(activeRequestId)")
                    self.isMarkingAttendance = false
                    return
                }
                let targetDate = AttendanceService.relevantDate()
                try await AttendanceService.shared.markAttendance(
                    passengerId: passengerId,
                    routeId: resolvedRouteId,
                    requestId: activeRequestId,
                    session: sessionLabel,
                    date: targetDate,
                    status: status
                )
                print("[PassengerDashboardVM] Marked \(sessionLabel) attendance: \(status)")
            } catch {
                print("[PassengerDashboardVM] Attendance error: \(error.localizedDescription)")
            }
            self.isMarkingAttendance = false
        }
    }

    private func scheduleAttendanceReminder(session: String) {
        var tomorrowComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        tomorrowComponents.day! += 1
        tomorrowComponents.hour = session == "Morning" ? 6 : 14
        tomorrowComponents.minute = 30

        let reminderNotificationContent = UNMutableNotificationContent()
        reminderNotificationContent.title = "Mark Your Attendance"
        reminderNotificationContent.body = "Don't forget to confirm your \(session.lowercased()) trip attendance for today!"
        reminderNotificationContent.sound = .default

        let calendarTrigger = UNCalendarNotificationTrigger(dateMatching: tomorrowComponents, repeats: false)
        let reminderRequest = UNNotificationRequest(
            identifier: "attendance_reminder_\(session)_\(Date().timeIntervalSince1970)",
            content: reminderNotificationContent,
            trigger: calendarTrigger
        )
        UNUserNotificationCenter.current().add(reminderRequest) { schedulingError in
            if let schedulingError {
                print("[PassengerDashboardVM] Reminder scheduling error: \(schedulingError.localizedDescription)")
            } else {
                print("[PassengerDashboardVM] \(session) reminder scheduled for tomorrow.")
            }
        }
    }

    private func buildEnrolledService(from req: JoinRequestModel, docId: String) async -> EnrolledService? {
        guard let route = try? await RouteService.shared.fetchRoute(routeId: req.routeId) else { return nil }
        let driverProfile = try? await DriverService.shared.fetchDriver(driverId: req.driverId)

        let driverFullName = driverProfile?.fullName ?? "Driver"
        let vehicleBrandName = driverProfile?.busInformation.busName ?? "Bus"
        let vehicleTypeName = driverProfile?.busInformation.busType ?? "Bus"
        let licensePlateNumber = driverProfile?.busInformation.plateNumber ?? "—"

        func formattedTimeLabel(_ date: Date) -> String {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "hh:mm a"
            timeFormatter.locale = Locale(identifier: "en_US_POSIX")
            return timeFormatter.string(from: date)
        }

        let morningScheduleEntry = route.scheduleEntries.first
        let eveningScheduleEntry = route.scheduleEntries.count >= 2 ? route.scheduleEntries[1] : nil

        let morningSessionInfo: EnrolledSessionInfo? = morningScheduleEntry.map {
            EnrolledSessionInfo(
                startTime: formattedTimeLabel($0.scheduledDepartureTime),
                endTime: formattedTimeLabel($0.scheduledArrivalTime ?? $0.scheduledDepartureTime),
                driverName: driverFullName,
                vehicleBrand: vehicleBrandName,
                vehicleType: vehicleTypeName,
                licensePlate: licensePlateNumber
            )
        }
        let eveningSessionInfo: EnrolledSessionInfo? = eveningScheduleEntry.map {
            EnrolledSessionInfo(
                startTime: formattedTimeLabel($0.scheduledDepartureTime),
                endTime: formattedTimeLabel($0.scheduledArrivalTime ?? $0.scheduledDepartureTime),
                driverName: driverFullName,
                vehicleBrand: vehicleBrandName,
                vehicleType: vehicleTypeName,
                licensePlate: licensePlateNumber
            )
        }

        let resolvedSessionType: EnrolledSessionType
        let resolvedSessionFee: Double
        switch req.session {
        case "Morning": resolvedSessionType = .morning; resolvedSessionFee = route.morningPrice ?? 0
        case "Evening": resolvedSessionType = .evening; resolvedSessionFee = route.eveningPrice ?? 0
        default:        resolvedSessionType = .both;    resolvedSessionFee = route.bothTripsPrice ?? 0
        }

        return EnrolledService(
            id: docId,
            routeId: req.routeId,
            driverId: req.driverId,
            routeName: "\(route.startLocation.locationName) → \(route.endLocation.locationName)",
            routeStart: req.pickupStop,
            routeEnd: req.dropoffStop,
            session: resolvedSessionType,
            morning: resolvedSessionType == .both || resolvedSessionType == .morning ? morningSessionInfo : nil,
            evening: resolvedSessionType == .both || resolvedSessionType == .evening ? eveningSessionInfo : nil,
            monthlyFee: resolvedSessionFee,
            isActive: true,
            activeDays: route.scheduleEntries.first?.activeDays ?? []
        )
    }
}
