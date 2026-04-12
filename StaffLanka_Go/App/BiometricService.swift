//
//  BiometricService.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-12.
//

import Foundation
import LocalAuthentication

final class BiometricService {

    static let shared = BiometricService()

    private init() {}

    var deviceSupportsBiometricAuthentication: Bool {
        let authenticationContext = LAContext()
        var evaluationError: NSError?
        return authenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &evaluationError)
    }

    var biometricTypeDisplayName: String {
        let authenticationContext = LAContext()
        var evaluationError: NSError?
        guard authenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &evaluationError) else {
            return "Biometrics"
        }
        switch authenticationContext.biometryType {
        case .faceID:   return "Face ID"
        case .touchID:  return "Touch ID"
        case .opticID:  return "Optic ID"
        default:        return "Biometrics"
        }
    }

    func authenticateWithBiometrics(reasonMessage: String) async -> Bool {
        let authenticationContext = LAContext()
        var evaluationError: NSError?

        guard authenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &evaluationError) else {
            return false
        }

        do {
            let authenticationResult = try await authenticationContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reasonMessage
            )
            return authenticationResult
        } catch {
            return false
        }
    }
}
