//
//  AccountDeletionService.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-08.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore

//  Permanently deletes every piece of data owned by the current user from
//  Firestore and Firebase Auth, then wipes Core Data.
// 
//  Deletion order (matters for rule consistency):
//    1. Passenger-owned subcollections  (joinRequests, attendance)
//    2. Driver-owned subcollections     (trips, tripHistory, joinRequests for driverId)
//    3. Driver document                 (drivers/{uid})
//    4. Route document                  (routes/{routeId})   — only if driver
//    5. User document                   (users/{uid})
//    6. Core Data cache                 (local device)
//    7. Firebase Auth account           (must be last — loses the token)
final class AccountDeletionService {

    static let shared = AccountDeletionService()
    private init() {}

    private let db = Firestore.firestore()

    // Public entry point

    //  Call this once the user has confirmed deletion.
    //  Throws `AccountDeletionError` on any unrecoverable failure.
    func deleteCurrentUserAccount(role: String) async throws {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw AccountDeletionError.notSignedIn
        }
        let userId = firebaseUser.uid

        // 1. Delete passenger-side Firestore data (safe to run for drivers too)
        try await deletePassengerFirestoreData(userId: userId)

        // 2. If driver, delete driver-side Firestore data
        if role == "driver" {
            try await deleteDriverFirestoreData(userId: userId)
        }

        // 3. Delete the top-level user document
        try await db.collection("users").document(userId).delete()
        print("[AccountDeletion] Deleted users/\(userId)")

        // 4. Wipe Core Data — must happen before Auth deletion so we still have UID
        await MainActor.run {
            CoreDataManager.shared.deleteAllLocalData(userId: userId)
        }
        print("[AccountDeletion] Core Data wiped for \(userId)")

        // 5. Delete the Firebase Auth account (token becomes invalid after this)
        try await firebaseUser.delete()
        print("[AccountDeletion] Firebase Auth account deleted for \(userId)")
    }

    // Passenger data

    private func deletePassengerFirestoreData(userId: String) async throws {
        // joinRequests where passengerId == userId
        let joinRequestsSnapshot = try await db
            .collection("joinRequests")
            .whereField("passengerId", isEqualTo: userId)
            .getDocuments()

        for doc in joinRequestsSnapshot.documents {
            try await doc.reference.delete()
        }
        print("[AccountDeletion] Deleted \(joinRequestsSnapshot.documents.count) joinRequest(s) for passenger \(userId)")

        // attendance where passengerId == userId
        let attendanceSnapshot = try await db
            .collection("attendance")
            .whereField("passengerId", isEqualTo: userId)
            .getDocuments()

        for doc in attendanceSnapshot.documents {
            try await doc.reference.delete()
        }
        print("[AccountDeletion] Deleted \(attendanceSnapshot.documents.count) attendance record(s) for passenger \(userId)")
    }

    // Driver data

    private func deleteDriverFirestoreData(userId: String) async throws {
        // Fetch the driver document to get the routeId before deleting it
        let driverSnapshot = try await db
            .collection("drivers")
            .document(userId)
            .getDocument()

        let routeId = driverSnapshot.data()?["routeId"] as? String

        // trips where driverId == userId
        let tripsSnapshot = try await db
            .collection("trips")
            .whereField("driverId", isEqualTo: userId)
            .getDocuments()

        for doc in tripsSnapshot.documents {
            try await doc.reference.delete()
        }
        print("[AccountDeletion] Deleted \(tripsSnapshot.documents.count) trip(s) for driver \(userId)")

        // tripHistory where driverId == userId
        let tripHistorySnapshot = try await db
            .collection("tripHistory")
            .whereField("driverId", isEqualTo: userId)
            .getDocuments()

        for doc in tripHistorySnapshot.documents {
            try await doc.reference.delete()
        }
        print("[AccountDeletion] Deleted \(tripHistorySnapshot.documents.count) tripHistory record(s) for driver \(userId)")

        // joinRequests where driverId == userId
        let driverRequestsSnapshot = try await db
            .collection("joinRequests")
            .whereField("driverId", isEqualTo: userId)
            .getDocuments()

        for doc in driverRequestsSnapshot.documents {
            try await doc.reference.delete()
        }
        print("[AccountDeletion] Deleted \(driverRequestsSnapshot.documents.count) joinRequest(s) for driver \(userId)")

        // Driver document
        if driverSnapshot.exists {
            try await driverSnapshot.reference.delete()
            print("[AccountDeletion] Deleted drivers/\(userId)")
        }

        // Route document (owned by this driver)
        if let routeId, !routeId.isEmpty {
            try await db.collection("routes").document(routeId).delete()
            print("[AccountDeletion] Deleted routes/\(routeId)")
        }
    }
}

// Error type

enum AccountDeletionError: LocalizedError {
    case notSignedIn
    case firestoreDeleteFailed(String)
    case authDeleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "No signed-in user was found. Please sign in and try again."
        case .firestoreDeleteFailed(let reason):
            return "Could not delete your data from the server: \(reason)"
        case .authDeleteFailed(let reason):
            return "Could not delete your account credentials: \(reason)"
        }
    }
}
