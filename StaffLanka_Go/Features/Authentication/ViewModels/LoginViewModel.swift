//
//  LoginViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-03-31.
//


import Foundation
import Combine
import FirebaseAuth

enum LoginState: Equatable {
    case idle
    case loading
    case otpSent
    case error(String)
}

@MainActor
final class LoginViewModel: ObservableObject {

    @Published var phoneNumber: String = ""
    @Published var loginState: LoginState = .idle

    var selectedCountryCode: String { "+94" }

    var isPhoneNumberValid: Bool {
        let numericDigitsOnly = phoneNumber.filter { $0.isNumber }
        return numericDigitsOnly.count >= 9 && numericDigitsOnly.count <= 10
    }

    var canSendOTP: Bool {
        isPhoneNumberValid
    }

    var shouldShowBiometricLoginButton: Bool {
        AuthManager.shared.isBiometricEnabled &&
        !AuthManager.shared.storedPhoneNumber.isEmpty
    }

    //Update the phone number to strip spaces
    var fullPhoneNumber: String {
        let combined = selectedCountryCode + phoneNumber
        return combined.replacingOccurrences(of: " ", with: "")
    }
    
    
    func sendOTP() async {
        guard canSendOTP else { return }
        loginState = .loading
        
        print("DEBUG: Sending OTP to EXACT string: '\(fullPhoneNumber)'")
        
        do {
            //bypass buggy verification
            let firebaseVerificationID = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                
                PhoneAuthProvider.provider().verifyPhoneNumber(fullPhoneNumber, uiDelegate: nil) { verificationID, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    if let verificationID = verificationID {
                        continuation.resume(returning: verificationID)
                        return
                    }
                    
                    let unknownError = NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred."])
                    continuation.resume(throwing: unknownError)
                }
            }
            
            // Success
            AuthManager.shared.storeFirebaseVerificationID(firebaseVerificationID)
            loginState = .otpSent
            print("DEBUG: OTP Request Successful! Verification ID saved.")
            
        } catch let firebaseError as NSError {
            print("DEBUG: Firebase Error Code: \(firebaseError.code)")
            print("DEBUG: Firebase Error Details: \(firebaseError.localizedDescription)")
            
            let errorMessage = mapFirebasePhoneAuthErrorToUserMessage(firebaseError)
            loginState = .error(errorMessage)
        }
    }

    private func mapFirebasePhoneAuthErrorToUserMessage(_ error: NSError) -> String {
        switch AuthErrorCode(rawValue: error.code) {
        case .invalidPhoneNumber:
            return "The phone number you entered is not valid."
        case .quotaExceeded:
            return "Too many requests. Please try again later."
        case .networkError:
            return "No internet connection. Please check your network."
        default:
            return error.localizedDescription
        }
    }
}
