//
//  LoginViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-03-31.
//


import Foundation
import Combine

enum LoginState: Equatable {
    case idle
    case loading
    case otpSent
    case error(String)
}

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var termsAccepted: Bool = false
    //@Published var selectedCountryCode: String = "+94"
    @Published var loginState: LoginState = .idle
    @Published var showTermsSheet: Bool = false
    var selectedCountryCode: String { "+94"}

    var fullPhoneNumber: String {
        selectedCountryCode + phoneNumber
    }

    var isPhoneNumberValid: Bool {
        let digits = phoneNumber.filter { $0.isNumber }
        return digits.count >= 9 && digits.count <= 10
    }

    var canContinue: Bool {
        isPhoneNumberValid && termsAccepted
    }

    func sendOTP() async {
        guard canContinue else { return }
        loginState = .loading
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        loginState = .otpSent
    }
}
