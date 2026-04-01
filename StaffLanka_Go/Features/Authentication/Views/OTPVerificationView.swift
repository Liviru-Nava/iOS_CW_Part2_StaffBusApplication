//
//  OTPVerificationView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-01.
//


import SwiftUI
import Combine

struct OTPVerificationView: View {
    let phone: String
    let onSuccess: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var otpViewModel: OTPVerificationViewModel
    @State private var activeIndex = 0
    @FocusState private var focusedIndex: Int?
    
    var enteredOTP: String { otpViewModel.otpDigits.joined() }
    
    init(phone: String, onSuccess: @escaping () -> Void) {
        self.phone = phone
        self.onSuccess = onSuccess
        _otpViewModel = StateObject(wrappedValue: OTPVerificationViewModel(phoneNumber: phone))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                headerSection
                otpArea
                    .offset(x: otpViewModel.shakeOffset)
                hiddenInputField
                verifyButton
                resendRow
                Spacer()
            }
        }
        .navigationBarHidden(false)
        .onAppear {
            focusedIndex = 0
        }
        .onAppear {
            focusedIndex = 0
            otpViewModel.startCountdown()
        }
        .onChange(of: enteredOTP) { _, _ in
            Task {
                await otpViewModel.handleAutoSubmit()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.surfaceBackground)
                    .frame(width: 80, height: 80)
                Image(systemName: "message.badge.filled.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.brandAccent)
            }

            Text("Verify Your Number")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)

            Text("Enter the 6-digit code sent to\n\(phone)")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var otpArea: some View {
        VStack(alignment: .trailing, spacing: 14) {
            Button {
                dismiss()
            } label: {
                Text("Change Number")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.brandAccent)
            }

            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { i in
                    OTPDigitBox(digit: otpViewModel.otpDigits[i], isActive: activeIndex == i)
                        .onTapGesture {
                            activeIndex = i
                            focusedIndex = 0
                        }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var hiddenInputField: some View {
        TextField("", text: Binding(
            get: { enteredOTP },
            set: { newVal in
                let digits = newVal.filter(\.isNumber)
                for i in 0..<6 {
                    otpViewModel.otpDigits[i] = i < digits.count
                        ? String(digits[digits.index(digits.startIndex, offsetBy: i)])
                        : ""
                }
                activeIndex = min(digits.count, 5)
            }
        ))
        .keyboardType(.numberPad)
        .opacity(0)
        .frame(width: 1, height: 1)
        .focused($focusedIndex, equals: 0)
    }

    private var verifyButton: some View {
        Button {
            Task {
                await otpViewModel.verify()
            }
        } label: {
            ZStack {
                if otpViewModel.state == .verifying {
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
                otpViewModel.isComplete
                ? Color.brandSecondary
                : Color.statusInactive.opacity(0.35)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!otpViewModel.isComplete || otpViewModel.state == .verifying)
        .padding(.horizontal, 24)
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
            .foregroundColor(
                otpViewModel.secondsRemaining > 0
                ? .textTertiary
                : .brandSecondary
            )
            .monospacedDigit()
        }
        .disabled(!otpViewModel.canResend)
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
        OTPVerificationView(phone: "+94 77 123 4567") {}
    }
    .preferredColorScheme(.dark)
}
