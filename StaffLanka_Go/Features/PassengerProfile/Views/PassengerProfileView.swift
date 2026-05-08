//
//  PassengerProfile.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import SwiftUI
 
struct PassengerProfileView: View {
    @ObservedObject var profileViewModel: PassengerProfileViewModel
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
        // Sign Out confirmation
        .alert("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                profileViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        // Remove Local Data confirmation
        .alert("Remove Local Data", isPresented: $profileViewModel.showRemoveLocalDataConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                profileViewModel.removeLocalData()
            }
        } message: {
            Text("This will remove all locally cached profile information, trip history, and notifications stored on this device. Your account and data on the server will not be affected.")
        }
        // Confirmation toast after removal
        .alert("Local Data Removed", isPresented: $profileViewModel.localDataRemoved) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("All locally stored data has been cleared from this device.")
        }
        // Delete Account — first confirmation
        .alert("Delete Account", isPresented: $profileViewModel.showDeleteAccountConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete My Account", role: .destructive) {
                profileViewModel.deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account, all your trip history, enrollment records, and attendance data. This action cannot be undone.")
        }
        // Delete Account — error
        .alert("Deletion Failed", isPresented: $profileViewModel.showDeleteAccountError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(profileViewModel.deleteAccountError ?? "An unexpected error occurred. Please try again.")
        }
        // Deletion in-progress overlay
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
 
 
    //Profile Header
 
    private var profileHeader: some View {
        Button {
            profileViewModel.openEditProfile()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.brand)
                        .frame(width: 64, height: 64)
                    Text(profileViewModel.initials)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
 
                VStack(alignment: .leading, spacing: 4) {
                    if profileViewModel.isLoadingProfile {
                        ProgressView()
                            .tint(Color.brandAccent)
                            .padding(.vertical, 4)
                    } else {
                        Text(profileViewModel.user.name.isEmpty ? "Loading..." : profileViewModel.user.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Text(profileViewModel.user.phone.isEmpty ? "" : profileViewModel.user.phone)
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                        Text(profileViewModel.user.role)
                            .font(.system(size: 11, weight: .medium))
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
 
    //Sections
 
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
 
    private var accountSection: some View {
        profileSection(title: "Account") {
            profileRow(icon: "questionmark.circle.fill", iconColor: Color.statusWarning, title: "Help & Support") {}
            rowDivider
            profileRow(icon: "doc.text.fill", iconColor: Color.brandSecondary, title: "Terms & Privacy") {}
            rowDivider
            // Remove Local Data
            profileRow(
                icon: "internaldrive",
                iconColor: Color.statusInfo,
                title: "Remove Local Data",
                showChevron: false
            ) {
                profileViewModel.showRemoveLocalDataConfirm = true
            }
            rowDivider
            // Sign Out
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
            // Delete Account
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
 
    private var versionFooter: some View {
        Text("StaffLanka Go  v1.0.0")
            .font(.system(size: 12))
            .foregroundColor(.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }
 
    //Reusable Helpers
 
    private func profileSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 4)
 
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
                .font(.system(size: 15))
                .foregroundColor(titleColor)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textTertiary)
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
                    .font(.system(size: 15))
                    .foregroundColor(titleColor)
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textTertiary)
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
 
//Edit Profile Sheet
 
struct PassengerEditProfileSheet: View {
    @ObservedObject var profileViewModel: PassengerProfileViewModel
    @Environment(\.dismiss) private var dismiss
 
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.brand)
                            .frame(width: 88, height: 88)
                        Text(profileViewModel.initials)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 24)
 
                    VStack(spacing: 0) {
                        editField(label: "Full Name", icon: "person.fill", value: $profileViewModel.editingName, keyboard: .default)
                        Divider().padding(.leading, 16)
                        editField(label: "Email", icon: "envelope.fill", value: $profileViewModel.editingEmail, keyboard: .emailAddress)
                        Divider().padding(.leading, 16)
 
                        HStack(spacing: 12) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.brandAccent)
                                .frame(width: 18)
                            Text(profileViewModel.user.phone)
                                .font(.system(size: 15))
                                .foregroundColor(.textSecondary)
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                Text("Verified")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.statusActive)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.statusActive.opacity(0.10))
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.divider, lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
 
                    Spacer()
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 15))
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
 
    private func editField(label: String, icon: String, value: Binding<String>, keyboard: UIKeyboardType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.brandAccent)
                .frame(width: 18)
            TextField(label, text: value)
                .font(.system(size: 15))
                .foregroundColor(.textPrimary)
                .tint(.brandAccent)
                .keyboardType(keyboard)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
