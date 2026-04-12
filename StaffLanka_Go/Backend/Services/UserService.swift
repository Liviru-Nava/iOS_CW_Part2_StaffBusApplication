// StaffLanka Go — Created by Liviru Navaratna

import Foundation
import FirebaseFirestore

final class UserService {

    static let shared = UserService()
    private init() {}

    private let firestoreDatabase = Firestore.firestore()
    private let usersCollectionPath = "users"

    func createUserIfNeeded(userId: String, phoneNumber: String) async throws {
        let userDocumentReference = firestoreDatabase
            .collection(usersCollectionPath)
            .document(userId)

        let existingUserSnapshot = try await userDocumentReference.getDocument()

        guard !existingUserSnapshot.exists else { return }

        let newUserDocument: [String: Any] = [
            "phone"     : phoneNumber,
            "name"      : "New User",
            "role"      : "passenger",
            "emailAddress": "",
            "createdAt" : Timestamp(date: Date())
        ]

        try await userDocumentReference.setData(newUserDocument)
    }

    func fetchUser(userId: String) async throws -> AppUser? {
        let userDocumentReference = firestoreDatabase
            .collection(usersCollectionPath)
            .document(userId)

        let userDocumentSnapshot = try await userDocumentReference.getDocument()

        guard userDocumentSnapshot.exists else { return nil }

        return try userDocumentSnapshot.data(as: AppUser.self)
    }

    func updateUserRole(userId: String, updatedRole: String) async throws {
        let userDocumentReference = firestoreDatabase
            .collection(usersCollectionPath)
            .document(userId)

        try await userDocumentReference.updateData(["role": updatedRole])
    }
}
