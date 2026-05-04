//
//  DriverPassengerRequestsView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//

import SwiftUI

struct DriverPassengerRequestsView: View {

    @ObservedObject var driverProfileViewModel: DriverProfileViewModel

    var body: some View {
        List {
            if driverProfileViewModel.passengerRequestsList.isEmpty {
                emptyStateSection
            } else {
                summarySection
                requestsSection
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Join Requests")
        .navigationBarTitleDisplayMode(.large)
    }

    private var summarySection: some View {
        Section {
            HStack(spacing: 0) {
                summaryStatCell(
                    value: "\(driverProfileViewModel.passengerRequestsList.count)",
                    label: "Pending",
                    valueColor: .statusWarning
                )
                Divider().frame(height: 36)
                summaryStatCell(
                    value: "\(driverProfileViewModel.passengerRequestsList.filter { $0.preferredSessionType == .morningOnly }.count)",
                    label: "Morning",
                    valueColor: .statusWarning
                )
                Divider().frame(height: 36)
                summaryStatCell(
                    value: "\(driverProfileViewModel.passengerRequestsList.filter { $0.preferredSessionType == .eveningOnly }.count)",
                    label: "Evening",
                    valueColor: Color(hex: "#FF7B54")
                )
                Divider().frame(height: 36)
                summaryStatCell(
                    value: "\(driverProfileViewModel.passengerRequestsList.filter { $0.preferredSessionType == .bothSessions }.count)",
                    label: "Both",
                    valueColor: .brandAccent
                )
            }
            .padding(.vertical, 6)
            .listRowBackground(Color.cardBackground)
        }
    }

    private func summaryStatCell(value: String, label: String, valueColor: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var requestsSection: some View {
        Section {
            ForEach(driverProfileViewModel.passengerRequestsList) { request in
                passengerRequestRow(request: request)
                    .listRowBackground(Color.cardBackground)
            }
        } header: {
            Text("Pending Requests")
        }
    }

    private func passengerRequestRow(request: DriverProfileViewModel.PassengerJoinRequest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.brandSubtle)
                        .frame(width: 44, height: 44)
                    Text(String(request.passengerFullName.prefix(1)))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.brandAccent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(request.passengerFullName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text(request.preferredSessionType.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(sessionPreferenceColor(sessionType: request.preferredSessionType))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(sessionPreferenceColor(sessionType: request.preferredSessionType).opacity(0.12))
                        .clipShape(Capsule())
                }
                Spacer()
            }

            HStack(spacing: 8) {
                Image(systemName: "arrow.up.to.line")
                    .font(.system(size: 11))
                    .foregroundColor(.statusActive)
                Text(request.requestedPickupStopName)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)

                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundColor(.textTertiary)
                    .padding(.horizontal, 2)

                Image(systemName: "arrow.down.to.line")
                    .font(.system(size: 11))
                    .foregroundColor(.statusDanger)
                Text(request.requestedDropOffLocationName)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }

            HStack(spacing: 10) {
                Button {
                    driverProfileViewModel.acceptPassengerJoinRequest(requestIdentifier: request.id)
                } label: {
                    Label("Accept", systemImage: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.statusActive)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button {
                    driverProfileViewModel.rejectPassengerJoinRequest(requestIdentifier: request.id)
                } label: {
                    Label("Reject", systemImage: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.statusDanger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.statusDanger.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.statusDanger.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "tray")
                    .font(.system(size: 40))
                    .foregroundColor(.textTertiary)
                Text("No Pending Requests")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text("New passenger join requests will appear here.")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .listRowBackground(Color.cardBackground)
        }
    }

    private func sessionPreferenceColor(sessionType: DriverProfileViewModel.PassengerRequestSessionPreference) -> Color {
        switch sessionType {
        case .morningOnly: return .statusWarning
        case .eveningOnly: return Color(hex: "#FF7B54")
        case .bothSessions: return .brandAccent
        }
    }
}
