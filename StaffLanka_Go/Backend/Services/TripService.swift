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
    func updateDriverLocation(tripId: String, location: CLLocationCoordinate2D) async throws {
        try await db.collection(collection).document(tripId).updateData([
            "driverLatitude":    location.latitude,
            "driverLongitude":   location.longitude,
            "locationUpdatedAt": Timestamp(date: Date())
        ])
    }

    // Passenger: listen for an active trip driven by a specific driver
    // Queries driverId + status == "active" — requires no composite index
    func listenForActiveTrip(
        driverId: String,
        session: String,
        onChange: @escaping (TripModel?) -> Void
    ) -> ListenerRegistration {
        print("🔵 [TripService] Attaching trip listener — driverId: \(driverId) session: \(session)")
        return db.collection(collection)
            .whereField("driverId", isEqualTo: driverId)
            .whereField("status", isEqualTo: "active")
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
                // Pick the trip matching today's session; fall back to any active trip
                let today = Calendar.current.startOfDay(for: Date())
                let todayTrip = trips.first(where: {
                    $0.session == session &&
                    Calendar.current.startOfDay(for: $0.tripDate) == today
                }) ?? trips.first
                print("🟢 [TripService] Listener fired — \(trips.count) active trips, matched: \(todayTrip?.id ?? "none") status: \(todayTrip?.status ?? "none")")
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
}
