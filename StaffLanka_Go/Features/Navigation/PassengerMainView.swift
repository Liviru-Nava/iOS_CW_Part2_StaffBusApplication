import SwiftUI

struct PassengerNavigationBar: View {

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            PassengerDashboard()
                .tabItem {
                    Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            placeholderView(title: "History", icon: "clock")
                .tabItem {
                    Label("History", systemImage: selectedTab == 1 ? "clock.fill" : "clock")
                }
                .tag(1)

            placeholderView(title: "Costs", icon: "chart.bar")
                .tabItem {
                    Label("Costs", systemImage: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                }
                .tag(2)

            placeholderView(title: "Profile", icon: "person")
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 3 ? "person.fill" : "person")
                }
                .tag(3)
        }
        .tint(Color.brandAccent)
    }

    private func placeholderView(title: String, icon: String) -> some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(Color.textTertiary)
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("Coming soon")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
            }
        }
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
