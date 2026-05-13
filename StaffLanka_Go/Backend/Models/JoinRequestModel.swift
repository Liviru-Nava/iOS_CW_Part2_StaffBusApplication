//
//  JoinRequestModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-05.
//

import Foundation
import FirebaseFirestore

struct JoinRequestModel: Codable, Identifiable {
    @DocumentID var id: String?
    var routeId: String
    var driverId: String
    var passengerId: String?       // Auth UID of the requesting passenger
    var passengerName: String
    var passengerPhone: String
    var pickupStop: String
    var dropoffStop: String
    var session: String            // "Morning" | "Evening" | "Both"
    var note: String
    var status: String             // "pending" | "accepted" | "rejected" | "cancelled"
    var createdAt: Date

    // Written when a passenger removes only one session from a Both enrollment
    // Holds the session label that was removed: "Morning" or "Evening"
    var cancelledSession: String?

    // Written on any cancellation to record who initiated the removal
    // "passenger" = passenger self-cancelled; "driver" = driver removed the passenger
    var cancelledBy: String?
}
