//
//  PassengerProfileView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import SwiftUI
import PhotosUI

struct PassengerProfileView: View {
    @ObservedObject var profileViewModel: PassengerProfileViewModel
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showSignOutConfirm: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                profileHeader
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)

                VStack(spacing: 20) {
                    servicesSection
                    accountSection
                    versionFooter
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 48)
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $profileViewModel.showEditProfile) {
            PassengerEditProfileSheet(profileViewModel: profileViewModel)
        }
        .alert("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                profileViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Remove Local Data", isPresented: $profileViewModel.showRemoveLocalDataConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                profileViewModel.removeLocalData()
            }
        } message: {
            Text("This will remove all locally cached profile information, trip history, and notifications stored on this device. Your account and data on the server will not be affected.")
        }
        .alert("Local Data Removed", isPresented: $profileViewModel.localDataRemoved) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("All locally stored data has been cleared from this device.")
        }
        .alert("Delete Account", isPresented: $profileViewModel.showDeleteAccountConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete My Account", role: .destructive) {
                profileViewModel.deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account, all your trip history, enrollment records, and attendance data. This action cannot be undone.")
        }
        .alert("Deletion Failed", isPresented: $profileViewModel.showDeleteAccountError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(profileViewModel.deleteAccountError ?? "An unexpected error occurred. Please try again.")
        }
        .overlay {
            if profileViewModel.isDeletingAccount {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.4)
                        Text("Deleting account…")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
            }
        }
    }

    private var profileHeader: some View {
        Button {
            profileViewModel.openEditProfile()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    if let profilePhotoData = profileViewModel.passengerProfilePhotoImageData,
                       let uiImageFromData = UIImage(data: profilePhotoData) {
                        Image(uiImage: uiImageFromData)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(LinearGradient.brand)
                            .frame(width: 64, height: 64)
                        Text(profileViewModel.initials)
                            .font(.appTitle3)
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    if profileViewModel.isLoadingProfile {
                        ProgressView()
                            .tint(Color.brandAccent)
                            .padding(.vertical, 4)
                    } else {
                        Text(profileViewModel.user.name.isEmpty ? "Loading..." : profileViewModel.user.name)
                            .font(.appHeadline)
                            .foregroundColor(.textPrimary)
                        Text(profileViewModel.user.phone.isEmpty ? "" : profileViewModel.user.phone)
                            .font(.appFootnote)
                            .foregroundColor(.textSecondary)
                        Text(profileViewModel.user.role)
                            .font(.appCaption2Semibold)
                            .foregroundColor(.brandAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.brandAccent.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textTertiary)
            }
            .padding(16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var servicesSection: some View {
        profileSection(title: "Services") {
            NavigationLink(destination: PassengerEnrolledServicesView()) {
                profileRowContent(icon: "bus.fill", iconColor: Color.brandSecondary, title: "Enrolled Services")
            }
            rowDivider
            NavigationLink(destination: SentRequestsView()) {
                profileRowContent(icon: "paperplane.fill", iconColor: Color.statusActive, title: "Sent Requests")
            }
        }
    }

    // Account section — Help & Support and Terms & Privacy removed per requirements
    private var accountSection: some View {
        profileSection(title: "Account") {
            NavigationLink(destination: PassengerNotificationSettingsView()) {
                profileRowContent(icon: "bell.badge.fill", iconColor: Color.statusWarning, title: "Notification Settings")
            }
            rowDivider

            if BiometricService.shared.deviceSupportsBiometricAuthentication {
                biometricToggleRow
                rowDivider
            }

            profileRow(
                icon: "internaldrive",
                iconColor: Color.statusInfo,
                title: "Remove Local Data",
                showChevron: false
            ) {
                profileViewModel.showRemoveLocalDataConfirm = true
            }
            rowDivider

            profileRow(
                icon: "arrow.right.square.fill",
                iconColor: Color.statusDanger,
                title: "Sign Out",
                titleColor: .statusDanger,
                showChevron: false
            ) {
                showSignOutConfirm = true
            }
            rowDivider

            profileRow(
                icon: "trash.fill",
                iconColor: Color.statusDanger,
                title: "Delete Account",
                titleColor: .statusDanger,
                showChevron: false
            ) {
                profileViewModel.showDeleteAccountConfirm = true
            }
        }
    }

    private var biometricToggleRow: some View {
        HStack(spacing: 12) {
            settingsIcon(systemName: "faceid", color: Color.brandAccent)
            Text("\(BiometricService.shared.biometricTypeDisplayName) Sign-In")
                .font(.appBody)
                .foregroundColor(.textPrimary)
            Spacer()
            Toggle("", isOn: Binding(
                get: { authManager.isBiometricEnabled },
                set: { newBiometricToggleValue in
                    if newBiometricToggleValue {
                        Task {
                            let biometricAuthSucceeded = await BiometricService.shared.authenticateWithBiometrics(
                                reasonMessage: "Verify your identity to enable \(BiometricService.shared.biometricTypeDisplayName) sign-in"
                            )
                            if biometricAuthSucceeded {
                                authManager.enableBiometric()
                            }
                        }
                    } else {
                        authManager.disableBiometric()
                    }
                }
            ))
            .labelsHidden()
            .tint(Color.brandAccent)
            .accessibilityLabel("\(BiometricService.shared.biometricTypeDisplayName) Sign-In")
            .accessibilityHint("Toggle to enable or disable biometric authentication")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }

    private var versionFooter: some View {
        Text("StaffLanka Go  v1.0.0")
            .font(.appCaption)
            .foregroundColor(.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
            .accessibilityLabel("App version 1.0.0")
    }

    private func profileSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.appCaptionSemibold)
                .foregroundColor(.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.divider, lineWidth: 1)
            )
        }
    }

    private func profileRowContent(icon: String, iconColor: Color, title: String, titleColor: Color = .textPrimary) -> some View {
        HStack(spacing: 12) {
            settingsIcon(systemName: icon, color: iconColor)
            Text(title)
                .font(.appBody)
                .foregroundColor(titleColor)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }

    private func profileRow(
        icon: String,
        iconColor: Color,
        title: String,
        titleColor: Color = .textPrimary,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                settingsIcon(systemName: icon, color: iconColor)
                Text(title)
                    .font(.appBody)
                    .foregroundColor(titleColor)
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textTertiary)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func settingsIcon(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 30, height: 30)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    private var rowDivider: some View {
        Divider()
            .padding(.leading, 58)
    }
}

// Edit Profile Sheet for passenger — mirrors the driver edit sheet exactly:
// list layout, photo picker, name field, phone NavigationLink (no verified badge), email field
// Each row has .listRowBackground(Color.cardBackground) so the theme blue shows instead of system gray

struct PassengerEditProfileSheet: View {
    @ObservedObject var profileViewModel: PassengerProfileViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Avatar photo picker section
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(
                            selection: $profileViewModel.selectedProfilePhotoPicPickerItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            ZStack(alignment: .bottomTrailing) {
                                passengerAvatarInEditSheet
                                ZStack {
                                    Circle()
                                        .fill(Color.brandAccent)
                                        .frame(width: 26, height: 26)
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .offset(x: 2, y: 2)
                            }
                        }
                        .onChange(of: profileViewModel.selectedProfilePhotoPicPickerItem) { _, newPickerItem in
                            if let newPickerItem {
                                profileViewModel.processAndSaveSelectedProfilePhoto(selectedPhotoPickerItem: newPickerItem)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                // Personal information section — each row explicitly tagged with cardBackground
                Section("Personal Information") {
                    editSheetTextField(
                        fieldLabel: "Full Name",
                        iconName: "person.fill",
                        boundValue: $profileViewModel.editingName,
                        keyboardType: .default
                    )
                    .listRowBackground(Color.cardBackground)

                    // Phone number row — NavigationLink to change phone flow, no verified badge
                    NavigationLink {
                        PassengerChangePhoneView(passengerProfileViewModel: profileViewModel)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.brandAccent)
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Phone Number")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textSecondary)
                                Text(profileViewModel.user.phone)
                                    .font(.system(size: 15))
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }
                    .listRowBackground(Color.cardBackground)

                    editSheetTextField(
                        fieldLabel: "Email Address",
                        iconName: "envelope.fill",
                        boundValue: $profileViewModel.editingEmail,
                        keyboardType: .emailAddress
                    )
                    .listRowBackground(Color.cardBackground)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        profileViewModel.saveProfile()
                    } label: {
                        if profileViewModel.isSaving {
                            ProgressView().tint(Color.brandAccent)
                        } else {
                            Text("Save")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.brandAccent)
                        }
                    }
                    .disabled(profileViewModel.isSaving)
                }
            }
        }
    }

    // Avatar shown in the edit sheet — photo if available, otherwise gradient initials circle
    @ViewBuilder
    private var passengerAvatarInEditSheet: some View {
        if let profilePhotoData = profileViewModel.passengerProfilePhotoImageData,
           let uiImageFromData = UIImage(data: profilePhotoData) {
            Image(uiImage: uiImageFromData)
                .resizable()
                .scaledToFill()
                .frame(width: 88, height: 88)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(LinearGradient.brand)
                .frame(width: 88, height: 88)
                .overlay(
                    Text(profileViewModel.initials)
                        .font(.appTitle)
                        .foregroundColor(.white)
                )
        }
    }

    private func editSheetTextField(fieldLabel: String, iconName: String, boundValue: Binding<String>, keyboardType: UIKeyboardType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 13))
                .foregroundColor(.brandAccent)
                .frame(width: 18)
                .accessibilityHidden(true)
            TextField(fieldLabel, text: boundValue)
                .font(.appBody)
                .foregroundColor(.textPrimary)
                .tint(.brandAccent)
                .keyboardType(keyboardType)
        }
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        PassengerProfileView(profileViewModel: PassengerProfileViewModel())
    }
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    NavigationStack {
        PassengerProfileView(profileViewModel: PassengerProfileViewModel())
    }
    .preferredColorScheme(.light)
}
