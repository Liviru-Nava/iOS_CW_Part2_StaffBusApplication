import SwiftUI

struct DriverNotificationSettingsView: View {
    @AppStorage("muteTripAlerts") private var muteTripAlerts = false
    @AppStorage("mutePassengerAlerts") private var mutePassengerAlerts = false
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(
                    get: { !muteTripAlerts },
                    set: { muteTripAlerts = !$0 }
                )) {
                    HStack(spacing: 12) {
                        profileIconBadge(systemIconName: "bus.fill", badgeColor: Color.statusWarning)
                        Text("Trip Status Alerts")
                            .font(.system(size: 15))
                            .foregroundColor(Color.textPrimary)
                    }
                }
                .tint(Color.brandAccent)
                .listRowBackground(Color.cardBackground)
                
                Toggle(isOn: Binding(
                    get: { !mutePassengerAlerts },
                    set: { mutePassengerAlerts = !$0 }
                )) {
                    HStack(spacing: 12) {
                        profileIconBadge(systemIconName: "person.3.fill", badgeColor: Color.brandAccent)
                        Text("Passenger Boarding Alerts")
                            .font(.system(size: 15))
                            .foregroundColor(Color.textPrimary)
                    }
                }
                .tint(Color.brandAccent)
                .listRowBackground(Color.cardBackground)
            } header: {
                Text("Push Notifications")
                    .foregroundColor(Color.textSecondary)
            } footer: {
                Text("Control which app alerts you receive as local notifications while driving.")
                    .font(.system(size: 13))
                    .foregroundColor(Color.textTertiary)
                    .padding(.top, 8)
            }
        }
        .listStyle(.insetGrouped)
        .background(Color.appBackground)
        .scrollContentBackground(.hidden)
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Extracted helper matching Profile design snippet
    private func profileIconBadge(systemIconName: String, badgeColor: Color) -> some View {
        Image(systemName: systemIconName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 30, height: 30)
            .background(badgeColor)
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}
