//
//  PassengerDashboard.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-01.
//

import SwiftUI

struct PassengerDashboard: View {

    @StateObject private var passengerViewModel = PassengerDashboardViewModel()
    @State private var showRouteSearch = false

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
        .navigationDestination(isPresented: $showRouteSearch) {
            RouteSearchView()
        }
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
                            .foregroundStyle(Color.brandAccent)
                            .frame(width: 44, height: 44)
                            .background(Color.brandAccent.opacity(0.13))
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
                    [.foregroundColor: UIColor(Color.brandSecondary)],
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
                registerRouteCard
            }
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

            VStack(spacing: 4) {
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
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var registerRouteCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.brandAccent.opacity(0.13))
                        .frame(width: 52, height: 52)
                    Image(systemName: "map.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.brandAccent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Find Your Route")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Text("Browse available routes and register for a service that fits your schedule.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()
                .background(Color.divider)

            VStack(spacing: 12) {
                stepRow(number: "1", text: "Search for routes near your pickup point")
                stepRow(number: "2", text: "Choose a route that matches your commute")
                stepRow(number: "3", text: "Submit a registration request to the driver")
            }

            Button {
                showRouteSearch = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Browse Routes")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.brandAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.brandAccent.opacity(0.18), lineWidth: 1)
        )
    }

    private func stepRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.13))
                    .frame(width: 26, height: 26)
                Text(number)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.brandAccent)
            }
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        PassengerDashboard()
    }
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    NavigationStack {
        PassengerDashboard()
    }
    .preferredColorScheme(.light)
}
