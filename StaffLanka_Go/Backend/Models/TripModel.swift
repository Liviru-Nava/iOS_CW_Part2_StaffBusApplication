//
//  TripModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-06.
//

import Foundation
import FirebaseFirestore
import CoreLocation

// Firestore document in the "trips" collection.
// Created by the driver when they tap Start Trip updated throughout the trip.
struct TripModel: Codable, Identifiable {
    @DocumentID var id: String?
    var routeId: String
    var driverId: String
    var session: String            // "Morning" | "Evening"
    var tripDate: Date             // midnight of the trip day (for querying)
    var status: String             // "active" | "completed"
    var startedAt: Date
    var endedAt: Date?
    var driverLatitude: Double?    // updated every ~5 s while active
    var driverLongitude: Double?
    var locationUpdatedAt: Date?
    var currentStopIndex: Int?     // updated as the driver reaches each stop in the simulation

    var driverCoordinate: CLLocationCoordinate2D? {
        guard let lat = driverLatitude, let lon = driverLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
