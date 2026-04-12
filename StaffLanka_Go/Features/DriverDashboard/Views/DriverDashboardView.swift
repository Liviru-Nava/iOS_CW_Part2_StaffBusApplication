//
//  DriverDashboardView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-08.
//

import SwiftUI
import MapKit

struct DriverDashboardView: View {

    @StateObject private var dashboardViewModel = DriverDashboardViewModel()
    @State private var showRouteMapFullScreen: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                greetingHeaderSection
                mainContentSection
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 56)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .fullScreenCover(isPresented: $showRouteMapFullScreen) {
            RouteMapFullscreenView(isPresented: $showRouteMapFullScreen, sessionType: dashboardViewModel.selectedSessionType)
        }
    }

    private var greetingHeaderSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dashboardViewModel.greetingText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.textPrimary.opacity(0.65))
                    Text(dashboardViewModel.driverFullName)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    HStack(spacing: 5) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.brandAccent)
                        Text("\(dashboardViewModel.totalEnrolledPassengerCount) passengers enrolled")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }
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

            Picker("Session", selection: $dashboardViewModel.selectedSessionType) {
                Text("Morning").tag(DriverDashboardViewModel.SessionType.morning)
                Text("Evening").tag(DriverDashboardViewModel.SessionType.evening)
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
        .background(Color.appBackground)
    }

    private var mainContentSection: some View {
        VStack(spacing: 20) {
            tripStatusCard
            
            switch dashboardViewModel.currentTripState {
            case .beforeTrip:
                attendanceConfirmationSection
            case .duringTrip:
                activeStopsListSection
            case .afterTrip:
                tripSummarySection
            }
        }
    }

    private var tripStatusCard: some View {
        Group {
            switch dashboardViewModel.currentTripState {
            case .beforeTrip:
                beforeTripStatusCard
            case .duringTrip:
                duringTripStatusCard
            case .afterTrip:
                afterTripStatusCard
            }
        }
    }

    private var beforeTripStatusCard: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Upcoming Trip")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                    Text(dashboardViewModel.selectedSessionType == .morning ? "Morning Session" : "Evening Session")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.statusWarning.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: dashboardViewModel.selectedSessionType == .morning ? "sunrise.fill" : "moon.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.statusWarning)
                }
            }

            HStack(spacing: 0) {
                tripTimeInfoBlock(
                    label: "Scheduled Start",
                    timeValue: dashboardViewModel.currentSessionScheduledStartTime,
                    iconName: "clock.fill",
                    accentColor: Color.brandAccent
                )
                Spacer()
                Rectangle()
                    .fill(Color.divider)
                    .frame(width: 1, height: 40)
                Spacer()
                tripTimeInfoBlock(
                    label: "Est. End Time",
                    timeValue: dashboardViewModel.currentSessionEstimatedEndTime,
                    iconName: "flag.checkered",
                    accentColor: Color.statusActive
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        dashboardViewModel.startTrip()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(dashboardViewModel.isStartTripButtonEnabled ? "Start Trip" : "Not Available Yet")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        dashboardViewModel.isStartTripButtonEnabled
                        ? LinearGradient.brand
                        : LinearGradient(colors: [Color.statusInactive.opacity(0.45)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(!dashboardViewModel.isStartTripButtonEnabled)

                Button {
                    showRouteMapFullScreen = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "scope")
                            .font(.system(size: 12, weight: .semibold))
                        Text("View Live Route")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Color.brandAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.brandAccent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.brandAccent.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            if !dashboardViewModel.isStartTripButtonEnabled {
                HStack(spacing: 5) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.statusWarning)
                    Text("Start is available within the scheduled window only")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
        .padding(18)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.divider, lineWidth: 1)
        )
    }

    private func tripTimeInfoBlock(label: String, timeValue: String, iconName: String, accentColor: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 10))
                    .foregroundStyle(accentColor)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
            Text(timeValue)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    private var duringTripStatusCard: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.statusActive)
                            .frame(width: 8, height: 8)
                        Text("Trip In Progress")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.statusActive)
                    }
                    Text(dashboardViewModel.selectedSessionType == .morning ? "Morning Session" : "Evening Session")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.statusActive.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bus.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.statusActive)
                }
            }

            VStack(spacing: 10) {
                stopProgressRow(
                    label: "Current Stop",
                    stopName: dashboardViewModel.currentStopName,
                    badgeColor: Color.brandAccent,
                    iconName: "location.fill"
                )
                stopProgressRow(
                    label: "Next Stop",
                    stopName: dashboardViewModel.nextStopName,
                    badgeColor: Color.statusWarning,
                    iconName: "arrow.right.circle.fill"
                )
            }

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    dashboardViewModel.finishTrip()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Finish Trip")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.statusActive.opacity(0.85), Color.statusActive],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.statusActive.opacity(0.3), lineWidth: 1.5)
        )
    }

    private func stopProgressRow(label: String, stopName: String, badgeColor: Color, iconName: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(badgeColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                Text(stopName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var afterTripStatusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.statusActive.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.statusActive)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Trip Completed")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.brandAccent)
                    Text("\(dashboardViewModel.totalPassengersForCurrentSummary) passengers transported")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Spacer()
        }
        .padding(18)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.statusActive.opacity(0.3), lineWidth: 1.5)
        )
    }

