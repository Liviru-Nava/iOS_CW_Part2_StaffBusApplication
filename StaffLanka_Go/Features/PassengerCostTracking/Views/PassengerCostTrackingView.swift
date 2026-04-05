//
//  PassengerCostTrackingView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import SwiftUI

struct PassengerCostTrackingView: View {
    @StateObject private var passengerCostTrackingViewModel = PassengerCostTrackingViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if passengerCostTrackingViewModel.hasService, let service = passengerCostTrackingViewModel.service {
                    passengerCostTrackingServiceCard(service)
                        .padding(.top, 8)
                    filterBar
                    monthlyHistorySection
                } else {
                    passengerCostTrackingEmptyState
                }
            }
            .padding(.bottom, 48)
        }
        .background(Color.appBackground)
        .navigationTitle("Cost Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $passengerCostTrackingViewModel.showPaymentSheet) {
            paymentSheet
        }
    }

    private func passengerCostTrackingServiceCard(_ service: ServiceRegistration) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient.brand
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(service.routeName)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        sessionBadge(service.session, onDark: true)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 13))
                        Text(service.pickup)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.80))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.45))
                        Text(service.destination)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.80))
                    }

                    Divider().background(Color.white.opacity(0.18))

                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Amount This Month")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.60))
                            Text("Rs. \(Int(service.amountThisMonth))")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("Day \(service.daysElapsed) of \(service.totalDays)")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.60))
                            progressPill(elapsed: service.daysElapsed, total: service.totalDays)
                        }
                    }

                    if !service.currentMonthPaid {
                        Button {
                            passengerCostTrackingViewModel.initiateCurrentMonthPayment()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 14))
                                Text("Pay for This Month")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(Color.brandPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                            Text("Paid for This Month")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(20)
            }
        }
        .padding(.horizontal, 16)
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Filter")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterPill(label: "All", active: passengerCostTrackingViewModel.sessionFilter == nil && !passengerCostTrackingViewModel.showUnpaidOnly && !passengerCostTrackingViewModel.sortByAmount) {
                        passengerCostTrackingViewModel.sessionFilter = nil
                        passengerCostTrackingViewModel.showUnpaidOnly = false
                        passengerCostTrackingViewModel.sortByAmount = false
                    }

                    Divider().frame(height: 18)

                    filterPill(label: "Morning", icon: "sunrise.fill", active: passengerCostTrackingViewModel.sessionFilter == .morning) {
                        passengerCostTrackingViewModel.sessionFilter =
                            passengerCostTrackingViewModel.sessionFilter == .morning ? nil : .morning
                    }
                    filterPill(label: "Evening", icon: "moon.fill", active: passengerCostTrackingViewModel.sessionFilter == .evening) {
                        passengerCostTrackingViewModel.sessionFilter =
                            passengerCostTrackingViewModel.sessionFilter == .evening ? nil : .evening
                    }
                    filterPill(label: "Both", icon: "arrow.2.squarepath", active: passengerCostTrackingViewModel.sessionFilter == .both) {
                        passengerCostTrackingViewModel.sessionFilter =
                            passengerCostTrackingViewModel.sessionFilter == .both ? nil : .both
                    }

                    Divider().frame(height: 18)

                    filterPill(label: "Unpaid", icon: "exclamationmark.circle.fill", active: passengerCostTrackingViewModel.showUnpaidOnly, tint: .statusWarning) {
                        passengerCostTrackingViewModel.showUnpaidOnly.toggle()
                    }
                    filterPill(label: "By Amount", icon: "arrow.up.arrow.down", active: passengerCostTrackingViewModel.sortByAmount) {
                        passengerCostTrackingViewModel.sortByAmount.toggle()
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func filterPill(label: String, icon: String? = nil, active: Bool, tint: Color = .brandAccent, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                }
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(active ? tint.opacity(0.14) : Color.cardBackground)
            .foregroundColor(active ? tint : Color.textSecondary)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(active ? tint.opacity(0.45) : Color.divider, lineWidth: 1))
        }
        .animation(.easeInOut(duration: 0.15), value: active)
    }

    private var monthlyHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Payment History")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(passengerCostTrackingViewModel.filteredRecords.count) records")
                    .font(.system(size: 12))
                    .foregroundColor(.textTertiary)
            }
            .padding(.horizontal, 16)

            if passengerCostTrackingViewModel.filteredRecords.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundColor(.textTertiary)
                    Text("No records match the selected filter.")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(passengerCostTrackingViewModel.filteredRecords) { record in
                    monthlyRecordCard(record)
                }
            }
        }
    }

    private func monthlyRecordCard(_ record: MonthlyRecord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if record.isGracePeriod && !record.isPaid {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                    Text("Grace period active — payment overdue")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.statusWarning.opacity(0.75))
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.monthLabel)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.textPrimary)
                        sessionBadge(record.session, onDark: false)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Rs. \(Int(record.amount))")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        recordStatusBadge(record)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.routeName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.textTertiary)
                        Text(record.pickup)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.textTertiary)
                        Text(record.destination)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                }

                if record.isGracePeriod && !record.isPaid {
                    Button {
                        passengerCostTrackingViewModel.initiateRecordPayment(record)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 13))
                            Text("Pay Now")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.brandSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(16)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    record.isGracePeriod && !record.isPaid
                        ? Color.statusWarning.opacity(0.55)
                        : Color.divider,
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16)
    }

    private func recordStatusBadge(_ record: MonthlyRecord) -> some View {
        let label = record.isPaid ? "Paid" : "Payment Overdue"
        let icon  = record.isPaid ? "checkmark.circle.fill" : "clock.fill"
        let color: Color = record.isPaid ? .statusActive : .statusWarning

        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(label)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .clipShape(Capsule())
    }

    private var passengerCostTrackingEmptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 80)
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.10))
                    .frame(width: 96, height: 96)
                Image(systemName: "creditcard.slash")
                    .font(.system(size: 38))
                    .foregroundColor(Color.brandAccent)
            }
            Text("No Registered Service")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.textPrimary)
            Text("You don't have any registered bus service yet.\nOnce you join a route, your cost tracking will appear here.")
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    @ViewBuilder
    private var paymentSheet: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.divider)
                .frame(width: 36, height: 4)
                .padding(.top, 14)
                .padding(.bottom, 20)

            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.brandAccent.opacity(0.12))
                        .frame(width: 64, height: 64)
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color.brandAccent)
                }
                Text("Confirm Payment")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .padding(.top, 4)
            }
            .padding(.bottom, 24)

            VStack(spacing: 0) {
                if passengerCostTrackingViewModel.payingCurrentMonth, let service = passengerCostTrackingViewModel.service {
                    paymentRow(label: "Route", value: service.routeName)
                    Divider().padding(.horizontal, 16)
                    paymentRow(label: "Session", value: service.session.rawValue)
                    Divider().padding(.horizontal, 16)
                    paymentRow(label: "Month", value: Date().formatted(.dateTime.month(.wide).year()))
                    Divider().padding(.horizontal, 16)
                    paymentRow(label: "Amount Due", value: "Rs. \(Int(service.amountThisMonth))", highlight: true)
                } else if let record = passengerCostTrackingViewModel.selectedRecord {
                    paymentRow(label: "Month", value: record.monthLabel)
                    Divider().padding(.horizontal, 16)
                    paymentRow(label: "Session", value: record.session.rawValue)
                    Divider().padding(.horizontal, 16)
                    paymentRow(label: "Amount Due", value: "Rs. \(Int(record.amount))", highlight: true)
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    passengerCostTrackingViewModel.confirmPayment()
                } label: {
                    Text("Confirm & Pay")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(LinearGradient.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    passengerCostTrackingViewModel.showPaymentSheet = false
                } label: {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    private func paymentRow(label: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: highlight ? .bold : .semibold))
                .foregroundColor(highlight ? Color.brandAccent : .textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func sessionBadge(_ session: TripSession, onDark: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: sessionIcon(session))
                .font(.system(size: 10, weight: .semibold))
            Text(session.rawValue)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(onDark ? Color.white.opacity(0.15) : Color.brandAccent.opacity(0.12))
        .foregroundColor(onDark ? .white : Color.brandAccent)
        .clipShape(Capsule())
    }

    private func sessionIcon(_ session: TripSession) -> String {
        switch session {
        case .morning: return "sunrise.fill"
        case .evening: return "moon.fill"
        case .both:    return "arrow.2.squarepath"
        }
    }

    private func progressPill(elapsed: Int, total: Int) -> some View {
        let progress = min(Double(elapsed) / Double(total), 1.0)
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.20))
                .frame(width: 90, height: 6)
            Capsule()
                .fill(Color.white)
                .frame(width: 90 * progress, height: 6)
        }
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        PassengerCostTrackingView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    NavigationStack {
        PassengerCostTrackingView()
    }
    .preferredColorScheme(.light)
}
