//
//  DriverPassengerManagementView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//

import SwiftUI

struct DriverPassengerManagementView: View {

    @ObservedObject var driverProfileViewModel: DriverProfileViewModel

    var body: some View {
        List {
            statsSection
            filterPickerSection
            if driverProfileViewModel.selectedPassengerFilterType == .active {
                activePassengersSection
            } else {
                inactivePassengersSection
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Passengers")
        .navigationBarTitleDisplayMode(.large)
    }

    private var statsSection: some View {
        Section {
            HStack(spacing: 0) {
                statCell(
                    value: "\(driverProfileViewModel.activePassengersList.count)",
                    label: "Active",
                    valueColor: .statusActive
                )
                Divider().frame(height: 36)
                statCell(
                    value: "\(driverProfileViewModel.inactivePassengersList.count)",
                    label: "Inactive",
                    valueColor: .statusInactive
                )
                Divider().frame(height: 36)
                statCell(
                    value: "\(driverProfileViewModel.activePassengersList.filter { $0.currentPaymentStatus == .paid }.count)",
                    label: "Paid",
                    valueColor: .statusActive
                )
                Divider().frame(height: 36)
                statCell(
                    value: "\(driverProfileViewModel.activePassengersList.filter { $0.currentPaymentStatus == .pending }.count)",
                    label: "Pending",
                    valueColor: .statusWarning
                )
            }
            .padding(.vertical, 6)
            .listRowBackground(Color.cardBackground)
        }
    }

    private func statCell(value: String, label: String, valueColor: Color) -> some View {
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

    private var activePassengersSection: some View {
        Section {
            if driverProfileViewModel.activePassengersList.isEmpty {
                emptyRow(message: "No active passengers", iconName: "person.slash")
            } else {
                ForEach(driverProfileViewModel.activePassengersList) { passenger in
                    activePassengerRow(passenger: passenger)
                        .listRowBackground(Color.cardBackground)
                }
            }
        } header: {
            Text("Active Passengers (\(driverProfileViewModel.activePassengersList.count))")
        }
    }

    private var inactivePassengersSection: some View {
        Section {
            if driverProfileViewModel.inactivePassengersList.isEmpty {
                emptyRow(message: "No inactive passengers", iconName: "checkmark.circle")
            } else {
                ForEach(driverProfileViewModel.inactivePassengersList) { passenger in
                    inactivePassengerRow(passenger: passenger)
                        .listRowBackground(Color.cardBackground)
                }
            }
        } header: {
            Text("Inactive Passengers (\(driverProfileViewModel.inactivePassengersList.count))")
        }
    }

    private func activePassengerRow(passenger: DriverProfileViewModel.ActivePassengerEntry) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient.brandSubtle)
                    .frame(width: 44, height: 44)
                Text(String(passenger.passengerFullName.prefix(1)))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.brandAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(passenger.passengerFullName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textPrimary)
                Label(passenger.boardingStopName, systemImage: "mappin")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                Text(passenger.enrolledSessionType.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.brandAccent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.brandAccent.opacity(0.10))
                    .clipShape(Capsule())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(passenger.currentPaymentStatus.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(passenger.currentPaymentStatus == .paid ? .statusActive : .statusWarning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((passenger.currentPaymentStatus == .paid ? Color.statusActive : Color.statusWarning).opacity(0.12))
                    .clipShape(Capsule())

                Button {
                    driverProfileViewModel.terminateActivePassenger(passengerIdentifier: passenger.id)
                } label: {
                    Text("Remove")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.statusDanger)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.statusDanger.opacity(0.10))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.statusDanger.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }

    private func inactivePassengerRow(passenger: DriverProfileViewModel.InactivePassengerEntry) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.statusInactive.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(String(passenger.passengerFullName.prefix(1)))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.statusInactive)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(passenger.passengerFullName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textSecondary)
                Text(passenger.inactiveReasonType.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(passenger.inactiveReasonType == .notPaid ? .statusWarning : .statusInactive)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background((passenger.inactiveReasonType == .notPaid ? Color.statusWarning : Color.statusInactive).opacity(0.12))
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func emptyRow(message: String, iconName: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 16))
                .foregroundColor(.textTertiary)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
        .listRowBackground(Color.clear)
    }
}
