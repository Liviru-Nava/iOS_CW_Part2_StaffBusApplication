//
//  AuthManager.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

enum AuthenticationState {
    case onboarding
    case terms
    case unauthenticated
    case authenticated
    case driverAuthenticated
}

@MainActor
final class AuthManager: ObservableObject {

    static let shared = AuthManager()

    @Published var authenticationState: AuthenticationState = .onboarding
    @Published var currentUserRole: String = "passenger"

    @Published var isBiometricEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBiometricEnabled, forKey: isBiometricEnabledStorageKey)
        }
    }

    private let hasSeenOnboardingStorageKey      = "hasSeenOnboarding"
    private let hasAcceptedTermsStorageKey        = "hasAcceptedTerms"
    private let isLoggedInStorageKey              = "isLoggedIn"
    private let storedPhoneNumberKey              = "storedPhoneNumber"
    private let isBiometricEnabledStorageKey      = "isBiometricEnabled"
    private let firebaseVerificationIDStorageKey  = "firebaseVerificationID"
    private let storedUserRoleKey                 = "storedUserRole"

    var storedPhoneNumber: String {
        UserDefaults.standard.string(forKey: storedPhoneNumberKey) ?? ""
    }

    var hasSeenOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasSeenOnboardingStorageKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSeenOnboardingStorageKey) }
    }

    var hasAcceptedTerms: Bool {
        get { UserDefaults.standard.bool(forKey: hasAcceptedTermsStorageKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasAcceptedTermsStorageKey) }
    }

    private init() {
        self.isBiometricEnabled = UserDefaults.standard.bool(forKey: "isBiometricEnabled")
        checkSession()
    }

    func checkSession() {
        if !hasSeenOnboarding {
            authenticationState = .onboarding
            return
        }
        if !hasAcceptedTerms {
            authenticationState = .terms
            return
        }
        let isLoggedIn = UserDefaults.standard.bool(forKey: isLoggedInStorageKey)
        guard isLoggedIn else {
            authenticationState = .unauthenticated
            return
        }
        if isBiometricEnabled {
            authenticationState = .unauthenticated
            return
        }
        let restoredRole = UserDefaults.standard.string(forKey: storedUserRoleKey) ?? "passenger"
        currentUserRole = restoredRole
        authenticationState = restoredRole == "driver" ? .driverAuthenticated : .authenticated
    }

    func markOnboardingComplete() {
        hasSeenOnboarding = true
        checkSession()
    }

    func acceptTerms() {
        hasAcceptedTerms = true
        checkSession()
    }

    func signIn(phoneNumber: String) {
        UserDefaults.standard.set(true,        forKey: isLoggedInStorageKey)
        UserDefaults.standard.set(phoneNumber, forKey: storedPhoneNumberKey)
    }

    func completeSignIn() {
        Task {
            guard let currentFirebaseUser = Auth.auth().currentUser else {
                authenticationState = .authenticated
                return
            }
            await refreshUserRoleFromFirestore(userId: currentFirebaseUser.uid)
        }
    }

    func refreshUserRoleFromFirestore(userId: String) async {
        do {
            let fetchedUser = try await UserService.shared.fetchUser(userId: userId)
            let resolvedRole = fetchedUser?.userRole ?? "passenger"
            UserDefaults.standard.set(resolvedRole, forKey: storedUserRoleKey)
            currentUserRole = resolvedRole
            authenticationState = resolvedRole == "driver" ? .driverAuthenticated : .authenticated
        } catch {
            authenticationState = .authenticated
        }
    }

    func signOut() {
        UserDefaults.standard.set(false, forKey: isLoggedInStorageKey)
        UserDefaults.standard.removeObject(forKey: storedPhoneNumberKey)
        UserDefaults.standard.removeObject(forKey: firebaseVerificationIDStorageKey)
        UserDefaults.standard.removeObject(forKey: storedUserRoleKey)
        currentUserRole = "passenger"
        try? Auth.auth().signOut()
        authenticationState = .unauthenticated
    }

    func storeFirebaseVerificationID(_ verificationID: String) {
        UserDefaults.standard.set(verificationID, forKey: firebaseVerificationIDStorageKey)
    }

    func retrieveStoredFirebaseVerificationID() -> String? {
        UserDefaults.standard.string(forKey: firebaseVerificationIDStorageKey)
    }

    func enableBiometric() {
        isBiometricEnabled = true
    }

    func disableBiometric() {
        isBiometricEnabled = false
    }
}
