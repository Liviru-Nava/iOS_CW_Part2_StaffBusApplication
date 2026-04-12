//
//  DriverTripDetailView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-09.

import SwiftUI

struct DriverTripDetailView: View {

    let tripRecord: DriverHistoryTripRecord
    @State private var selectedDetailDisplayMode: DriverTripDetailDisplayMode = .textView

    private var sessionDisplayColor: Color {
        tripRecord.sessionType == .morning ? Color.statusWarning : Color.brandAccent
    }

    private var sessionIconName: String {
        tripRecord.sessionType == .morning ? "sunrise.fill" : "moon.fill"
    }

    private var completionStatusColor: Color {
        tripRecord.completionStatus == .completed ? Color.statusActive : Color.statusWarning
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                tripHeaderCard
                    .padding(.top, 8)
                displayModeToggle
                performanceSummarySection
                if selectedDetailDisplayMode == .textView {
                    stopsTimelineSection
                    passengerAttendanceSection
                } else {
                    mapPlaceholderSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 48)
        }
        .background(Color.appBackground)
        .navigationTitle(tripRecord.tripDate.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var tripHeaderCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient.brand
                .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: sessionIconName)
                            .font(.system(size: 22))
                            .foregroundStyle(Color.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(tripRecord.sessionType == .morning ? "Morning Trip" : "Evening Trip")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.white)
                        Text(tripRecord.tripDate.formatted(date: .long, time: .omitted))
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.70))
                    }

                    Spacer()

                    completionStatusHeaderBadge
                }

                Rectangle()
                    .fill(Color.white.opacity(0.18))
                    .frame(height: 1)

                HStack(spacing: 0) {
                    headerTimeCell(labelText: "Start", timeText: tripRecord.scheduledStartTime)
                    Rectangle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 1, height: 28)
                        .padding(.horizontal, 16)
                    headerTimeCell(labelText: "End", timeText: tripRecord.actualEndTime)
                    Rectangle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 1, height: 28)
                        .padding(.horizontal, 16)
                    headerTimeCell(labelText: "Duration", timeText: "\(tripRecord.performanceSummary.tripDurationInMinutes) min")
                    Spacer()
                }
            }
            .padding(18)
        }
    }

    private var completionStatusHeaderBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: tripRecord.completionStatus == .completed ? "checkmark.circle.fill" : "clock.fill")
                .font(.system(size: 11))
            Text(tripRecord.completionStatus.rawValue)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.18))
        .clipShape(Capsule())
    }

    private func headerTimeCell(labelText: String, timeText: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(labelText)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.60))
            Text(timeText)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
        }
    }

    private var displayModeToggle: some View {
        HStack(spacing: 0) {
            displayModeToggleButton(
                labelText: "Stop Details",
                iconName: "list.bullet",
                targetMode: .textView
            )
            displayModeToggleButton(
                labelText: "Map View",
                iconName: "map.fill",
                targetMode: .mapView
            )
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.divider, lineWidth: 1)
        )
    }

    private func displayModeToggleButton(labelText: String, iconName: String, targetMode: DriverTripDetailDisplayMode) -> some View {
        let isActiveMode = selectedDetailDisplayMode == targetMode
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedDetailDisplayMode = targetMode
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .semibold))
                Text(labelText)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(isActiveMode ? Color.brandAccent : Color.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(isActiveMode ? Color.brandAccent.opacity(0.13) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 11))
        }
        .buttonStyle(.plain)
    }

    private var performanceSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeaderLabel(titleText: "Trip Performance", iconName: "chart.bar.fill")

            HStack(spacing: 12) {
                performanceStatCard(
                    iconName: "mappin.circle.fill",
                    iconColor: Color.brandAccent,
                    statValue: "\(tripRecord.performanceSummary.totalStopCount)",
                    statLabel: "Total Stops"
                )
                performanceStatCard(
                    iconName: "checkmark.circle.fill",
                    iconColor: Color.statusActive,
                    statValue: "\(tripRecord.performanceSummary.completedStopCount)",
                    statLabel: "Completed"
                )
                performanceStatCard(
                    iconName: "person.2.fill",
                    iconColor: Color.statusWarning,
                    statValue: "\(tripRecord.performanceSummary.totalPassengersPickedUp)",
                    statLabel: "Passengers"
                )
                performanceStatCard(
                    iconName: "timer",
                    iconColor: Color.statusInfo,
                    statValue: "\(tripRecord.performanceSummary.tripDurationInMinutes)m",
                    statLabel: "Duration"
                )
            }
        }
    }

    private func performanceStatCard(iconName: String, iconColor: Color, statValue: String, statLabel: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.13))
                    .frame(width: 38, height: 38)
                Image(systemName: iconName)
                    .font(.system(size: 15))
                    .foregroundStyle(iconColor)
            }
            VStack(spacing: 1) {
                Text(statValue)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text(statLabel)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var stopsTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeaderLabel(titleText: "Stops Timeline", iconName: "point.topleft.down.to.point.bottomright.curvepath.fill")

            VStack(spacing: 0) {
                ForEach(Array(tripRecord.stopsTimeline.enumerated()), id: \.element.id) { index, stopRecord in
                    stopTimelineRow(
                        stopRecord: stopRecord,
                        isFirstStop: index == 0,
                        isLastStop: index == tripRecord.stopsTimeline.count - 1
                    )
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func stopTimelineRow(stopRecord: DriverTripStopRecord, isFirstStop: Bool, isLastStop: Bool) -> some View {
        let isCompleted = stopRecord.stopStatus == .completed
        let dotColor: Color = isCompleted ? Color.statusActive : Color.statusInactive

        return HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                if !isFirstStop {
                    Rectangle()
                        .fill(Color.divider)
                        .frame(width: 2, height: 16)
                } else {
                    Spacer().frame(height: 16)
                }
                ZStack {
                    Circle()
                        .fill(dotColor.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Circle()
                        .fill(dotColor)
                        .frame(width: 10, height: 10)
                }
                if !isLastStop {
                    Rectangle()
                        .fill(Color.divider)
                        .frame(width: 2)
                        .frame(minHeight: 20)
                }
            }
            .frame(width: 52)
            .padding(.leading, 14)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(stopRecord.stopName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isCompleted ? Color.textPrimary : Color.textTertiary)
                    Text(stopRecord.timeReached)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.vertical, 16)

                Spacer()

                stopStatusPill(isCompleted: isCompleted)
                    .padding(.trailing, 16)
            }
        }
    }

    private func stopStatusPill(isCompleted: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "minus.circle.fill")
                .font(.system(size: 10))
            Text(isCompleted ? "Completed" : "Skipped")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(isCompleted ? Color.statusActive : Color.statusInactive)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isCompleted ? Color.statusActive : Color.statusInactive).opacity(0.12))
        .clipShape(Capsule())
    }

    private var passengerAttendanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeaderLabel(titleText: "Passenger Pickups", iconName: "person.2.fill")

            VStack(spacing: 0) {
                ForEach(Array(tripRecord.passengerPickupList.enumerated()), id: \.element.id) { index, passengerRecord in
                    passengerPickupRow(passengerRecord: passengerRecord)
                    if index < tripRecord.passengerPickupList.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func passengerPickupRow(passengerRecord: DriverTripPassengerPickupRecord) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.12))
                    .frame(width: 38, height: 38)
                Text(String(passengerRecord.passengerFullName.prefix(1)))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.brandAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(passengerRecord.passengerFullName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                HStack(spacing: 5) {
                    Image(systemName: "mappin.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.brandAccent)
                    Text(passengerRecord.boardingStopName)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                Text("Boarded")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(Color.statusActive)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.statusActive.opacity(0.11))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var mapPlaceholderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeaderLabel(titleText: "Route Map", iconName: "map.fill")

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .frame(height: 320)

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.brandAccent.opacity(0.12))
                            .frame(width: 64, height: 64)
                        Image(systemName: "map.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color.brandAccent)
                    }
                    VStack(spacing: 6) {
                        Text("Route Visualisation")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                        Text("Interactive map with route and stops")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.divider, lineWidth: 1)
            )
        }
    }

    private func sectionHeaderLabel(titleText: String, iconName: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.brandAccent)
            Text(titleText)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.textPrimary)
        }
    }
}

#Preview("Dark") {
    NavigationStack {
        DriverTripDetailView(tripRecord: DriverHistoryTripRecord.mockDriverTrips[0])
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    NavigationStack {
        DriverTripDetailView(tripRecord: DriverHistoryTripRecord.mockDriverTrips[0])
    }
    .preferredColorScheme(.light)
}
