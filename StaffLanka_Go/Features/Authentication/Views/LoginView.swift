//
//  LoginView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-03-31.
//

import SwiftUI

struct LoginView: View {

    @StateObject private var loginViewModel = LoginViewModel()
    @EnvironmentObject private var authManager: AuthManager
    @State private var navigateToOTPVerification = false
    @State private var isBiometricAuthenticationInProgress = false
    @FocusState private var isPhoneFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                    .onTapGesture { isPhoneFieldFocused = false }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection
                            .padding(.top, 64)
                            .padding(.bottom, 48)

                        VStack(spacing: 16) {
                            phoneInputSection
                            sendOTPButton
                            if loginViewModel.shouldShowBiometricLoginButton {
                                biometricDividerRow
                                biometricLoginButton
                            }
                            driverRegisterRow
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 48)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToOTPVerification) {
                OTPVerificationView(phoneNumber: loginViewModel.fullPhoneNumber)
            }
            .onChange(of: loginViewModel.loginState) { _, newState in
                if case .otpSent = newState {
                    navigateToOTPVerification = true
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.15))
                    .frame(width: 88, height: 88)
                Image(systemName: "bus.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(.brandAccent)
            }
            .accessibilityHidden(true)

            Text("StaffLanka Go")
                .font(.appLargeTitle)
                .foregroundColor(.textPrimary)

            Text("Your smart commute companion")
                .font(.appBody)
                .foregroundColor(.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("StaffLanka Go. Your smart commute companion.")
    }

    private var phoneInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mobile Number")
                .font(.appCaptionSemibold)
                .foregroundColor(.textSecondary)

            HStack(spacing: 0) {
                Text("🇱🇰 +94")
                    .font(.appBodyMedium)
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 52)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityHidden(true)

                Rectangle()
                    .fill(Color.divider)
                    .frame(width: 1, height: 26)
                    .accessibilityHidden(true)

                TextField("7X XXX XXXX", text: $loginViewModel.phoneNumber)
                    .keyboardType(.numberPad)
                    .font(.appBodyMedium)
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 52)
                    .frame(maxWidth: .infinity)
                    .focused($isPhoneFieldFocused)
                    .accessibilityLabel("Mobile number")
                    .accessibilityHint("Enter your Sri Lanka mobile number without the leading zero")
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        loginViewModel.phoneNumber.isEmpty
                            ? Color.clear
                            : (loginViewModel.isPhoneNumberValid ? Color.brandSecondary.opacity(0.5) : Color.statusDanger.opacity(0.5)),
                        lineWidth: 1.5
                    )
            )

            if !loginViewModel.phoneNumber.isEmpty && !loginViewModel.isPhoneNumberValid {
                Text("Please enter a valid phone number")
                    .font(.appCaption)
                    .foregroundColor(.statusDanger)
                    .accessibilityLabel("Error: Please enter a valid phone number")
            }
        }
    }

    private var sendOTPButton: some View {
        Button {
            Task { await loginViewModel.sendOTP() }
        } label: {
            ZStack {
                if case .loading = loginViewModel.loginState {
                    ProgressView().tint(.white)
                } else {
                    Text("Send OTP")
                        .font(.appBodySemibold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(
                loginViewModel.canSendOTP
                    ? Color.brandSecondary
                    : Color.statusInactive.opacity(0.35)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!loginViewModel.canSendOTP || {
            if case .loading = loginViewModel.loginState { return true }
            return false
        }())
        .padding(.top, 4)
        .accessibilityLabel("Send OTP")
        .accessibilityHint(loginViewModel.canSendOTP ? "Sends a one-time password to your mobile number" : "Enter a valid mobile number first")
    }

    private var biometricDividerRow: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.divider).frame(height: 1)
            Text("or")
                .font(.appFootnote)
                .foregroundColor(.textSecondary)
                .fixedSize()
            Rectangle().fill(Color.divider).frame(height: 1)
        }
        .padding(.vertical, 4)
        .accessibilityHidden(true)
    }

    private var biometricLoginButton: some View {
        Button {
            Task { await performBiometricLogin() }
        } label: {
            ZStack {
                if isBiometricAuthenticationInProgress {
                    ProgressView().tint(.brandAccent)
                } else {
                    Image(systemName: "faceid")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.brandAccent)
                }
            }
            .frame(width: 64, height: 54)
            .background(Color.brandAccent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.brandAccent.opacity(0.35), lineWidth: 1.5)
            )
        }
        .disabled(isBiometricAuthenticationInProgress)
        .accessibilityLabel("Sign in with \(BiometricService.shared.biometricTypeDisplayName)")
        .accessibilityHint("Authenticates using your device biometrics")
        .accessibilityAddTraits(.isButton)
    }

    private var driverRegisterRow: some View {
        NavigationStack{
            VStack(spacing: 4) {
                Text("Would you like to onboard as a driver?")
                    .font(.appFootnote)
                    .foregroundColor(.textSecondary)
                
                NavigationLink {
                    DriverPersonalInfoView()
                } label: {
                    Text("Register now")
                        .font(.appCalloutSemibold)
                        .foregroundColor(.textPrimary)
                        .underline()
                }
                .accessibilityLabel("Register now as a driver")
                .accessibilityHint("Opens the driver onboarding form")
            }
            .padding(.top, 8)
        }
        
    }

    private func performBiometricLogin() async {
        isBiometricAuthenticationInProgress = true
        let succeeded = await BiometricService.shared.authenticateWithBiometrics(
            reasonMessage: "Sign in to StaffLanka Go"
        )
        isBiometricAuthenticationInProgress = false
        if succeeded {
            authManager.signIn(phoneNumber: authManager.storedPhoneNumber)
            authManager.completeSignIn()
        }
    }
}

#Preview {
    LoginView()
        .preferredColorScheme(.dark)
}
