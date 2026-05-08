//
//  OTPVerificationView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-01.
//

import SwiftUI
import Combine

struct OTPVerificationView: View {

    let phoneNumber: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var otpViewModel: OTPVerificationViewModel
    @State private var currentlyActiveBoxIndex: Int = 0
    @FocusState private var hiddenFieldFocused: Bool

    init(phoneNumber: String) {
        self.phoneNumber = phoneNumber
        _otpViewModel = StateObject(wrappedValue: OTPVerificationViewModel(phoneNumber: phoneNumber))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                headerSection
                otpBoxesRow
                    .offset(x: otpViewModel.shakeAnimationOffset)
                hiddenNumericInputField
                verifyButton
                resendCodeRow
                Spacer()
            }
        }
        .navigationBarHidden(false)
        .alert(
            "Enable \(BiometricService.shared.biometricTypeDisplayName)?",
            isPresented: $otpViewModel.shouldPromptBiometricEnrollment
        ) {
            Button("Enable") { otpViewModel.enrollBiometric() }
            Button("Not Now", role: .cancel) { otpViewModel.dismissBiometricEnrollmentPrompt() }
        } message: {
            Text("Sign in faster next time using \(BiometricService.shared.biometricTypeDisplayName) instead of your phone number.")
        }
        .overlay {
            if otpViewModel.isBiometricEnrolling {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.4)
                        Text("Verifying \(BiometricService.shared.biometricTypeDisplayName)…")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
            }
        }
        .onAppear {
            hiddenFieldFocused = true
            otpViewModel.startResendCountdown()
        }
        .onChange(of: otpViewModel.enteredOTPString) {
            Task { await otpViewModel.handleAutoSubmitIfComplete() }
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
                .foregroundColor(.textPrimary)

            Text("Enter the 6-digit code sent to\n\(phoneNumber)")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var otpBoxesRow: some View {
        VStack(alignment: .trailing, spacing: 14) {
            Button {
                dismiss()
            } label: {
                Text("Change Number")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.brandAccent)
            }

            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { boxIndex in
                    OTPDigitBox(
                        digit: otpViewModel.otpDigits[boxIndex],
                        isActive: currentlyActiveBoxIndex == boxIndex
                    )
                    .onTapGesture {
                        currentlyActiveBoxIndex = boxIndex
                        hiddenFieldFocused = true
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var hiddenNumericInputField: some View {
        TextField("", text: Binding(
            get: { otpViewModel.enteredOTPString },
            set: { newInputValue in
                let numericCharactersOnly = newInputValue.filter(\.isNumber)
                for digitIndex in 0..<6 {
                    otpViewModel.otpDigits[digitIndex] = digitIndex < numericCharactersOnly.count
                        ? String(numericCharactersOnly[numericCharactersOnly.index(numericCharactersOnly.startIndex, offsetBy: digitIndex)])
                        : ""
                }
                currentlyActiveBoxIndex = min(numericCharactersOnly.count, 5)
            }
        ))
        .keyboardType(.numberPad)
        .opacity(0)
        .frame(width: 1, height: 1)
        .focused($hiddenFieldFocused)
    }

    private var verifyButton: some View {
        Button {
            Task { await otpViewModel.verifyOTP() }
        } label: {
            ZStack {
                if otpViewModel.verificationState == .verifying {
                    ProgressView().tint(.white)
                } else {
                    Text("Verify")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                otpViewModel.isOTPComplete
                    ? Color.brandSecondary
                    : Color.statusInactive.opacity(0.35)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!otpViewModel.isOTPComplete || otpViewModel.verificationState == .verifying)
        .padding(.horizontal, 24)
    }

    private var resendCodeRow: some View {
        Button {
            otpViewModel.resendOTP()
        } label: {
            Text(
                otpViewModel.secondsRemainingForResend > 0
                    ? "Resend Code in \(otpViewModel.secondsRemainingForResend)s"
                    : "Resend Code"
            )
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(
                otpViewModel.secondsRemainingForResend > 0
                    ? .textTertiary
                    : .brandSecondary
            )
            .monospacedDigit()
        }
        .disabled(!otpViewModel.canResendOTP)
    }
}

struct OTPDigitBox: View {
    let digit: String
    let isActive: Bool

    var body: some View {
        Text(digit.isEmpty ? " " : digit)
            .font(.system(size: 22, weight: .semibold, design: .monospaced))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isActive ? Color.brandAccent : Color.divider,
                        lineWidth: isActive ? 2 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}

#Preview {
    NavigationStack {
        OTPVerificationView(phoneNumber: "+94771234567")
    }
    .preferredColorScheme(.dark)
}
