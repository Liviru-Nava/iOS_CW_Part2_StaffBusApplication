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

import FirebaseAuth
import FirebaseFirestore

@MainActor
final class PassengerTripHistoryViewModel: ObservableObject {
    @Published var records: [TripDayRecord] = []
    @Published var selectedDateFilter: TripHistoryDateFilter = .last30Days
    @Published var selectedRecord: TripDayRecord? = nil

    func fetchHistory() {
        guard let passengerId = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                // 1. Get passenger's join requests
                let snapshot = try await Firestore.firestore().collection("joinRequests")
                    .whereField("passengerId", isEqualTo: passengerId)
                    .whereField("status", isEqualTo: "accepted")
                    .getDocuments()
                let joinRequests = snapshot.documents.compactMap { try? $0.data(as: JoinRequestModel.self) }
                
                // 2. Fetch history for those routes
                var allHistories: [DriverHistoryTripRecord] = []
                for req in joinRequests {
                    let routeHistory = try await TripService.shared.fetchPassengerTripHistory(routeId: req.routeId)
                    allHistories.append(contentsOf: routeHistory)
                }
                
                // 3. Fetch all attendance for this passenger
                let attSnapshot = try await Firestore.firestore().collection("attendance")
                    .whereField("passengerId", isEqualTo: passengerId)
                    .getDocuments()
                let attendances = attSnapshot.documents.compactMap { try? $0.data(as: AttendanceModel.self) }
                
                // 4. Group by Date
                let groupedByDate = Dictionary(grouping: allHistories) { Calendar.current.startOfDay(for: $0.tripDate) }
                
                var builtRecords: [TripDayRecord] = []
                
                for (date, trips) in groupedByDate {
                    let morningTrip = trips.first { $0.sessionType == "Morning" }
                    let eveningTrip = trips.first { $0.sessionType == "Evening" }
                    
                    var morningSession: TripSessionRecord? = nil
                    if let mt = morningTrip {
                        // find join request for this route
                        let req = joinRequests.first { $0.routeId == mt.routeId }
                        let routeName = "Route" // Could fetch actual route name, simplify for now
                        
                        // find attendance
                        let att = attendances.first { $0.routeId == mt.routeId && $0.session == "Morning" && Calendar.current.startOfDay(for: $0.tripDate) == date }
                        let status: TripAttendanceStatus = (att?.status == "attending") ? .attended : .skipped
                        
                        morningSession = TripSessionRecord(
                            id: UUID(), session: .morning,
                            boardTime: mt.tripDate, departureTime: mt.tripDate.addingTimeInterval(TimeInterval(mt.performanceSummary.tripDurationInMinutes * 60)),
                            pickupStop: req?.pickupStop ?? "", dropoffStop: req?.dropoffStop ?? "",
                            attendance: status, duration: status == .attended ? mt.performanceSummary.tripDurationInMinutes : nil
                        )
                    }
                    
                    var eveningSession: TripSessionRecord? = nil
                    if let et = eveningTrip {
                        let req = joinRequests.first { $0.routeId == et.routeId }
                        let att = attendances.first { $0.routeId == et.routeId && $0.session == "Evening" && Calendar.current.startOfDay(for: $0.tripDate) == date }
                        let status: TripAttendanceStatus = (att?.status == "attending") ? .attended : .skipped
                        
                        eveningSession = TripSessionRecord(
                            id: UUID(), session: .evening,
                            boardTime: et.tripDate, departureTime: et.tripDate.addingTimeInterval(TimeInterval(et.performanceSummary.tripDurationInMinutes * 60)),
                            pickupStop: req?.dropoffStop ?? "", dropoffStop: req?.pickupStop ?? "", // reversed for evening
                            attendance: status, duration: status == .attended ? et.performanceSummary.tripDurationInMinutes : nil
                        )
                    }
                    
                    // Assign a route name based on what's available
                    let anyTrip = morningTrip ?? eveningTrip
                    var finalRouteName = "Bus Route"
                    if let reqRouteId = anyTrip?.routeId {
                        if let route = try? await RouteService.shared.fetchRoute(routeId: reqRouteId) {
                            finalRouteName = "\(route.startName ?? route.startLocation.locationName) - \(route.endName ?? route.endLocation.locationName)"
                        }
                    }
                    
                    builtRecords.append(TripDayRecord(
                        id: UUID(), date: date, routeName: finalRouteName, serviceSession: .both,
                        morning: morningSession, evening: eveningSession
                    ))
                }
                
                self.records = builtRecords.sorted { $0.date > $1.date }
                
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

    var averageTravelTime: Int {
        var totalDurations = 0
        var totalTrips = 0
        for r in filteredRecords {
            if r.morning?.attendance == .attended, let dur = r.morning?.duration {
                totalDurations += dur
                totalTrips += 1
            }
            if r.evening?.attendance == .attended, let dur = r.evening?.duration {
                totalDurations += dur
                totalTrips += 1
            }
        }
        return totalTrips > 0 ? totalDurations / totalTrips : 0
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
                attendance: attended ? .attended : .skipped,
                duration: attended ? 80 : nil
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
