//
//  DriverOTPViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-07.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

enum DriverOTPState: Equatable {
    case idle
    case verifying
    case success
    case error(String)
}

@MainActor
final class DriverOTPViewModel: ObservableObject {

    let phoneNumber: String

    init(phoneNumber: String) {
        self.phoneNumber = phoneNumber
    }

    @Published var otpDigits: [String] = Array(repeating: "", count: 6)
    @Published var state: DriverOTPState = .idle
    @Published var secondsRemaining: Int = 30
    @Published var shakeOffset: CGFloat = 0

    private var countdownTask: Task<Void, Never>?

    var enteredOTP: String { otpDigits.joined() }
    var isComplete: Bool { enteredOTP.count == 6 }
    var canResend: Bool { secondsRemaining == 0 }

    func startCountdown() {
        countdownTask?.cancel()
        secondsRemaining = 30
        countdownTask = Task {
            while secondsRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                secondsRemaining -= 1
            }
        }
    }

    func resendOTP() {
        otpDigits = Array(repeating: "", count: 6)
        state = .idle
        startCountdown()
        Task { await requestFreshVerificationCode() }
    }

    private func requestFreshVerificationCode() async {
        do {
            let freshVerificationID = try await PhoneAuthProvider.provider(auth: Auth.auth())
                .verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            AuthManager.shared.storeFirebaseVerificationID(freshVerificationID)
        } catch {
        }
    }

    func verify() async {
        guard isComplete, state != .verifying else { return }
        guard let storedVerificationID = AuthManager.shared.retrieveStoredFirebaseVerificationID() else {
            state = .error("Session expired. Please go back and request a new code.")
            return
        }
        state = .verifying
        let phoneAuthCredential = PhoneAuthProvider.provider(auth: Auth.auth()).credential(
            withVerificationID: storedVerificationID,
            verificationCode: enteredOTP
        )
        do {
            let authDataResult = try await Auth.auth().signIn(with: phoneAuthCredential)
            let authenticatedUserId = authDataResult.user.uid
            let authenticatedPhoneNumber = authDataResult.user.phoneNumber ?? phoneNumber
            try await UserService.shared.createUserIfNeeded(
                userId: authenticatedUserId,
                phoneNumber: authenticatedPhoneNumber
            )
            state = .success
        } catch let firebaseError as NSError {
            state = .error(mapVerifyFirebaseError(firebaseError))
            await triggerShake()
        }
    }

    func handleAutoSubmit() async {
        guard isComplete && state == .idle else { return }
        await verify()
    }

    func triggerShake() async {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) { shakeOffset = 10 }
        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation { shakeOffset = 0 }
    }

    private func mapVerifyFirebaseError(_ error: NSError) -> String {
        switch AuthErrorCode(rawValue: error.code) {
        case .invalidVerificationCode:
            return "The code you entered is incorrect. Please try again."
        case .sessionExpired:
            return "Your session has expired. Please go back and request a new code."
        case .networkError:
            return "No internet connection. Please check your network."
        default:
            return error.localizedDescription
        }
    }
}
