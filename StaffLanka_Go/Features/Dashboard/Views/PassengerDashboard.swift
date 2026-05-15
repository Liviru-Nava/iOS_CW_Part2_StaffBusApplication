//
//  PassengerDashboard.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-01.
//

import SwiftUI
import CoreData
import FirebaseAuth

struct PassengerDashboard: View {

    @StateObject private var passengerViewModel = PassengerDashboardViewModel()
    @State private var showRouteSearch = false
    @State private var showTripTracking = false
    @State private var showPassengerNotifications = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NotificationEntity.timestamp, ascending: false)],
        animation: .default
    )
    private var allStoredNotifications: FetchedResults<NotificationEntity>

    private var unreadNotificationCountForCurrentUser: Int {
        let currentFirebaseUserId = Auth.auth().currentUser?.uid ?? ""
        return allStoredNotifications.filter { $0.userId == currentFirebaseUserId && !$0.isRead }.count
    }

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
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationDestination(isPresented: $showRouteSearch) {
            RouteSearchView()
        }
        .navigationDestination(isPresented: $showPassengerNotifications) {
            PassengerNotificationsView()
        }
        .onAppear {
            passengerViewModel.startListening()
        }
        .fullScreenCover(isPresented: $showTripTracking) {
            if let trip = passengerViewModel.currentTrip,
               let tripId = trip.id,
               let service = passengerViewModel.currentService {

                let selectedSessionInfo = passengerViewModel.selectedTrip == .morning
                    ? service.morning
                    : service.evening

                PassengerTripTrackingView(
                    tripId: tripId,
                    routeData: nil,
                    driverName: selectedSessionInfo?.driverName ?? "Driver",
                    plateNumber: selectedSessionInfo?.licensePlate ?? "—",
                    session: passengerViewModel.selectedTrip == .morning ? "Morning" : "Evening",
                    passengerPickupStopName: service.routeStart,
                    passengerDropOffStopName: service.routeEnd,
                    passengerFullName: passengerViewModel.userName
                )
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(passengerViewModel.greetingText)
                        .font(.appCaption)
                        .foregroundStyle(Color.textPrimary.opacity(0.65))
                    Text(passengerViewModel.userName.isEmpty ? "Passenger" : passengerViewModel.userName)
                        .font(.appLargeTitle)
                        .foregroundStyle(Color.textPrimary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(passengerViewModel.greetingText), \(passengerViewModel.userName.isEmpty ? "Passenger" : passengerViewModel.userName)")

                Spacer()

                ZStack(alignment: .topTrailing) {
                    Button {
                        showPassengerNotifications = true
                    } label: {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.brandAccent)
                            .frame(width: 44, height: 44)
                            .background(Color.brandAccent.opacity(0.13))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(unreadNotificationCountForCurrentUser > 0
                        ? "Notifications, \(unreadNotificationCountForCurrentUser) unread"
                        : "Notifications")
                    .accessibilityHint("Opens your notification centre")

                    if unreadNotificationCountForCurrentUser > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.statusWarning)
                                .frame(width: unreadNotificationCountForCurrentUser > 9 ? 18 : 14, height: 14)
                            if unreadNotificationCountForCurrentUser > 1 {
                                Text(unreadNotificationCountForCurrentUser > 99 ? "99+" : "\(unreadNotificationCountForCurrentUser)")
                                    .font(.appCaption2Bold)
                                    .foregroundStyle(.white)
                            }
                        }
                        .offset(x: 2, y: -2)
                        .accessibilityHidden(true)
                    }
                }
            }

            Picker("Trip session", selection: $passengerViewModel.selectedTrip) {
                Text("Morning Trip").tag(PassengerDashboardViewModel.TripTab.morning)
                Text("Evening Trip").tag(PassengerDashboardViewModel.TripTab.evening)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Trip session selector")
            .accessibilityHint("Select morning or evening trip")
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

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 22) {
            if passengerViewModel.isLoading {
                loadingCard
            } else if let service = passengerViewModel.currentService {
                activeServiceCard(service)
            } else {
                noServiceCard
            }
            registerRouteCard
        }
    }

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
        .accessibilityLabel("Loading your service information")
    }

    private func activeServiceCard(_ service: EnrolledService) -> some View {
        VStack(spacing: 0) {

            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.brandAccent.opacity(0.12)).frame(width: 44, height: 44)
                    Image(systemName: "bus.fill").font(.system(size: 18)).foregroundStyle(Color.brandAccent)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.routeName)
                        .font(.appSubheadline)
                        .foregroundStyle(Color.textPrimary)
                    Text(sessionBadgeLabel(service.session))
                        .font(.appCaption)
                        .foregroundStyle(Color.brandAccent)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.brandAccent.opacity(0.12))
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(16)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(service.routeName), \(sessionBadgeLabel(service.session))")

            Divider().background(Color.divider)

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

            tripStatusRow

            Divider().background(Color.divider)

            attendanceSection
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.statusActive.opacity(0.25), lineWidth: 1))
    }

    private var tripStatusRow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 5) {
                Circle()
                    .fill(passengerViewModel.isTripActive ? Color.statusActive : (passengerViewModel.isTripCompleted ? Color.textTertiary : Color.statusWarning))
                    .frame(width: 7, height: 7)
                    .accessibilityHidden(true)
                Text(passengerViewModel.isTripActive ? "Trip Active"
                     : passengerViewModel.isTripCompleted ? "Trip Completed"
                     : "Awaiting Departure")
                    .font(.appCaptionSemibold)
                    .foregroundStyle(passengerViewModel.isTripActive ? Color.statusActive : Color.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(passengerViewModel.isTripActive ? Color.statusActive.opacity(0.1) : Color.surfaceBackground)
            .clipShape(Capsule())
            .accessibilityLabel(passengerViewModel.isTripActive ? "Trip is active" : passengerViewModel.isTripCompleted ? "Trip completed" : "Awaiting departure")

            Spacer()

            Button {
                if passengerViewModel.isTripActive { showTripTracking = true }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "location.fill").font(.system(size: 11, weight: .semibold))
                    Text("Track Driver").font(.appCaptionSemibold)
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
            .accessibilityLabel("Track driver")
            .accessibilityHint(passengerViewModel.isTripActive ? "Opens live map tracking" : "Only available when a trip is active")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

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
                    .accessibilityHidden(true)
                Text(passengerViewModel.attendanceSectionTitle)
                    .font(.appCaptionSemibold)
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
                        .font(.appCaption2Semibold)
                        .foregroundStyle(badgeColor)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(badgeColor.opacity(0.1))
                        .clipShape(Capsule())
                } else if !passengerViewModel.isAttendanceOutsideWindow {
                    Text("Not marked")
                        .font(.appCaption2)
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel({
                if let att = passengerViewModel.currentAttendance {
                    let status = att.status == "attending" ? "Attending" : att.status == "not_sure" ? "Not Sure" : "Absent"
                    return "\(passengerViewModel.attendanceSectionTitle). Current status: \(status)"
                }
                return passengerViewModel.attendanceSectionTitle
            }())

            Text(passengerViewModel.attendanceWindowMessage)
                .font(.appCaption2)
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
                Text(title).font(.appCaptionSemibold)
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
        .accessibilityLabel("Mark attendance as \(title)")
        .accessibilityHint("Double tap to set your attendance status for this trip")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func serviceInfoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(Color.brandAccent).frame(width: 18)
                .accessibilityHidden(true)
            Text(label).font(.appFootnote).foregroundStyle(Color.textTertiary).frame(width: 52, alignment: .leading)
            Text(value).font(.appFootnoteMedium).foregroundStyle(Color.textPrimary)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func sessionBadgeLabel(_ session: EnrolledSessionType) -> String {
        switch session {
        case .both:    return passengerViewModel.selectedTrip == .morning ? "Morning Session" : "Evening Session"
        case .morning: return "Morning Only"
        case .evening: return "Evening Only"
        }
    }

    private var noServiceCard: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color.brandAccent.opacity(0.13)).frame(width: 60, height: 60)
                Image(systemName: "bus.fill").font(.system(size: 24)).foregroundStyle(Color.brandAccent)
            }
            .accessibilityHidden(true)
            VStack(spacing: 4) {
                Text(passengerViewModel.noServiceTitle).font(.appSubheadline).foregroundStyle(Color.textPrimary)
                Text(passengerViewModel.noServiceSubtitle).font(.appCallout).foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center).lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30).padding(.horizontal, 20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(passengerViewModel.noServiceTitle). \(passengerViewModel.noServiceSubtitle)")
    }

    private var registerRouteCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.brandAccent.opacity(0.13)).frame(width: 52, height: 52)
                    Image(systemName: "map.fill").font(.system(size: 22)).foregroundStyle(Color.brandAccent)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Find Your Route").font(.appHeadline).foregroundStyle(Color.textPrimary)
                    Text("Browse available routes and register for a service that fits your schedule.")
                        .font(.appFootnote).foregroundStyle(Color.textSecondary).lineSpacing(3)
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
                    Text("Browse Routes").font(.appBodySemibold)
                }
                .foregroundStyle(Color.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.brandAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Browse Routes")
            .accessibilityHint("Search for available bus routes you can register for")
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
                Text(number).font(.appCaption2Bold).foregroundStyle(Color.brandAccent)
            }
            .accessibilityHidden(true)
            Text(text).font(.appFootnote).foregroundStyle(Color.textSecondary).lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(text)")
    }
}

#Preview("Dark Mode") {
    NavigationStack { PassengerDashboard() }.preferredColorScheme(.dark)
}
#Preview("Light Mode") {
    NavigationStack { PassengerDashboard() }.preferredColorScheme(.light)
}
