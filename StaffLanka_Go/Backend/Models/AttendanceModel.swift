//
//  AttendanceModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-06.
//

import Foundation
import FirebaseFirestore

// Firestore document in the `attendance` collection.
// One record per passenger × per session × per date.
struct AttendanceModel: Codable, Identifiable {
    @DocumentID var id: String?
    var passengerId: String
    var routeId: String
    var requestId: String          // joinRequest doc ID
    var session: String            // "Morning" | "Evening"
    var tripDate: Date             // midnight of the target date
    var status: String             // "attending" | "absent"
    var markedAt: Date
    var updatedAt: Date
}
