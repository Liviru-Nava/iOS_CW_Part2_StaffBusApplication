//
//  DriverNavigationBar.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-08.
//

import SwiftUI

struct DriverNavigationBar: View {

    @State private var selectedDriverTab: Int = 0

    var body: some View {
        TabView(selection: $selectedDriverTab) {
            NavigationStack {
                DriverDashboardView()
            }
            .tabItem {
                Label("Home", systemImage: selectedDriverTab == 0 ? "house.fill" : "house")
            }
            .tag(0)

            NavigationStack {
                DriverEarningsView()
            }
            .tabItem {
                Label("Earnings", systemImage: selectedDriverTab == 1 ? "banknote.fill" : "banknote")
            }
            .tag(1)

            NavigationStack {
                DriverTripHistoryView()
            }
            .tabItem {
                Label("History", systemImage: selectedDriverTab == 2 ? "clock.fill" : "clock")
            }
            .tag(2)

            NavigationStack {
                DriverProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: selectedDriverTab == 3 ? "person.fill" : "person")
            }
            .tag(3)
        }
        .tint(Color.brandAccent)
    }
}


struct DriverTripHistoryComingSoonView: View {
    var body: some View {
        DriverComingSoonView(
            pageTitle: "Trip History",
            featureIconName: "clock.arrow.circlepath",
            featureHeadline: "Trip History",
            featureDescription: "Review all your completed trips with full details including passenger counts, route summaries, and timestamps."
        )
    }
}

struct DriverProfileComingSoonView: View {
    var body: some View {
        DriverComingSoonView(
            pageTitle: "Profile",
            featureIconName: "person.crop.circle.fill",
            featureHeadline: "Driver Profile",
            featureDescription: "Manage your personal information, vehicle details, license documents, and account preferences all in one place."
        )
    }
}

private struct DriverComingSoonView: View {
    let pageTitle: String
    let featureIconName: String
    let featureHeadline: String
    let featureDescription: String

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.brandAccent.opacity(0.12))
                        .frame(width: 110, height: 110)
                    Image(systemName: featureIconName)
                        .font(.system(size: 44))
                        .foregroundStyle(Color.brandAccent)
                }

                VStack(spacing: 12) {
                    Text(featureHeadline)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)

                    Text("Coming Soon")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.brandAccent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(Color.brandAccent.opacity(0.13))
                        .clipShape(Capsule())

                    Text(featureDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }

                Spacer()
            }
        }
        .navigationTitle(pageTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Dark") {
    DriverNavigationBar()
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    DriverNavigationBar()
        .preferredColorScheme(.light)
}
