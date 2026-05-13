//
//  DriverEarningsView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//

import SwiftUI

struct DriverEarningsView: View {

    @StateObject private var earningsViewModel = DriverEarningsViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                totalEarningsSummaryCard.padding(.top, 8)
                monthChipFilterBar
                if earningsViewModel.numberOfUnpaidPassengers > 0 {
                    unpaidPassengersAlertBanner
                }
                passengerPaymentStatusListSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .background(Color.appBackground)
        .navigationTitle("Earnings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { earningsViewModel.startListening() }
        .overlay {
            if earningsViewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView().scaleEffect(1.2).tint(Color.brandAccent)
                    Text("Loading earnings...").font(.system(size: 13)).foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground.opacity(0.7))
            }
        }
    }

    // Top summary card showing selected month totals
    private var totalEarningsSummaryCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient.brand.clipShape(RoundedRectangle(cornerRadius: 20))
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Earnings").font(.system(size: 11, weight: .medium)).foregroundStyle(Color.white.opacity(0.55))
                        Text(currentMonthDisplayLabel).font(.system(size: 16, weight: .bold)).foregroundStyle(Color.white)
                    }
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.12)).frame(width: 36, height: 36)
                        Image(systemName: "banknote.fill").font(.system(size: 15)).foregroundStyle(Color.white.opacity(0.85))
                    }
                }

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("Rs.").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.white.opacity(0.70))
                    Text(earningsViewModel.totalEarningsForSelectedMonth.formattedWithSeparator)
                        .font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(Color.white)
                }

                Rectangle().fill(Color.white.opacity(0.14)).frame(height: 1)

                HStack(spacing: 0) {
                    compactStatCell(labelText: "Collected", valueText: "Rs. \(earningsViewModel.totalCollectedAmountForSelectedMonth.formattedWithSeparator)", valueColor: Color.statusActive)
                    thinVerticalDivider
                    compactStatCell(labelText: "Pending", valueText: "Rs. \(earningsViewModel.totalPendingAmountForSelectedMonth.formattedWithSeparator)", valueColor: Color.statusWarning)
                    thinVerticalDivider
                    compactPassengerCell(labelText: "Passengers", count: earningsViewModel.totalPassengerCount, countColor: .white)
                    thinVerticalDivider
                    compactPassengerCell(labelText: "Paid", count: earningsViewModel.numberOfPaidPassengers, countColor: Color.statusActive)
                    thinVerticalDivider
                    compactPassengerCell(labelText: "Unpaid", count: earningsViewModel.numberOfUnpaidPassengers, countColor: Color.statusWarning)
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 16)
        }
    }

    // Horizontally scrollable month chip bar — replaces the Picker dropdown
    // Shows the last 12 months as tappable chips with the current month highlighted
    private var monthChipFilterBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Filter by Month")
                .font(.system(size: 12, weight: .semibold)).foregroundColor(.textTertiary).textCase(.uppercase).tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(earningsViewModel.availableMonthChips) { chip in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                earningsViewModel.selectMonth(chip.monthYear)
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Text(chip.displayLabel)
                                    .font(.system(size: 13, weight: chip.monthYear == earningsViewModel.selectedMonthYear ? .bold : .medium))
                                    .foregroundColor(chip.monthYear == earningsViewModel.selectedMonthYear ? .white : .textPrimary)
                                if chip.isCurrentMonth {
                                    Circle().fill(chip.monthYear == earningsViewModel.selectedMonthYear ? Color.white : Color.brandAccent).frame(width: 4, height: 4)
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(chip.monthYear == earningsViewModel.selectedMonthYear ? Color.brandAccent : Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(
                                chip.isCurrentMonth && chip.monthYear != earningsViewModel.selectedMonthYear
                                    ? Color.brandAccent.opacity(0.5) : Color.divider,
                                lineWidth: 1
                            ))
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: earningsViewModel.selectedMonthYear)
                    }
                }
                .padding(.horizontal, 2).padding(.vertical, 2)
            }
        }
    }

    private var currentMonthDisplayLabel: String {
        earningsViewModel.availableMonthChips.first { $0.monthYear == earningsViewModel.selectedMonthYear }?.displayLabel
            ?? earningsViewModel.selectedMonthYear
    }

    private var thinVerticalDivider: some View {
        Rectangle().fill(Color.white.opacity(0.18)).frame(width: 1, height: 28).padding(.horizontal, 12)
    }

    private func compactStatCell(labelText: String, valueText: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(labelText).font(.system(size: 10)).foregroundStyle(Color.white.opacity(0.55))
            Text(valueText).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(valueColor).lineLimit(1).minimumScaleFactor(0.75)
        }
    }

    private func compactPassengerCell(labelText: String, count: Int, countColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(labelText).font(.system(size: 10)).foregroundStyle(Color.white.opacity(0.55))
            HStack(spacing: 3) {
                Image(systemName: "person.fill").font(.system(size: 9)).foregroundStyle(countColor.opacity(0.75))
                Text("\(count)").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(countColor)
            }
        }
    }

    private var unpaidPassengersAlertBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.statusWarning.opacity(0.18)).frame(width: 38, height: 38)
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 16)).foregroundStyle(Color.statusWarning)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(earningsViewModel.numberOfUnpaidPassengers) passenger\(earningsViewModel.numberOfUnpaidPassengers == 1 ? "" : "s") have not paid yet")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.textPrimary)
                Text("See the list below").font(.system(size: 12)).foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.statusWarning.opacity(0.10)))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.statusWarning.opacity(0.35), lineWidth: 1))
    }

    private var passengerPaymentStatusListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle.fill").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.brandAccent)
                    Text("Passenger Payments").font(.system(size: 15, weight: .bold)).foregroundStyle(Color.textPrimary)
                }
                Spacer()
                Text("\(earningsViewModel.totalPassengerCount) passenger\(earningsViewModel.totalPassengerCount == 1 ? "" : "s"), \(earningsViewModel.listOfPassengerPaymentStatuses.count) enrollment\(earningsViewModel.listOfPassengerPaymentStatuses.count == 1 ? "" : "s")").font(.system(size: 12)).foregroundStyle(Color.textSecondary)
            }

            if earningsViewModel.totalPassengerCount == 0 {
                VStack(spacing: 16) {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark").font(.system(size: 36)).foregroundStyle(Color.statusInactive)
                    Text("No enrolled passengers for this month.").font(.system(size: 15, weight: .medium)).foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 160)
                .background(Color.cardBackground).clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.divider, lineWidth: 1))
                .padding(.top, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(earningsViewModel.listOfPassengerPaymentStatuses) { record in
                        passengerPaymentRow(record: record)
                    }
                }
            }
        }
    }

    // Full-detail passenger row: name, phone, pickup → drop-off, session, fee, paid/pending badge
    private func passengerPaymentRow(record: DriverEarningsViewModel.PassengerPaymentRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.brandAccent.opacity(0.12)).frame(width: 44, height: 44)
                    Text(String(record.passengerFullName.prefix(1))).font(.system(size: 17, weight: .bold)).foregroundStyle(Color.brandAccent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.passengerFullName).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.textPrimary)
                    Text(record.passengerPhoneNumber).font(.system(size: 12)).foregroundStyle(Color.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Rs. \(record.monthlyFeeAmount.formattedWithSeparator)").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.textPrimary)
                    paymentStatusBadge(hasPaid: record.hasPassengerPaid)
                }
            }

            // Route detail
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 11)).foregroundStyle(Color.statusActive)
                    Text("Pickup:").font(.system(size: 12)).foregroundStyle(Color.textTertiary).frame(width: 48, alignment: .leading)
                    Text(record.boardingStopName).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.textPrimary)
                    Spacer()
                }
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill").font(.system(size: 11)).foregroundStyle(Color.statusDanger)
                    Text("Drop-off:").font(.system(size: 12)).foregroundStyle(Color.textTertiary).frame(width: 48, alignment: .leading)
                    Text(record.dropOffStopName).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.textPrimary)
                    Spacer()
                }
            }
            .padding(.leading, 58)

            // Session badge
            sessionTypeLabel(serviceType: record.routeServiceType).padding(.leading, 58)
        }
        .padding(14)
        .background(Color.cardBackground).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(record.hasPassengerPaid ? Color.clear : Color.statusWarning.opacity(0.28), lineWidth: 1))
    }

    private func sessionTypeLabel(serviceType: TripSession) -> some View {
        let labelText: String
        switch serviceType {
        case .morning: labelText = "Morning"
        case .evening: labelText = "Evening"
        case .both:    labelText = "Both"
        }
        return Text(labelText)
            .font(.system(size: 11, weight: .medium)).foregroundStyle(Color.brandAccent)
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(Color.brandAccent.opacity(0.13)).clipShape(Capsule())
    }

    private func paymentStatusBadge(hasPaid: Bool) -> some View {
        HStack(spacing: 4) {
            Circle().fill(hasPaid ? Color.statusActive : Color.statusWarning).frame(width: 6, height: 6)
            Text(hasPaid ? "Paid" : "Pending").font(.system(size: 11, weight: .semibold)).foregroundStyle(hasPaid ? Color.statusActive : Color.statusWarning)
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background((hasPaid ? Color.statusActive : Color.statusWarning).opacity(0.12)).clipShape(Capsule())
    }
}

private extension Int {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter(); formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

#Preview("Dark") { NavigationStack { DriverEarningsView() }.preferredColorScheme(.dark) }
#Preview("Light") { NavigationStack { DriverEarningsView() }.preferredColorScheme(.light) }
