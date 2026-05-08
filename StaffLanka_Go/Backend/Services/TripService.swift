//
//  TripService.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-06.
//

import Foundation
import FirebaseFirestore
import CoreLocation

final class TripService {

    static let shared = TripService()
    private init() {}

    private let db = Firestore.firestore()
    private let collection = "trips"

    // Driver: start a trip

    // Creates a new trip document with status = "active". Returns the new tripId.
    @discardableResult
    func startTrip(routeId: String, driverId: String, session: String) async throws -> String {
        let now = Date()
        let tripDate = Calendar.current.startOfDay(for: now)
        let model = TripModel(
            routeId: routeId,
            driverId: driverId,
            session: session,
            tripDate: tripDate,
            status: "active",
            startedAt: now
        )
        let ref = try db.collection(collection).addDocument(from: model)
        print("🟢 [TripService] Trip started — id: \(ref.documentID) session: \(session)")
        return ref.documentID
    }

    // Driver: finish a trip

    func finishTrip(tripId: String) async throws {
        try await db.collection(collection).document(tripId).updateData([
            "status":  "completed",
            "endedAt": Timestamp(date: Date())
        ])
        print("🟢 [TripService] Trip completed — id: \(tripId)")
    }

    // Driver: update live location

    // Called every ~5 seconds while a trip is active.
    func updateDriverLocation(tripId: String, location: CLLocationCoordinate2D, currentStopIndex: Int? = nil) async throws {
        var data: [String: Any] = [
            "driverLatitude":    location.latitude,
            "driverLongitude":   location.longitude,
            "locationUpdatedAt": Timestamp(date: Date())
        ]
        if let currentStopIndex {
            data["currentStopIndex"] = currentStopIndex
        }
        try await db.collection(collection).document(tripId).updateData(data)
    }

    // Passenger: listen for today's trip for a specific driver + session
    // Queries by driverId only (no composite index needed), filters by today + session in Swift
    func listenForActiveTrip(
        driverId: String,
        session: String,
        onChange: @escaping (TripModel?) -> Void
    ) -> ListenerRegistration {
        print("🔵 [TripService] Attaching trip listener — driverId: \(driverId) session: \(session)")
        return db.collection(collection)
            .whereField("driverId", isEqualTo: driverId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("🔴 [TripService] Listener error: \(error.localizedDescription)")
                    onChange(nil)
                    return
                }
                let trips = snapshot?.documents.compactMap { doc -> TripModel? in
                    var model = try? doc.data(as: TripModel.self)
                    model?.id = doc.documentID
                    return model
                } ?? []

                // Only consider trips from TODAY that match this session — never fall back to other days
                let today = Calendar.current.startOfDay(for: Date())
                let todayTrip = trips.first(where: {
                    $0.session == session &&
                    Calendar.current.startOfDay(for: $0.tripDate) == today
                })
                print("🟢 [TripService] Listener fired — \(trips.count) total, today's \(session): \(todayTrip?.status ?? "none") id: \(todayTrip?.id ?? "none")")
                onChange(todayTrip)
            }
    }

    // Fetch a specific trip by ID (for passenger tracking view)

    func fetchTrip(tripId: String) async throws -> TripModel? {
        let doc = try await db.collection(collection).document(tripId).getDocument()
        var model = try? doc.data(as: TripModel.self)
        model?.id = doc.documentID
        return model
    }

    // Listen to a specific trip (live location updates)

    func listenToTrip(
        tripId: String,
        onChange: @escaping (TripModel?) -> Void
    ) -> ListenerRegistration {
        return db.collection(collection).document(tripId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("🔴 [TripService] Trip listener error: \(error.localizedDescription)")
                    onChange(nil)
                    return
                }
                var model = try? snapshot?.data(as: TripModel.self)
                model?.id = snapshot?.documentID
                onChange(model)
            }
    }

    // Trip History Persistence

    func saveTripHistoryRecord(_ record: DriverHistoryTripRecord) async throws {
        let _ = try db.collection("tripHistory").addDocument(from: record)
        print("🟢 [TripService] Saved trip history record for route: \(record.routeId)")
    }

    func fetchDriverTripHistory(driverId: String) async throws -> [DriverHistoryTripRecord] {
        let snapshot = try await db.collection("tripHistory")
            .whereField("driverId", isEqualTo: driverId)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            var record = try? doc.data(as: DriverHistoryTripRecord.self)
            record?.id = doc.documentID
            return record
        }.sorted { $0.tripDate > $1.tripDate }
    }

    func fetchPassengerTripHistory(routeId: String) async throws -> [DriverHistoryTripRecord] {
        let snapshot = try await db.collection("tripHistory")
            .whereField("routeId", isEqualTo: routeId)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            var record = try? doc.data(as: DriverHistoryTripRecord.self)
            record?.id = doc.documentID
            return record
        }.sorted { $0.tripDate > $1.tripDate }
    }
}
