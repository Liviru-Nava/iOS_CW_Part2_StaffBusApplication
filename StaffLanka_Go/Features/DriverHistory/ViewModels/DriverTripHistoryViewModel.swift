//
//  DriverTripHistoryViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-09.

import Foundation
import SwiftUI
import Combine

enum DriverTripCompletionStatus: String {
    case completed = "Completed"
    case autoCompleted = "Auto Completed"
}

enum DriverTripStopStatus {
    case completed, skipped
}

enum DriverTripDetailDisplayMode {
    case textView, mapView
}

struct DriverTripStopRecord: Identifiable {
    let id = UUID()
    let stopName: String
    let timeReached: String
    let stopStatus: DriverTripStopStatus
}

struct DriverTripPassengerPickupRecord: Identifiable {
    let id = UUID()
    let passengerFullName: String
    let boardingStopName: String
}

struct DriverTripPerformanceSummary {
    let totalStopCount: Int
    let completedStopCount: Int
    let totalPassengersPickedUp: Int
    let tripDurationInMinutes: Int
}

struct DriverHistoryTripRecord: Identifiable {
    let id = UUID()
    let tripDate: Date
    let sessionType: TripSession
    let completionStatus: DriverTripCompletionStatus
    let scheduledStartTime: String
    let actualEndTime: String
    let stopsTimeline: [DriverTripStopRecord]
    let passengerPickupList: [DriverTripPassengerPickupRecord]
    let performanceSummary: DriverTripPerformanceSummary
}

@MainActor
final class DriverTripHistoryViewModel: ObservableObject {

    @Published var selectedTripForDetailView: DriverHistoryTripRecord? = nil
    @Published var selectedTripDetailDisplayMode: DriverTripDetailDisplayMode = .textView
    @Published var selectedDateRangeFilter: TripHistoryDateFilter = .last30Days

    let allTripRecords: [DriverHistoryTripRecord] = DriverHistoryTripRecord.mockDriverTrips

    var filteredTripRecords: [DriverHistoryTripRecord] {
        let now = Date()
        let cutoffDate: Date
        switch selectedDateRangeFilter {
        case .last7Days:  cutoffDate = Calendar.current.date(byAdding: .day,   value: -7,  to: now)!
        case .last30Days: cutoffDate = Calendar.current.date(byAdding: .day,   value: -30, to: now)!
        case .last90Days: cutoffDate = Calendar.current.date(byAdding: .month, value: -3,  to: now)!
        case .all:        return allTripRecords.sorted { $0.tripDate > $1.tripDate }
        }
        return allTripRecords.filter { $0.tripDate >= cutoffDate }.sorted { $0.tripDate > $1.tripDate }
    }

    var tripRecordsGroupedByDate: [(String, [DriverHistoryTripRecord])] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        var groupDictionary: [String: [DriverHistoryTripRecord]] = [:]
        for tripRecord in filteredTripRecords {
            let groupKey: String
            if calendar.isDateInToday(tripRecord.tripDate) {
                groupKey = "Today"
            } else if calendar.isDateInYesterday(tripRecord.tripDate) {
                groupKey = "Yesterday"
            } else {
                groupKey = dateFormatter.string(from: tripRecord.tripDate)
            }
            groupDictionary[groupKey, default: []].append(tripRecord)
        }
        return groupDictionary.sorted { pairA, pairB in
            guard let dateA = pairA.value.first?.tripDate,
                  let dateB = pairB.value.first?.tripDate else { return false }
            return dateA > dateB
        }
    }

    var totalCompletedTripsCount: Int {
        filteredTripRecords.count
    }

    var totalPassengersAcrossAllTrips: Int {
        filteredTripRecords.reduce(0) { $0 + $1.performanceSummary.totalPassengersPickedUp }
    }

    var averageTripDurationInMinutes: Int {
        guard !filteredTripRecords.isEmpty else { return 0 }
        let totalMinutes = filteredTripRecords.reduce(0) { $0 + $1.performanceSummary.tripDurationInMinutes }
        return totalMinutes / filteredTripRecords.count
    }

    func selectTripForDetail(trip: DriverHistoryTripRecord) {
        selectedTripForDetailView = trip
        selectedTripDetailDisplayMode = .textView
    }
}

extension DriverHistoryTripRecord {

