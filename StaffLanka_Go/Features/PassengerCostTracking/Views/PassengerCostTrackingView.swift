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
                if passengerCostTrackingViewModel.isLoadingServices {
                    loadingState
                } else if passengerCostTrackingViewModel.hasService {
                    serviceCardsSection.padding(.top, 8)
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
        .onAppear { passengerCostTrackingViewModel.startListening() }
        .sheet(isPresented: $passengerCostTrackingViewModel.showPaymentSheet) {
            paymentSheet
        }
        .alert("Payment Error", isPresented: Binding(
            get: { passengerCostTrackingViewModel.paymentError != nil },
            set: { if !$0 { passengerCostTrackingViewModel.paymentError = nil } }
        )) {
            Button("OK", role: .cancel) { passengerCostTrackingViewModel.paymentError = nil }
        } message: {
            Text(passengerCostTrackingViewModel.paymentError ?? "")
        }
        .alert("Payment Confirmed", isPresented: Binding(
            get: { passengerCostTrackingViewModel.paymentSuccessMessage != nil },
            set: { if !$0 { passengerCostTrackingViewModel.paymentSuccessMessage = nil } }
        )) {
            Button("OK", role: .cancel) { passengerCostTrackingViewModel.paymentSuccessMessage = nil }
        } message: {
            Text(passengerCostTrackingViewModel.paymentSuccessMessage ?? "")
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 80)
            ProgressView().scaleEffect(1.2).tint(Color.brandAccent)
            Text("Loading your services...").font(.system(size: 13)).foregroundColor(.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // Service cards section
    // If only one service and it is "Both": single full-width card, no horizontal scroll
    // If multiple services OR single morning/evening: horizontally scrollable cards
    private var serviceCardsSection: some View {
        let services = passengerCostTrackingViewModel.services
        let showSingleCard = services.count == 1 && services.first?.session == .both

        return Group {
            if showSingleCard, let singleService = services.first {
                serviceCard(singleService).padding(.horizontal, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(services) { service in
                            serviceCard(service)
                                .frame(width: UIScreen.main.bounds.width - 56)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func serviceCard(_ service: ServiceRegistration) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient.brand.clipShape(RoundedRectangle(cornerRadius: 20))
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(service.routeName).font(.system(size: 17, weight: .bold)).foregroundColor(.white).lineLimit(1)
                        sessionBadge(service.session, onDark: true)
                    }
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.12)).frame(width: 36, height: 36)
                        Image(systemName: sessionIcon(service.session)).font(.system(size: 14)).foregroundColor(.white.opacity(0.85))
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill").foregroundColor(.white.opacity(0.6)).font(.system(size: 13))
                    Text(service.pickup).font(.system(size: 13)).foregroundColor(.white.opacity(0.80))
                    Image(systemName: "arrow.right").font(.system(size: 11, weight: .semibold)).foregroundColor(.white.opacity(0.45))
                    Text(service.destination).font(.system(size: 13)).foregroundColor(.white.opacity(0.80))
                }

                Divider().background(Color.white.opacity(0.18))

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Amount This Month").font(.system(size: 11)).foregroundColor(.white.opacity(0.60))
                        Text("Rs. \(Int(service.amountThisMonth))").font(.system(size: 30, weight: .bold, design: .rounded)).foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Day \(service.daysElapsed) of \(service.totalDays)").font(.system(size: 11)).foregroundColor(.white.opacity(0.60))
                        progressPill(elapsed: service.daysElapsed, total: service.totalDays)
                    }
                }

                if !service.currentMonthPaid {
                    Button { passengerCostTrackingViewModel.initiatePayment(for: service) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "creditcard.fill").font(.system(size: 14))
                            Text("Pay for This Month").font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(Color.brandPrimary).frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 14))
                        Text("Paid for This Month").font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.75)).frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Color.white.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20)
        }
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Filter").font(.system(size: 12, weight: .semibold)).foregroundColor(.textTertiary).textCase(.uppercase).tracking(0.5).padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterPill(label: "All", active: passengerCostTrackingViewModel.sessionFilter == nil && !passengerCostTrackingViewModel.showUnpaidOnly && !passengerCostTrackingViewModel.sortByAmount) {
                        passengerCostTrackingViewModel.sessionFilter = nil
                        passengerCostTrackingViewModel.showUnpaidOnly = false
                        passengerCostTrackingViewModel.sortByAmount = false
                    }
                    Divider().frame(height: 18)
                    filterPill(label: "Morning", icon: "sunrise.fill", active: passengerCostTrackingViewModel.sessionFilter == .morning) {
                        passengerCostTrackingViewModel.sessionFilter = passengerCostTrackingViewModel.sessionFilter == .morning ? nil : .morning
                    }
                    filterPill(label: "Evening", icon: "moon.fill", active: passengerCostTrackingViewModel.sessionFilter == .evening) {
                        passengerCostTrackingViewModel.sessionFilter = passengerCostTrackingViewModel.sessionFilter == .evening ? nil : .evening
                    }
                    filterPill(label: "Both", icon: "arrow.2.squarepath", active: passengerCostTrackingViewModel.sessionFilter == .both) {
                        passengerCostTrackingViewModel.sessionFilter = passengerCostTrackingViewModel.sessionFilter == .both ? nil : .both
                    }
                    Divider().frame(height: 18)
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
                if let icon { Image(systemName: icon).font(.system(size: 11, weight: .medium)) }
                Text(label).font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
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
                Text("Payment History").font(.system(size: 15, weight: .semibold)).foregroundColor(.textPrimary)
                Spacer()
                Text("\(passengerCostTrackingViewModel.filteredRecords.count) records").font(.system(size: 12)).foregroundColor(.textTertiary)
            }
            .padding(.horizontal, 16)

            if passengerCostTrackingViewModel.filteredRecords.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "doc.text.magnifyingglass").font(.system(size: 28)).foregroundColor(.textTertiary)
                    Text("No payment records yet.").font(.system(size: 14)).foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 40)
            } else {
                ForEach(passengerCostTrackingViewModel.filteredRecords) { record in monthlyRecordCard(record) }
            }
        }
    }

    private func monthlyRecordCard(_ record: MonthlyRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.monthLabel).font(.system(size: 15, weight: .bold)).foregroundColor(.textPrimary)
                    sessionBadge(record.session, onDark: false)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Rs. \(Int(record.amount))").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.textPrimary)
                    paidBadge
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text(record.routeName).font(.system(size: 13, weight: .semibold)).foregroundColor(.textPrimary)
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill").font(.system(size: 11)).foregroundColor(.textTertiary)
                    Text(record.pickup).font(.system(size: 12)).foregroundColor(.textSecondary)
                    Image(systemName: "arrow.right").font(.system(size: 10, weight: .semibold)).foregroundColor(.textTertiary)
                    Text(record.destination).font(.system(size: 12)).foregroundColor(.textSecondary)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.divider, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private var paidBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 10, weight: .semibold))
            Text("Paid").font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color.statusActive.opacity(0.12)).foregroundColor(.statusActive).clipShape(Capsule())
    }

    private var passengerCostTrackingEmptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 80)
            ZStack {
                Circle().fill(Color.brandAccent.opacity(0.10)).frame(width: 96, height: 96)
                Image(systemName: "creditcard.slash").font(.system(size: 38)).foregroundColor(Color.brandAccent)
            }
            Text("No Registered Service").font(.system(size: 22, weight: .bold)).foregroundColor(.textPrimary)
            Text("You don't have any registered bus service yet.\nOnce you join a route, your cost tracking will appear here.")
                .font(.system(size: 15)).foregroundColor(.textSecondary).multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }

    @ViewBuilder
    private var paymentSheet: some View {
        if let service = passengerCostTrackingViewModel.selectedServiceForPayment {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3).fill(Color.divider).frame(width: 36, height: 4).padding(.top, 14).padding(.bottom, 20)
                VStack(spacing: 6) {
                    ZStack {
                        Circle().fill(Color.brandAccent.opacity(0.12)).frame(width: 64, height: 64)
                        Image(systemName: "creditcard.fill").font(.system(size: 26)).foregroundColor(Color.brandAccent)
                    }
                    Text("Confirm Payment").font(.system(size: 20, weight: .bold)).foregroundColor(.textPrimary).padding(.top, 4)
                }
                .padding(.bottom, 24)

                VStack(spacing: 0) {
                    paymentRow(label: "Route", value: service.routeName)
                    Divider().padding(.horizontal, 16)
                    paymentRow(label: "Session", value: service.session.rawValue)
                    Divider().padding(.horizontal, 16)
                    paymentRow(label: "Month", value: PassengerCostTrackingViewModel.currentMonthLabel())
                    Divider().padding(.horizontal, 16)
                    paymentRow(label: "Amount Due", value: "Rs. \(Int(service.amountThisMonth))", highlight: true)
                }
                .background(Color.cardBackground).clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 12) {
                    Button { passengerCostTrackingViewModel.confirmPayment() } label: {
                        Text("Confirm & Pay").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(LinearGradient.brand).clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    Button { passengerCostTrackingViewModel.dismissPaymentSheet() } label: {
                        Text("Cancel").font(.system(size: 15, weight: .medium)).foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 32)
            }
            .background(Color.appBackground)
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(24)
        }
    }

    private func paymentRow(label: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(.textSecondary)
            Spacer()
            Text(value).font(.system(size: 14, weight: highlight ? .bold : .semibold)).foregroundColor(highlight ? Color.brandAccent : .textPrimary)
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
    }

    private func sessionBadge(_ session: TripSession, onDark: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: sessionIcon(session)).font(.system(size: 10, weight: .semibold))
            Text(session.rawValue).font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(onDark ? Color.white.opacity(0.15) : Color.brandAccent.opacity(0.12))
        .foregroundColor(onDark ? .white : Color.brandAccent).clipShape(Capsule())
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
            Capsule().fill(Color.white.opacity(0.20)).frame(width: 90, height: 6)
            Capsule().fill(Color.white).frame(width: 90 * progress, height: 6)
        }
    }
}

#Preview("Dark Mode") { NavigationStack { PassengerCostTrackingView() }.preferredColorScheme(.dark) }
#Preview("Light Mode") { NavigationStack { PassengerCostTrackingView() }.preferredColorScheme(.light) }
