//
//  DriverPersonalInfoView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-07.
//

import SwiftUI

struct DriverPersonalInfoView: View {
    @StateObject private var personalInfoViewModel = DriverPersonalInfoViewModel()
    @FocusState private var focusedField: Field?

    enum Field { case name, phone, license }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    headerSection
                    formSection
                    continueButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Personal Info")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $personalInfoViewModel.navigateToOTP) {
            DriverOTPView(
                phoneNumber: personalInfoViewModel.fullPhoneNumberWithCountryCode,
                personalInfoViewModel: personalInfoViewModel
            )
        }
        .onTapGesture { focusedField = nil }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.13))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.brandAccent)
            }

            Text("Your Details")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            Text("We need a few details to set up your driver profile")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            driverInputField(
                label: "Full Name",
                placeholder: "e.g. Kamal Perera",
                text: $personalInfoViewModel.fullName,
                icon: "person.fill",
                keyboard: .default,
                field: .name,
                isValid: personalInfoViewModel.isFullNameValid || personalInfoViewModel.fullName.isEmpty
            )

            driverInputField(
                label: "Phone Number",
                placeholder: "77 123 4567",
                text: $personalInfoViewModel.phoneNumber,
                icon: "phone.fill",
                keyboard: .phonePad,
                field: .phone,
                isValid: personalInfoViewModel.isPhoneValid || personalInfoViewModel.phoneNumber.isEmpty,
                prefix: "+94"
            )

            driverInputField(
                label: "Driver's License Number",
                placeholder: "e.g. B1234567",
                text: $personalInfoViewModel.licenseNumber,
                icon: "creditcard.fill",
                keyboard: .default,
                field: .license,
                isValid: personalInfoViewModel.isLicenseValid || personalInfoViewModel.licenseNumber.isEmpty
            )
        }
    }

    private func driverInputField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        icon: String,
        keyboard: UIKeyboardType,
        field: Field,
        isValid: Bool,
        prefix: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(focusedField == field ? Color.brandAccent : Color.textTertiary)
                    .frame(width: 20)

                if let prefix = prefix {
                    Text(prefix)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                    Rectangle()
                        .fill(Color.divider)
                        .frame(width: 1, height: 20)
                }

                TextField(placeholder, text: text)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                    .keyboardType(keyboard)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: field)
                    .tint(Color.brandAccent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        !isValid ? Color.statusDanger :
                        focusedField == field ? Color.brandAccent.opacity(0.6) : Color.divider,
                        lineWidth: focusedField == field || !isValid ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: focusedField)
        }
    }

    private var continueButton: some View {
        VStack(spacing: 10) {
            Button {
                Task { await personalInfoViewModel.sendOTP() }
            } label: {
                ZStack {
                    if personalInfoViewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        HStack(spacing: 8) {
                            Text("Send OTP & Continue")
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
                    personalInfoViewModel.canContinue
                    ? LinearGradient.brand
                    : LinearGradient(colors: [Color.statusInactive.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!personalInfoViewModel.canContinue || personalInfoViewModel.isLoading)

            if let errorMessage = personalInfoViewModel.sendOTPErrorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.statusDanger)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: personalInfoViewModel.sendOTPErrorMessage)
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        DriverPersonalInfoView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    NavigationStack {
        DriverPersonalInfoView()
    }
    .preferredColorScheme(.light)
}
