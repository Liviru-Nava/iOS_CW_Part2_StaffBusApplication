//
//  PassengerEnrolledServicesView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import SwiftUI

struct PassengerEnrolledServicesView: View {
    @StateObject private var passengerEnrolledServiceViewModel = PassengerEnrolledServicesViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $passengerEnrolledServiceViewModel.showingPast) {
                Text("Active").tag(false)
                Text("Past").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appBackground)

            if passengerEnrolledServiceViewModel.showingPast {
                pastDateRangeFilterBar
            }

            ScrollView(showsIndicators: false) {
                if passengerEnrolledServiceViewModel.showingPast {
                    pastContent
                } else {
                    activeContent
                }
            }
            .background(Color.appBackground)
        }
        .background(Color.appBackground)
        .navigationTitle("Enrolled Services")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { passengerEnrolledServiceViewModel.startListening() }
        .overlay {
            if passengerEnrolledServiceViewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView().scaleEffect(1.2).tint(Color.brandAccent)
                    Text("Loading your services...").font(.system(size: 13)).foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground.opacity(0.8))
            }
        }
        .alert("Cancel Enrollment", isPresented: $passengerEnrolledServiceViewModel.showCancelAlert) {
            Button("Keep Service", role: .cancel) {}
            Button("Cancel Enrollment", role: .destructive) { passengerEnrolledServiceViewModel.handleCancel() }
        } message: {
            Text(passengerEnrolledServiceViewModel.cancelAlertMessage())
        }
    }

    private var pastDateRangeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PassengerEnrolledServicesViewModel.PastEnrollmentDateRangeFilter.allCases) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            passengerEnrolledServiceViewModel.selectedPastEnrollmentDateRangeFilter = option
                        }
                    } label: {
                        Text(option.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(passengerEnrolledServiceViewModel.selectedPastEnrollmentDateRangeFilter == option ? .white : .brandAccent)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(passengerEnrolledServiceViewModel.selectedPastEnrollmentDateRangeFilter == option ? Color.brandAccent : Color.brandAccent.opacity(0.10))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .background(Color.appBackground)
    }

    private var activeContent: some View {
        VStack(spacing: 16) {
            if passengerEnrolledServiceViewModel.activeServices.isEmpty {
                emptyState(icon: "bus.fill", title: "No Active Services",
                           message: "You are not enrolled in any bus service yet. Browse routes to get started.")
            } else {
                ForEach(passengerEnrolledServiceViewModel.activeServices) { service in
                    activeServiceCard(service)
                }
                if !passengerEnrolledServiceViewModel.hasMorningActive || !passengerEnrolledServiceViewModel.hasEveningActive {
                    if !passengerEnrolledServiceViewModel.hasBothEnrollmentActive {
                        availableSlotHint
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 32)
    }

    private var pastContent: some View {
        VStack(spacing: 0) {
            let groupedPast = passengerEnrolledServiceViewModel.pastServicesGroupedByDate
            if groupedPast.isEmpty {
                emptyState(icon: "clock.arrow.circlepath", title: "No Past Enrollments",
                           message: "Cancelled or expired enrollments will appear here.")
                    .padding(.top, 8)
            } else {
                ForEach(groupedPast, id: \.0) { dateLabel, servicesInGroup in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(dateLabel)
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(.textTertiary)
                            .textCase(.uppercase).tracking(0.5).padding(.horizontal, 4).padding(.top, 16)
                        ForEach(servicesInGroup) { service in pastServiceCard(service) }
                    }
                    .padding(.horizontal, 16)
                }
                Color.clear.frame(height: 32)
            }
        }
    }

    private func activeServiceCard(_ service: EnrolledService) -> some View {
        VStack(spacing: 0) {
            routeHeader(service, dimmed: false)
            Divider().background(Color.divider).padding(.horizontal, 16)

            HStack(spacing: 12) {
                Image(systemName: "creditcard.fill").font(.system(size: 12)).foregroundColor(.brandAccent).frame(width: 18)
                Text("Monthly Fee").font(.system(size: 13)).foregroundColor(.textTertiary).frame(width: 80, alignment: .leading)
                Text(String(format: "Rs. %.0f / month", service.monthlyFee)).font(.system(size: 13, weight: .semibold)).foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12).background(Color.brandAccent.opacity(0.04))

            Divider().background(Color.divider).padding(.horizontal, 16)

            if let morning = service.morning {
                sessionBlock(info: morning, label: "Morning", icon: "sunrise.fill", iconColor: .statusWarning)
            }
            if service.morning != nil && service.evening != nil {
                Divider().background(Color.divider).padding(.horizontal, 16)
            }
            if let evening = service.evening {
                sessionBlock(info: evening, label: "Evening", icon: "moon.stars.fill", iconColor: .brandAccent)
            }

            Divider().background(Color.divider).padding(.horizontal, 16)

            Button(role: .destructive) {
                passengerEnrolledServiceViewModel.requestCancel(service: service)
            } label: {
                cancelLabel(service.session == .both ? "Cancel Entire Enrollment" : "Cancel Enrollment")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.divider, lineWidth: 1))
    }

    private func pastServiceCard(_ service: EnrolledService) -> some View {
        VStack(spacing: 0) {
            routeHeader(service, dimmed: true)
            Divider().background(Color.divider).padding(.horizontal, 16)

            if let morning = service.morning {
                pastSessionBlock(info: morning, label: "Morning", icon: "sunrise.fill", iconColor: .statusWarning)
            }
            if service.morning != nil && service.evening != nil {
                Divider().background(Color.divider).padding(.horizontal, 16)
            }
            if let evening = service.evening {
                pastSessionBlock(info: evening, label: "Evening", icon: "moon.stars.fill", iconColor: .brandAccent)
            }
            Divider().background(Color.divider).padding(.horizontal, 16)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly Fee").font(.system(size: 12)).foregroundColor(.textTertiary)
                    Text(String(format: "Rs. %.0f", service.monthlyFee)).font(.system(size: 15, weight: .semibold)).foregroundColor(.textSecondary)
                }
                Spacer()
                if let date = service.cancelledDate {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 12)).foregroundColor(.statusInactive)
                        Text("Cancelled \(date.formatted(date: .abbreviated, time: .shortened))").font(.system(size: 12)).foregroundColor(.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.divider, lineWidth: 1))
        .opacity(0.75)
    }

    private func routeHeader(_ service: EnrolledService, dimmed: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.brandAccent.opacity(dimmed ? 0.07 : 0.12)).frame(width: 44, height: 44)
                Image(systemName: "bus.fill").font(.system(size: 18)).foregroundColor(dimmed ? .textTertiary : .brandAccent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(service.routeName).font(.system(size: 15, weight: .semibold)).foregroundColor(dimmed ? .textSecondary : .textPrimary)
                Text(passengerEnrolledServiceViewModel.sessionLabel(service.session))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(dimmed ? .textTertiary : .brandAccent)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(dimmed ? Color.surfaceBackground : Color.brandAccent.opacity(0.12))
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    private func sessionBlock(info: EnrolledSessionInfo, label: String, icon: String, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 13)).foregroundColor(iconColor)
                Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(.textSecondary).textCase(.uppercase).tracking(0.4)
            }
            VStack(spacing: 10) {
                infoRow(icon: "person.fill", label: "Driver", value: info.driverName)
                infoRow(icon: info.vehicleType.lowercased() == "van" ? "car.fill" : "bus.fill", label: "Vehicle", value: "\(info.vehicleBrand) \(info.vehicleType)")
                infoRow(icon: "rectangle.and.text.magnifyingglass", label: "Plate", value: info.licensePlate)
                infoRow(icon: "clock.fill", label: "Time", value: "\(info.startTime) – \(info.endTime)")
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    private func pastSessionBlock(info: EnrolledSessionInfo, label: String, icon: String, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 13)).foregroundColor(iconColor.opacity(0.5))
                Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(.textTertiary).textCase(.uppercase).tracking(0.4)
            }
            VStack(spacing: 10) {
                infoRow(icon: "person.fill", label: "Driver", value: info.driverName)
                infoRow(icon: info.vehicleType.lowercased() == "van" ? "car.fill" : "bus.fill", label: "Vehicle", value: "\(info.vehicleBrand) \(info.vehicleType)")
                infoRow(icon: "rectangle.and.text.magnifyingglass", label: "Plate", value: info.licensePlate)
                infoRow(icon: "clock.fill", label: "Time", value: "\(info.startTime) – \(info.endTime)")
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 12)).foregroundColor(.brandAccent).frame(width: 18)
            Text(label).font(.system(size: 13)).foregroundColor(.textTertiary).frame(width: 52, alignment: .leading)
            Text(value).font(.system(size: 13, weight: .medium)).foregroundColor(.textPrimary)
            Spacer()
        }
    }

    private func cancelLabel(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "xmark.circle").font(.system(size: 13))
            Text(text).font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(.statusDanger).frame(maxWidth: .infinity).padding(.vertical, 11)
        .background(Color.statusDanger.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var availableSlotHint: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill").font(.system(size: 20)).foregroundColor(.brandAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text(hintTitle).font(.system(size: 14, weight: .semibold)).foregroundColor(.textPrimary)
                Text(hintSubtitle).font(.system(size: 12)).foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(14).background(Color.brandAccent.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.brandAccent.opacity(0.18), lineWidth: 1))
    }

    private var hintTitle: String {
        if !passengerEnrolledServiceViewModel.hasMorningActive && !passengerEnrolledServiceViewModel.hasEveningActive { return "No active sessions" }
        if !passengerEnrolledServiceViewModel.hasMorningActive { return "Morning slot available" }
        return "Evening slot available"
    }

    private var hintSubtitle: String {
        if !passengerEnrolledServiceViewModel.hasMorningActive && !passengerEnrolledServiceViewModel.hasEveningActive { return "Browse routes to enrol in a service." }
        if !passengerEnrolledServiceViewModel.hasMorningActive { return "You can enrol in a morning service." }
        return "You can enrol in an evening service."
    }

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 14) {
            Spacer(minLength: 48)
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color.brandAccent.opacity(0.10)).frame(width: 64, height: 64)
                Image(systemName: icon).font(.system(size: 26)).foregroundColor(.brandAccent)
            }
            Text(title).font(.system(size: 17, weight: .semibold)).foregroundColor(.textPrimary)
            Text(message).font(.system(size: 14)).foregroundColor(.textSecondary).multilineTextAlignment(.center)
            Spacer(minLength: 48)
        }
        .padding(.horizontal, 32)
    }
}

#Preview("Dark") { NavigationStack { PassengerEnrolledServicesView() }.preferredColorScheme(.dark) }
#Preview("Light") { NavigationStack { PassengerEnrolledServicesView() }.preferredColorScheme(.light) }
