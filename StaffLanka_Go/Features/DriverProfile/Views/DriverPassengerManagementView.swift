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
        List {
            statsSection
            filterPickerSection
            if driverProfileViewModel.selectedPassengerFilterType == .active {
                activePassengersSection
            } else {
                inactiveDateRangePickerSection
                inactivePassengersSection
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
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

    private var statsSection: some View {
        Section {
            HStack(spacing: 0) {
                statCell(value: "\(driverProfileViewModel.activePassengersList.count)", label: "Active", valueColor: .statusActive)
                Divider().frame(height: 36)
                statCell(value: "\(driverProfileViewModel.inactivePassengersList.count)", label: "Inactive", valueColor: .statusInactive)
                Divider().frame(height: 36)
                statCell(value: "\(driverProfileViewModel.activePassengersList.filter { $0.currentPaymentStatus == .paid }.count)", label: "Paid", valueColor: .statusActive)
                Divider().frame(height: 36)
                statCell(value: "\(driverProfileViewModel.activePassengersList.filter { $0.currentPaymentStatus == .pending }.count)", label: "Pending", valueColor: .statusWarning)
            }
            .padding(.vertical, 6)
            .listRowBackground(Color.cardBackground)
        }
    }

    private func statCell(value: String, label: String, valueColor: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(valueColor)
            Text(label).font(.system(size: 11)).foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var filterPickerSection: some View {
        Section {
            Picker("Passenger Filter", selection: $driverProfileViewModel.selectedPassengerFilterType) {
                ForEach(DriverProfileViewModel.PassengerFilterType.allCases) { filterType in
                    Text(filterType.rawValue).tag(filterType)
                }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            .listRowBackground(Color.cardBackground)
        }
    }

    private var inactiveDateRangePickerSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DriverProfileViewModel.InactiveDateRangeFilter.allCases) { option in
                        Button {
                            driverProfileViewModel.selectedInactiveDateRangeFilter = option
                        } label: {
                            Text(option.rawValue)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(driverProfileViewModel.selectedInactiveDateRangeFilter == option ? .white : .brandAccent)
                                .padding(.horizontal, 14).padding(.vertical, 7)
                                .background(driverProfileViewModel.selectedInactiveDateRangeFilter == option ? Color.brandAccent : Color.brandAccent.opacity(0.10))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2).padding(.vertical, 4)
            }
            .listRowBackground(Color.cardBackground)
            .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
        }
    }

    private var activePassengersSection: some View {
        Section {
            if driverProfileViewModel.activePassengersList.isEmpty {
                emptyStateRow(message: "No active passengers", iconName: "person.slash")
            } else {
                ForEach(driverProfileViewModel.activePassengersList) { passenger in
                    activePassengerCard(passengerEntry: passenger)
                        .listRowBackground(Color.cardBackground)
                }
            }
        } header: {
            Text("Active Passengers (\(driverProfileViewModel.activePassengersList.count))")
        }
    }

    private var inactivePassengersSection: some View {
        let grouped = driverProfileViewModel.inactivePassengersGroupedByDate
        return Group {
            if grouped.isEmpty {
                Section {
                    emptyStateRow(message: "No inactive passengers", iconName: "checkmark.circle")
                } header: {
                    Text("Inactive Passengers (\(driverProfileViewModel.inactivePassengersFilteredByDateRange.count))")
                }
            } else {
                ForEach(grouped, id: \.0) { dateLabel, passengersInGroup in
                    Section {
                        ForEach(passengersInGroup) { passenger in
                            inactivePassengerCard(passengerEntry: passenger)
                                .listRowBackground(Color.cardBackground)
                        }
                    } header: {
                        Text(dateLabel)
                    }
                }
            }
        }
    }

    // Full detail card: name, phone, pickup, drop-off, session, payment status, remove button
    private func activePassengerCard(passengerEntry: DriverProfileViewModel.ActivePassengerEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(LinearGradient.brandSubtle).frame(width: 44, height: 44)
                    Text(String(passengerEntry.passengerFullName.prefix(1))).font(.system(size: 17, weight: .bold)).foregroundColor(.brandAccent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(passengerEntry.passengerFullName).font(.system(size: 15, weight: .semibold)).foregroundColor(.textPrimary)
                    Text(passengerEntry.passengerPhoneNumber).font(.system(size: 12)).foregroundColor(.textSecondary)
                }
                Spacer()
                // Session badge
                Text(sessionLabelText(passengerEntry.enrolledSessionType))
                    .font(.system(size: 11, weight: .medium)).foregroundColor(.brandAccent)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.brandAccent.opacity(0.10)).clipShape(Capsule())
            }

            // Route detail rows
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 11)).foregroundColor(.statusActive)
                Text("Pickup:").font(.system(size: 12)).foregroundColor(.textTertiary).frame(width: 48, alignment: .leading)
                Text(passengerEntry.boardingStopName).font(.system(size: 12, weight: .medium)).foregroundColor(.textPrimary)
                Spacer()
            }
            HStack(spacing: 6) {
                Image(systemName: "arrow.down.circle.fill").font(.system(size: 11)).foregroundColor(.statusDanger)
                Text("Drop-off:").font(.system(size: 12)).foregroundColor(.textTertiary).frame(width: 48, alignment: .leading)
                Text(passengerEntry.dropOffStopName).font(.system(size: 12, weight: .medium)).foregroundColor(.textPrimary)
                Spacer()
            }

            HStack {
                // Payment status badge
                Text(passengerEntry.currentPaymentStatus.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(passengerEntry.currentPaymentStatus == .paid ? .statusActive : .statusWarning)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background((passengerEntry.currentPaymentStatus == .paid ? Color.statusActive : Color.statusWarning).opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
                // Remove button
                Button {
                    pendingRemovalPassengerDocumentId = passengerEntry.id
                    showRemovePassengerConfirmationAlert = true
                } label: {
                    Text("Remove")
                        .font(.system(size: 11, weight: .medium)).foregroundColor(.statusDanger)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.statusDanger.opacity(0.10)).clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.statusDanger.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    private func inactivePassengerCard(passengerEntry: DriverProfileViewModel.InactivePassengerEntry) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.statusInactive.opacity(0.12)).frame(width: 44, height: 44)
                Text(String(passengerEntry.passengerFullName.prefix(1))).font(.system(size: 17, weight: .bold)).foregroundColor(.statusInactive)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(passengerEntry.passengerFullName).font(.system(size: 15, weight: .medium)).foregroundColor(.textSecondary)
                Text(passengerEntry.inactiveReasonType.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(inactiveReasonBadgeColor(for: passengerEntry.inactiveReasonType))
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(inactiveReasonBadgeColor(for: passengerEntry.inactiveReasonType).opacity(0.12))
                    .clipShape(Capsule())
                Text(passengerEntry.removedDate.formatted(date: .omitted, time: .shortened)).font(.system(size: 11)).foregroundColor(.textTertiary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func emptyStateRow(message: String, iconName: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: iconName).font(.system(size: 16)).foregroundColor(.textTertiary)
            Text(message).font(.system(size: 14)).foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 24).listRowBackground(Color.clear)
    }

    private func sessionLabelText(_ sessionType: DriverProfileViewModel.PassengerSessionType) -> String {
        switch sessionType {
        case .morningOnly:  return "Morning"
        case .eveningOnly:  return "Evening"
        case .bothSessions: return "Both"
        }
    }

    private func inactiveReasonBadgeColor(for reasonType: DriverProfileViewModel.PassengerInactiveReasonType) -> Color {
        switch reasonType {
        case .notPaid:     return .statusWarning
        case .selfRemoved: return .statusInfo
        case .removed:     return .statusInactive
        }
    }
}
