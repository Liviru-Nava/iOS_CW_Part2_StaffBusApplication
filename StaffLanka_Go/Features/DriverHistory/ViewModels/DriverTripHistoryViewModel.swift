//
//  DriverTripHistoryViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-09.

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

enum DriverTripCompletionStatus: String, Codable {
    case completed = "Completed"
    case autoCompleted = "Auto Completed"
}

enum DriverTripStopStatus: String, Codable {
    case completed = "completed"
    case skipped = "skipped"
}

enum DriverTripDetailDisplayMode {
    case textView, mapView
}

struct DriverTripStopRecord: Identifiable, Codable {
    var id: String = UUID().uuidString
    let stopName: String
    let timeReached: String
    let stopStatus: DriverTripStopStatus
}

struct DriverTripPassengerPickupRecord: Identifiable, Codable {
    var id: String = UUID().uuidString
    let passengerFullName: String
    let boardingStopName: String
}

struct DriverTripPerformanceSummary: Codable {
    let totalStopCount: Int
    let completedStopCount: Int
    let totalPassengersPickedUp: Int
    let tripDurationInMinutes: Int
}

struct DriverHistoryTripRecord: Identifiable, Codable {
    @DocumentID var id: String?
    var driverId: String
    var routeId: String
    let tripDate: Date
    let sessionType: String // e.g., "Morning", "Evening"
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
    @Published var allTripRecords: [DriverHistoryTripRecord] = []
    @Published var isLoading: Bool = false

    func fetchHistory() {
        guard let userId = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        self.isLoading = true
        Task {
            do {
                let records = try await TripService.shared.fetchDriverTripHistory(driverId: userId)
                self.allTripRecords = records
            } catch {
                print("🔴 Failed to fetch driver history: \(error.localizedDescription)")
            }
            self.isLoading = false
        }
    }

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
    static let mockDriverTrips: [DriverHistoryTripRecord] = []
}
