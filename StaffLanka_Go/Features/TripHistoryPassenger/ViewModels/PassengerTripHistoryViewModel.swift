//
//  PassengerTripHistoryViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import Foundation
import Combine

enum TripAttendanceStatus {
    case attended
    case skipped
    case notScheduled
}

struct TripSessionRecord: Identifiable {
    let id: UUID
    let session: TripSession
    let boardTime: Date?
    let departureTime: Date?
    let pickupStop: String
    let dropoffStop: String
    let attendance: TripAttendanceStatus

    var duration: Int? {
        guard let boardTime = boardTime, let departTime = departureTime else { return nil }
        return Int(departTime.timeIntervalSince(boardTime) / 60)
    }
}

struct TripDayRecord: Identifiable {
    let id: UUID
    let date: Date
    let routeName: String
    let serviceSession: TripSession
    let morning: TripSessionRecord?
    let evening: TripSessionRecord?
}

enum TripHistoryDateFilter: String, CaseIterable, Identifiable {
    case last7Days  = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case last90Days = "Last 3 Months"
    case all        = "All Time"
    var id: String { rawValue }
}

@MainActor
final class PassengerTripHistoryViewModel: ObservableObject {
    @Published var records: [TripDayRecord] = TripDayRecord.mockHistory
    @Published var selectedDateFilter: TripHistoryDateFilter = .last30Days
    @Published var selectedRecord: TripDayRecord? = nil

    var filteredRecords: [TripDayRecord] {
        let now = Date()
        let cutoff: Date
        switch selectedDateFilter {
        case .last7Days:  cutoff = Calendar.current.date(byAdding: .day,   value: -7,  to: now)!
        case .last30Days: cutoff = Calendar.current.date(byAdding: .day,   value: -30, to: now)!
        case .last90Days: cutoff = Calendar.current.date(byAdding: .month, value: -3,  to: now)!
        case .all:        return records.sorted { $0.date > $1.date }
        }
        return records.filter { $0.date >= cutoff }.sorted { $0.date > $1.date }
    }

    var groupedRecords: [(String, [TripDayRecord])] {
        let currentDate = Calendar.current
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        var tripDictionary: [String: [TripDayRecord]] = [:]
        for record in filteredRecords {
            let key: String
            if currentDate.isDateInToday(record.date) {
                key = "Today"
            } else if currentDate.isDateInYesterday(record.date) {
                key = "Yesterday"
            } else {
                key = formatter.string(from: record.date)
            }
            tripDictionary[key, default: []].append(record)
        }
        return tripDictionary.sorted { a, b in
            guard let dateA = a.value.first?.date, let dateB = b.value.first?.date else { return false }
            return dateA > dateB
        }
    }

    var totalTripsAttended: Int {
        filteredRecords.reduce(0) { count, r in
            count
                + (r.morning?.attendance == .attended ? 1 : 0)
                + (r.evening?.attendance == .attended ? 1 : 0)
        }
    }

    var totalTripsSkipped: Int {
        filteredRecords.reduce(0) { count, r in
            count
                + (r.morning?.attendance == .skipped ? 1 : 0)
                + (r.evening?.attendance == .skipped ? 1 : 0)
        }
    }

    var attendanceRate: Int {
        let total = totalTripsAttended + totalTripsSkipped
        guard total > 0 else { return 0 }
        return Int((Double(totalTripsAttended) / Double(total)) * 100)
    }
}

extension TripDayRecord {
    static let mockHistory: [TripDayRecord] = {
        let cal = Calendar.current
        let now = Date()

        func makeDate(daysBack: Int, hour: Int, minute: Int) -> Date {
            var comps = cal.dateComponents([.year, .month, .day], from: now)
            comps.day! -= daysBack
            comps.hour = hour
            comps.minute = minute
            return cal.date(from: comps)!
        }

        func morningSession(daysBack: Int, attended: Bool) -> TripSessionRecord {
            TripSessionRecord(
                id: UUID(),
                session: .morning,
                boardTime:  attended ? makeDate(daysBack: daysBack, hour: 6,  minute: 35) : nil,
                departureTime: attended ? makeDate(daysBack: daysBack, hour: 7,  minute: 55) : nil,
                pickupStop:  "Kadawatha Junction",
                dropoffStop: "Colombo Fort",
                attendance: attended ? .attended : .skipped
            )
        }

        func eveningSession(daysBack: Int, attended: Bool) -> TripSessionRecord {
            TripSessionRecord(
                id: UUID(),
                session: .evening,
                boardTime:  attended ? makeDate(daysBack: daysBack, hour: 17, minute: 15) : nil,
                departureTime: attended ? makeDate(daysBack: daysBack, hour: 18, minute: 40) : nil,
                pickupStop:  "Colombo Fort",
                dropoffStop: "Kadawatha Junction",
                attendance: attended ? .attended : .skipped
            )
        }

        let route = "Colombo – Kandy Express"

        return [
            TripDayRecord(id: UUID(), date: makeDate(daysBack: 0, hour: 0, minute: 0),
                          routeName: route, serviceSession: .both,
                          morning: morningSession(daysBack: 0, attended: true),
                          evening: nil),

            TripDayRecord(id: UUID(), date: makeDate(daysBack: 1, hour: 0, minute: 0),
                          routeName: route, serviceSession: .both,
                          morning: morningSession(daysBack: 1, attended: true),
                          evening: eveningSession(daysBack: 1, attended: true)),

            TripDayRecord(id: UUID(), date: makeDate(daysBack: 2, hour: 0, minute: 0),
                          routeName: route, serviceSession: .both,
                          morning: morningSession(daysBack: 2, attended: true),
                          evening: eveningSession(daysBack: 2, attended: false)),

            TripDayRecord(id: UUID(), date: makeDate(daysBack: 3, hour: 0, minute: 0),
                          routeName: route, serviceSession: .both,
                          morning: morningSession(daysBack: 3, attended: false),
                          evening: eveningSession(daysBack: 3, attended: true)),

            TripDayRecord(id: UUID(), date: makeDate(daysBack: 5, hour: 0, minute: 0),
                          routeName: route, serviceSession: .morning,
                          morning: morningSession(daysBack: 5, attended: true),
                          evening: nil),

            TripDayRecord(id: UUID(), date: makeDate(daysBack: 7, hour: 0, minute: 0),
                          routeName: route, serviceSession: .both,
                          morning: morningSession(daysBack: 7, attended: true),
                          evening: eveningSession(daysBack: 7, attended: false)),

            TripDayRecord(id: UUID(), date: makeDate(daysBack: 10, hour: 0, minute: 0),
                          routeName: route, serviceSession: .both,
                          morning: morningSession(daysBack: 10, attended: false),
                          evening: eveningSession(daysBack: 10, attended: false)),

            TripDayRecord(id: UUID(), date: makeDate(daysBack: 14, hour: 0, minute: 0),
                          routeName: route, serviceSession: .evening,
                          morning: nil,
                          evening: eveningSession(daysBack: 14, attended: true)),

            TripDayRecord(id: UUID(), date: makeDate(daysBack: 20, hour: 0, minute: 0),
                          routeName: route, serviceSession: .both,
                          morning: morningSession(daysBack: 20, attended: true),
                          evening: eveningSession(daysBack: 20, attended: true)),

            TripDayRecord(id: UUID(), date: makeDate(daysBack: 25, hour: 0, minute: 0),
                          routeName: route, serviceSession: .both,
                          morning: morningSession(daysBack: 25, attended: true),
                          evening: eveningSession(daysBack: 25, attended: false)),
        ]
    }()
}
