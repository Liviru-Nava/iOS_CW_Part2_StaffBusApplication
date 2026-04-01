//
//  OTPVerificationViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-01.
//


import Foundation
import Combine
import SwiftUI

enum OTPVerificationState: Equatable {
    case idle
    case verifying
    case success
    case error(String)
}

@MainActor
final class OTPVerificationViewModel: ObservableObject {
    let phoneNumber: String

    init(phoneNumber: String) {
        self.phoneNumber = phoneNumber
    }

    @Published var otpDigits: [String] = Array(repeating: "", count: 6)
    @Published var state: OTPVerificationState = .idle
    @Published var secondsRemaining: Int = 30
    @Published var shakeOffset: CGFloat = 0

    private var countdownTask: Task<Void, Never>?

    var enteredOTP: String {
        otpDigits.joined()
    }

    var isComplete: Bool {
        enteredOTP.count == 6
    }

    var canResend: Bool {
        secondsRemaining == 0
    }

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
        if enteredOTP.count == 6 {
            state = .success
        } else {
            state = .error("Invalid code. Please try again.")
            await triggerShake()
        }
    }

    func handleAutoSubmit() async {
        guard isComplete && state == .idle else { return }
        await verify()
    }

    private func triggerShake() async {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
            shakeOffset = 12
        }
        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            shakeOffset = 0
        }
    }
}

