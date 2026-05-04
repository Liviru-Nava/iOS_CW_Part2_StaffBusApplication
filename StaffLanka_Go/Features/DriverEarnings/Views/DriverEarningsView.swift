//
//  DriverEarningsView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//

import SwiftUI

struct DriverEarningsView: View {

    @StateObject private var earningsViewModel = DriverEarningsViewModel()
    @State private var isUnpaidAlertHighlighted: Bool = false
    @State private var currentPassengerListPage: Int = 1

    private let passengerRowsPerPage: Int = 5

    private var totalPageCount: Int {
        let totalRecords = earningsViewModel.listOfPassengerPaymentStatuses.count
        return max(1, Int(ceil(Double(totalRecords) / Double(passengerRowsPerPage))))
    }

    private var passengerRecordsForCurrentPage: [DriverEarningsViewModel.PassengerPaymentRecord] {
        let allRecords = earningsViewModel.listOfPassengerPaymentStatuses
        let startIndex = (currentPassengerListPage - 1) * passengerRowsPerPage
        let endIndex = min(startIndex + passengerRowsPerPage, allRecords.count)
        guard startIndex < allRecords.count else { return [] }
        return Array(allRecords[startIndex..<endIndex])
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                totalEarningsSummaryCard
                    .padding(.top, 8)
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
        .onChange(of: earningsViewModel.selectedMonthForEarningsDisplay) {
            currentPassengerListPage = 1
        }
    }

    private var totalEarningsSummaryCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient.brand
                .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Total Earnings")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.55))
                        Picker("Month", selection: $earningsViewModel.selectedMonthForEarningsDisplay) {
                            ForEach(earningsViewModel.availableMonthDisplayLabels, id: \.self) { monthLabel in
                                Text(monthLabel).tag(monthLabel)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color.white)
                        .padding(.leading, -8)
                        .padding(.top, -6)
                    }
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.white.opacity(0.85))
                    }
                }

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("Rs.")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.70))
                    Text(earningsViewModel.totalEarningsForSelectedMonth.formattedWithSeparator)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.14))
                    .frame(height: 1)

                HStack(spacing: 0) {
                    compactStatCell(
                        labelText: "Collected",
                        valueText: "Rs. \(earningsViewModel.totalCollectedAmountForSelectedMonth.formattedWithSeparator)",
                        valueColor: Color.statusActive
                    )
                    thinVerticalDivider
                    compactStatCell(
                        labelText: "Pending",
                        valueText: "Rs. \(earningsViewModel.totalPendingAmountForSelectedMonth.formattedWithSeparator)",
                        valueColor: Color.statusWarning
                    )
                    thinVerticalDivider
                    compactPassengerCell(labelText: "Passengers", count: earningsViewModel.totalPassengerCount, countColor: .white)
                    thinVerticalDivider
                    compactPassengerCell(labelText: "Paid", count: earningsViewModel.numberOfPaidPassengers, countColor: Color.statusActive)
                    thinVerticalDivider
                    compactPassengerCell(labelText: "Unpaid", count: earningsViewModel.numberOfUnpaidPassengers, countColor: Color.statusWarning)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
    }

    private var thinVerticalDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.18))
            .frame(width: 1, height: 28)
            .padding(.horizontal, 12)
    }

    private func compactStatCell(labelText: String, valueText: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(labelText)
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.55))
            Text(valueText)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private func compactPassengerCell(labelText: String, count: Int, countColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(labelText)
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.55))
            HStack(spacing: 3) {
                Image(systemName: "person.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(countColor.opacity(0.75))
                Text("\(count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(countColor)
            }
        }
    }

    private var unpaidPassengersAlertBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.statusWarning.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.statusWarning)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(earningsViewModel.numberOfUnpaidPassengers) passengers have not paid yet")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("See the list below")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.statusWarning.opacity(isUnpaidAlertHighlighted ? 0.18 : 0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.statusWarning.opacity(0.35), lineWidth: 1)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) { isUnpaidAlertHighlighted = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.25)) { isUnpaidAlertHighlighted = false }
            }
        }
    }

    private var passengerPaymentStatusListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.brandAccent)
                    Text("Passenger Payments")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                }
                Spacer()
                if earningsViewModel.totalPassengerCount > 0 {
                    Text("Page \(currentPassengerListPage) of \(totalPageCount)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }
            }

            if earningsViewModel.totalPassengerCount == 0 {
                VStack(spacing: 16) {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.statusInactive)
                    Text("No payment records for this month.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 160)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.divider, lineWidth: 1)
                )
                .padding(.top, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(passengerRecordsForCurrentPage) { passengerRecord in
                        passengerPaymentRow(record: passengerRecord)
                    }
                }

                paginationControlRow
            }
        }
    }

    private var paginationControlRow: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.20)) {
                    currentPassengerListPage = max(1, currentPassengerListPage - 1)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Previous")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(currentPassengerListPage > 1 ? Color.brandAccent : Color.textTertiary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(currentPassengerListPage <= 1)

            Spacer()

            HStack(spacing: 6) {
                ForEach(1...totalPageCount, id: \.self) { pageIndex in
                    Circle()
                        .fill(pageIndex == currentPassengerListPage ? Color.brandAccent : Color.textTertiary.opacity(0.40))
                        .frame(width: pageIndex == currentPassengerListPage ? 8 : 6,
                               height: pageIndex == currentPassengerListPage ? 8 : 6)
                        .animation(.easeInOut(duration: 0.18), value: currentPassengerListPage)
                }
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.20)) {
                    currentPassengerListPage = min(totalPageCount, currentPassengerListPage + 1)
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Next")
                        .font(.system(size: 13, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(currentPassengerListPage < totalPageCount ? Color.brandAccent : Color.textTertiary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(currentPassengerListPage >= totalPageCount)
        }
        .padding(.top, 4)
    }

    private func passengerPaymentRow(record: DriverEarningsViewModel.PassengerPaymentRecord) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text(String(record.passengerFullName.prefix(1)))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.brandAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(record.passengerFullName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                HStack(spacing: 6) {
                    Text(record.boardingStopName)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.textTertiary)
                    sessionTypeLabel(serviceType: record.routeServiceType)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Rs. \(record.monthlyFeeAmount.formattedWithSeparator)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                paymentStatusBadge(hasPaid: record.hasPassengerPaid)
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    record.hasPassengerPaid ? Color.clear : Color.statusWarning.opacity(0.28),
                    lineWidth: 1
                )
        )
    }

    private func sessionTypeLabel(serviceType: TripSession) -> some View {
        let labelText: String
        switch serviceType {
        case .morning: labelText = "Morning"
        case .evening: labelText = "Evening"
        case .both:    labelText = "Both"
        }
        return Text(labelText)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.brandAccent)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Color.brandAccent.opacity(0.13))
            .clipShape(Capsule())
    }

    private func paymentStatusBadge(hasPaid: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(hasPaid ? Color.statusActive : Color.statusWarning)
                .frame(width: 6, height: 6)
            Text(hasPaid ? "Paid" : "Pending")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(hasPaid ? Color.statusActive : Color.statusWarning)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background((hasPaid ? Color.statusActive : Color.statusWarning).opacity(0.12))
        .clipShape(Capsule())
    }
}

private extension Int {
    var formattedWithSeparator: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

#Preview("Dark") {
    NavigationStack {
        DriverEarningsView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    NavigationStack {
        DriverEarningsView()
    }
    .preferredColorScheme(.light)
}
