//
//  UserService.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-12.
//


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
            "phone"        : phoneNumber,
            "name"         : "New User",
            "role"         : "passenger",
            "emailAddress" : "",
            "createdAt"    : Timestamp(date: Date())
        ]

        try await userDocumentReference.setData(newUserDocument)
    }

    func fetchUser(userId: String) async throws -> UserModel? {
        let userDocumentReference = firestoreDatabase
            .collection(usersCollectionPath)
            .document(userId)

        let userDocumentSnapshot = try await userDocumentReference.getDocument()

        guard userDocumentSnapshot.exists else { return nil }

        return try userDocumentSnapshot.data(as: UserModel.self)
    }

    func updateUserRoleAndName(userId: String, updatedRole: String, fullName: String) async throws {
        let userDocumentReference = firestoreDatabase
            .collection(usersCollectionPath)
            .document(userId)

        try await userDocumentReference.updateData([
            "role": updatedRole,
            "name": fullName
        ])
    }

    // Updates only the email address field in the users collection
    func updateUserEmailAddress(userId: String, updatedEmailAddress: String) async throws {
        let userDocumentReference = firestoreDatabase
            .collection(usersCollectionPath)
            .document(userId)

        try await userDocumentReference.updateData([
            "emailAddress": updatedEmailAddress
        ])
    }

    // Updates only the phone number field in the users collection after OTP verification
    func updateUserPhoneNumber(userId: String, updatedPhoneNumber: String) async throws {
        let userDocumentReference = firestoreDatabase
            .collection(usersCollectionPath)
            .document(userId)

        try await userDocumentReference.updateData([
            "phone": updatedPhoneNumber
        ])
    }

    // Saves the passenger profile photo as a base64 string in the users collection
    // Used by PassengerProfileViewModel when the user picks a new photo from their library
    func updatePassengerProfilePhoto(userId: String, base64PhotoString: String) async throws {
        let userDocumentReference = firestoreDatabase
            .collection(usersCollectionPath)
            .document(userId)

        try await userDocumentReference.updateData([
            "profilePhotoBase64": base64PhotoString
        ])
    }
}
