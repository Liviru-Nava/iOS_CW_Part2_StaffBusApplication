//
//  DriverProfileView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//


import SwiftUI
import PhotosUI
 
struct DriverProfileView: View {
 
    @StateObject private var driverProfileViewModel = DriverProfileViewModel()
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showSignOutConfirmationAlert: Bool = false
 
    var body: some View {
        List {
            profileHeaderSection
            serviceSection
            busRouteSection
            passengersSection
            reviewsSection
            settingsSection
        }
        .listStyle(.insetGrouped)
        .background(Color.appBackground)
        .scrollContentBackground(.hidden)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            driverProfileViewModel.loadFromCoreData()
            driverProfileViewModel.fetchDriverProfile()
        }
        .sheet(isPresented: $driverProfileViewModel.isEditingDriverProfile) {
            DriverEditProfileSheet(driverProfileViewModel: driverProfileViewModel)
        }
        // Sign Out confirmation
        .alert("Sign Out", isPresented: $showSignOutConfirmationAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) { driverProfileViewModel.signOut() }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        // Remove Local Data — confirmation
        .alert("Remove Local Data", isPresented: $driverProfileViewModel.showRemoveLocalDataConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                driverProfileViewModel.removeLocalData()
            }
        } message: {
            Text("This will remove all locally cached profile information, trip history, and notifications stored on this device. Your account and data on the server will not be affected.")
        }
        // Remove Local Data — success
        .alert("Local Data Removed", isPresented: $driverProfileViewModel.localDataRemoved) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("All locally stored data has been cleared from this device.")
        }
    }
 
    //Profile Header
 
    private var profileHeaderSection: some View {
        Section {
            Button {
                driverProfileViewModel.openDriverProfileEditMode()
            } label: {
                HStack(spacing: 14) {
                    driverProfileAvatarDisplayView(diameter: 58, initialsFont: .system(size: 20, weight: .bold))
 
                    VStack(alignment: .leading, spacing: 3) {
                        Text(driverProfileViewModel.driverProfileInformationValues.driverFullName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Text(driverProfileViewModel.driverProfileInformationValues.driverPhoneNumber)
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                        Text(driverProfileViewModel.driverProfileInformationValues.driverLicenseNumber)
                            .font(.system(size: 12))
                            .foregroundColor(.textTertiary)
                        if !driverProfileViewModel.driverProfileInformationValues.driverEmailAddress.isEmpty {
                            Text(driverProfileViewModel.driverProfileInformationValues.driverEmailAddress)
                                .font(.system(size: 12))
                                .foregroundColor(.textTertiary)
                        }
                    }
 
                    Spacer()
 
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.statusWarning)
                            Text(String(format: "%.1f", driverProfileViewModel.averageDriverRatingValue))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.textPrimary)
                        }
                        Text("Driver")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.brandAccent)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.brandAccent.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.cardBackground)
        }
    }
 
    @ViewBuilder
    func driverProfileAvatarDisplayView(diameter: CGFloat, initialsFont: Font) -> some View {
        if let profilePhotoData = driverProfileViewModel.driverProfilePhotoImageData,
           let uiImageFromPhotoData = UIImage(data: profilePhotoData) {
            Image(uiImage: uiImageFromPhotoData)
                .resizable()
                .scaledToFill()
                .frame(width: diameter, height: diameter)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(LinearGradient.brand)
                .frame(width: diameter, height: diameter)
                .overlay(
                    Text(driverProfileViewModel.driverProfileInitialsText)
                        .font(initialsFont)
                        .foregroundColor(.white)
                )
        }
    }
 
    //Sections
 
    private var serviceSection: some View {
        Section("Service") {
            NavigationLink {
                DriverServiceStatusView(driverProfileViewModel: driverProfileViewModel)
            } label: {
                profileListRow(
                    iconName: "antenna.radiowaves.left.and.right",
                    iconBadgeColor: driverProfileViewModel.driverAvailabilityStatusIsOnline ? Color.statusActive : Color.statusInactive,
                    rowTitle: "Service Status",
                    rowSubtitle: driverProfileViewModel.driverAvailabilityStatusIsOnline ? "Online" : "Offline"
                )
            }
            .listRowBackground(Color.cardBackground)
        }
    }
 
    private var busRouteSection: some View {
        Section("Bus & Route") {
            NavigationLink {
                DriverBusRouteView(driverProfileViewModel: driverProfileViewModel)
            } label: {
                profileListRow(
                    iconName: "bus.fill",
                    iconBadgeColor: Color.brandSecondary,
                    rowTitle: "Bus & Route Details",
                    rowSubtitle: driverProfileViewModel.busDetailsInformationValues.busPlateNumber
                )
            }
            .listRowBackground(Color.cardBackground)
        }
    }
 
    private var passengersSection: some View {
        Section("Passengers") {
            NavigationLink {
                DriverPassengerRequestsView(driverProfileViewModel: driverProfileViewModel)
            } label: {
                profileListRow(
                    iconName: "person.badge.clock.fill",
                    iconBadgeColor: Color.statusWarning,
                    rowTitle: "Join Requests",
                    rowSubtitle: driverProfileViewModel.passengerRequestsList.isEmpty
                        ? "No pending requests"
                        : "\(driverProfileViewModel.passengerRequestsList.count) pending"
                )
            }
            .listRowBackground(Color.cardBackground)
 
            NavigationLink {
                DriverPassengerManagementView(driverProfileViewModel: driverProfileViewModel)
            } label: {
                profileListRow(
                    iconName: "person.2.fill",
                    iconBadgeColor: Color.brandAccent,
                    rowTitle: "Manage Passengers",
                    rowSubtitle: "\(driverProfileViewModel.activePassengersList.count) active"
                )
            }
            .listRowBackground(Color.cardBackground)
        }
    }
 
    private var reviewsSection: some View {
        Section("Feedback") {
            NavigationLink {
                DriverReviewsView(driverProfileViewModel: driverProfileViewModel)
            } label: {
                profileListRow(
                    iconName: "star.bubble.fill",
                    iconBadgeColor: Color.statusWarning,
                    rowTitle: "Passenger Reviews",
                    rowSubtitle: "\(driverProfileViewModel.driverReviewsList.count) reviews · \(String(format: "%.1f", driverProfileViewModel.averageDriverRatingValue)) avg"
                )
            }
            .listRowBackground(Color.cardBackground)
        }
    }
 
    private var settingsSection: some View {
        Section(
            header: Text("Settings"),
            footer: Text("StaffLanka Go  v1.0.0")
                .font(.system(size: 12))
                .foregroundColor(.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        ) {
            Button {} label: {
                profileListRow(iconName: "lock.shield.fill", iconBadgeColor: Color.brandSecondary, rowTitle: "Privacy Settings", rowSubtitle: nil)
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.cardBackground)
 
            NavigationLink {
                DriverNotificationSettingsView()
            } label: {
                profileListRow(iconName: "bell.badge.fill", iconBadgeColor: Color.statusWarning, rowTitle: "Notification Settings", rowSubtitle: nil)
            }
            .listRowBackground(Color.cardBackground)
 
            Button {} label: {
                profileListRow(iconName: "questionmark.circle.fill", iconBadgeColor: Color.statusInfo, rowTitle: "Help & Support", rowSubtitle: nil)
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.cardBackground)
 
            // Face ID / Touch ID toggle — only shown when the device supports biometrics
            if BiometricService.shared.deviceSupportsBiometricAuthentication {
                biometricToggleRow
                    .listRowBackground(Color.cardBackground)
            }
 
            // Remove Local Data
            Button {
                driverProfileViewModel.showRemoveLocalDataConfirm = true
            } label: {
                profileListRow(iconName: "internaldrive", iconBadgeColor: Color.statusInfo, rowTitle: "Remove Local Data", rowSubtitle: nil)
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.cardBackground)
 
            Button(role: .destructive) {
                showSignOutConfirmationAlert = true
            } label: {
                HStack(spacing: 12) {
                    profileIconBadge(systemIconName: "arrow.right.square.fill", badgeColor: .statusDanger)
                    Text("Sign Out")
                        .font(.system(size: 15))
                        .foregroundColor(.statusDanger)
                }
                .padding(.vertical, 2)
            }
            .listRowBackground(Color.cardBackground)
        }
    }
 
    //A toggle row that enables or disables biometric sign-in.
    //Turning it ON triggers a live Face ID challenge to confirm hardware consent
    //before the preference is persisted. Turning it OFF simply clears the flag.
    private var biometricToggleRow: some View {
        HStack(spacing: 12) {
            profileIconBadge(systemIconName: "faceid", badgeColor: Color.brandAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(BiometricService.shared.biometricTypeDisplayName) Sign-In")
                    .font(.system(size: 15))
                    .foregroundColor(.textPrimary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { authManager.isBiometricEnabled },
                set: { newValue in
                    if newValue {
                        Task {
                            let succeeded = await BiometricService.shared.authenticateWithBiometrics(
                                reasonMessage: "Verify your identity to enable \(BiometricService.shared.biometricTypeDisplayName) sign-in"
                            )
                            if succeeded {
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
        }
        .padding(.vertical, 2)
    }
 
    //Reusable Row Helper
 
    private func profileListRow(iconName: String, iconBadgeColor: Color, rowTitle: String, rowSubtitle: String?) -> some View {
        HStack(spacing: 12) {
            profileIconBadge(systemIconName: iconName, badgeColor: iconBadgeColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(rowTitle)
                    .font(.system(size: 15))
                    .foregroundColor(.textPrimary)
                if let subtitle = rowSubtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
 
//Icon Badge (file-scope helper, unchanged)
 
func profileIconBadge(systemIconName: String, badgeColor: Color) -> some View {
    Image(systemName: systemIconName)
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(.white)
        .frame(width: 30, height: 30)
        .background(badgeColor)
        .clipShape(RoundedRectangle(cornerRadius: 7))
}
 
//Edit Profile Sheet (unchanged)
 
struct DriverEditProfileSheet: View {
    @ObservedObject var driverProfileViewModel: DriverProfileViewModel
    @Environment(\.dismiss) private var dismissSheet
 
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(
                            selection: $driverProfileViewModel.selectedProfilePhotoPicPickerItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            ZStack(alignment: .bottomTrailing) {
                                driverProfileEditSheetAvatarView
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
                        .onChange(of: driverProfileViewModel.selectedProfilePhotoPicPickerItem) { _, newPickerItem in
                            if let newPickerItem {
                                driverProfileViewModel.processAndUploadSelectedProfilePhoto(selectedPhotoPickerItem: newPickerItem)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
 
                Section("Personal Information") {
                    editSheetTextField(fieldLabel: "Full Name", iconName: "person.fill", boundValue: $driverProfileViewModel.editingDriverFullName, keyboardType: .default)
                    NavigationLink {
                        DriverChangePhoneView(driverProfileViewModel: driverProfileViewModel)
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
                                Text(driverProfileViewModel.driverProfileInformationValues.driverPhoneNumber)
                                    .font(.system(size: 15))
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }
                    editSheetTextField(fieldLabel: "Email Address", iconName: "envelope.fill", boundValue: $driverProfileViewModel.editingDriverEmailAddress, keyboardType: .emailAddress)
                    editSheetTextField(fieldLabel: "License Number", iconName: "creditcard.fill", boundValue: $driverProfileViewModel.editingDriverLicenseNumber, keyboardType: .default)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { driverProfileViewModel.cancelDriverProfileEdits() }
                        .foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { driverProfileViewModel.saveDriverProfileEdits() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.brandAccent)
                }
            }
        }
    }
 
    @ViewBuilder
    private var driverProfileEditSheetAvatarView: some View {
        if let profilePhotoData = driverProfileViewModel.driverProfilePhotoImageData,
           let uiImageFromPhotoData = UIImage(data: profilePhotoData) {
            Image(uiImage: uiImageFromPhotoData)
                .resizable()
                .scaledToFill()
                .frame(width: 88, height: 88)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(LinearGradient.brand)
                .frame(width: 88, height: 88)
                .overlay(
                    Text(driverProfileViewModel.driverProfileInitialsText)
                        .font(.system(size: 30, weight: .bold))
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
            TextField(fieldLabel, text: boundValue)
                .font(.system(size: 15))
                .foregroundColor(.textPrimary)
                .tint(.brandAccent)
                .keyboardType(keyboardType)
        }
    }
}
 
//Edit Bus Details Sheet (unchanged)
 
struct DriverEditBusDetailsSheet: View {
    @ObservedObject var driverProfileViewModel: DriverProfileViewModel
    @Environment(\.dismiss) private var dismissSheet
 
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient.brand)
                                .frame(width: 88, height: 88)
                            Image(systemName: "bus.fill")
                                .font(.system(size: 34))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
 
                Section("Vehicle Information") {
                    busEditField(fieldLabel: "Plate Number", iconName: "number", boundValue: $driverProfileViewModel.editingBusPlateNumber, keyboardType: .default)
                    busEditField(fieldLabel: "Bus Name", iconName: "bus", boundValue: $driverProfileViewModel.editingBusDisplayName, keyboardType: .default)
                    busEditField(fieldLabel: "Passenger Capacity", iconName: "person.3.fill", boundValue: $driverProfileViewModel.editingBusPassengerCapacity, keyboardType: .numberPad)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Edit Bus Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { driverProfileViewModel.cancelBusDetailsEdits() }
                        .foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { driverProfileViewModel.saveBusDetailsEdits() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.brandAccent)
                }
            }
        }
    }
 
    private func busEditField(fieldLabel: String, iconName: String, boundValue: Binding<String>, keyboardType: UIKeyboardType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 13))
                .foregroundColor(.brandAccent)
                .frame(width: 18)
            TextField(fieldLabel, text: boundValue)
                .font(.system(size: 15))
                .foregroundColor(.textPrimary)
                .tint(.brandAccent)
                .keyboardType(keyboardType)
        }
    }
}
 
//Edit Pricing Sheet (unchanged)
 
struct DriverEditPricingSheet: View {
    @ObservedObject var driverProfileViewModel: DriverProfileViewModel
    @Environment(\.dismiss) private var dismissSheet
 
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.statusActive.opacity(0.12))
                                .frame(width: 88, height: 88)
                            Image(systemName: "banknote.fill")
                                .font(.system(size: 34))
                                .foregroundColor(.statusActive)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
 
                Section("Monthly Fees") {
                    pricingEditField(fieldLabel: "Morning Only (Rs.)", iconName: "sunrise.fill", iconColor: .statusWarning, boundValue: $driverProfileViewModel.editingMorningOnlyFee)
                    pricingEditField(fieldLabel: "Evening Only (Rs.)", iconName: "sunset.fill", iconColor: Color(hex: "#FF7B54"), boundValue: $driverProfileViewModel.editingEveningOnlyFee)
                    pricingEditField(fieldLabel: "Both Sessions (Rs.)", iconName: "arrow.2.squarepath", iconColor: .brandAccent, boundValue: $driverProfileViewModel.editingBothSessionsFee)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Edit Pricing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { driverProfileViewModel.cancelPricingDetailsEdits() }
                        .foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { driverProfileViewModel.savePricingDetailsEdits() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.brandAccent)
                }
            }
        }
    }
 
    private func pricingEditField(fieldLabel: String, iconName: String, iconColor: Color, boundValue: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 13))
                .foregroundColor(iconColor)
                .frame(width: 18)
            TextField(fieldLabel, text: boundValue)
                .font(.system(size: 15))
                .foregroundColor(.textPrimary)
                .tint(.brandAccent)
                .keyboardType(.numberPad)
        }
    }
}
 
//Previews
 
#Preview("Dark Mode") {
    NavigationStack {
        DriverProfileView()
    }
    .preferredColorScheme(.dark)
}
 
#Preview("Light Mode") {
    NavigationStack {
        DriverProfileView()
    }
    .preferredColorScheme(.light)
}
