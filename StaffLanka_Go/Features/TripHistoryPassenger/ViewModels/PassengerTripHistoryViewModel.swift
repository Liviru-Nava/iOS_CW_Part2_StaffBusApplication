//
//  PassengerTripHistoryViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

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
    let duration: Int?
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
    @Published var records: [TripDayRecord] = []
    @Published var selectedDateFilter: TripHistoryDateFilter = .last30Days
    @Published var selectedRecord: TripDayRecord? = nil

    // Formatter used consistently everywhere a date-only string key is needed
    // Using yyyyMMdd in the local calendar avoids any UTC vs local midnight mismatch
    private let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.calendar = Calendar.current
        formatter.locale = Locale.current
        return formatter
    }()

    func fetchHistory() {
        guard let passengerId = FirebaseAuth.Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                // Step 1: get all accepted join requests for this passenger
                let joinRequestSnapshot = try await Firestore.firestore()
                    .collection("joinRequests")
                    .whereField("passengerId", isEqualTo: passengerId)
                    .whereField("status", isEqualTo: "accepted")
                    .getDocuments()
                let joinRequests = joinRequestSnapshot.documents.compactMap {
                    try? $0.data(as: JoinRequestModel.self)
                }

                // Step 2: fetch completed trip records for each enrolled route
                var allTripHistories: [DriverHistoryTripRecord] = []
                for joinRequest in joinRequests {
                    let routeTripHistory = try await TripService.shared.fetchPassengerTripHistory(
                        routeId: joinRequest.routeId
                    )
                    allTripHistories.append(contentsOf: routeTripHistory)
                }

                // Step 3: fetch all attendance records for this passenger
                let attendanceSnapshot = try await Firestore.firestore()
                    .collection("attendance")
                    .whereField("passengerId", isEqualTo: passengerId)
                    .getDocuments()
                let allAttendanceRecords = attendanceSnapshot.documents.compactMap {
                    try? $0.data(as: AttendanceModel.self)
                }

                // Build a lookup keyed by "routeId|session|yyyyMMdd" → status string
                // Using a string date key derived from the local calendar avoids the UTC/local
                // midnight mismatch that caused attendance records to never match trip records.
                // AttendanceService stores tripDate as UTC midnight of the local day; when decoded
                // back to a Swift Date it may differ from local midnight by the timezone offset.
                // Converting both sides to the same yyyyMMdd string sidesteps this entirely.
                var attendanceLookup: [String: String] = [:]
                for attendanceRecord in allAttendanceRecords {
                    let dayKey = dateKeyFormatter.string(from: attendanceRecord.tripDate)
                    let lookupKey = "\(attendanceRecord.routeId)|\(attendanceRecord.session)|\(dayKey)"
                    attendanceLookup[lookupKey] = attendanceRecord.status
                }

                // Step 4: group trip history records by local calendar day
                let tripsGroupedByDay = Dictionary(
                    grouping: allTripHistories
                ) { Calendar.current.startOfDay(for: $0.tripDate) }

                var builtDayRecords: [TripDayRecord] = []

                for (dayDate, tripsOnThisDay) in tripsGroupedByDay {
                    let morningTripRecord = tripsOnThisDay.first { $0.sessionType == "Morning" }
                    let eveningTripRecord = tripsOnThisDay.first { $0.sessionType == "Evening" }
                    let tripDayKey = dateKeyFormatter.string(from: dayDate)

                    var morningSessionRecord: TripSessionRecord? = nil
                    if let morningTrip = morningTripRecord {
                        let matchingJoinRequest = joinRequests.first { $0.routeId == morningTrip.routeId }
                        let attendanceLookupKey = "\(morningTrip.routeId)|Morning|\(tripDayKey)"
                        let attendanceStatus = attendanceLookup[attendanceLookupKey]
                        let resolvedStatus: TripAttendanceStatus = (attendanceStatus == "attending") ? .attended : .skipped

                        morningSessionRecord = TripSessionRecord(
                            id: UUID(),
                            session: .morning,
                            boardTime: morningTrip.tripDate,
                            departureTime: morningTrip.tripDate.addingTimeInterval(
                                TimeInterval(morningTrip.performanceSummary.tripDurationInMinutes * 60)
                            ),
                            pickupStop: matchingJoinRequest?.pickupStop ?? "",
                            dropoffStop: matchingJoinRequest?.dropoffStop ?? "",
                            attendance: resolvedStatus,
                            duration: resolvedStatus == .attended ? morningTrip.performanceSummary.tripDurationInMinutes : nil
                        )
                    }

                    var eveningSessionRecord: TripSessionRecord? = nil
                    if let eveningTrip = eveningTripRecord {
                        let matchingJoinRequest = joinRequests.first { $0.routeId == eveningTrip.routeId }
                        let attendanceLookupKey = "\(eveningTrip.routeId)|Evening|\(tripDayKey)"
                        let attendanceStatus = attendanceLookup[attendanceLookupKey]
                        let resolvedStatus: TripAttendanceStatus = (attendanceStatus == "attending") ? .attended : .skipped

                        eveningSessionRecord = TripSessionRecord(
                            id: UUID(),
                            session: .evening,
                            boardTime: eveningTrip.tripDate,
                            departureTime: eveningTrip.tripDate.addingTimeInterval(
                                TimeInterval(eveningTrip.performanceSummary.tripDurationInMinutes * 60)
                            ),
                            // Evening reverses pickup and drop-off relative to the join request
                            pickupStop: matchingJoinRequest?.dropoffStop ?? "",
                            dropoffStop: matchingJoinRequest?.pickupStop ?? "",
                            attendance: resolvedStatus,
                            duration: resolvedStatus == .attended ? eveningTrip.performanceSummary.tripDurationInMinutes : nil
                        )
                    }

                    var resolvedRouteName = "Bus Route"
                    let representativeTrip = morningTripRecord ?? eveningTripRecord
                    if let routeId = representativeTrip?.routeId,
                       let fetchedRoute = try? await RouteService.shared.fetchRoute(routeId: routeId) {
                        let startName = fetchedRoute.startName ?? fetchedRoute.startLocation.locationName
                        let endName = fetchedRoute.endName ?? fetchedRoute.endLocation.locationName
                        resolvedRouteName = "\(startName) - \(endName)"
                    }

                    builtDayRecords.append(TripDayRecord(
                        id: UUID(),
                        date: dayDate,
                        routeName: resolvedRouteName,
                        serviceSession: .both,
                        morning: morningSessionRecord,
                        evening: eveningSessionRecord
                    ))
                }

                self.records = builtDayRecords.sorted { $0.date > $1.date }

            } catch {
                print(" Failed to fetch passenger history: \(error)")
            }
        }
    }

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
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        var tripDictionary: [String: [TripDayRecord]] = [:]
        for record in filteredRecords {
            let key: String
            if calendar.isDateInToday(record.date) {
                key = "Today"
            } else if calendar.isDateInYesterday(record.date) {
                key = "Yesterday"
            } else {
                key = formatter.string(from: record.date)
            }
            tripDictionary[key, default: []].append(record)
        }
        return tripDictionary.sorted { pairA, pairB in
            guard let dateA = pairA.value.first?.date,
                  let dateB = pairB.value.first?.date else { return false }
            return dateA > dateB
        }
    }

    var totalTripsAttended: Int {
        filteredRecords.reduce(0) { count, record in
            count
                + (record.morning?.attendance == .attended ? 1 : 0)
                + (record.evening?.attendance == .attended ? 1 : 0)
        }
    }

    var totalTripsSkipped: Int {
        filteredRecords.reduce(0) { count, record in
            count
                + (record.morning?.attendance == .skipped ? 1 : 0)
                + (record.evening?.attendance == .skipped ? 1 : 0)
        }
    }

    var averageTravelTime: Int {
        var totalDurationMinutes = 0
        var totalTripCount = 0
        for record in filteredRecords {
            if record.morning?.attendance == .attended, let duration = record.morning?.duration {
                totalDurationMinutes += duration
                totalTripCount += 1
            }
            if record.evening?.attendance == .attended, let duration = record.evening?.duration {
                totalDurationMinutes += duration
                totalTripCount += 1
            }
        }
        return totalTripCount > 0 ? totalDurationMinutes / totalTripCount : 0
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
                boardTime:     attended ? makeDate(daysBack: daysBack, hour: 6,  minute: 35) : nil,
                departureTime: attended ? makeDate(daysBack: daysBack, hour: 7,  minute: 55) : nil,
                pickupStop:  "Kadawatha Junction",
                dropoffStop: "Colombo Fort",
                attendance: attended ? .attended : .skipped,
                duration: attended ? 80 : nil
            )
        }

        func eveningSession(daysBack: Int, attended: Bool) -> TripSessionRecord {
            TripSessionRecord(
                id: UUID(),
                session: .evening,
                boardTime:     attended ? makeDate(daysBack: daysBack, hour: 17, minute: 15) : nil,
                departureTime: attended ? makeDate(daysBack: daysBack, hour: 18, minute: 40) : nil,
                pickupStop:  "Colombo Fort",
                dropoffStop: "Kadawatha Junction",
                attendance: attended ? .attended : .skipped,
                duration: attended ? 85 : nil
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