//    private var mapPreviewSection: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Route Map")
//                .font(.system(size: 16, weight: .semibold))
//                .foregroundStyle(Color.textPrimary)
//
//            ZStack {
//                RoundedRectangle(cornerRadius: 14)
//                    .fill(Color.cardBackground)
//                    .frame(height: 200)
//
//                VStack(spacing: 10) {
//                    ZStack {
//                        Circle()
//                            .fill(Color.brandAccent.opacity(0.13))
//                            .frame(width: 52, height: 52)
//                        Image(systemName: "map.fill")
//                            .font(.system(size: 22))
//                            .foregroundStyle(Color.brandAccent)
//                    }
//                    Text("Map Preview")
//                        .font(.system(size: 14, weight: .medium))
//                        .foregroundStyle(Color.textSecondary)
//                    Text("Route visualization will appear here")
//                        .font(.system(size: 12))
//                        .foregroundStyle(Color.textTertiary)
//                }
//            }
//            .overlay(
//                RoundedRectangle(cornerRadius: 14)
//                    .strokeBorder(Color.divider, lineWidth: 1)
//            )
//        }
//    }

    private var attendanceConfirmationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Passenger Attendance")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(dashboardViewModel.currentSessionAttendanceStops.count) stops")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }

            VStack(spacing: 8) {
                ForEach(dashboardViewModel.currentSessionAttendanceStops) { attendanceStop in
                    attendanceStopRow(attendanceStop: attendanceStop)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.divider, lineWidth: 1)
        )
    }

    private func attendanceStopRow(attendanceStop: DriverDashboardViewModel.AttendanceStopInfo) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(attendanceStop.confirmedPassengerCount > 0 ? Color.brandAccent.opacity(0.13) : Color.statusInactive.opacity(0.13))
                    .frame(width: 36, height: 36)
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(attendanceStop.confirmedPassengerCount > 0 ? Color.brandAccent : Color.statusInactive)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(attendanceStop.stopName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Text(attendanceStop.confirmedPassengerCount == 0 ? "No passengers confirmed" : "\(attendanceStop.confirmedPassengerCount) passenger\(attendanceStop.confirmedPassengerCount == 1 ? "" : "s") confirmed")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            if attendanceStop.confirmedPassengerCount > 0 {
                Text("\(attendanceStop.confirmedPassengerCount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.brandAccent)
                    .frame(width: 28, height: 28)
                    .background(Color.brandAccent.opacity(0.13))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var activeStopsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Stops")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(dashboardViewModel.currentSessionActiveStops.count) stops")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }

            VStack(spacing: 8) {
                ForEach(Array(dashboardViewModel.currentSessionActiveStops.enumerated()), id: \.element.id) { stopIndex, activeStop in
                    activeStopRow(stopIndex: stopIndex, activeStop: activeStop)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.statusActive.opacity(0.25), lineWidth: 1)
        )
    }

    private func activeStopRow(stopIndex: Int, activeStop: DriverDashboardViewModel.RouteStopInfo) -> some View {
        let isCurrentActiveStop = activeStop.stopName == dashboardViewModel.currentStopName
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCurrentActiveStop ? Color.brandAccent.opacity(0.18) : Color.surfaceBackground)
                    .frame(width: 34, height: 34)
                Text("\(stopIndex + 1)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isCurrentActiveStop ? Color.brandAccent : Color.textTertiary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(activeStop.stopName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isCurrentActiveStop ? Color.textPrimary : Color.textSecondary)
                Text("\(activeStop.passengerCount) passenger\(activeStop.passengerCount == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }
            Spacer()
            stopStatusBadge(isCompleted: activeStop.isCompleted, isCurrentStop: isCurrentActiveStop)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isCurrentActiveStop ? Color.brandAccent.opacity(0.07) : Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isCurrentActiveStop ? Color.brandAccent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private func stopStatusBadge(isCompleted: Bool, isCurrentStop: Bool) -> some View {
        let badgeLabel: String
        let badgeTextColor: Color
        let badgeBackgroundColor: Color

        if isCompleted {
            badgeLabel = "Done"
            badgeTextColor = Color.statusActive
            badgeBackgroundColor = Color.statusActive.opacity(0.13)
        } else if isCurrentStop {
            badgeLabel = "Current"
            badgeTextColor = Color.brandAccent
            badgeBackgroundColor = Color.brandAccent.opacity(0.13)
        } else {
            badgeLabel = "Pending"
            badgeTextColor = Color.statusWarning
            badgeBackgroundColor = Color.statusWarning.opacity(0.13)
        }

        return Text(badgeLabel)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(badgeTextColor)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(badgeBackgroundColor)
            .clipShape(Capsule())
    }

    private var tripSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Trip Summary")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
            }

            summaryViewToggle

            switch dashboardViewModel.selectedSummaryViewType {
            case .textSummary:
                textSummaryContent
            case .mapSummary:
                mapSummaryContent
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.divider, lineWidth: 1)
        )
    }

    private var summaryViewToggle: some View {
        HStack(spacing: 0) {
            summaryToggleButton(label: "Stop Details", iconName: "list.bullet", summaryType: .textSummary)
            summaryToggleButton(label: "Map View", iconName: "map", summaryType: .mapSummary)
        }
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.divider, lineWidth: 1)
        )
    }

    private func summaryToggleButton(label: String, iconName: String, summaryType: DriverDashboardViewModel.SummaryViewType) -> some View {
        let isSelectedType = dashboardViewModel.selectedSummaryViewType == summaryType
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                dashboardViewModel.selectedSummaryViewType = summaryType
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: iconName)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelectedType ? Color.brandAccent : Color.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(isSelectedType ? Color.brandAccent.opacity(0.13) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(3)
        }
        .buttonStyle(.plain)
    }

    private var textSummaryContent: some View {
        VStack(spacing: 8) {
            HStack {
                summaryStatBlock(value: "\(dashboardViewModel.currentSessionSummaryStopRecords.count)", label: "Stops Visited", iconName: "mappin.circle.fill", accentColor: Color.brandAccent)
                Spacer()
                Rectangle().fill(Color.divider).frame(width: 1, height: 40)
                Spacer()
                summaryStatBlock(value: "\(dashboardViewModel.totalPassengersForCurrentSummary)", label: "Passengers", iconName: "person.2.fill", accentColor: Color.statusActive)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 6) {
                ForEach(dashboardViewModel.currentSessionSummaryStopRecords) { summaryStopRecord in
                    tripSummaryStopRow(summaryStopRecord: summaryStopRecord)
                }
            }
        }
    }

    private func summaryStatBlock(value: String, label: String, iconName: String, accentColor: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 10))
                    .foregroundStyle(accentColor)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    private func tripSummaryStopRow(summaryStopRecord: DriverDashboardViewModel.TripSummaryStopRecord) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.statusActive.opacity(0.13))
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.statusActive)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(summaryStopRecord.stopName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Text("Arrived \(summaryStopRecord.arrivalTime)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary)
            }
            Spacer()
            HStack(spacing: 3) {
                Image(systemName: "person.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.brandAccent)
                Text("\(summaryStopRecord.passengersPickedUp)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.brandAccent)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var mapSummaryContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.surfaceBackground)
                .frame(height: 200)

            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.statusActive.opacity(0.13))
                        .frame(width: 52, height: 52)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.statusActive)
                }
                Text("Route Completed")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("Full route visualization will appear here")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.statusActive.opacity(0.25), lineWidth: 1)
        )
    }
}

