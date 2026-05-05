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

    let morningAllStops: [RouteStopInfo] = []
    let eveningAllStops: [RouteStopInfo] = []

    let morningAttendanceStops: [AttendanceStopInfo] = []
    let eveningAttendanceStops: [AttendanceStopInfo] = []

    let morningSummaryStopRecords: [TripSummaryStopRecord] = []
    let eveningSummaryStopRecords: [TripSummaryStopRecord] = []

    // Core Location variables
    private var locationManager = CLLocationManager()
    @Published var currentUserLocation: CLLocationCoordinate2D?
    @Published var isNearEndingLocation: Bool = false

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.requestWhenInUseAuthorization()
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

    var isStartTripButtonEnabled: Bool {
        let currentHour = Calendar.current.component(.hour, from: Date())
        if selectedSessionType == .morning {
            return currentHour >= 5 && currentHour < 10
        } else {
            return currentHour >= 15 && currentHour < 20
        }
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
        
        NotificationManager.shared.scheduleNotification(
            title: "Trip Completed",
            body: "You have arrived at the destination. Well done!",
            actionType: "TRIP_END",
            isTripAlert: true
        )
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
                    let route = try await RouteService.shared.fetchRoute(routeId: routeId)
                    self.fetchedRouteData = route
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
                } catch {
                    print("Error fetching route for dashboard: \(error)")
                    self.morningSessionScheduledStartTime = "Unavailable"
                    self.morningSessionEstimatedEndTime = "Unavailable"
                    self.eveningSessionScheduledStartTime = "Unavailable"
                    self.eveningSessionEstimatedEndTime = "Unavailable"
                }
                
                self.totalEnrolledPassengerCount = 0
                self.isLoadingData = false
            } catch {
                self.driverFullName = "Unknown Driver"
                self.isLoadingData = false
            }
        }
    }
}
