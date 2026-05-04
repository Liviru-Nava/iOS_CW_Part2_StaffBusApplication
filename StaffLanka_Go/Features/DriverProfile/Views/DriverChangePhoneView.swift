// DriverChangePhoneView.swift
// StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//

import SwiftUI

struct DriverChangePhoneView: View {

    @ObservedObject var driverProfileViewModel: DriverProfileViewModel
    @StateObject private var changePhoneViewModel = DriverChangePhoneViewModel()
    @FocusState private var isPhoneInputFieldFocused: Bool
    @Environment(\.dismiss) private var dismissToProfileSheet

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    changePhoneHeaderSection
                    newPhoneInputSection
                    sendVerificationCodeButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Change Number")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $changePhoneViewModel.shouldNavigateToOTPConfirmationScreen) {
            DriverConfirmPhoneOTPView(
                newPhoneNumberBeingVerified: changePhoneViewModel.fullPhoneNumberWithCountryCodePrefix,
                changePhoneViewModel: changePhoneViewModel,
                driverProfileViewModel: driverProfileViewModel
            )
        }
        .onTapGesture {
            isPhoneInputFieldFocused = false
        }
    }

    private var changePhoneHeaderSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.13))
                    .frame(width: 80, height: 80)
                Image(systemName: "phone.badge.checkmark.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.brandAccent)
            }

            Text("Update Phone Number")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            Text("Enter your new phone number. We will send a verification code to confirm the change.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var newPhoneInputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("New Phone Number")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(isPhoneInputFieldFocused ? Color.brandAccent : Color.textTertiary)
                    .frame(width: 20)

                // Country code prefix shown as static text before the input
                Text("+1")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.textSecondary)

                Rectangle()
                    .fill(Color.divider)
                    .frame(width: 1, height: 20)

                TextField("e.g. 415 555 0100", text: $changePhoneViewModel.newPhoneNumberDigitsInput)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                    .keyboardType(.phonePad)
                    .autocorrectionDisabled()
                    .focused($isPhoneInputFieldFocused)
                    .tint(Color.brandAccent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isPhoneInputFieldFocused ? Color.brandAccent.opacity(0.6) : Color.divider,
                        lineWidth: isPhoneInputFieldFocused ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isPhoneInputFieldFocused)
        }
    }

    private var sendVerificationCodeButton: some View {
        VStack(spacing: 10) {
            Button {
                Task { await changePhoneViewModel.sendVerificationCodeToNewPhoneNumber() }
            } label: {
                ZStack {
                    if changePhoneViewModel.isSendingVerificationCodeToFirebase {
                        ProgressView().tint(.white)
                    } else {
                        HStack(spacing: 8) {
                            Text("Send Verification Code")
                                .font(.system(size: 16, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    changePhoneViewModel.canProceedToSendVerificationCode
                    ? LinearGradient.brand
                    : LinearGradient(colors: [Color.statusInactive.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!changePhoneViewModel.canProceedToSendVerificationCode || changePhoneViewModel.isSendingVerificationCodeToFirebase)

            if let errorMessage = changePhoneViewModel.sendVerificationCodeErrorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.statusDanger)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: changePhoneViewModel.sendVerificationCodeErrorMessage)
    }
}

// Confirmation screen where the driver enters the OTP sent to their new number
struct DriverConfirmPhoneOTPView: View {

    let newPhoneNumberBeingVerified: String
    @ObservedObject var changePhoneViewModel: DriverChangePhoneViewModel
    @ObservedObject var driverProfileViewModel: DriverProfileViewModel

    @State private var otpDigitsEnteredByDriver: [String] = Array(repeating: "", count: 6)
    @State private var otpVerificationShakeOffset: CGFloat = 0
    @State private var otpVerificationCountdownSeconds: Int = 30
    @State private var isVerifyingEnteredOTPCode: Bool = false
    @State private var otpVerificationErrorMessage: String? = nil
    @State private var otpResendCountdownTask: Task<Void, Never>? = nil
    @FocusState private var isHiddenOTPInputFocused: Bool
    @Environment(\.dismiss) private var dismissToPhoneEntryScreen

    var enteredOTPCodeJoined: String { otpDigitsEnteredByDriver.joined() }
    var isEnteredOTPCodeComplete: Bool { enteredOTPCodeJoined.count == 6 }
    var canResendOTPCode: Bool { otpVerificationCountdownSeconds == 0 }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                otpConfirmationHeaderSection
                otpDigitBoxesRow
                    .offset(x: otpVerificationShakeOffset)
                hiddenOTPTextInputField
                if let errorMessage = otpVerificationErrorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.statusDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                confirmOTPButton
                resendOTPCodeRow
                Spacer()
            }
            .animation(.easeInOut(duration: 0.2), value: otpVerificationErrorMessage)
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .navigationTitle("Confirm Number")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .onAppear {
            beginOTPResendCountdown()
            isHiddenOTPInputFocused = true
        }
        .onChange(of: enteredOTPCodeJoined) { _, _ in
            Task { await handleOTPAutoSubmitIfComplete() }
        }
    }

    private var otpConfirmationHeaderSection: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 50)
                    .fill(Color.brandAccent.opacity(0.13))
                    .frame(width: 80, height: 80)
                Image(systemName: "message.badge.filled.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.brandAccent)
            }

            Text("Verify New Number")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            Text("Enter the 6-digit code sent to\n\(newPhoneNumberBeingVerified)")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var otpDigitBoxesRow: some View {
        HStack(spacing: 10) {
            ForEach(0..<6, id: \.self) { digitIndex in
                phoneOTPDigitBox(digitIndex: digitIndex)
                    .onTapGesture {
                        isHiddenOTPInputFocused = true
                    }
            }
        }
    }

    private func phoneOTPDigitBox(digitIndex: Int) -> some View {
        let digitCharacter: String = {
            let characters = Array(enteredOTPCodeJoined)
            return digitIndex < characters.count ? String(characters[digitIndex]) : ""
        }()
        let isThisBoxFilled = digitIndex < enteredOTPCodeJoined.count

        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isThisBoxFilled ? Color.brandAccent : Color.divider,
                            lineWidth: isThisBoxFilled ? 2 : 1
                        )
                )
                .frame(maxWidth: .infinity)
                .frame(height: 56)

            Text(digitCharacter)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
        }
    }

    private var hiddenOTPTextInputField: some View {
        TextField("", text: Binding(
            get: { enteredOTPCodeJoined },
            set: { newInputValue in
                let digitsOnlyFromInput = String(newInputValue.filter(\.isNumber).prefix(6))
                for digitIndex in 0..<6 {
                    otpDigitsEnteredByDriver[digitIndex] = digitIndex < digitsOnlyFromInput.count
                        ? String(digitsOnlyFromInput[digitsOnlyFromInput.index(digitsOnlyFromInput.startIndex, offsetBy: digitIndex)])
                        : ""
                }
            }
        ))
        .keyboardType(.numberPad)
        .opacity(0)
        .frame(width: 1, height: 1)
        .focused($isHiddenOTPInputFocused)
    }

    private var confirmOTPButton: some View {
        Button {
            Task { await verifyEnteredOTPCodeAndUpdatePhone() }
        } label: {
            ZStack {
                if isVerifyingEnteredOTPCode {
                    ProgressView().tint(.white)
                } else {
                    Text("Confirm & Update Number")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                isEnteredOTPCodeComplete
                ? LinearGradient.brand
                : LinearGradient(colors: [Color.statusInactive.opacity(0.35)], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!isEnteredOTPCodeComplete || isVerifyingEnteredOTPCode)
    }

    private var resendOTPCodeRow: some View {
        Button {
            resendVerificationCodeToNewNumber()
        } label: {
            Text(
                otpVerificationCountdownSeconds > 0
                ? "Resend Code in \(otpVerificationCountdownSeconds)s"
                : "Resend Code"
            )
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(
                otpVerificationCountdownSeconds > 0 ? Color.textTertiary : Color.brandAccent
            )
            .monospacedDigit()
        }
        .disabled(!canResendOTPCode)
    }

    private func verifyEnteredOTPCodeAndUpdatePhone() async {
        guard isEnteredOTPCodeComplete && !isVerifyingEnteredOTPCode else { return }
        isVerifyingEnteredOTPCode = true
        otpVerificationErrorMessage = nil

        await changePhoneViewModel.confirmPhoneNumberChangeWithEnteredOTP(enteredOTPCode: enteredOTPCodeJoined) {
            // Refresh the displayed phone number in the profile after a successful change
            driverProfileViewModel.refreshDisplayedPhoneNumber()
            dismissToPhoneEntryScreen()
        }

        isVerifyingEnteredOTPCode = false
    }

    private func handleOTPAutoSubmitIfComplete() async {
        guard isEnteredOTPCodeComplete && !isVerifyingEnteredOTPCode else { return }
        await verifyEnteredOTPCodeAndUpdatePhone()
    }

    private func beginOTPResendCountdown() {
        otpResendCountdownTask?.cancel()
        otpVerificationCountdownSeconds = 30
        otpResendCountdownTask = Task {
            while otpVerificationCountdownSeconds > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                otpVerificationCountdownSeconds -= 1
            }
        }
    }

    private func resendVerificationCodeToNewNumber() {
        otpDigitsEnteredByDriver = Array(repeating: "", count: 6)
        otpVerificationErrorMessage = nil
        beginOTPResendCountdown()
        Task { await changePhoneViewModel.sendVerificationCodeToNewPhoneNumber() }
    }

    private func triggerOTPBoxShakeAnimation() async {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) { otpVerificationShakeOffset = 10 }
        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation { otpVerificationShakeOffset = 0 }
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        DriverChangePhoneView(driverProfileViewModel: DriverProfileViewModel())
    }
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    NavigationStack {
        DriverChangePhoneView(driverProfileViewModel: DriverProfileViewModel())
    }
    .preferredColorScheme(.light)
}
