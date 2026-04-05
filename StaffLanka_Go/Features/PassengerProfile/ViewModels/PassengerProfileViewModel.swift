//
//  PassengerProfileViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import SwiftUI
import Combine

struct PassengerUser {
    var name: String
    var phone: String
    var email: String
    var role: String

    static let mock = PassengerUser(
        name: "Liviru Navaratna",
        phone: "+94 77 123 4567",
        email: "liviru@example.com",
        role: "Passenger"
    )
}

@MainActor
final class PassengerProfileViewModel: ObservableObject {
    @Published var user: PassengerUser = PassengerUser.mock
    @Published var showEditProfile: Bool = false
    @Published var isSaving: Bool = false
    @Published var editingName: String = ""
    @Published var editingEmail: String = ""

    var initials: String {
        let parts = user.name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(user.name.prefix(2)).uppercased()
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
            self.user.name  = self.editingName.trimmingCharacters(in: .whitespaces).isEmpty
                ? self.user.name
                : self.editingName
            self.user.email = self.editingEmail
            self.isSaving   = false
            self.showEditProfile = false
        }
    }

    func signOut() {
        AuthManager.shared.signOut()
    }
}
