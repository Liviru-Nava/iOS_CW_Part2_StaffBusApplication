//
//  DriverDashboardViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-08.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class DriverDashboardViewModel: ObservableObject {

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

    let driverFullName: String = "Kamal Perera"
    let totalEnrolledPassengerCount: Int = 24

    let morningSessionScheduledStartTime: String = "6:30 AM"
    let morningSessionEstimatedEndTime: String = "7:45 AM"
    let eveningSessionScheduledStartTime: String = "5:00 PM"
    let eveningSessionEstimatedEndTime: String = "6:15 PM"

    let morningAllStops: [RouteStopInfo] = [
        RouteStopInfo(stopName: "Nugegoda Junction", passengerCount: 6, isCompleted: false),
        RouteStopInfo(stopName: "Maharagama Town", passengerCount: 4, isCompleted: false),
        RouteStopInfo(stopName: "Borella", passengerCount: 7, isCompleted: false),
        RouteStopInfo(stopName: "Fort Railway Station", passengerCount: 0, isCompleted: false),
        RouteStopInfo(stopName: "World Trade Center", passengerCount: 7, isCompleted: false),
    ]

    let eveningAllStops: [RouteStopInfo] = [
        RouteStopInfo(stopName: "World Trade Center", passengerCount: 7, isCompleted: false),
        RouteStopInfo(stopName: "Borella", passengerCount: 7, isCompleted: false),
        RouteStopInfo(stopName: "Maharagama Town", passengerCount: 4, isCompleted: false),
        RouteStopInfo(stopName: "Nugegoda Junction", passengerCount: 6, isCompleted: false),
    ]

    let morningAttendanceStops: [AttendanceStopInfo] = [
        AttendanceStopInfo(stopName: "Nugegoda Junction", confirmedPassengerCount: 6),
        AttendanceStopInfo(stopName: "Maharagama Town", confirmedPassengerCount: 4),
        AttendanceStopInfo(stopName: "Borella", confirmedPassengerCount: 7),
        AttendanceStopInfo(stopName: "Fort Railway Station", confirmedPassengerCount: 0),
        AttendanceStopInfo(stopName: "World Trade Center", confirmedPassengerCount: 7),
    ]

    let eveningAttendanceStops: [AttendanceStopInfo] = [
        AttendanceStopInfo(stopName: "World Trade Center", confirmedPassengerCount: 7),
        AttendanceStopInfo(stopName: "Borella", confirmedPassengerCount: 7),
        AttendanceStopInfo(stopName: "Maharagama Town", confirmedPassengerCount: 4),
        AttendanceStopInfo(stopName: "Nugegoda Junction", confirmedPassengerCount: 6),
    ]

    let morningSummaryStopRecords: [TripSummaryStopRecord] = [
        TripSummaryStopRecord(stopName: "Nugegoda Junction", arrivalTime: "6:38 AM", passengersPickedUp: 6),
        TripSummaryStopRecord(stopName: "Maharagama Town", arrivalTime: "6:50 AM", passengersPickedUp: 4),
        TripSummaryStopRecord(stopName: "Borella", arrivalTime: "7:10 AM", passengersPickedUp: 7),
        TripSummaryStopRecord(stopName: "World Trade Center", arrivalTime: "7:41 AM", passengersPickedUp: 7),
    ]

    let eveningSummaryStopRecords: [TripSummaryStopRecord] = [
        TripSummaryStopRecord(stopName: "World Trade Center", arrivalTime: "5:08 PM", passengersPickedUp: 7),
        TripSummaryStopRecord(stopName: "Borella", arrivalTime: "5:30 PM", passengersPickedUp: 7),
        TripSummaryStopRecord(stopName: "Maharagama Town", arrivalTime: "5:52 PM", passengersPickedUp: 4),
        TripSummaryStopRecord(stopName: "Nugegoda Junction", arrivalTime: "6:10 PM", passengersPickedUp: 6),
    ]

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
        selectedSessionType == .morning ? "Borella" : "Borella"
    }

    var nextStopName: String {
        selectedSessionType == .morning ? "Fort Railway Station" : "Maharagama Town"
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
    }

    func finishTrip() {
        if selectedSessionType == .morning {
            morningTripState = .afterTrip
        } else {
            eveningTripState = .afterTrip
        }
    }

    func selectSession(_ session: SessionType) {
        selectedSessionType = session
    }
}
