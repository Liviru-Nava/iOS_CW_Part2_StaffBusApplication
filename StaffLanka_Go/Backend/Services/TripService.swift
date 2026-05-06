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

    // Passenger: listen for an active trip on this route + session

    // Fires whenever a trip document for this route+session changes (active → completed).
    func listenForActiveTrip(
        routeId: String,
        session: String,
        onChange: @escaping (TripModel?) -> Void
    ) -> ListenerRegistration {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        print("🔵 [TripService] Attaching trip listener for routeId: \(routeId) session: \(session)")
        return db.collection(collection)
            .whereField("routeId", isEqualTo: routeId)
            .whereField("session", isEqualTo: session)
            .whereField("tripDate", isGreaterThanOrEqualTo: Timestamp(date: today))
            .whereField("tripDate", isLessThan: Timestamp(date: tomorrow))
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("🔴 [TripService] Listener error: \(error.localizedDescription)")
                    onChange(nil)
                    return
                }
                // Take the most recent trip for today
                let trips = snapshot?.documents.compactMap { doc -> TripModel? in
                    var model = try? doc.data(as: TripModel.self)
                    model?.id = doc.documentID
                    return model
                } ?? []
                let active = trips.first(where: { $0.status == "active" })
                    ?? trips.sorted(by: { $0.startedAt > $1.startedAt }).first
                print("🟢 [TripService] Listener fired — status: \(active?.status ?? "none")")
                onChange(active)
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
