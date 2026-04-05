//
//  PassengerMainView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-01.
//

import SwiftUI

struct PassengerNavigationBar: View {

    @State private var selectedTab: Int = 0
    @StateObject private var profileViewModel = PassengerProfileViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PassengerDashboard()
            }
            .tabItem {
                Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
            }
            .tag(0)

            NavigationStack {
                PassengerTripHistoryView()
            }
            .tabItem {
                Label("History", systemImage: selectedTab == 1 ? "clock.fill" : "clock")
            }
            .tag(1)

            NavigationStack {
                PassengerCostTrackingView()
            }
            .tabItem {
                Label("Costs", systemImage: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
            }
            .tag(2)

            NavigationStack {
                PassengerProfileView(profileViewModel: profileViewModel)
            }
            .tabItem {
                Label("Profile", systemImage: selectedTab == 3 ? "person.fill" : "person")
            }
            .tag(3)
        }
        .tint(Color.brandAccent)
    }
}

#Preview("Dark") {
    PassengerNavigationBar()
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    PassengerNavigationBar()
        .preferredColorScheme(.light)
}
