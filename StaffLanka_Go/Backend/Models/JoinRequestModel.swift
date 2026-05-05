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
    var status: String             // "pending" | "accepted" | "rejected"
    var createdAt: Date

}
