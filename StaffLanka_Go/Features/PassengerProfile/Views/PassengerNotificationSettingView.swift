//
//  PassengerNotificationSettingView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-08.
//

import SwiftUI
import UserNotifications

struct PassengerNotificationSettingsView: View {

    @ObservedObject private var notificationManager = NotificationManager.shared

    @AppStorage("muteTripAlerts") private var muteTripAlerts = false
    @AppStorage("mutePassengerAlerts") private var mutePassengerAlerts = false
    @AppStorage("muteInAppNotifications") private var muteInAppNotifications = false

    var systemBannersAreAuthorized: Bool {
        notificationManager.systemBannerAuthorizationStatus == .authorized
            || notificationManager.systemBannerAuthorizationStatus == .provisional
    }

    var body: some View {
        List {
            inAppNotificationsSection
            bannerNotificationsSection
            alertTypesSection
        }
        .listStyle(.insetGrouped)
        .background(Color.appBackground)
        .scrollContentBackground(.hidden)
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notificationManager.refreshSystemBannerAuthorizationStatus()
        }
    }

    private var inAppNotificationsSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { !muteInAppNotifications },
                set: { newValue in
                    muteInAppNotifications = !newValue
                    notificationManager.toggleInAppNotifications(isOn: newValue)
                }
            )) {
                HStack(spacing: 12) {
                    settingsIconBadge(systemIconName: "bell.fill", badgeColor: Color.brandAccent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("In-App Notifications")
                            .font(.system(size: 15))
                            .foregroundColor(Color.textPrimary)
                        Text("Show alerts in your notification inbox")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }
            .tint(Color.brandAccent)
            .listRowBackground(Color.cardBackground)
        } header: {
            Text("In-App")
                .foregroundColor(Color.textSecondary)
        } footer: {
            Text("When enabled, notifications appear in the bell icon inbox on your dashboard.")
                .font(.system(size: 13))
                .foregroundColor(Color.textTertiary)
                .padding(.top, 4)
        }
    }

    private var bannerNotificationsSection: some View {
        Section {
            HStack(spacing: 12) {
                settingsIconBadge(
                    systemIconName: systemBannersAreAuthorized ? "bell.badge.fill" : "bell.slash.fill",
                    badgeColor: systemBannersAreAuthorized ? Color.statusActive : Color.statusDanger
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Banner Notifications")
                        .font(.system(size: 15))
                        .foregroundColor(Color.textPrimary)
                    Text(systemBannersAreAuthorized ? "Enabled in system settings" : "Disabled — tap to open Settings")
                        .font(.system(size: 12))
                        .foregroundColor(systemBannersAreAuthorized ? Color.statusActive : Color.statusDanger)
                }
                Spacer()
                if systemBannersAreAuthorized {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.statusActive)
                        .font(.system(size: 18))
                } else {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(Color.statusDanger)
                        .font(.system(size: 16))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if let systemSettingsURL = URL(string: UIApplication.openNotificationSettingsURLString) {
                    UIApplication.shared.open(systemSettingsURL)
                }
            }
            .listRowBackground(Color.cardBackground)
        } header: {
            Text("Banner Alerts")
                .foregroundColor(Color.textSecondary)
        } footer: {
            Text("Banner notifications appear on your lock screen and at the top of your screen. This is controlled by iOS — tap the row above to manage it in Settings.")
                .font(.system(size: 13))
                .foregroundColor(Color.textTertiary)
                .padding(.top, 4)
        }
    }

    private var alertTypesSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { !muteTripAlerts },
                set: { newValue in
                    muteTripAlerts = !newValue
                    notificationManager.toggleTripAlerts(isOn: newValue)
                }
            )) {
                HStack(spacing: 12) {
                    settingsIconBadge(systemIconName: "bus.fill", badgeColor: Color.statusWarning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Trip Alerts")
                            .font(.system(size: 15))
                            .foregroundColor(Color.textPrimary)
                        Text("Trip started, completed and proximity alerts")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }
            .tint(Color.brandAccent)
            .listRowBackground(Color.cardBackground)

            Toggle(isOn: Binding(
                get: { !mutePassengerAlerts },
                set: { newValue in
                    mutePassengerAlerts = !newValue
                    notificationManager.togglePassengerAlerts(isOn: newValue)
                }
            )) {
                HStack(spacing: 12) {
                    settingsIconBadge(systemIconName: "person.fill.checkmark", badgeColor: Color.brandAccent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Account Alerts")
                            .font(.system(size: 15))
                            .foregroundColor(Color.textPrimary)
                        Text("Login confirmations and account activity")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }
            .tint(Color.brandAccent)
            .listRowBackground(Color.cardBackground)
        } header: {
            Text("Alert Types")
                .foregroundColor(Color.textSecondary)
        } footer: {
            Text("Control which categories of alerts you receive as notifications.")
                .font(.system(size: 13))
                .foregroundColor(Color.textTertiary)
                .padding(.top, 4)
        }
    }

    private func settingsIconBadge(systemIconName: String, badgeColor: Color) -> some View {
        Image(systemName: systemIconName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 30, height: 30)
            .background(badgeColor)
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

#Preview("Dark Mode") {
    NavigationStack { PassengerNotificationSettingsView() }
        .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    NavigationStack { PassengerNotificationSettingsView() }
        .preferredColorScheme(.light)
}
