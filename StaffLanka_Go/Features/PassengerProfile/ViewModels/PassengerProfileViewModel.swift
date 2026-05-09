//
//  PassengerProfileViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import PhotosUI

struct PassengerUser {
    var name: String
    var phone: String
    var email: String
    var role: String

    static let empty = PassengerUser(name: "", phone: "", email: "", role: "Passenger")
}

@MainActor
final class PassengerProfileViewModel: ObservableObject {

    @Published var user: PassengerUser = .empty
    @Published var showEditProfile: Bool = false
    @Published var isSaving: Bool = false
    @Published var editingName: String = ""
    @Published var editingEmail: String = ""
    @Published var isLoadingProfile: Bool = false

    // Holds the profile photo in memory — loaded from Firestore on fetch and updated on photo selection
    @Published var passengerProfilePhotoImageData: Data? = nil
    @Published var selectedProfilePhotoPicPickerItem: PhotosPickerItem? = nil

    // State for the Remove Local Data confirmation alert
    @Published var showRemoveLocalDataConfirm: Bool = false
    @Published var localDataRemoved: Bool = false

    // Delete account states
    @Published var showDeleteAccountConfirm: Bool = false
    @Published var isDeletingAccount: Bool = false
    @Published var deleteAccountError: String? = nil
    @Published var showDeleteAccountError: Bool = false

    var initials: String {
        let nameParts = user.name.split(separator: " ")
        if nameParts.count >= 2 {
            return "\(nameParts[0].prefix(1))\(nameParts[1].prefix(1))".uppercased()
        }
        return String(user.name.prefix(2)).uppercased()
    }

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    init() {
        loadUserData()
    }

    // Primary load: try Core Data first, fall back to Firestore if the cached name is empty
    func loadUserData() {
        loadFromCoreData()
        if user.name.isEmpty {
            Task { await fetchFromFirestore() }
        }
    }

    func loadFromCoreData() {
        guard let userId = currentUserId else { return }
        guard let cachedPassengerProfile = CoreDataManager.shared.fetchPassengerProfile(userId: userId) else { return }
        user = PassengerUser(
            name:  cachedPassengerProfile.fullName     ?? "",
            phone: cachedPassengerProfile.phoneNumber  ?? "",
            email: cachedPassengerProfile.emailAddress ?? "",
            role:  "Passenger"
        )
    }

    func fetchFromFirestore() async {
        guard let userId = currentUserId else { return }
        isLoadingProfile = true
        defer { isLoadingProfile = false }

        do {
            guard let fetchedUserRecord = try await UserService.shared.fetchUser(userId: userId) else { return }
            let resolvedPhoneNumber = fetchedUserRecord.phoneNumber.isEmpty
                ? AuthManager.shared.storedPhoneNumber
                : fetchedUserRecord.phoneNumber

            CoreDataManager.shared.savePassengerProfile(
                userId:       userId,
                fullName:     fetchedUserRecord.fullName,
                phoneNumber:  resolvedPhoneNumber,
                emailAddress: fetchedUserRecord.emailAddress ?? ""
            )
            user = PassengerUser(
                name:  fetchedUserRecord.fullName,
                phone: resolvedPhoneNumber,
                email: fetchedUserRecord.emailAddress ?? "",
                role:  "Passenger"
            )

            // Load the profile photo from Firestore if a base64 string was previously saved
            await loadProfilePhotoFromFirestore(userId: userId)
        } catch {
            print("[PassengerProfileViewModel] Firestore fetch failed: \(error.localizedDescription)")
        }
    }

    // Fetches the base64 profile photo from the Firestore users document and decodes it into image data
    private func loadProfilePhotoFromFirestore(userId: String) async {
        do {
            let firestoreDatabase = Firestore.firestore()
            let userDocumentSnapshot = try await firestoreDatabase.collection("users").document(userId).getDocument()
            if let base64PhotoString = userDocumentSnapshot.data()?["profilePhotoBase64"] as? String,
               !base64PhotoString.isEmpty,
               let decodedPhotoData = Data(base64Encoded: base64PhotoString) {
                passengerProfilePhotoImageData = decodedPhotoData
            }
        } catch {
            print("[PassengerProfileViewModel] Failed to load profile photo from Firestore: \(error.localizedDescription)")
        }
    }

