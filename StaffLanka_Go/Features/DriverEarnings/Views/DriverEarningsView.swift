//
//  DriverEarningsView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//

import SwiftUI

struct DriverEarningsView: View {

    @StateObject private var earningsViewModel = DriverEarningsViewModel()
    // Local Date binding for the DatePicker — only month and year matter
    @State private var selectedPickerDate: Date = Date()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                totalEarningsSummaryCard.padding(.top, 8)
                monthYearPickerSection
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
        .onAppear {
            earningsViewModel.startListening()
            // Sync the picker to the currently selected month on appear
            selectedPickerDate = earningsViewModel.dateFromMonthYearString(earningsViewModel.selectedMonthYear) ?? Date()
        }
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

    private var totalEarningsSummaryCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient.brand.clipShape(RoundedRectangle(cornerRadius: 20))
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Earnings").font(.appCaption2).foregroundStyle(Color.white.opacity(0.55))
                        Text(currentMonthDisplayLabel).font(.appCalloutSemibold).foregroundStyle(Color.white)
                    }
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.12)).frame(width: 36, height: 36)
                        Image(systemName: "banknote.fill").font(.system(size: 15)).foregroundStyle(Color.white.opacity(0.85))
                    }
                }

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("Rs.").font(.appCalloutSemibold).foregroundStyle(Color.white.opacity(0.70))
                    Text(earningsViewModel.totalEarningsForSelectedMonth.formattedWithSeparator)
                        .font(.appLargeTitle).foregroundStyle(Color.white)
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

    // DatePicker allowing the user to select month and year only
    // Data is scoped to the selected month and doesnt show other month data
    private var monthYearPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Filter by Month")
                .font(.appCaptionSemibold)
                .foregroundColor(.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.brandAccent)

                DatePicker(
                    "",
                    selection: $selectedPickerDate,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(Color.brandAccent)
                .onChange(of: selectedPickerDate) { _, newDate in
                    let newMonthYear = earningsViewModel.monthYearStringFromDate(newDate)
                    if newMonthYear != earningsViewModel.selectedMonthYear {
                        earningsViewModel.selectMonth(newMonthYear)
                    }
                }

                Spacer()

                // Shows which month is currently displayed
                Text(currentMonthDisplayLabel)
                    .font(.appFootnoteSemibold)
                    .foregroundStyle(Color.brandAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.brandAccent.opacity(0.10))
                    .clipShape(Capsule())
                    .accessibilityLabel("Showing earnings for \(currentMonthDisplayLabel)")
            }
            .padding(14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.divider, lineWidth: 1))
        }
    }

    private var currentMonthDisplayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedPickerDate)
    }

    private var thinVerticalDivider: some View {
        Rectangle().fill(Color.white.opacity(0.18)).frame(width: 1, height: 28).padding(.horizontal, 12)
    }

    private func compactStatCell(labelText: String, valueText: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(labelText).font(.appCaption2).foregroundStyle(Color.white.opacity(0.55))
            Text(valueText).font(.appCaptionSemibold).foregroundStyle(valueColor).lineLimit(1).minimumScaleFactor(0.75)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(labelText): \(valueText)")
    }

    private func compactPassengerCell(labelText: String, count: Int, countColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(labelText).font(.appCaption2).foregroundStyle(Color.white.opacity(0.55))
            HStack(spacing: 3) {
                Image(systemName: "person.fill").font(.system(size: 9)).foregroundStyle(countColor.opacity(0.75))
                    .accessibilityHidden(true)
                Text("\(count)").font(.appFootnoteSemibold).foregroundStyle(countColor)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(labelText): \(count)")
    }

    private var unpaidPassengersAlertBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.statusWarning.opacity(0.18)).frame(width: 38, height: 38)
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 16)).foregroundStyle(Color.statusWarning)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(earningsViewModel.numberOfUnpaidPassengers) passenger\(earningsViewModel.numberOfUnpaidPassengers == 1 ? "" : "s") have not paid yet")
                    .font(.appCalloutSemibold).foregroundStyle(Color.textPrimary)
                Text("See the list below").font(.appCaption).foregroundStyle(Color.textSecondary)
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

    private func passengerPaymentRow(record: DriverEarningsViewModel.PassengerPaymentRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.brandAccent.opacity(0.12)).frame(width: 44, height: 44)
                    Text(String(record.passengerFullName.prefix(1))).font(.system(size: 17, weight: .bold)).foregroundStyle(Color.brandAccent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.passengerFullName).font(.appCalloutSemibold).foregroundStyle(Color.textPrimary)
                    Text(record.passengerPhoneNumber).font(.appCaption).foregroundStyle(Color.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Rs. \(record.monthlyFeeAmount.formattedWithSeparator)").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.textPrimary)
                    paymentStatusBadge(hasPaid: record.hasPassengerPaid)
                }
            }

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
