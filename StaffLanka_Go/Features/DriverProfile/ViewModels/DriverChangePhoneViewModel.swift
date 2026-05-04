// DriverChangePhoneViewModel.swift
// StaffLanka_Go
//
// Created by Liviru Navaratna on 2026-04-10.
//

import Foundation
import SwiftUI
import FirebaseAuth
import Combine

// Manages the two step flow for verifying and updating the driver phone number
@MainActor
final class DriverChangePhoneViewModel: ObservableObject {

    // The new phone number digits entered by the driver without country code
    @Published var newPhoneNumberDigitsInput: String = ""

    // Controls whether the OTP confirmation screen is shown after code is sent
    @Published var shouldNavigateToOTPConfirmationScreen: Bool = false

    // Tracks whether the verification code is currently being sent to Firebase
    @Published var isSendingVerificationCodeToFirebase: Bool = false

    // Holds an error message to show under the send code button if something goes wrong
    @Published var sendVerificationCodeErrorMessage: String? = nil

    // The full phone number including the country code prefix used for Firebase
    var fullPhoneNumberWithCountryCodePrefix: String {
        "+1" + newPhoneNumberDigitsInput.filter { $0.isNumber }
    }

    // Validates that the entered digits form a plausible 10 digit US phone number
    var isEnteredPhoneNumberValid: Bool {
        let digitsOnly = newPhoneNumberDigitsInput.filter { $0.isNumber }
        return digitsOnly.count == 10
    }

    var canProceedToSendVerificationCode: Bool {
        isEnteredPhoneNumberValid
    }

    // Sends a Firebase OTP to the new phone number and navigates to the confirmation screen
    func sendVerificationCodeToNewPhoneNumber() async {
        guard canProceedToSendVerificationCode else { return }
        isSendingVerificationCodeToFirebase = true
        sendVerificationCodeErrorMessage = nil

        do {
            let newFirebaseVerificationID = try await PhoneAuthProvider.provider(auth: Auth.auth())
                .verifyPhoneNumber(fullPhoneNumberWithCountryCodePrefix, uiDelegate: nil)
            AuthManager.shared.storeFirebaseVerificationID(newFirebaseVerificationID)
            isSendingVerificationCodeToFirebase = false
            shouldNavigateToOTPConfirmationScreen = true
        } catch let firebaseError as NSError {
            isSendingVerificationCodeToFirebase = false
            sendVerificationCodeErrorMessage = mapSendCodeFirebaseError(firebaseError)
        }
    }

    // Verifies the OTP entered by the driver and updates Firestore and local session on success
    func confirmPhoneNumberChangeWithEnteredOTP(enteredOTPCode: String, onSuccessCompletion: @escaping () -> Void) async {
        guard let storedVerificationID = AuthManager.shared.retrieveStoredFirebaseVerificationID() else {
            return
        }

        let phoneAuthCredential = PhoneAuthProvider.provider(auth: Auth.auth()).credential(
            withVerificationID: storedVerificationID,
            verificationCode: enteredOTPCode
        )

        do {
            // Re-authenticate the current user with the new phone credential
            try await Auth.auth().currentUser?.reauthenticate(with: phoneAuthCredential)

            guard let userId = Auth.auth().currentUser?.uid else { return }

            // Write the updated phone number to the users Firestore collection
            try await UserService.shared.updateUserPhoneNumber(userId: userId, updatedPhoneNumber: fullPhoneNumberWithCountryCodePrefix)

            // Update the locally stored phone number in AuthManager so the session reflects the change
            UserDefaults.standard.set(fullPhoneNumberWithCountryCodePrefix, forKey: "storedPhoneNumber")

            onSuccessCompletion()
        } catch {
            print("Phone number change confirmation failed: \(error)")
        }
    }

    private func mapSendCodeFirebaseError(_ error: NSError) -> String {
        switch AuthErrorCode(rawValue: error.code) {
        case .invalidPhoneNumber:
            return "The phone number entered is not valid."
        case .quotaExceeded:
            return "Too many requests. Please try again later."
        case .networkError:
            return "No internet connection. Please check your network."
        default:
            return error.localizedDescription
        }
    }
}
