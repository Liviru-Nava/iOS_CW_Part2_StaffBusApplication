//
//  LoginView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-03-31.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var navigateToOTP = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection
                            .padding(.top, 64)
                            .padding(.bottom, 48)

                        VStack(spacing: 16) {
                            phoneInputSection
                            termsRow
                            sendOTPButton
                            dividerRow
                            socialRow
                            driverRegisterRow
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 48)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToOTP){
                //navigate to OTP Page need to implement
            }
            .sheet(isPresented: $viewModel.showTermsSheet) {
                TermsSheetView()
            }
            .onChange(of: viewModel.loginState) { _, newState in
                if case .otpSent = newState {
                    navigateToOTP = true
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.surfaceBackground)
                    .frame(width: 88, height: 88)
                Image(systemName: "bus.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(.textOnBrand)
            }

            Text("StaffLanka Go")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)

            Text("Your smart commute companion")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.textSecondary)
        }
    }

    private var phoneInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mobile Number")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textSecondary)

            HStack(spacing: 0) {
//                Menu {
//                    Button("+94  Sri Lanka") { viewModel.selectedCountryCode = "+94" }
//                    Button("+44  United Kingdom") { viewModel.selectedCountryCode = "+44" }
//                    Button("+1  United States") { viewModel.selectedCountryCode = "+1" }
//                    Button("+91  India") { viewModel.selectedCountryCode = "+91" }
//                } label: {
//                    HStack(spacing: 6) {
//                        Text("🇱🇰")
//                            .font(.system(size: 18))
//                        Text(viewModel.selectedCountryCode)
//                            .font(.system(size: 15, weight: .medium))
//                            .foregroundColor(.textPrimary)
//                        Image(systemName: "chevron.down")
//                            .font(.system(size: 10, weight: .semibold))
//                            .foregroundColor(.textSecondary)
//                    }
//                    .padding(.horizontal, 14)
//                    .frame(height: 52)
//                }
                
                Text("🇱🇰 +94")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Rectangle()
                    .fill(Color.divider)
                    .frame(width: 1, height: 26)

                TextField("7X XXX XXXX", text: $viewModel.phoneNumber)
                    .keyboardType(.numberPad)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .frame(maxWidth: .infinity)
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        viewModel.phoneNumber.isEmpty
                            ? Color.clear
                            : (viewModel.isPhoneNumberValid ? Color.brandSecondary.opacity(0.5) : Color.statusDanger.opacity(0.5)),
                        lineWidth: 1.5
                    )
            )

            if !viewModel.phoneNumber.isEmpty && !viewModel.isPhoneNumberValid {
                Text("Please enter a valid phone number")
                    .font(.system(size: 12))
                    .foregroundColor(.statusDanger)
            }
        }
    }

    private var termsRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                viewModel.termsAccepted.toggle()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(viewModel.termsAccepted ? Color.brandSecondary : Color.surfaceBackground)
                        .frame(width: 20, height: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(viewModel.termsAccepted ? Color.brandSecondary : Color.divider, lineWidth: 1.5)
                        )
                    if viewModel.termsAccepted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            Group {
                Text("By continuing, you agree to our ")
                    .foregroundColor(.textSecondary)
                + Text("Terms & Conditions")
                    .foregroundColor(.brandSecondary)
                    .underline()
                + Text(" and ")
                    .foregroundColor(.textSecondary)
                + Text("Privacy Policy")
                    .foregroundColor(.brandSecondary)
                    .underline()
            }
            .font(.system(size: 12, weight: .regular))
            .onTapGesture { viewModel.showTermsSheet = true }
        }
    }

    private var sendOTPButton: some View {
        Button {
            Task { await viewModel.sendOTP() }
        } label: {
            ZStack {
                if case .loading = viewModel.loginState {
                    ProgressView().tint(.white)
                } else {
                    Text("Send OTP")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                viewModel.canContinue
                    ? Color.brandSecondary
                    : Color.statusInactive.opacity(0.35)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!viewModel.canContinue || {
            if case .loading = viewModel.loginState { return true }
            return false
        }())
        .padding(.top, 4)
    }

    private var dividerRow: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.divider)
                .frame(height: 1)
            Text("or sign in with")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.textSecondary)
                .fixedSize()
            Rectangle()
                .fill(Color.divider)
                .frame(height: 1)
        }
        .padding(.vertical, 4)
    }

    private var socialRow: some View {
        HStack(spacing: 20) {
            Button {
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.surfaceBackground)
                        .frame(width: 56, height: 56)
                    Image(systemName: "apple.logo")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.textPrimary)
                }
            }

            Button {
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.surfaceBackground)
                        .frame(width: 56, height: 56)
                        .overlay(Circle().stroke(Color.divider, lineWidth: 1.5))
                    Image(systemName: "faceid")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.textPrimary)
                }
            }
        }
    }

    private var driverRegisterRow: some View {
        VStack(spacing: 4) {
            Text("Would you like to onboard as a driver?")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.textSecondary)
            Button {
            } label: {
                Text("Register now")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .underline()
            }
        }
        .padding(.top, 8)
    }
}

struct TermsSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    termsBlock(title: "1. Acceptance of Terms", body: "By using StaffLanka Go, you agree to be bound by these Terms & Conditions. If you do not agree, please do not use the application.")
                    termsBlock(title: "2. Use of the Application", body: "StaffLanka Go is intended solely for staff bus commuters and drivers operating within registered transport services. You agree to use the app only for its intended purpose.")
                    termsBlock(title: "3. Location Data", body: "The app collects real-time location data to provide ride detection, route tracking, and stop alerts. Location data is processed on-device and only shared with your registered transport provider.")
                    termsBlock(title: "4. Attendance & Bookings", body: "Your attendance confirmations and booking records are stored to calculate subscription-based fares. These records may be visible to your bus driver and transport administrator.")
                    termsBlock(title: "5. Privacy Policy", body: "We do not sell your personal data to third parties. Your phone number, location, and trip history are used exclusively to deliver and improve the service. Data is stored securely and accessible only to authorised parties.")
                    termsBlock(title: "6. Notifications", body: "The app sends push notifications and vibration-based alerts for stop reminders and attendance prompts. You may adjust notification preferences in your device settings.")
                    termsBlock(title: "7. Payments", body: "Subscription fees are calculated based on actual trip usage. Payments processed through the app are subject to the terms of the respective payment gateway provider.")
                    termsBlock(title: "8. Modifications", body: "We reserve the right to modify these terms at any time. Continued use of the app after changes constitutes acceptance of the updated terms.")
                }
                .padding(24)
            }
            .background(Color.appBackground)
            .navigationTitle("Terms & Conditions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.brandSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func termsBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)
            Text(body)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    LoginView()
        .preferredColorScheme(.dark)
}
