//
//  DriverBusRouteView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//

import SwiftUI

struct DriverBusRouteView: View {

    @ObservedObject var driverProfileViewModel: DriverProfileViewModel

    var body: some View {
        List {
            busDetailsSection
            routeSection
            scheduleSection
            pricingSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Bus & Route")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $driverProfileViewModel.isEditingBusDetails) {
            DriverEditBusDetailsSheet(driverProfileViewModel: driverProfileViewModel)
        }
        .sheet(isPresented: $driverProfileViewModel.isEditingPricingDetails) {
            DriverEditPricingSheet(driverProfileViewModel: driverProfileViewModel)
        }
        .sheet(isPresented: $driverProfileViewModel.isEditingRouteStops) {
            DriverEditRouteStopsSheet(driverProfileViewModel: driverProfileViewModel)
        }
        .sheet(isPresented: $driverProfileViewModel.isEditingSchedule) {
            DriverEditScheduleSheet(driverProfileViewModel: driverProfileViewModel)
        }
    }

    private var busDetailsSection: some View {
        Section {
            detailRow(label: "Plate Number", value: driverProfileViewModel.busDetailsInformationValues.busPlateNumber)
                .listRowBackground(Color.cardBackground)
            detailRow(label: "Bus Name", value: driverProfileViewModel.busDetailsInformationValues.busDisplayName)
                .listRowBackground(Color.cardBackground)
            detailRow(label: "Vehicle Type", value: driverProfileViewModel.busDetailsInformationValues.busVehicleType.rawValue)
                .listRowBackground(Color.cardBackground)
            detailRow(label: "Capacity", value: "\(driverProfileViewModel.busDetailsInformationValues.busPassengerCapacity) seats")
                .listRowBackground(Color.cardBackground)
        } header: {
            // Edit icon is placed inline with the section title
            HStack {
                Text("Bus Details")
                Spacer()
                Button {
                    driverProfileViewModel.openBusDetailsEditMode()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.brandAccent)
                }
            }
        }
    }

    private var routeSection: some View {
        Section {
            detailRow(label: "Starting Point", value: driverProfileViewModel.routeInformationValues.routeStartingPointName)
                .listRowBackground(Color.cardBackground)
            detailRow(label: "Ending Point", value: driverProfileViewModel.routeInformationValues.routeEndingPointName)
                .listRowBackground(Color.cardBackground)
            detailRow(label: "Total Stops", value: "\(driverProfileViewModel.routeInformationValues.orderedListOfRouteStops.count)")
                .listRowBackground(Color.cardBackground)

            ForEach(Array(driverProfileViewModel.routeInformationValues.orderedListOfRouteStops.enumerated()), id: \.element.id) { index, stop in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(stopNumberBackgroundColor(index: index, total: driverProfileViewModel.routeInformationValues.orderedListOfRouteStops.count))
                            .frame(width: 28, height: 28)
                        Text("\(stop.stopPositionIndex + 1)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(stopNumberForegroundColor(index: index, total: driverProfileViewModel.routeInformationValues.orderedListOfRouteStops.count))
                    }

                    Text(stop.stopDisplayName)
                        .font(.system(size: 15))
                        .foregroundColor(.textPrimary)

                    Spacer()

                    if index == 0 {
                        stopBadge(labelText: "Start", badgeColor: .statusActive)
                    } else if index == driverProfileViewModel.routeInformationValues.orderedListOfRouteStops.count - 1 {
                        stopBadge(labelText: "End", badgeColor: .statusDanger)
                    }
                }
                .listRowBackground(Color.cardBackground)
            }
        } header: {
            // Edit icon is placed inline with the section title
            HStack {
                Text("Route")
                Spacer()
                Button {
                    driverProfileViewModel.openRouteEditMode()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.brandAccent)
                }
            }
        }
    }

    private var scheduleSection: some View {
        Section {
            HStack(spacing: 12) {
                profileIconBadge(systemIconName: "sunrise.fill", badgeColor: .statusWarning)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Morning Trip")
                        .font(.system(size: 15))
                        .foregroundColor(.textPrimary)
                    Text("Departs \(driverProfileViewModel.scheduleDetailsValues.morningTripSchedule.departureTime)  ·  Arrives ~\(driverProfileViewModel.scheduleDetailsValues.morningTripSchedule.estimatedArrivalTime)")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.vertical, 2)
            .listRowBackground(Color.cardBackground)

            HStack(spacing: 12) {
                profileIconBadge(systemIconName: "sunset.fill", badgeColor: Color(hex: "#FF7B54"))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Evening Trip")
                        .font(.system(size: 15))
                        .foregroundColor(.textPrimary)
                    Text("Departs \(driverProfileViewModel.scheduleDetailsValues.eveningTripSchedule.departureTime)  ·  Arrives ~\(driverProfileViewModel.scheduleDetailsValues.eveningTripSchedule.estimatedArrivalTime)")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.vertical, 2)
            .listRowBackground(Color.cardBackground)
        } header: {
            // Edit icon is placed inline with the section title
            HStack {
                Text("Schedule")
                Spacer()
                Button {
                    driverProfileViewModel.openScheduleEditMode()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.brandAccent)
                }
            }
        }
    }

    private var pricingSection: some View {
        Section {
            pricingRow(label: "Morning Only", amount: driverProfileViewModel.pricingDetailsValues.morningOnlyMonthlyFee, dotColor: .statusWarning)
                .listRowBackground(Color.cardBackground)
            pricingRow(label: "Evening Only", amount: driverProfileViewModel.pricingDetailsValues.eveningOnlyMonthlyFee, dotColor: Color(hex: "#FF7B54"))
                .listRowBackground(Color.cardBackground)
            pricingRow(label: "Both Sessions", amount: driverProfileViewModel.pricingDetailsValues.bothSessionsMonthlyFee, dotColor: .brandAccent)
                .listRowBackground(Color.cardBackground)
        } header: {
            // Edit icon is placed inline with the section title
            HStack {
                Text("Monthly Pricing")
                Spacer()
                Button {
                    driverProfileViewModel.openPricingDetailsEditMode()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.brandAccent)
                }
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
        }
    }

    private func pricingRow(label: String, amount: Int, dotColor: Color) -> some View {
        HStack {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.textPrimary)
            Spacer()
            Text("Rs. \(amount.formatted())")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)
        }
    }

    private func stopBadge(labelText: String, badgeColor: Color) -> some View {
        Text(labelText)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(badgeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private func stopNumberBackgroundColor(index: Int, total: Int) -> Color {
        if index == 0 { return Color.statusActive.opacity(0.15) }
        if index == total - 1 { return Color.statusDanger.opacity(0.15) }
        return Color.brandAccent.opacity(0.12)
    }

    private func stopNumberForegroundColor(index: Int, total: Int) -> Color {
        if index == 0 { return .statusActive }
        if index == total - 1 { return .statusDanger }
        return .brandAccent
    }
}
