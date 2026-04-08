//
//  DriverPersonalInfoViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-07.
//

import Foundation
import Combine

@MainActor
final class DriverPersonalInfoViewModel: ObservableObject {
    @Published var fullName: String = ""
    @Published var phoneNumber: String = ""
    @Published var licenseNumber: String = ""
    @Published var isLoading: Bool = false
    @Published var navigateToOTP: Bool = false

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
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        isLoading = false
        navigateToOTP = true
    }
}
