//
//  PassengerProfileViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import SwiftUI
import Combine
import FirebaseAuth
 
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
 
    // State for the "Remove Local Data" confirmation alert
    @Published var showRemoveLocalDataConfirm: Bool = false
    @Published var localDataRemoved: Bool = false
 
    // Delete account states
    @Published var showDeleteAccountConfirm: Bool = false
    @Published var isDeletingAccount: Bool = false
    @Published var deleteAccountError: String? = nil
    @Published var showDeleteAccountError: Bool = false
 
    var initials: String {
        let parts = user.name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(user.name.prefix(2)).uppercased()
    }
 
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
 
    init() {
        loadUserData()
    }
 
    //Primary load: try Core Data first; fall back to Firestore if empty.
    func loadUserData() {
        loadFromCoreData()
        if user.name.isEmpty {
            Task { await fetchFromFirestore() }
        }
    }
 
    func loadFromCoreData() {
        guard let userId = currentUserId else { return }
        guard let cached = CoreDataManager.shared.fetchPassengerProfile(userId: userId) else { return }
        user = PassengerUser(
            name:  cached.fullName     ?? "",
            phone: cached.phoneNumber  ?? "",
            email: cached.emailAddress ?? "",
            role:  "Passenger"
        )
    }
 
    func fetchFromFirestore() async {
        guard let userId = currentUserId else { return }
        isLoadingProfile = true
        defer { isLoadingProfile = false }
 
        do {
            guard let fetchedUser = try await UserService.shared.fetchUser(userId: userId) else { return }
            let phone = fetchedUser.phoneNumber.isEmpty
                ? AuthManager.shared.storedPhoneNumber
                : fetchedUser.phoneNumber
 
            CoreDataManager.shared.savePassengerProfile(
                userId:       userId,
                fullName:     fetchedUser.fullName,
                phoneNumber:  phone,
                emailAddress: fetchedUser.emailAddress ?? ""
            )
            user = PassengerUser(
                name:  fetchedUser.fullName,
                phone: phone,
                email: fetchedUser.emailAddress ?? "",
                role:  "Passenger"
            )
        } catch {
            print("[PassengerProfileViewModel] Firestore fetch failed: \(error.localizedDescription)")
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self else { return }
            let resolvedName = self.editingName.trimmingCharacters(in: .whitespaces).isEmpty
                ? self.user.name
                : self.editingName
            self.user.name  = resolvedName
            self.user.email = self.editingEmail
            self.cacheProfile(
                fullName:     resolvedName,
                phoneNumber:  self.user.phone,
                emailAddress: self.editingEmail
            )
            self.isSaving        = false
            self.showEditProfile = false
        }
    }
 
    func removeLocalData() {
        guard let userId = currentUserId else { return }
        CoreDataManager.shared.deleteAllLocalData(userId: userId)
        user             = .empty
        localDataRemoved = true
    }
 
    func signOut() {
        if let userId = currentUserId {
            CoreDataManager.shared.deleteAllLocalData(userId: userId)
        }
        AuthManager.shared.signOut()
    }
 
    //Delete Account
    func deleteAccount() {
        isDeletingAccount = true
        Task {
            do {
                try await AccountDeletionService.shared.deleteCurrentUserAccount(role: "passenger")
                // Auth deletion succeeded — AuthManager cleans up UserDefaults and
                // sets state to .unauthenticated, which RootView will pick up automatically.
                AuthManager.shared.signOut()
            } catch {
                isDeletingAccount    = false
                deleteAccountError   = error.localizedDescription
                showDeleteAccountError = true
                print("[PassengerProfileViewModel] Account deletion failed: \(error.localizedDescription)")
            }
        }
    }
}
