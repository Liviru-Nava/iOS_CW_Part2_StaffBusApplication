//
//  DriverPersonalInfoViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-07.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class DriverPersonalInfoViewModel: ObservableObject {
    @Published var fullName: String = ""
    @Published var phoneNumber: String = ""
    @Published var licenseNumber: String = ""
    @Published var isLoading: Bool = false
    @Published var navigateToOTP: Bool = false
    @Published var sendOTPErrorMessage: String? = nil

    var fullPhoneNumberWithCountryCode: String {
        "+94" + phoneNumber.filter { $0.isNumber }
    }

    var isFullNameValid: Bool {
        fullName.trimmingCharacters(in: .whitespaces).count >= 2
    }

    var isPhoneValid: Bool {
        let digits = phoneNumber.filter { $0.isNumber }
        return digits.count >= 9 && digits.count <= 10
    }

    var isLicenseValid: Bool {
        licenseNumber.trimmingCharacters(in: .whitespaces).count >= 4
    }

    var canContinue: Bool {
        isFullNameValid && isPhoneValid && isLicenseValid
    }

    func sendOTP() async {
        guard canContinue else { return }
        isLoading = true
        sendOTPErrorMessage = nil
        do {
            let firebaseVerificationID = try await PhoneAuthProvider.provider(auth: Auth.auth())
                .verifyPhoneNumber(fullPhoneNumberWithCountryCode, uiDelegate: nil)
            AuthManager.shared.storeFirebaseVerificationID(firebaseVerificationID)
            isLoading = false
            navigateToOTP = true
        } catch let firebaseError as NSError {
            isLoading = false
            sendOTPErrorMessage = mapSendOTPFirebaseError(firebaseError)
        }
    }

    private func mapSendOTPFirebaseError(_ error: NSError) -> String {
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
