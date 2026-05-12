//
//  PassengerChangePhoneViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-09.
//

import Foundation
import SwiftUI
import FirebaseAuth
import Combine

// Manages the two-step flow for verifying and updating the passenger phone number
// Mirrors DriverChangePhoneViewModel exactly, adapted for the passenger context
@MainActor
final class PassengerChangePhoneViewModel: ObservableObject {

    // The new phone number digits entered by the passenger without country code
    @Published var newPhoneNumberDigitsInput: String = ""

    // Controls whether the OTP confirmation screen is shown after the code is sent
    @Published var shouldNavigateToOTPConfirmationScreen: Bool = false

    // Tracks whether the verification code is currently being sent to Firebase
    @Published var isSendingVerificationCodeToFirebase: Bool = false

    // Holds an error message to show under the send code button if something goes wrong
    @Published var sendVerificationCodeErrorMessage: String? = nil

    // The full phone number including the Sri Lanka country code prefix used for Firebase Auth
    var fullPhoneNumberWithCountryCodePrefix: String {
        "+94" + newPhoneNumberDigitsInput.filter { $0.isNumber }
    }

    // Validates that the entered digits form a plausible 9-digit Sri Lankan phone number
    // Sri Lankan local numbers are 9 digits after the +94 prefix, e.g. 711047585
    var isEnteredPhoneNumberValid: Bool {
        let digitsOnly = newPhoneNumberDigitsInput.filter { $0.isNumber }
        return digitsOnly.count == 9
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

    // Verifies the OTP and updates the phone number in Firestore and the local session on success
    func confirmPhoneNumberChangeWithEnteredOTP(enteredOTPCode: String, onSuccessCompletion: @escaping () -> Void) async {
        guard let storedVerificationID = AuthManager.shared.retrieveStoredFirebaseVerificationID() else {
            return
        }

        let phoneAuthCredential = PhoneAuthProvider.provider(auth: Auth.auth()).credential(
            withVerificationID: storedVerificationID,
            verificationCode: enteredOTPCode
        )

        do {
            try await Auth.auth().currentUser?.reauthenticate(with: phoneAuthCredential)

            guard let userId = Auth.auth().currentUser?.uid else { return }

            try await UserService.shared.updateUserPhoneNumber(userId: userId, updatedPhoneNumber: fullPhoneNumberWithCountryCodePrefix)

            // Update the locally stored phone number so the session reflects the change immediately
            UserDefaults.standard.set(fullPhoneNumberWithCountryCodePrefix, forKey: "storedPhoneNumber")

            onSuccessCompletion()
        } catch {
            print("[PassengerChangePhoneVM] Phone number change confirmation failed: \(error)")
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
