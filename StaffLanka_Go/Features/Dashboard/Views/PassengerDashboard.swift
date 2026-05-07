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
    @State private var showTripTracking = false

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
        .onAppear {
            passengerViewModel.startListening()
        }
        .fullScreenCover(isPresented: $showTripTracking) {
            if let trip = passengerViewModel.currentTrip,
               let tripId = trip.id,
               let service = passengerViewModel.currentService {
                PassengerTripTrackingView(
                    tripId: tripId,
                    routeData: nil,        // route fetched inside view via TripService
                    driverName: service.morning?.driverName ?? service.evening?.driverName ?? "Driver",
                    plateNumber: service.morning?.licensePlate ?? service.evening?.licensePlate ?? "—",
                    session: passengerViewModel.selectedTrip == .morning ? "Morning" : "Evening"
                )
            }
        }
    }

    // Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(passengerViewModel.greetingText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.textPrimary.opacity(0.65))
                    Text(passengerViewModel.userName.isEmpty ? "Passenger" : passengerViewModel.userName)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                }
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Button {} label: {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.brandAccent)
                            .frame(width: 44, height: 44)
                            .background(Color.brandAccent.opacity(0.13))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Circle().fill(Color.statusWarning).frame(width: 9, height: 9).offset(x: 1, y: -1)
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
                    [.foregroundColor: UIColor(Color.brandSecondary)], for: .selected)
                UISegmentedControl.appearance().setTitleTextAttributes(
                    [.foregroundColor: UIColor(Color.textSecondary)], for: .normal)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .padding(.top, 64)
        .background(Color.appBackground.ignoresSafeArea(edges: .top))
    }

    // Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 22) {
            if passengerViewModel.isLoading {
                loadingCard
            } else if let service = passengerViewModel.currentService {
                activeServiceCard(service)
            } else {
                noServiceCard
            }
            registerRouteCard   // always visible
        }
    }

    // Loading skeleton

    private var loadingCard: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10).fill(Color.cardBackground).frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 6).fill(Color.cardBackground).frame(width: 160, height: 14)
                RoundedRectangle(cornerRadius: 6).fill(Color.cardBackground).frame(width: 100, height: 12)
            }
            Spacer()
        }
        .padding(20)
        .background(Color.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // Active service card

    private func activeServiceCard(_ service: EnrolledService) -> some View {
        VStack(spacing: 0) {

            // ── Route header ──
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.brandAccent.opacity(0.12)).frame(width: 44, height: 44)
                    Image(systemName: "bus.fill").font(.system(size: 18)).foregroundStyle(Color.brandAccent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.routeName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(sessionBadgeLabel(service.session))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.brandAccent)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.brandAccent.opacity(0.12))
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(16)

            Divider().background(Color.divider)

            // ── Session info ──
            let sessionInfo = passengerViewModel.selectedTrip == .morning ? service.morning : service.evening
            if let info = sessionInfo {
                let isEvening = passengerViewModel.selectedTrip == .evening
                let fromLabel = isEvening ? service.routeEnd   : service.routeStart
                let toLabel   = isEvening ? service.routeStart : service.routeEnd
                VStack(spacing: 10) {
                    serviceInfoRow(icon: "location.fill",        label: "From",   value: fromLabel)
                    serviceInfoRow(icon: "mappin.circle.fill",    label: "To",     value: toLabel)
                    serviceInfoRow(icon: "person.fill",           label: "Driver", value: info.driverName)
                    serviceInfoRow(icon: info.vehicleType.lowercased() == "van" ? "car.fill" : "bus.fill",
                                   label: "Vehicle", value: "\(info.vehicleBrand) \(info.vehicleType)")
                    serviceInfoRow(icon: "rectangle.and.text.magnifyingglass", label: "Plate", value: info.licensePlate)
                    serviceInfoRow(icon: "clock.fill",            label: "Time",   value: "\(info.startTime) – \(info.endTime)")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }

            Divider().background(Color.divider)

            // ── Trip status + Track button ──
            tripStatusRow

            Divider().background(Color.divider)

            // ── Attendance section ──
            attendanceSection
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.statusActive.opacity(0.25), lineWidth: 1))
    }

    // ── Trip status + Track Driver button

    private var tripStatusRow: some View {
        HStack(spacing: 12) {
            // Status chip
            HStack(spacing: 5) {
                Circle()
                    .fill(passengerViewModel.isTripActive ? Color.statusActive : (passengerViewModel.isTripCompleted ? Color.textTertiary : Color.statusWarning))
                    .frame(width: 7, height: 7)
                Text(passengerViewModel.isTripActive ? "Trip Active"
                     : passengerViewModel.isTripCompleted ? "Trip Completed"
                     : "Awaiting Departure")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(passengerViewModel.isTripActive ? Color.statusActive : Color.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(passengerViewModel.isTripActive ? Color.statusActive.opacity(0.1) : Color.surfaceBackground)
            .clipShape(Capsule())

            Spacer()

            // Track Driver button — only enabled when trip is active
            Button {
                if passengerViewModel.isTripActive { showTripTracking = true }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "location.fill").font(.system(size: 11, weight: .semibold))
                    Text("Track Driver").font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(passengerViewModel.isTripActive ? Color.brandAccent : Color.textTertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(passengerViewModel.isTripActive ? Color.brandAccent.opacity(0.12) : Color.surfaceBackground)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(
                    passengerViewModel.isTripActive ? Color.brandAccent.opacity(0.3) : Color.divider,
                    lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(!passengerViewModel.isTripActive)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // ── Attendance section

    private var attendanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: passengerViewModel.isAttendanceLocked
                    ? "lock.fill"
                    : passengerViewModel.isAttendanceOutsideWindow ? "clock.slash" : "calendar.badge.checkmark")
                    .font(.system(size: 13))
                    .foregroundStyle(
                        passengerViewModel.isAttendanceOutsideWindow || passengerViewModel.isAttendanceLocked
                            ? Color.textTertiary : Color.brandAccent)
                Text(passengerViewModel.attendanceSectionTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        passengerViewModel.isAttendanceOutsideWindow || passengerViewModel.isAttendanceLocked
                            ? Color.textTertiary : Color.textPrimary)
                Spacer()
                if let att = passengerViewModel.currentAttendance {
                    let badgeLabel = att.status == "attending" ? "Attending"
                        : att.status == "not_sure" ? "Not Sure" : "Absent"
                    let badgeColor: Color = att.status == "attending" ? Color.statusActive
                        : att.status == "not_sure" ? Color.statusWarning : Color.statusDanger
                    Text(badgeLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(badgeColor)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(badgeColor.opacity(0.1))
                        .clipShape(Capsule())
                } else if !passengerViewModel.isAttendanceOutsideWindow {
                    Text("Not marked")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textTertiary)
                }
            }

            Text(passengerViewModel.attendanceWindowMessage)
                .font(.system(size: 11))
                .foregroundStyle(
                    passengerViewModel.isAttendanceOutsideWindow || passengerViewModel.isAttendanceLocked
                        ? Color.textTertiary : Color.textSecondary)

            if !passengerViewModel.isAttendanceOutsideWindow && !passengerViewModel.isAttendanceLocked {
                HStack(spacing: 8) {
                    attendanceButton(title: "Attending", icon: "checkmark.circle.fill",
                                     isSelected: passengerViewModel.currentAttendance?.status == "attending",
                                     color: Color.statusActive) {
                        passengerViewModel.markAttendance(status: "attending")
                    }
                    attendanceButton(title: "Not Sure", icon: "questionmark.circle.fill",
                                     isSelected: passengerViewModel.currentAttendance?.status == "not_sure",
                                     color: Color.statusWarning) {
                        passengerViewModel.markAttendance(status: "not_sure")
                    }
                    attendanceButton(title: "Absent", icon: "xmark.circle.fill",
                                     isSelected: passengerViewModel.currentAttendance?.status == "absent",
                                     color: Color.statusDanger) {
                        passengerViewModel.markAttendance(status: "absent")
                    }
                }
                .disabled(passengerViewModel.isMarkingAttendance)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .opacity(passengerViewModel.isAttendanceOutsideWindow ? 0.55 : 1)
    }

    private func attendanceButton(title: String, icon: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13))
                Text(title).font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? color : Color.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? color.opacity(0.12) : Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(
                isSelected ? color.opacity(0.35) : Color.divider, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // Helpers

    private func serviceInfoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(Color.brandAccent).frame(width: 18)
            Text(label).font(.system(size: 13)).foregroundStyle(Color.textTertiary).frame(width: 52, alignment: .leading)
            Text(value).font(.system(size: 13, weight: .medium)).foregroundStyle(Color.textPrimary)
            Spacer()
        }
    }

    private func sessionBadgeLabel(_ session: EnrolledSessionType) -> String {
        switch session {
        case .both:    return passengerViewModel.selectedTrip == .morning ? "Morning Session" : "Evening Session"
        case .morning: return "Morning Only"
        case .evening: return "Evening Only"
        }
    }

    // No-service placeholder

    private var noServiceCard: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color.brandAccent.opacity(0.13)).frame(width: 60, height: 60)
                Image(systemName: "bus.fill").font(.system(size: 24)).foregroundStyle(Color.brandAccent)
            }
            VStack(spacing: 4) {
                Text(passengerViewModel.noServiceTitle).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.textPrimary)
                Text(passengerViewModel.noServiceSubtitle).font(.system(size: 14)).foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center).lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30).padding(.horizontal, 20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // Browse routes card (always visible)

    private var registerRouteCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.brandAccent.opacity(0.13)).frame(width: 52, height: 52)
                    Image(systemName: "map.fill").font(.system(size: 22)).foregroundStyle(Color.brandAccent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Find Your Route").font(.system(size: 17, weight: .bold)).foregroundStyle(Color.textPrimary)
                    Text("Browse available routes and register for a service that fits your schedule.")
                        .font(.system(size: 13)).foregroundStyle(Color.textSecondary).lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider().background(Color.divider)

            VStack(spacing: 12) {
                stepRow(number: "1", text: "Search for routes near your pickup point")
                stepRow(number: "2", text: "Choose a route that matches your commute")
                stepRow(number: "3", text: "Submit a registration request to the driver")
            }

            Button { showRouteSearch = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").font(.system(size: 14, weight: .semibold))
                    Text("Browse Routes").font(.system(size: 15, weight: .semibold))
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
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.brandAccent.opacity(0.18), lineWidth: 1))
    }

    private func stepRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(Color.brandAccent.opacity(0.13)).frame(width: 26, height: 26)
                Text(number).font(.system(size: 12, weight: .bold)).foregroundStyle(Color.brandAccent)
            }
            Text(text).font(.system(size: 13)).foregroundStyle(Color.textSecondary).lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

#Preview("Dark Mode") {
    NavigationStack { PassengerDashboard() }.preferredColorScheme(.dark)
}
#Preview("Light Mode") {
    NavigationStack { PassengerDashboard() }.preferredColorScheme(.light)
}
