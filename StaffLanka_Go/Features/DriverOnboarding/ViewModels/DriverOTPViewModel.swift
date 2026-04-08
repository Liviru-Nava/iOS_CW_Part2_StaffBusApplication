//
//  DriverOTPViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-07.
//

import Foundation
import SwiftUI
import Combine

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
    }

    func verify() async {
        guard isComplete, state != .verifying else { return }
        state = .verifying
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        state = .success
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
}
