//
//  DriverServiceStatusView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//

import SwiftUI

struct DriverServiceStatusView: View {

    @ObservedObject var profileViewModel: DriverProfileViewModel

    var body: some View {
        List {
            statusBannerSection
            togglesSection
            statusInfoSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Service Status")
        .navigationBarTitleDisplayMode(.large)
    }

    private var statusBannerSection: some View {
        Section {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(profileViewModel.driverAvailabilityStatusIsOnline ? Color.statusActive.opacity(0.15) : Color.statusInactive.opacity(0.12))
                        .frame(width: 64, height: 64)
                    Image(systemName: profileViewModel.driverAvailabilityStatusIsOnline ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 26))
                        .foregroundColor(profileViewModel.driverAvailabilityStatusIsOnline ? .statusActive : .statusInactive)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(profileViewModel.driverAvailabilityStatusIsOnline ? "Currently Online" : "Currently Offline")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text(profileViewModel.driverAvailabilityStatusIsOnline
                         ? "Passengers can see your route and book trips."
                         : "Your route is hidden from passengers.")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(2)
                }
            }
            .padding(.vertical, 8)
            .listRowBackground(Color.cardBackground)
        }
    }

    private var togglesSection: some View {
        Section {
            Toggle(isOn: $profileViewModel.driverAvailabilityStatusIsOnline) {
                HStack(spacing: 12) {
                    profileIconBadge(
                        systemIconName: "wifi",
                        badgeColor: profileViewModel.driverAvailabilityStatusIsOnline ? .statusActive : .statusInactive
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Online Status")
                            .font(.system(size: 15))
                            .foregroundColor(.textPrimary)
                        Text(profileViewModel.driverAvailabilityStatusIsOnline ? "Active – visible to passengers" : "Inactive – hidden from passengers")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .tint(Color.statusActive)
            .listRowBackground(Color.cardBackground)

            Toggle(isOn: $profileViewModel.driverAcceptingRequestsState) {
                HStack(spacing: 12) {
                    profileIconBadge(
                        systemIconName: "person.badge.plus",
                        badgeColor: profileViewModel.driverAcceptingRequestsState ? .brandAccent : .statusInactive
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accepting Join Requests")
                            .font(.system(size: 15))
                            .foregroundColor(.textPrimary)
                        Text(profileViewModel.driverAcceptingRequestsState ? "New passengers can request to join" : "No new requests will be received")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .tint(Color.brandAccent)
            .listRowBackground(Color.cardBackground)
        }
    }

    private var statusInfoSection: some View {
        Section {
            infoRow(iconName: "info.circle", iconColor: .statusInfo, text: "Going offline will not affect passengers already enrolled in your service.")
                .listRowBackground(Color.cardBackground)
            infoRow(iconName: "person.badge.minus", iconColor: .statusWarning, text: "Disabling join requests prevents new passengers from finding your route.")
                .listRowBackground(Color.cardBackground)
        } header: {
            Text("Important Notes")
        }
    }

    private func infoRow(iconName: String, iconColor: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 15))
                .foregroundColor(iconColor)
                .frame(width: 20)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
                .lineSpacing(3)
        }
        .padding(.vertical, 4)
    }
}
