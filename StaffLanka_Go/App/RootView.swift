//
//  RootView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-12.
//

import SwiftUI

struct RootView: View {

    @EnvironmentObject private var authManager: AuthManager
    @State private var isBiometricAutoLoginInProgress: Bool = false

    var body: some View {
        Group {
            switch authManager.authenticationState {
            case .onboarding:
                OnboardingView()
                    .transition(.opacity)

            case .terms:
                TermsView()
                    .transition(.opacity)

            case .unauthenticated:
                LoginView()
                    .transition(.opacity)

            case .authenticated:
                PassengerNavigationBar()
                    .transition(.opacity)

            case .driverAuthenticated:
                DriverNavigationBar()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.authenticationState)
        .onAppear {
            Task { await attemptBiometricAutoLoginOnLaunch() }
        }
    }

    private func attemptBiometricAutoLoginOnLaunch() async {
        guard authManager.authenticationState == .unauthenticated else { return }
        guard authManager.isBiometricEnabled else { return }
        guard !authManager.storedPhoneNumber.isEmpty else { return }

        isBiometricAutoLoginInProgress = true
        let biometricLoginSucceeded = await BiometricService.shared.authenticateWithBiometrics(
            reasonMessage: "Sign in to StaffLanka Go"
        )
        isBiometricAutoLoginInProgress = false

        if biometricLoginSucceeded {
            authManager.signIn(phoneNumber: authManager.storedPhoneNumber)
        }
    }
}
