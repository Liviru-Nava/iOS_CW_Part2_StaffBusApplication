//
//  OTPVerificationViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-01.
//

import Foundation
import Combine
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum OTPVerificationState: Equatable {
    case idle
    case verifying
    case success
    case error(String)
}

@MainActor
final class OTPVerificationViewModel: ObservableObject {

    let phoneNumber: String

    @Published var otpDigits: [String] = Array(repeating: "", count: 6)
    @Published var verificationState: OTPVerificationState = .idle
    @Published var secondsRemainingForResend: Int = 30
    @Published var shakeAnimationOffset: CGFloat = 0
    @Published var shouldPromptBiometricEnrollment: Bool = false
    @Published var isBiometricEnrolling: Bool = false

    private var countdownTask: Task<Void, Never>?

    init(phoneNumber: String) {
        self.phoneNumber = phoneNumber
    }

    var enteredOTPString: String {
        otpDigits.joined()
    }

    var isOTPComplete: Bool {
        enteredOTPString.count == 6
    }

    var canResendOTP: Bool {
        secondsRemainingForResend == 0
    }

    func startResendCountdown() {
        countdownTask?.cancel()
        secondsRemainingForResend = 30
        countdownTask = Task {
            while secondsRemainingForResend > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                secondsRemainingForResend -= 1
            }
        }
    }

    func resendOTP() {
        otpDigits = Array(repeating: "", count: 6)
        verificationState = .idle
        startResendCountdown()
        Task { await requestFreshOTPFromFirebase() }
    }

    private func requestFreshOTPFromFirebase() async {
        do {
            let freshVerificationID = try await PhoneAuthProvider.provider(auth: Auth.auth()).verifyPhoneNumber(
                phoneNumber,
                uiDelegate: nil
            )
            AuthManager.shared.storeFirebaseVerificationID(freshVerificationID)
        } catch {
        }
    }

    func verifyOTP() async {
        guard isOTPComplete, verificationState != .verifying else { return }
        guard let storedVerificationID = AuthManager.shared.retrieveStoredFirebaseVerificationID() else {
            verificationState = .error("Session expired. Please request a new code.")
            return
        }
        verificationState = .verifying
        let phoneAuthCredential = PhoneAuthProvider.provider(auth: Auth.auth()).credential(
            withVerificationID: storedVerificationID,
            verificationCode: enteredOTPString
        )
        do {
            let authDataResult = try await Auth.auth().signIn(with: phoneAuthCredential)
            let authenticatedUserId = authDataResult.user.uid
            let authenticatedPhoneNumber = authDataResult.user.phoneNumber ?? phoneNumber

            try await UserService.shared.createUserIfNeeded(
                userId: authenticatedUserId,
                phoneNumber: authenticatedPhoneNumber
            )

            AuthManager.shared.signIn(phoneNumber: authenticatedPhoneNumber)

            if !AuthManager.shared.isBiometricEnabled
                && BiometricService.shared.deviceSupportsBiometricAuthentication {
                shouldPromptBiometricEnrollment = true
            } else {
                AuthManager.shared.completeSignIn()
                verificationState = .success
            }
        } catch let firebaseError as NSError {
            let userFacingErrorMessage = mapFirebaseOTPErrorToUserMessage(firebaseError)
            verificationState = .error(userFacingErrorMessage)
            await triggerShakeAnimation()
        }
    }

    func enrollBiometric() {
        isBiometricEnrolling = true
        Task {
            let challengeSucceeded = await BiometricService.shared.authenticateWithBiometrics(
                reasonMessage: "Verify your identity to enable \(BiometricService.shared.biometricTypeDisplayName)"
            )
            isBiometricEnrolling = false
            if challengeSucceeded {
                AuthManager.shared.enableBiometric()
            }
            shouldPromptBiometricEnrollment = false
            AuthManager.shared.completeSignIn()
            verificationState = .success
        }
    }

    func dismissBiometricEnrollmentPrompt() {
        shouldPromptBiometricEnrollment = false
        AuthManager.shared.completeSignIn()
        verificationState = .success
    }

    func handleAutoSubmitIfComplete() async {
        guard isOTPComplete && verificationState == .idle else { return }
        await verifyOTP()
    }

    private func mapFirebaseOTPErrorToUserMessage(_ error: NSError) -> String {
        switch AuthErrorCode(rawValue: error.code) {
        case .invalidVerificationCode:
            return "The code you entered is incorrect. Please try again."
        case .sessionExpired:
            return "Your session has expired. Please request a new code."
        case .networkError:
            return "No internet connection. Please check your network."
        default:
            return error.localizedDescription
        }
    }

    private func triggerShakeAnimation() async {
        let shakeOffsets: [CGFloat] = [0, -10, 10, -8, 8, -4, 4, 0]
        for offset in shakeOffsets {
            shakeAnimationOffset = offset
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }
}
