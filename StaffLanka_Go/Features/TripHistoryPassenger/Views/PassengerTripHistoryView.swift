//
//  PassengerTripHistoryView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import SwiftUI

struct PassengerTripHistoryView: View {
    @StateObject private var tripHistoryViewModel = PassengerTripHistoryViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                summaryBanner
                dateFilterBar
                if tripHistoryViewModel.groupedRecords.isEmpty {
                    emptyState
                } else {
                    groupedTripList
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 48)
        }
        .background(Color.appBackground)
        .navigationTitle("Trip History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            tripHistoryViewModel.fetchHistory()
        }
        .sheet(item: $tripHistoryViewModel.selectedRecord) { record in
            TripDayDetailSheet(record: record)
        }
    }

    private var summaryBanner: some View {
        ZStack {
            LinearGradient.brand
                .clipShape(RoundedRectangle(cornerRadius: 20))

            HStack(spacing: 0) {
                summaryCell(value: "\(tripHistoryViewModel.totalTripsAttended)", label: "Attended")
                bannerDivider
                summaryCell(value: "\(tripHistoryViewModel.totalTripsSkipped)", label: "Skipped")
                bannerDivider
                summaryCell(value: "\(tripHistoryViewModel.averageTravelTime)m", label: "Avg Time")
            }
            .padding(.vertical, 20)
        }
        .padding(.horizontal, 16)
    }

    private func summaryCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.appLargeTitle)
                .foregroundColor(.white)
            Text(label)
                .font(.appCaption)
                .foregroundColor(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var bannerDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.20))
            .frame(width: 1, height: 36)
    }

    private var dateFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TripHistoryDateFilter.allCases) { filter in
                    Button {
                        tripHistoryViewModel.selectedDateFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.appFootnoteMedium)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                tripHistoryViewModel.selectedDateFilter == filter
                                    ? Color.brandAccent.opacity(0.14)
                                    : Color.cardBackground
                            )
                            .foregroundColor(
                                tripHistoryViewModel.selectedDateFilter == filter
                                    ? Color.brandAccent
                                    : Color.textSecondary
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().strokeBorder(
                                    tripHistoryViewModel.selectedDateFilter == filter
                                        ? Color.brandAccent.opacity(0.45)
                                        : Color.divider,
                                    lineWidth: 1
                                )
                            )
                    }
                    .animation(.easeInOut(duration: 0.15), value: tripHistoryViewModel.selectedDateFilter)
                    .accessibilityLabel(filter.rawValue)
                    .accessibilityAddTraits(tripHistoryViewModel.selectedDateFilter == filter ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var groupedTripList: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(tripHistoryViewModel.groupedRecords, id: \.0) { sectionLabel, dayRecords in
                VStack(alignment: .leading, spacing: 10) {
                    Text(sectionLabel)
                        .font(.appCaption2Semibold)
                        .foregroundColor(.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .padding(.horizontal, 16)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(dayRecords) { record in
                        TripDayCard(record: record)
                            .onTapGesture { tripHistoryViewModel.selectedRecord = record }
                            .accessibilityLabel("Trip on \(record.date.formatted(date: .long, time: .omitted)): \(record.routeName). Tap for details")
                            .accessibilityAddTraits(.isButton)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.10))
                    .frame(width: 90, height: 90)
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 34))
                    .foregroundColor(Color.brandAccent)
            }
            Text("No Trips Found")
                .font(.appTitle)
                .foregroundColor(.textPrimary)
            Text("No trips recorded for the selected date range.")
                .font(.appBody)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

