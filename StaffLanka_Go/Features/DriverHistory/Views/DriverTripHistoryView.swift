//
//  DriverTripHistoryView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-09.

import SwiftUI

struct DriverTripHistoryView: View {

    @StateObject private var tripHistoryViewModel = DriverTripHistoryViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                tripSummaryBanner
                    .padding(.top, 8)
                dateRangeFilterBar
                if tripHistoryViewModel.tripRecordsGroupedByDate.isEmpty {
                    tripHistoryEmptyState
                } else {
                    groupedTripRecordsList
                }
            }
            .padding(.bottom, 48)
        }
        .background(Color.appBackground)
        .navigationTitle("Trip History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            tripHistoryViewModel.fetchHistory()
        }
    }

    private var tripSummaryBanner: some View {
        ZStack {
            LinearGradient.brand
                .clipShape(RoundedRectangle(cornerRadius: 20))

            HStack(spacing: 0) {
                bannerStatCell(
                    statValue: "\(tripHistoryViewModel.totalCompletedTripsCount)",
                    statLabel: "Trips"
                )
                bannerVerticalDivider
                bannerStatCell(
                    statValue: "\(tripHistoryViewModel.totalPassengersAcrossAllTrips)",
                    statLabel: "Passengers"
                )
                bannerVerticalDivider
                bannerStatCell(
                    statValue: "\(tripHistoryViewModel.averageTripDurationInMinutes)m",
                    statLabel: "Avg Duration"
                )
            }
            .padding(.vertical, 20)
        }
        .padding(.horizontal, 16)
    }

    private func bannerStatCell(statValue: String, statLabel: String) -> some View {
        VStack(spacing: 4) {
            Text(statValue)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
            Text(statLabel)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
    }

    private var bannerVerticalDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.20))
            .frame(width: 1, height: 36)
    }

    private var dateRangeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TripHistoryDateFilter.allCases) { filterOption in
                    let isSelectedFilter = tripHistoryViewModel.selectedDateRangeFilter == filterOption
                    Button {
                        tripHistoryViewModel.selectedDateRangeFilter = filterOption
                    } label: {
                        Text(filterOption.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(isSelectedFilter ? Color.brandAccent.opacity(0.14) : Color.cardBackground)
                            .foregroundStyle(isSelectedFilter ? Color.brandAccent : Color.textSecondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().strokeBorder(
                                    isSelectedFilter ? Color.brandAccent.opacity(0.45) : Color.divider,
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: tripHistoryViewModel.selectedDateRangeFilter)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var groupedTripRecordsList: some View {
        VStack(alignment: .leading, spacing: 24) {
            if tripHistoryViewModel.tripRecordsGroupedByDate.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "car.top.door.sliding.left.open")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.statusInactive)
                    Text("No trips recorded yet.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 80)
            } else {
                ForEach(tripHistoryViewModel.tripRecordsGroupedByDate, id: \.0) { groupLabel, tripsInGroup in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(groupLabel)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, 16)

                        ForEach(tripsInGroup) { tripRecord in
                            NavigationLink(destination: DriverTripDetailView(tripRecord: tripRecord)) {
                                DriverTripHistoryCard(tripRecord: tripRecord)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var tripHistoryEmptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.10))
                    .frame(width: 90, height: 90)
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.brandAccent)
            }
            Text("No Trips Found")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.textPrimary)
            Text("No trips recorded for the selected date range.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

struct DriverTripHistoryCard: View {

    let tripRecord: DriverHistoryTripRecord

    private var sessionDisplayColor: Color {
        tripRecord.sessionType == "Morning" ? Color.statusWarning : Color.brandAccent
    }

    private var sessionIconName: String {
        tripRecord.sessionType == "Morning" ? "sunrise.fill" : "moon.fill"
    }

    private var completionStatusColor: Color {
        tripRecord.completionStatus == .completed ? Color.statusActive : Color.statusWarning
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(sessionDisplayColor.opacity(0.13))
                        .frame(width: 46, height: 46)
                    Image(systemName: sessionIconName)
                        .font(.system(size: 19))
                        .foregroundStyle(sessionDisplayColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(tripRecord.sessionType == "Morning" ? "Morning Trip" : "Evening Trip")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        completionStatusPill
                    }
                    Text(tripRecord.tripDate.formatted(date: .long, time: .omitted))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()
                .padding(.horizontal, 16)

            HStack(spacing: 20) {
                cardDetailItem(iconName: "clock", labelText: tripRecord.scheduledStartTime)
                cardDetailItem(iconName: "flag.checkered", labelText: tripRecord.actualEndTime)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.brandAccent)
                    Text("\(tripRecord.performanceSummary.totalPassengersPickedUp) passengers")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.divider, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private var completionStatusPill: some View {
        Text(tripRecord.completionStatus.rawValue)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(completionStatusColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(completionStatusColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private func cardDetailItem(iconName: String, labelText: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.system(size: 11))
                .foregroundStyle(Color.textTertiary)
            Text(labelText)
                .font(.system(size: 12))
                .foregroundStyle(Color.textSecondary)
        }
    }
}

#Preview("Dark") {
    NavigationStack {
        DriverTripHistoryView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    NavigationStack {
        DriverTripHistoryView()
    }
    .preferredColorScheme(.light)
}