struct RouteMapFullscreenView: View {
    @Binding var isPresented: Bool
    var sessionType: DriverDashboardViewModel.SessionType
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )

    var body: some View {
        ZStack(alignment: .top) {
            ZStack {
                Rectangle()
                    .fill(Color.appBackground)
                    .ignoresSafeArea()
                VStack(spacing: 18) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.surfaceBackground)
                        .frame(height: 280)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Color.brandAccent)
                                Text("Route Map Preview")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Color.textPrimary)
                                Text("This is a fullscreen placeholder map. Replace with MapKit when needed.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.textTertiary)
                            }
                            .padding(24)
                        )

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(mockAnnotations) { item in
                            HStack(spacing: 10) {
                                Circle().fill(item.tint).frame(width: 10, height: 10)
                                Text(item.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.textPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.top, 80)
            }

            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.textPrimary.opacity(0.9))
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
                .padding(.top, 44)
            }
        }
    }

    private var mockAnnotations: [MapAnnotationItem] {
        if sessionType == .morning {
            return [
                MapAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: 6.8936, longitude: 79.9009), title: "Nugegoda Junction", tint: .brandAccent),
                MapAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: 6.8400, longitude: 79.9308), title: "Maharagama Town", tint: .brandAccent),
                MapAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), title: "Fort Railway Station", tint: .brandAccent),
            ]
        } else {
            return [
                MapAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), title: "World Trade Center", tint: .brandAccent),
                MapAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: 6.9279, longitude: 79.8572), title: "Borella", tint: .brandAccent),
            ]
        }
    }

    struct MapAnnotationItem: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let title: String
        let tint: Color
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        DriverDashboardView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    NavigationStack {
        DriverDashboardView()
    }
    .preferredColorScheme(.light)
}
