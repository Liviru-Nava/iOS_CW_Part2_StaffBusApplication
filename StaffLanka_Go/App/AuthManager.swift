//
//  AuthManager.swift
//  StaffLanka_Go
//
//  Created by automated edit on 2026-04-05.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated: Bool = false

    private init() {}

    func signIn() {
        isAuthenticated = true
    }

    func signOut() {
        isAuthenticated = false
    }
}
