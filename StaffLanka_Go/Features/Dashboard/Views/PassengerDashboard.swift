//
//  PassengerDashboard.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-01.
//

import SwiftUI

struct PassengerDashboard: View {

    @StateObject private var passengerViewModel = PassengerDashboardViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                contentSection
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(passengerViewModel.greetingText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.textPrimary.opacity(0.65))
                    Text(passengerViewModel.userName)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                }

                Spacer()

                ZStack(alignment: .topTrailing) {
                    Button {
                    } label: {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Circle()
                        .fill(Color.statusWarning)
                        .frame(width: 9, height: 9)
                        .offset(x: 1, y: -1)
                }
            }

            Picker("Trip", selection: $passengerViewModel.selectedTrip) {
                Text("Morning Trip").tag(PassengerDashboardViewModel.TripTab.morning)
                Text("Evening Trip").tag(PassengerDashboardViewModel.TripTab.evening)
            }
            .pickerStyle(.segmented)
            .onAppear {
                UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.white
                UISegmentedControl.appearance().backgroundColor = UIColor(white: 1, alpha: 0.12)
                UISegmentedControl.appearance().setTitleTextAttributes(
                    [.foregroundColor: UIColor(Color.brandPrimary)],
                    for: .selected
                )
                UISegmentedControl.appearance().setTitleTextAttributes(
                    [.foregroundColor: UIColor(Color.textSecondary)],
                    for: .normal
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .padding(.top, 64)
        .background(Color.appBackground.ignoresSafeArea(edges: .top))
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 22) {
            if !passengerViewModel.activeService {
                noServiceCard
            }
            findRouteSection
        }
    }

    private var noServiceCard: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.brandAccent.opacity(0.13))
                    .frame(width: 60, height: 60)
                Image(systemName: "bus.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.brandAccent)
            }

            VStack(spacing: 5) {
                Text(passengerViewModel.noServiceTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Text(passengerViewModel.noServiceSubtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var findRouteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(passengerViewModel.findRouteTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                locationRow(
                    icon: "location.fill",
                    iconColor: Color.brandAccent,
                    label: "PICKUP LOCATION",
                    placeholder: "Select Starting Point",
                    binding: $passengerViewModel.pickupLocation
                )

                Rectangle()
                    .fill(Color.divider)
                    .frame(height: 0.5)
                    .padding(.horizontal,12)

                locationRow(
                    icon: "mappin.circle.fill",
                    iconColor: Color.brandAccent,
                    label: "DROP-OFF LOCATION",
                    placeholder: "Select Destination",
                    binding: $passengerViewModel.dropoffLocation
                )
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Button {
                passengerViewModel.searchRoutes()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Search Routes")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    (passengerViewModel.pickupLocation.isEmpty || passengerViewModel.dropoffLocation.isEmpty)
                    ?Color.statusInactive.opacity(0.35)
                    : Color.brandPrimary
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(passengerViewModel.pickupLocation.isEmpty || passengerViewModel.dropoffLocation.isEmpty)
        }
    }

    private func locationRow(
        icon: String,
        iconColor: Color,
        label: String,
        placeholder: String,
        binding: Binding<String>
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)

                Text(binding.wrappedValue.isEmpty ? placeholder : binding.wrappedValue)
                    .font(.system(size: 15))
                    .foregroundStyle(binding.wrappedValue.isEmpty ? Color.textSecondary : Color.textPrimary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
    }
}

#Preview {
    PassengerDashboard()
        .preferredColorScheme(.dark)
}
