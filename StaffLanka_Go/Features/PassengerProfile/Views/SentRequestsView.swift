//
//  SentRequestsView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import SwiftUI

struct SentRequestsView: View {
    @StateObject private var sentRequestsViewModel = SentRequestsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            content
        }
        .background(Color.appBackground)
        .navigationTitle("Sent Requests")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            sentRequestsViewModel.startListeningForUserRequests()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    sentRequestsViewModel.toggleSort()
                } label: {
                    Image(systemName: sentRequestsViewModel.sortDescending
                          ? "arrow.down.circle" : "arrow.up.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.brandAccent)
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SentRequestsViewModel.FilterOption.allCases, id: \.self) { option in
                    filterChip(option)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.appBackground)
    }

    private func filterChip(_ option: SentRequestsViewModel.FilterOption) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                sentRequestsViewModel.selectedFilter = option
            }
        } label: {
            Text(option.rawValue)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(sentRequestsViewModel.selectedFilter == option ? .white : .brandAccent)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    sentRequestsViewModel.selectedFilter == option
                        ? Color.brandAccent
                        : Color.brandAccent.opacity(0.10)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        if sentRequestsViewModel.isLoadingRequests {
            loadingState
        } else if sentRequestsViewModel.groupedRequests.isEmpty {
            emptyState
        } else {
            List {
                ForEach(sentRequestsViewModel.groupedRequests, id: \.0) { section, requests in
                    Section {
                        ForEach(requests) { request in
                            requestCard(request)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    } header: {
                        Text(section)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, 4)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.brandAccent)
            Text("Loading your requests…")
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }

    private func requestCard(_ request: SentRequest) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(sentRequestsViewModel.statusColor(for: request.status).opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: sentRequestsViewModel.statusIcon(for: request.status))
                        .font(.system(size: 18))
                        .foregroundColor(sentRequestsViewModel.statusColor(for: request.status))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(request.routeStart)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.textTertiary)
                        Text(request.routeEnd)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                    Text(request.driverName)
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                statusBadge(request.status)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().background(Color.divider).padding(.horizontal, 16)

            VStack(spacing: 10) {
                detailRow(icon: "location.fill",       label: "Pickup",   value: request.pickupLocation)
                detailRow(icon: "mappin.and.ellipse",  label: "Drop-off", value: request.dropoffLocation)
                detailRow(icon: "sun.and.horizon.fill", label: "Session",  value: request.session)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    sentRequestsViewModel.statusColor(for: request.status).opacity(
                        request.status == .pending ? 0.30 : 0.15
                    ),
                    lineWidth: 1
                )
        )
    }

    private func statusBadge(_ status: RequestStatus) -> some View {
        Text(status.rawValue)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(sentRequestsViewModel.statusColor(for: status))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(sentRequestsViewModel.statusColor(for: status).opacity(0.12))
            .clipShape(Capsule())
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.brandAccent)
                .frame(width: 18)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.textTertiary)
                .frame(width: 52, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textPrimary)
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 48)
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.brandAccent.opacity(0.10))
                    .frame(width: 64, height: 64)
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.brandAccent)
            }
            Text("No Requests Found")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)
            Text("Requests you send to drivers will appear here.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: 48)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

#Preview("Dark") {
    NavigationStack { SentRequestsView() }
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    NavigationStack { SentRequestsView() }
        .preferredColorScheme(.light)
}