struct TripDayCard: View {
    let record: TripDayRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.routeName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(record.date.formatted(date: .long, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundColor(.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider().padding(.horizontal, 16)

            VStack(spacing: 0) {
                if let morning = record.morning {
                    sessionRow(session: morning)
                }
                if record.morning != nil && record.evening != nil {
                    Divider()
                        .padding(.horizontal, 16)
                }
                if let evening = record.evening {
                    sessionRow(session: evening)
                }
            }
            .padding(.bottom, 4)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.divider, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func sessionRow(session: TripSessionRecord) -> some View {
        let attended = session.attendance == .attended
        let sessionColor: Color = session.session == .morning ? Color.statusWarning : Color.brandAccent

        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(attended ? sessionColor.opacity(0.12) : Color.statusInactive.opacity(0.08))
                    .frame(width: 40, height: 40)
                Image(systemName: session.session == .morning ? "sunrise.fill" : "moon.fill")
                    .font(.system(size: 16))
                    .foregroundColor(attended ? sessionColor : Color.statusInactive)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(session.session == .morning ? "Morning" : "Evening")
                        .font(.appCalloutSemibold)
                        .foregroundColor(attended ? .textPrimary : .textTertiary)

                    if !attended {
                        Text("Skipped")
                            .font(.appCaption2Semibold)
                            .foregroundColor(.statusInactive)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.statusInactive.opacity(0.10))
                            .clipShape(Capsule())
                    }
                }

                if attended, let board = session.boardTime, let departureTime = session.departureTime {
                    HStack(spacing: 4) {
                        Text(board.formatted(date: .omitted, time: .shortened))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 9, weight: .semibold))
                        Text(departureTime.formatted(date: .omitted, time: .shortened))
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)

                    Text("\(session.pickupStop) → \(session.dropoffStop)")
                        .font(.system(size: 11))
                        .foregroundColor(.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if attended, let dur = session.duration {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(dur)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Text("min")
                        .font(.system(size: 10))
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .opacity(attended ? 1.0 : 0.55)
    }
}

struct TripDayDetailSheet: View {
    let record: TripDayRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    routeHeader
                    if let morning = record.morning {
                        sessionDetailCard(session: morning)
                    }
                    if let evening = record.evening {
                        sessionDetailCard(session: evening)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground)
            .navigationTitle(record.date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.appCalloutSemibold)
                        .foregroundColor(Color.brandAccent)
                        .accessibilityLabel("Done")
                        .accessibilityHint("Closes this detail sheet")
                }
            }
        }
    }

    private var routeHeader: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.brandAccent.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: "bus.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color.brandAccent)
            }
            Text(record.routeName)
                .font(.appTitle3)
                .foregroundColor(.textPrimary)
            Text(record.date.formatted(date: .long, time: .omitted))
                .font(.appFootnote)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    private func sessionDetailCard(session: TripSessionRecord) -> some View {
        let attended = session.attendance == .attended
        let sessionColor: Color = session.session == .morning ? Color.statusWarning : Color.brandAccent

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(attended ? sessionColor.opacity(0.13) : Color.statusInactive.opacity(0.08))
                        .frame(width: 40, height: 40)
                    Image(systemName: session.session == .morning ? "sunrise.fill" : "moon.fill")
                        .font(.system(size: 16))
                        .foregroundColor(attended ? sessionColor : Color.statusInactive)
                }

                Text(session.session == .morning ? "Morning Trip" : "Evening Trip")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(attended ? .textPrimary : .textTertiary)

                Spacer()

                if attended {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                        Text("Attended")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.statusActive.opacity(0.12))
                    .foregroundColor(Color.statusActive)
                    .clipShape(Capsule())
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                        Text("Skipped")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.statusInactive.opacity(0.10))
                    .foregroundColor(Color.statusInactive)
                    .clipShape(Capsule())
                }
            }
            .padding(16)

            if attended {
                Divider().padding(.horizontal, 16)

                VStack(spacing: 0) {
                    detailRow(label: "Boarding Time", value: session.boardTime?.formatted(date: .omitted, time: .shortened) ?? "—")
                    Divider().padding(.horizontal, 16)
                    detailRow(label: "Drop-off Time", value: session.departureTime?.formatted(date: .omitted, time: .shortened) ?? "—")
                    Divider().padding(.horizontal, 16)
                    detailRow(label: "Pickup Stop", value: session.pickupStop)
                    Divider().padding(.horizontal, 16)
                    detailRow(label: "Drop-off Stop", value: session.dropoffStop)
                    if let dur = session.duration {
                        Divider().padding(.horizontal, 16)
                        detailRow(label: "Duration", value: "\(dur) minutes")
                    }
                }
            } else {
                Divider().padding(.horizontal, 16)
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundColor(.textTertiary)
                    Text("This session was skipped.")
                        .font(.system(size: 13))
                        .foregroundColor(.textTertiary)
                }
                .padding(16)
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.divider, lineWidth: 1)
        )
        .opacity(attended ? 1.0 : 0.65)
        .padding(.horizontal, 16)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.appCallout)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.appCalloutSemibold)
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        PassengerTripHistoryView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    NavigationStack {
        PassengerTripHistoryView()
    }
    .preferredColorScheme(.light)
}
