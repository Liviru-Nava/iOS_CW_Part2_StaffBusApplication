//
//  DriverPassengerManagementView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//

import SwiftUI

struct DriverPassengerManagementView: View {

    @ObservedObject var driverProfileViewModel: DriverProfileViewModel
    @State private var showRemovePassengerConfirmationAlert: Bool = false
    @State private var pendingRemovalPassengerDocumentId: String? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                statsOverviewCard
                    .padding(.top, 8)

                filterSegmentControl

                if driverProfileViewModel.selectedPassengerFilterType == .active {
                    activePassengersList
                } else {
                    inactiveDateRangeFilterRow
                    inactivePassengersList
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 48)
        }
        .background(Color.appBackground)
        .navigationTitle("Passengers")
        .navigationBarTitleDisplayMode(.large)
        .alert("Remove Passenger", isPresented: $showRemovePassengerConfirmationAlert) {
            Button("Cancel", role: .cancel) { pendingRemovalPassengerDocumentId = nil }
            Button("Remove", role: .destructive) {
                if let docId = pendingRemovalPassengerDocumentId {
                    driverProfileViewModel.terminateActivePassenger(passengerDocumentId: docId)
                }
                pendingRemovalPassengerDocumentId = nil
            }
        } message: {
            Text("This will remove the passenger from your route. They will need to send a new request to re-enroll.")
        }
    }

    // Summary card showing four quick counts at the top
    private var statsOverviewCard: some View {
        HStack(spacing: 0) {
            statCell(
                value: "\(driverProfileViewModel.activePassengersList.count)",
                label: "Active",
                iconName: "person.fill.checkmark",
                accentColor: Color.statusActive
            )
            Divider().frame(height: 44)
            statCell(
                value: "\(driverProfileViewModel.inactivePassengersList.count)",
                label: "Inactive",
                iconName: "person.fill.xmark",
                accentColor: Color.statusInactive
            )
            Divider().frame(height: 44)
            statCell(
                value: "\(driverProfileViewModel.activePassengersList.filter { $0.currentPaymentStatus == .paid }.count)",
                label: "Paid",
                iconName: "checkmark.seal.fill",
                accentColor: Color.statusActive
            )
            Divider().frame(height: 44)
            statCell(
                value: "\(driverProfileViewModel.activePassengersList.filter { $0.currentPaymentStatus == .pending }.count)",
                label: "Pending",
                iconName: "clock.badge.exclamationmark.fill",
                accentColor: Color.statusWarning
            )
        }
        .padding(.vertical, 16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.divider, lineWidth: 1))
    }

    private func statCell(value: String, label: String, iconName: String, accentColor: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 13))
                .foregroundStyle(accentColor)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var filterSegmentControl: some View {
        Picker("Filter", selection: $driverProfileViewModel.selectedPassengerFilterType) {
            ForEach(DriverProfileViewModel.PassengerFilterType.allCases) { filterType in
                Text(filterType.rawValue).tag(filterType)
            }
        }
        .pickerStyle(.segmented)
        .onAppear {
            UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.brandSecondary)
            UISegmentedControl.appearance().backgroundColor = UIColor(Color.cardBackground)
            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(Color.textSecondary)], for: .normal)
        }
    }

    private var activePassengersList: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Active Passengers",
                count: driverProfileViewModel.activePassengersList.count
            )

            if driverProfileViewModel.activePassengersList.isEmpty {
                emptyStateCard(iconName: "person.slash", message: "No active passengers on this route.")
            } else {
                VStack(spacing: 12) {
                    ForEach(driverProfileViewModel.activePassengersList) { passenger in
                        activePassengerCard(passengerEntry: passenger)
                    }
                }
            }
        }
    }

    private var inactiveDateRangeFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DriverProfileViewModel.InactiveDateRangeFilter.allCases) { option in
                    let isSelected = driverProfileViewModel.selectedInactiveDateRangeFilter == option
                    Button {
                        driverProfileViewModel.selectedInactiveDateRangeFilter = option
                    } label: {
                        Text(option.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isSelected ? .white : .brandAccent)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(isSelected ? Color.brandAccent : Color.brandAccent.opacity(0.10))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: driverProfileViewModel.selectedInactiveDateRangeFilter)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var inactivePassengersList: some View {
        let grouped = driverProfileViewModel.inactivePassengersGroupedByDate
        return VStack(alignment: .leading, spacing: 20) {
            if grouped.isEmpty {
                sectionHeader(title: "Inactive Passengers", count: 0)
                emptyStateCard(iconName: "checkmark.circle", message: "No inactive passengers in this date range.")
            } else {
                ForEach(grouped, id: \.0) { dateLabel, passengersInGroup in
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader(title: dateLabel, count: passengersInGroup.count)
                        VStack(spacing: 10) {
                            ForEach(passengersInGroup) { passenger in
                                inactivePassengerCard(passengerEntry: passenger)
                            }
                        }
                    }
                }
            }
        }
    }

    private func activePassengerCard(passengerEntry: DriverProfileViewModel.ActivePassengerEntry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row: avatar + name + session badge
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.brandAccentGlow.opacity(0.18))
                        .frame(width: 50, height: 50)
                    Text(String(passengerEntry.passengerFullName.prefix(1)))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.brandAccent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(passengerEntry.passengerFullName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(passengerEntry.passengerPhoneNumber)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Text(sessionLabelText(passengerEntry.enrolledSessionType))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.brandAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.brandAccent.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider().padding(.horizontal, 16)

            // Route info rows
            VStack(spacing: 8) {
                routeInfoRow(
                    iconName: "arrow.up.circle.fill",
                    iconColor: Color.statusActive,
                    labelText: "Pickup",
                    valueText: passengerEntry.boardingStopName
                )
                routeInfoRow(
                    iconName: "arrow.down.circle.fill",
                    iconColor: Color.statusDanger,
                    labelText: "Drop-off",
                    valueText: passengerEntry.dropOffStopName
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.horizontal, 16)

            // Payment badge + remove button
            HStack {
                HStack(spacing: 5) {
                    Circle()
                        .fill(passengerEntry.currentPaymentStatus == .paid ? Color.statusActive : Color.statusWarning)
                        .frame(width: 7, height: 7)
                    Text(passengerEntry.currentPaymentStatus.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(passengerEntry.currentPaymentStatus == .paid ? Color.statusActive : Color.statusWarning)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background((passengerEntry.currentPaymentStatus == .paid ? Color.statusActive : Color.statusWarning).opacity(0.10))
                .clipShape(Capsule())

                Spacer()

                Button {
                    pendingRemovalPassengerDocumentId = passengerEntry.id
                    showRemovePassengerConfirmationAlert = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "person.fill.xmark")
                            .font(.system(size: 11))
                        Text("Remove")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.statusDanger)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.statusDanger.opacity(0.09))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.statusDanger.opacity(0.22), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    passengerEntry.currentPaymentStatus == .pending
                        ? Color.statusWarning.opacity(0.30)
                        : Color.divider,
                    lineWidth: 1
                )
        )
    }

    private func inactivePassengerCard(passengerEntry: DriverProfileViewModel.InactivePassengerEntry) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.statusInactive.opacity(0.10))
                    .frame(width: 46, height: 46)
                Text(String(passengerEntry.passengerFullName.prefix(1)))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.statusInactive)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(passengerEntry.passengerFullName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)

                HStack(spacing: 6) {
                    Text(passengerEntry.inactiveReasonType.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(inactiveReasonColor(for: passengerEntry.inactiveReasonType))
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(inactiveReasonColor(for: passengerEntry.inactiveReasonType).opacity(0.10))
                        .clipShape(Capsule())

                    Text(passengerEntry.removedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textTertiary)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.divider, lineWidth: 1))
        .opacity(0.75)
    }

    private func routeInfoRow(iconName: String, iconColor: Color, labelText: String, valueText: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)
                .frame(width: 20)
            Text(labelText)
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
                .frame(width: 52, alignment: .leading)
            Text(valueText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.brandAccent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.brandAccent.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    private func emptyStateCard(iconName: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 28))
                .foregroundStyle(Color.textTertiary)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.divider, lineWidth: 1))
    }

    private func sessionLabelText(_ sessionType: DriverProfileViewModel.PassengerSessionType) -> String {
        switch sessionType {
        case .morningOnly:  return "Morning"
        case .eveningOnly:  return "Evening"
        case .bothSessions: return "Both"
        }
    }

    private func inactiveReasonColor(for reasonType: DriverProfileViewModel.PassengerInactiveReasonType) -> Color {
        switch reasonType {
        case .notPaid:     return .statusWarning
        case .selfRemoved: return .statusInfo
        case .removed:     return .statusInactive
        }
    }
}