    func cacheProfile(fullName: String, phoneNumber: String, emailAddress: String) {
        guard let userId = currentUserId else { return }
        CoreDataManager.shared.savePassengerProfile(
            userId:       userId,
            fullName:     fullName,
            phoneNumber:  phoneNumber,
            emailAddress: emailAddress
        )
        user = PassengerUser(name: fullName, phone: phoneNumber, email: emailAddress, role: "Passenger")
    }

    func openEditProfile() {
        editingName  = user.name
        editingEmail = user.email
        showEditProfile = true
    }

    func saveProfile() {
        isSaving = true
        let resolvedSaveName = editingName.trimmingCharacters(in: .whitespaces).isEmpty
            ? user.name
            : editingName
        let resolvedSaveEmail = editingEmail

        Task {
            if let userId = currentUserId {
                do {
                    try await UserService.shared.updateUserRoleAndName(userId: userId, updatedRole: "passenger", fullName: resolvedSaveName)
                    try await UserService.shared.updateUserEmailAddress(userId: userId, updatedEmailAddress: resolvedSaveEmail)
                } catch {
                    print("[PassengerProfileViewModel] Failed to save profile to Firestore: \(error.localizedDescription)")
                }
            }

            user.name  = resolvedSaveName
            user.email = resolvedSaveEmail
            cacheProfile(
                fullName:     resolvedSaveName,
                phoneNumber:  user.phone,
                emailAddress: resolvedSaveEmail
            )
            isSaving        = false
            showEditProfile = false
        }
    }

    // Re-fetches only the phone number from Firestore after a successful phone change
    // Called by PassengerConfirmPhoneOTPView after the OTP is confirmed
    func refreshDisplayedPhoneNumber() {
        Task {
            guard let userId = currentUserId else { return }
            do {
                let userRecord = try await UserService.shared.fetchUser(userId: userId)
                let updatedPhone = userRecord?.phoneNumber ?? ""
                self.user.phone = updatedPhone
                // Also update the Core Data cache so the new number persists offline
                CoreDataManager.shared.savePassengerProfile(
                    userId:       userId,
                    fullName:     user.name,
                    phoneNumber:  updatedPhone,
                    emailAddress: user.email
                )
            } catch {
                print("[PassengerProfileViewModel] Failed to refresh phone number: \(error.localizedDescription)")
            }
        }
    }

    // Handles photo selection from PhotosPicker — compresses the image and saves to Firestore
    func processAndSaveSelectedProfilePhoto(selectedPhotoPickerItem item: PhotosPickerItem) {
        Task {
            guard let rawPhotoData = try? await item.loadTransferable(type: Data.self) else { return }
            guard let selectedUIImage = UIImage(data: rawPhotoData) else { return }
            let compressedPhotoData = selectedUIImage.jpegData(compressionQuality: 0.25) ?? rawPhotoData

            guard compressedPhotoData.count < 900_000 else {
                print("[PassengerProfileViewModel] Profile photo too large after compression.")
                return
            }

            self.passengerProfilePhotoImageData = compressedPhotoData

            guard let userId = currentUserId else { return }
            let base64EncodedPhotoString = compressedPhotoData.base64EncodedString()
            do {
                try await UserService.shared.updatePassengerProfilePhoto(userId: userId, base64PhotoString: base64EncodedPhotoString)
                print("[PassengerProfileViewModel] Profile photo saved to Firestore for passenger \(userId)")
            } catch {
                print("[PassengerProfileViewModel] Failed to save photo to Firestore: \(error.localizedDescription)")
            }
        }
    }

    func removeLocalData() {
        guard let userId = currentUserId else { return }
        CoreDataManager.shared.deleteAllLocalData(userId: userId)
        user                           = .empty
        passengerProfilePhotoImageData = nil
        localDataRemoved               = true
    }

    func signOut() {
        if let userId = currentUserId {
            CoreDataManager.shared.deleteAllLocalData(userId: userId)
        }
        AuthManager.shared.signOut()
    }

    // Delete Account — removes all Firestore data then deletes the Firebase Auth account
    func deleteAccount() {
        isDeletingAccount = true
        Task {
            do {
                try await AccountDeletionService.shared.deleteCurrentUserAccount(role: "passenger")
                AuthManager.shared.signOut()
            } catch {
                isDeletingAccount      = false
                deleteAccountError     = error.localizedDescription
                showDeleteAccountError = true
                print("[PassengerProfileViewModel] Account deletion failed: \(error.localizedDescription)")
            }
        }
    }
}