    static let mockDriverTrips: [DriverHistoryTripRecord] = {
        let calendar = Calendar.current
        let now = Date()

        func makeDate(daysBack: Int, hour: Int, minute: Int) -> Date {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.day! -= daysBack
            components.hour = hour
            components.minute = minute
            return calendar.date(from: components)!
        }

        let morningStopsTimeline: [DriverTripStopRecord] = [
            DriverTripStopRecord(stopName: "Nugegoda Junction", timeReached: "6:38 AM", stopStatus: .completed),
            DriverTripStopRecord(stopName: "Maharagama Town", timeReached: "6:52 AM", stopStatus: .completed),
            DriverTripStopRecord(stopName: "Borella", timeReached: "7:11 AM", stopStatus: .completed),
            DriverTripStopRecord(stopName: "Fort Railway Station", timeReached: "7:28 AM", stopStatus: .skipped),
            DriverTripStopRecord(stopName: "World Trade Center", timeReached: "7:44 AM", stopStatus: .completed),
        ]

        let eveningStopsTimeline: [DriverTripStopRecord] = [
            DriverTripStopRecord(stopName: "World Trade Center", timeReached: "5:08 PM", stopStatus: .completed),
            DriverTripStopRecord(stopName: "Borella", timeReached: "5:27 PM", stopStatus: .completed),
            DriverTripStopRecord(stopName: "Maharagama Town", timeReached: "5:50 PM", stopStatus: .completed),
            DriverTripStopRecord(stopName: "Nugegoda Junction", timeReached: "6:09 PM", stopStatus: .completed),
        ]

        let morningPassengers: [DriverTripPassengerPickupRecord] = [
            DriverTripPassengerPickupRecord(passengerFullName: "Amali Fernando", boardingStopName: "Nugegoda Junction"),
            DriverTripPassengerPickupRecord(passengerFullName: "Ruwan Perera", boardingStopName: "Nugegoda Junction"),
            DriverTripPassengerPickupRecord(passengerFullName: "Nimal Silva", boardingStopName: "Maharagama Town"),
            DriverTripPassengerPickupRecord(passengerFullName: "Kalyani Jayawardena", boardingStopName: "Borella"),
            DriverTripPassengerPickupRecord(passengerFullName: "Thilak Rajapaksa", boardingStopName: "Borella"),
            DriverTripPassengerPickupRecord(passengerFullName: "Saman Bandara", boardingStopName: "World Trade Center"),
            DriverTripPassengerPickupRecord(passengerFullName: "Dilrukshi Wijesinghe", boardingStopName: "World Trade Center"),
        ]

        let eveningPassengers: [DriverTripPassengerPickupRecord] = [
            DriverTripPassengerPickupRecord(passengerFullName: "Amali Fernando", boardingStopName: "World Trade Center"),
            DriverTripPassengerPickupRecord(passengerFullName: "Nimal Silva", boardingStopName: "World Trade Center"),
            DriverTripPassengerPickupRecord(passengerFullName: "Kalyani Jayawardena", boardingStopName: "Borella"),
            DriverTripPassengerPickupRecord(passengerFullName: "Prasad Gunasekara", boardingStopName: "Maharagama Town"),
            DriverTripPassengerPickupRecord(passengerFullName: "Iresha Dissanayake", boardingStopName: "Nugegoda Junction"),
        ]

        return [
            DriverHistoryTripRecord(
                tripDate: makeDate(daysBack: 0, hour: 6, minute: 30),
                sessionType: .morning,
                completionStatus: .completed,
                scheduledStartTime: "6:30 AM",
                actualEndTime: "7:48 AM",
                stopsTimeline: morningStopsTimeline,
                passengerPickupList: morningPassengers,
                performanceSummary: DriverTripPerformanceSummary(totalStopCount: 5, completedStopCount: 4, totalPassengersPickedUp: 7, tripDurationInMinutes: 78)
            ),
            DriverHistoryTripRecord(
                tripDate: makeDate(daysBack: 0, hour: 17, minute: 0),
                sessionType: .evening,
                completionStatus: .completed,
                scheduledStartTime: "5:00 PM",
                actualEndTime: "6:14 PM",
                stopsTimeline: eveningStopsTimeline,
                passengerPickupList: eveningPassengers,
                performanceSummary: DriverTripPerformanceSummary(totalStopCount: 4, completedStopCount: 4, totalPassengersPickedUp: 5, tripDurationInMinutes: 74)
            ),
            DriverHistoryTripRecord(
                tripDate: makeDate(daysBack: 1, hour: 6, minute: 30),
                sessionType: .morning,
                completionStatus: .autoCompleted,
                scheduledStartTime: "6:30 AM",
                actualEndTime: "7:55 AM",
                stopsTimeline: morningStopsTimeline,
                passengerPickupList: morningPassengers,
                performanceSummary: DriverTripPerformanceSummary(totalStopCount: 5, completedStopCount: 3, totalPassengersPickedUp: 6, tripDurationInMinutes: 85)
            ),
            DriverHistoryTripRecord(
                tripDate: makeDate(daysBack: 1, hour: 17, minute: 0),
                sessionType: .evening,
                completionStatus: .completed,
                scheduledStartTime: "5:00 PM",
                actualEndTime: "6:18 PM",
                stopsTimeline: eveningStopsTimeline,
                passengerPickupList: eveningPassengers,
                performanceSummary: DriverTripPerformanceSummary(totalStopCount: 4, completedStopCount: 4, totalPassengersPickedUp: 5, tripDurationInMinutes: 78)
            ),
            DriverHistoryTripRecord(
                tripDate: makeDate(daysBack: 2, hour: 6, minute: 30),
                sessionType: .morning,
                completionStatus: .completed,
                scheduledStartTime: "6:30 AM",
                actualEndTime: "7:50 AM",
                stopsTimeline: morningStopsTimeline,
                passengerPickupList: morningPassengers,
                performanceSummary: DriverTripPerformanceSummary(totalStopCount: 5, completedStopCount: 5, totalPassengersPickedUp: 7, tripDurationInMinutes: 80)
            ),
            DriverHistoryTripRecord(
                tripDate: makeDate(daysBack: 4, hour: 6, minute: 30),
                sessionType: .morning,
                completionStatus: .completed,
                scheduledStartTime: "6:30 AM",
                actualEndTime: "7:45 AM",
                stopsTimeline: morningStopsTimeline,
                passengerPickupList: morningPassengers,
                performanceSummary: DriverTripPerformanceSummary(totalStopCount: 5, completedStopCount: 4, totalPassengersPickedUp: 7, tripDurationInMinutes: 75)
            ),
            DriverHistoryTripRecord(
                tripDate: makeDate(daysBack: 4, hour: 17, minute: 0),
                sessionType: .evening,
                completionStatus: .autoCompleted,
                scheduledStartTime: "5:00 PM",
                actualEndTime: "6:22 PM",
                stopsTimeline: eveningStopsTimeline,
                passengerPickupList: eveningPassengers,
                performanceSummary: DriverTripPerformanceSummary(totalStopCount: 4, completedStopCount: 3, totalPassengersPickedUp: 4, tripDurationInMinutes: 82)
            ),
            DriverHistoryTripRecord(
                tripDate: makeDate(daysBack: 7, hour: 6, minute: 30),
                sessionType: .morning,
                completionStatus: .completed,
                scheduledStartTime: "6:30 AM",
                actualEndTime: "7:47 AM",
                stopsTimeline: morningStopsTimeline,
                passengerPickupList: morningPassengers,
                performanceSummary: DriverTripPerformanceSummary(totalStopCount: 5, completedStopCount: 5, totalPassengersPickedUp: 7, tripDurationInMinutes: 77)
            ),
            DriverHistoryTripRecord(
                tripDate: makeDate(daysBack: 10, hour: 17, minute: 0),
                sessionType: .evening,
                completionStatus: .completed,
                scheduledStartTime: "5:00 PM",
                actualEndTime: "6:10 PM",
                stopsTimeline: eveningStopsTimeline,
                passengerPickupList: eveningPassengers,
                performanceSummary: DriverTripPerformanceSummary(totalStopCount: 4, completedStopCount: 4, totalPassengersPickedUp: 5, tripDurationInMinutes: 70)
            ),
            DriverHistoryTripRecord(
                tripDate: makeDate(daysBack: 14, hour: 6, minute: 30),
                sessionType: .morning,
                completionStatus: .completed,
                scheduledStartTime: "6:30 AM",
                actualEndTime: "7:52 AM",
                stopsTimeline: morningStopsTimeline,
                passengerPickupList: morningPassengers,
                performanceSummary: DriverTripPerformanceSummary(totalStopCount: 5, completedStopCount: 4, totalPassengersPickedUp: 6, tripDurationInMinutes: 82)
            ),
        ]
    }()
}
