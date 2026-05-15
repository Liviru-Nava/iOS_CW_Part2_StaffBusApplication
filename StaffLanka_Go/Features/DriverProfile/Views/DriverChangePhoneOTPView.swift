//
//  DriverChangePhoneOTPView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.

import SwiftUI

struct DriverChangePhoneOTPView: View {
    @ObservedObject var driverProfileViewModel: DriverProfileViewModel
    let phoneNumber: String

    @StateObject private var otpViewModel: DriverChangePhoneOTPViewModel
    @State private var currentlyActiveBoxIndex: Int = 0
    @FocusState private var inputFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(phoneNumber: String, driverProfileViewModel: DriverProfileViewModel) {
        self.phoneNumber = phoneNumber
        self.driverProfileViewModel = driverProfileViewModel
        _otpViewModel = StateObject(wrappedValue: DriverChangePhoneOTPViewModel(phoneNumber: phoneNumber))
    }

    var body: some View {
        ZStack {
            // Background tap dismisses the number pad (Issue 1 / keyboard fix).
            Color.appBackground.ignoresSafeArea()
                .onTapGesture {
                    inputFocused = false
                }

            VStack(spacing: 32) {
                headerSection
                otpBoxRow
                    .offset(x: otpViewModel.shakeOffset)
                hiddenInput
                if case .error(let errorMessage) = otpViewModel.state {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.statusDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                verifyButton
                resendRow
                Spacer()
            }
            .animation(.easeInOut(duration: 0.2), value: otpViewModel.state)
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .navigationTitle("Verify Number")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            otpViewModel.startCountdown()
            inputFocused = true
        }
        .onChange(of: otpViewModel.enteredOTP) { _, _ in
            Task { await otpViewModel.handleAutoSubmit(driverProfileViewModel: driverProfileViewModel) }
        }
        .onChange(of: otpViewModel.state) { _, newState in
            if newState == .success {
                driverProfileViewModel.saveDriverProfileEdits()
                driverProfileViewModel.isEditingDriverProfile = false
                dismiss()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 50)
                    .fill(Color.brandAccent.opacity(0.13))
                    .frame(width: 80, height: 80)
                Image(systemName: "message.badge.filled.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.brandAccent)
            }

            Text("Verify Your Number")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            Text("Enter the 6-digit code sent to\n\(phoneNumber)")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }


    private var otpBoxRow: some View {
        HStack(spacing: 10) {
            ForEach(0..<6, id: \.self) { i in
                OTPDigitBox(
                    digit: otpViewModel.otpDigits[i],
                    isActive: currentlyActiveBoxIndex == i
                )
                .onTapGesture {
                    currentlyActiveBoxIndex = i
                    inputFocused = true
                }
            }
        }
    }

    private var hiddenInput: some View {
        TextField("", text: Binding(
            get: { otpViewModel.enteredOTP },
            set: { newVal in
                let digits = String(newVal.filter(\.isNumber).prefix(6))
                for i in 0..<6 {
                    otpViewModel.otpDigits[i] = i < digits.count
                        ? String(digits[digits.index(digits.startIndex, offsetBy: i)])
                        : ""
                }
                currentlyActiveBoxIndex = min(digits.count, 5)
            }
        ))
        .keyboardType(.numberPad)
        .opacity(0)
        .frame(width: 1, height: 1)
        .focused($inputFocused)
    }

    private var verifyButton: some View {
        Button {
            Task { await otpViewModel.verifyAndUpdateProfile(driverProfileViewModel: driverProfileViewModel) }
        } label: {
            ZStack {
                if otpViewModel.state == .verifying {
                    ProgressView().tint(.white)
                } else {
                    Text("Verify & Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                otpViewModel.isComplete
                ? LinearGradient.brand
                : LinearGradient(colors: [Color.statusInactive.opacity(0.35)], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!otpViewModel.isComplete || otpViewModel.state == .verifying)
    }

    private var resendRow: some View {
        Button {
            otpViewModel.resendOTP()
        } label: {
            Text(
                otpViewModel.secondsRemaining > 0
                ? "Resend Code in \(otpViewModel.secondsRemaining)s"
                : "Resend Code"
            )
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(
                otpViewModel.secondsRemaining > 0 ? Color.textTertiary : Color.brandAccent
            )
            .monospacedDigit()
        }
        .disabled(!otpViewModel.canResend)
    }
}
