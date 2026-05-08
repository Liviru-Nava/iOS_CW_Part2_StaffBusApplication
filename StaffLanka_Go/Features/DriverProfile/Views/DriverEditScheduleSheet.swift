//
//  DriverEditScheduleSheet.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-23.
//

import SwiftUI

struct DriverEditScheduleSheet: View {
    @ObservedObject var driverProfileViewModel: DriverProfileViewModel
    @Environment(\.dismiss) private var dismissSheet

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.statusWarning.opacity(0.12))
                                .frame(width: 88, height: 88)
                            Image(systemName: "clock.fill")
                                .font(.system(size: 34))
                                .foregroundColor(.statusWarning)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    HStack {
                        Image(systemName: "sunrise.fill")
                            .foregroundColor(.statusWarning)
                        DatePicker("Morning Departure", selection: $driverProfileViewModel.editingMorningDepartureTime, displayedComponents: .hourAndMinute)
                            .foregroundColor(.textPrimary)
                            .tint(.brandAccent)
                    }
                    HStack {
                        Image(systemName: "sunset.fill")
                            .foregroundColor(Color(hex: "#FF7B54"))
                        DatePicker("Evening Departure", selection: $driverProfileViewModel.editingEveningDepartureTime, displayedComponents: .hourAndMinute)
                            .foregroundColor(.textPrimary)
                            .tint(.brandAccent)
                    }
                } header: {
                    Text("Edit Schedule")
                } footer: {
                    Text("Arrival times will automatically be estimated based on distance.")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { driverProfileViewModel.cancelScheduleEdits() }
                        .foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { driverProfileViewModel.saveScheduleEdits() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.brandAccent)
                }
            }
        }
    }
}
