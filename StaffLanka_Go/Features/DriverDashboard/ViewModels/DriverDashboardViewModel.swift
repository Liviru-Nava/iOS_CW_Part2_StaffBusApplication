//
//  DriverDashboardViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-08.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import CoreLocation
import MapKit

@MainActor
final class DriverDashboardViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    enum SessionType: CaseIterable, Hashable {
        case morning, evening
    }

    enum TripState {
        case beforeTrip, duringTrip, afterTrip
    }

    enum SummaryViewType {
        case textSummary, mapSummary
    }

    struct RouteStopInfo: Identifiable {
        let id = UUID()
        let stopName: String
        let passengerCount: Int
        var isCompleted: Bool
    }

    struct AttendanceStopInfo: Identifiable {
        let id = UUID()
        let stopName: String
        let confirmedPassengerCount: Int
    }

    struct TripSummaryStopRecord: Identifiable {
        let id = UUID()
        let stopName: String
        let arrivalTime: String
        let passengersPickedUp: Int
    }

    @Published var selectedSessionType: SessionType = .morning
    @Published var morningTripState: TripState = .beforeTrip
    @Published var eveningTripState: TripState = .beforeTrip
    @Published var selectedSummaryViewType: SummaryViewType = .textSummary

    @Published var driverFullName: String = "Loading..."
    @Published var totalEnrolledPassengerCount: Int = 0
    @Published var isLoadingData: Bool = false

    @Published var morningSessionScheduledStartTime: String = "Loading..."
    @Published var morningSessionEstimatedEndTime: String = "Loading..."
    @Published var eveningSessionScheduledStartTime: String = "Loading..."
    @Published var eveningSessionEstimatedEndTime: String = "Loading..."
    
    @Published var fetchedRouteData: RouteModel?

    @Published var morningAllStops: [RouteStopInfo] = []
    @Published var eveningAllStops: [RouteStopInfo] = []

    @Published var morningAttendanceStops: [AttendanceStopInfo] = []
    @Published var eveningAttendanceStops: [AttendanceStopInfo] = []

    @Published var morningSummaryStopRecords: [TripSummaryStopRecord] = []
    @Published var eveningSummaryStopRecords: [TripSummaryStopRecord] = []
    
    @Published var morningEnrolledPassengers: [SimulationEnrolledPassenger] = []
    @Published var eveningEnrolledPassengers: [SimulationEnrolledPassenger] = []

    nonisolated(unsafe) private var _morningAttendanceListener: ListenerRegistration?
    nonisolated(unsafe) private var _eveningAttendanceListener: ListenerRegistration?
    
    deinit {
        _morningAttendanceListener?.remove()
        _eveningAttendanceListener?.remove()
    }

    // Core Location variables
    private var locationManager = CLLocationManager()
    @Published var currentUserLocation: CLLocationCoordinate2D?
    @Published var isNearEndingLocation: Bool = false

    // Firestore trip tracking
    private(set) var currentRouteId: String = ""
    private var activeTripId: String? = nil
    private var locationUpdateTimer: Timer? = nil

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.requestWhenInUseAuthorization()
        self.selectedSessionType = Calendar.current.component(.hour, from: Date()) < 12 ? .morning : .evening
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        Task { @MainActor in
            self.currentUserLocation = latestLocation.coordinate
            self.checkProximityToEndingLocation(currentLocation: latestLocation)
        }
    }
    
    private func checkProximityToEndingLocation(currentLocation: CLLocation) {
        guard let route = fetchedRouteData else { return }
        let endLocation = CLLocation(latitude: route.endLocation.latitude, longitude: route.endLocation.longitude)
        let distance = currentLocation.distance(from: endLocation)
        // Enable End trip if within 200 meters
        self.isNearEndingLocation = distance <= 200
    }

    var currentTripState: TripState {
        selectedSessionType == .morning ? morningTripState : eveningTripState
    }

    var currentSessionScheduledStartTime: String {
        selectedSessionType == .morning ? morningSessionScheduledStartTime : eveningSessionScheduledStartTime
    }

    var currentSessionEstimatedEndTime: String {
        selectedSessionType == .morning ? morningSessionEstimatedEndTime : eveningSessionEstimatedEndTime
    }

    var currentSessionActiveStops: [RouteStopInfo] {
        let allStops = selectedSessionType == .morning ? morningAllStops : eveningAllStops
        return allStops.filter { $0.passengerCount > 0 }
    }

    var currentSessionAttendanceStops: [AttendanceStopInfo] {
        selectedSessionType == .morning ? morningAttendanceStops : eveningAttendanceStops
    }

    var currentSessionSummaryStopRecords: [TripSummaryStopRecord] {
        selectedSessionType == .morning ? morningSummaryStopRecords : eveningSummaryStopRecords
    }

    var currentStopName: String {
        return "Unknown"
    }

    var nextStopName: String {
        return "Unknown"
    }

    var greetingText: String {
        let currentHour = Calendar.current.component(.hour, from: Date())
        switch currentHour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // Morning: 00:00–11:59  |  Evening: 12:00–23:59
    var isStartTripButtonEnabled: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        if selectedSessionType == .morning {
            return hour >= 0 && hour < 12
        } else {
            return hour >= 12 && hour <= 23
        }
    }

    var sessionWindowHint: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if selectedSessionType == .morning && hour >= 12 {
            return "Morning trips are available 12:00 AM – 11:59 AM"
        } else if selectedSessionType == .evening && hour < 12 {
            return "Evening trips are available 12:00 PM – 11:59 PM"
        }
        return ""
    }

    var totalPassengersForCurrentSummary: Int {
        currentSessionSummaryStopRecords.reduce(0) { $0 + $1.passengersPickedUp }
    }

    func startTrip() {
        if selectedSessionType == .morning {
            morningTripState = .duringTrip
        } else {
            eveningTripState = .duringTrip
        }
        locationManager.startUpdatingLocation()

        // Persist to Firestore
        let session = selectedSessionType == .morning ? "Morning" : "Evening"
        guard let userId = Auth.auth().currentUser?.uid, !currentRouteId.isEmpty else { return }
        Task {
            do {
                let tripId = try await TripService.shared.startTrip(
                    routeId: currentRouteId,
                    driverId: userId,
                    session: session
                )
                self.activeTripId = tripId
                self.startLocationUpdateTimer()
                print("🟢 [DriverDashboardVM] Trip started, tripId: \(tripId)")
            } catch {
                print("🔴 [DriverDashboardVM] startTrip Firestore error: \(error.localizedDescription)")
            }
        }

        NotificationManager.shared.scheduleNotification(
            title: "Trip Started",
            body: "Your \(selectedSessionType == .morning ? "morning" : "evening") session has officially begun.",
            actionType: "TRIP_START",
            isTripAlert: true
        )
    }

    func finishTrip() {
        if selectedSessionType == .morning {
            morningTripState = .afterTrip
        } else {
            eveningTripState = .afterTrip
        }
        locationManager.stopUpdatingLocation()
        stopLocationUpdateTimer()

        // Persist to Firestore
        if let tripId = activeTripId {
            Task {
                do {
                    try await TripService.shared.finishTrip(tripId: tripId)
                    print("🟢 [DriverDashboardVM] Trip finished, tripId: \(tripId)")
                } catch {
                    print("🔴 [DriverDashboardVM] finishTrip Firestore error: \(error.localizedDescription)")
                }
            }
            activeTripId = nil
        }

        NotificationManager.shared.scheduleNotification(
            title: "Trip Completed",
            body: "You have arrived at the destination. Well done!",
            actionType: "TRIP_END",
            isTripAlert: true
        )
    }

    // Location update timer (pushes GPS to Firestore every 5 s)

    private func startLocationUpdateTimer() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self, let coord = self.currentUserLocation, let tripId = self.activeTripId else { return }
            Task {
                try? await TripService.shared.updateDriverLocation(tripId: tripId, location: coord)
            }
        }
    }

    private func stopLocationUpdateTimer() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }

    func selectSession(_ session: SessionType) {
        selectedSessionType = session
    }

    func fetchDriverData() {
        guard let userId = FirebaseAuth.Auth.auth().currentUser?.uid else { return }

        isLoadingData = true
        Task {
            do {
                let driver = try await DriverService.shared.fetchDriver(driverId: userId)
                self.driverFullName = driver.fullName
                
                do {
                    let routeId = driver.assignedRouteId
                self.currentRouteId = routeId
                    let route = try await RouteService.shared.fetchRoute(routeId: routeId)
                    self.fetchedRouteData = route

                    // Fetch actual enrolled passenger count and join requests
                    let snapshot = try? await Firestore.firestore()
                        .collection("joinRequests")
                        .whereField("routeId", isEqualTo: routeId)
                        .whereField("status", isEqualTo: "accepted")
                        .getDocuments()
                    
                    if let docs = snapshot?.documents {
                        let requests = docs.compactMap { try? $0.data(as: JoinRequestModel.self) }
                        self.totalEnrolledPassengerCount = requests.count
                        print("🟢 [DriverDashboardVM] Enrolled passengers: \(self.totalEnrolledPassengerCount)")
                        
                        var mPass: [SimulationEnrolledPassenger] = []
                        var ePass: [SimulationEnrolledPassenger] = []
                        
                        for req in requests {
                            let passengerId = req.passengerId ?? UUID().uuidString
                            if req.session == "Morning" || req.session == "Both" {
                                mPass.append(SimulationEnrolledPassenger(id: passengerId, fullName: req.passengerName, assignedStopName: req.pickupStop, attendanceStatusLabel: "Not marked"))
                            }
                            if req.session == "Evening" || req.session == "Both" {
                                ePass.append(SimulationEnrolledPassenger(id: passengerId, fullName: req.passengerName, assignedStopName: req.dropoffStop, attendanceStatusLabel: "Not marked"))
                            }
                        }
                        self.morningEnrolledPassengers = mPass
                        self.eveningEnrolledPassengers = ePass
                    } else {
                        self.totalEnrolledPassengerCount = 0
                    }

                    let timeFormatter = DateFormatter()
                    timeFormatter.timeStyle = .short
                    
                    if route.scheduleEntries.count > 0 {
                        let morningStr = route.scheduleEntries[0]
                        self.morningSessionScheduledStartTime = timeFormatter.string(from: morningStr.scheduledDepartureTime)
                        if let arr = morningStr.scheduledArrivalTime {
                            self.morningSessionEstimatedEndTime = timeFormatter.string(from: arr)
                        } else {
                            self.morningSessionEstimatedEndTime = "TBD"
                        }
                    } else {
                        self.morningSessionScheduledStartTime = "N/A"
                        self.morningSessionEstimatedEndTime = "N/A"
                    }
                    if route.scheduleEntries.count > 1 {
                        let eveningStr = route.scheduleEntries[1]
                        self.eveningSessionScheduledStartTime = timeFormatter.string(from: eveningStr.scheduledDepartureTime)
                        if let arr = eveningStr.scheduledArrivalTime {
                            self.eveningSessionEstimatedEndTime = timeFormatter.string(from: arr)
                        } else {
                            self.eveningSessionEstimatedEndTime = "TBD"
                        }
                    } else {
                        self.eveningSessionScheduledStartTime = "N/A"
                        self.eveningSessionEstimatedEndTime = "N/A"
                    }
                    
                    // Start listeners after fetching route and joinRequests
                    self.startAttendanceListeners(routeId: routeId)
                    
                } catch {
                    print("🔴 [DriverDashboardVM] Error fetching route for dashboard: \(error)")
                    self.morningSessionScheduledStartTime = "Unavailable"
                    self.morningSessionEstimatedEndTime = "Unavailable"
                    self.eveningSessionScheduledStartTime = "Unavailable"
                    self.eveningSessionEstimatedEndTime = "Unavailable"
                }
                
                self.isLoadingData = false
            } catch {
                self.driverFullName = "Unknown Driver"
                self.isLoadingData = false
            }
        }
    }

    private func startAttendanceListeners(routeId: String) {
        let date = AttendanceService.relevantDate()
        
        _morningAttendanceListener?.remove()
        _morningAttendanceListener = AttendanceService.shared.listenForRouteAttendance(routeId: routeId, session: "Morning", date: date) { [weak self] records in
            guard let self = self else { return }
            Task { @MainActor in
                self.processAttendance(records: records, session: .morning)
            }
        }
        
        _eveningAttendanceListener?.remove()
        _eveningAttendanceListener = AttendanceService.shared.listenForRouteAttendance(routeId: routeId, session: "Evening", date: date) { [weak self] records in
            guard let self = self else { return }
            Task { @MainActor in
                self.processAttendance(records: records, session: .evening)
            }
        }
    }

    private func processAttendance(records: [AttendanceModel], session: SessionType) {
        
        // Statuses that should be counted
        let validStatuses: Set<String> = ["attending", "not_sure"]

        let countedPassengerIds = Set(
            records
                .filter { validStatuses.contains($0.status) }
                .map { $0.passengerId }
        )

        let allRecordsDict = Dictionary(
            uniqueKeysWithValues: records.map { ($0.passengerId, $0.status) }
        )

        var stopCounts: [String: Int] = [:]

        if session == .morning {

            for i in 0..<morningEnrolledPassengers.count {

                let pId = morningEnrolledPassengers[i].id

                if let status = allRecordsDict[pId] {

                    let newLabel: String

                    switch status {
                    case "attending":
                        newLabel = "Attending"

                    case "not_sure":
                        newLabel = "Not Sure"

                    case "absent":
                        newLabel = "Not coming"

                    default:
                        newLabel = "Not marked"
                    }

                    let existing = morningEnrolledPassengers[i]

                    morningEnrolledPassengers[i] = SimulationEnrolledPassenger(
                        id: existing.id,
                        fullName: existing.fullName,
                        assignedStopName: existing.assignedStopName,
                        attendanceStatusLabel: newLabel
                    )
                }

                // Count attending + not_sure
                if countedPassengerIds.contains(pId) {
                    stopCounts[morningEnrolledPassengers[i].assignedStopName, default: 0] += 1
                }
            }

            self.morningAttendanceStops = stopCounts
                .map {
                    AttendanceStopInfo(
                        stopName: $0.key,
                        confirmedPassengerCount: $0.value
                    )
                }
                .sorted { $0.stopName < $1.stopName }

        } else {

            for i in 0..<eveningEnrolledPassengers.count {

                let pId = eveningEnrolledPassengers[i].id

                if let status = allRecordsDict[pId] {

                    let newLabel: String

                    switch status {
                    case "attending":
                        newLabel = "Attending"

                    case "not_sure":
                        newLabel = "Not Sure"

                    case "absent":
                        newLabel = "Not coming"

                    default:
                        newLabel = "Not marked"
                    }

                    let existing = eveningEnrolledPassengers[i]

                    eveningEnrolledPassengers[i] = SimulationEnrolledPassenger(
                        id: existing.id,
                        fullName: existing.fullName,
                        assignedStopName: existing.assignedStopName,
                        attendanceStatusLabel: newLabel
                    )
                }

                // Count attending + not_sure
                if countedPassengerIds.contains(pId) {
                    stopCounts[eveningEnrolledPassengers[i].assignedStopName, default: 0] += 1
                }
            }

            self.eveningAttendanceStops = stopCounts
                .map {
                    AttendanceStopInfo(
                        stopName: $0.key,
                        confirmedPassengerCount: $0.value
                    )
                }
                .sorted { $0.stopName < $1.stopName }
        }
    }}

