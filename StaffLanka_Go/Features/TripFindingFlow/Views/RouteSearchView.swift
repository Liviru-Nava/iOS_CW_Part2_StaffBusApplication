//
//  RouteSearchView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-02.
//

import SwiftUI

struct RouteSearchView: View {

    @StateObject private var routeSearchViewModel = RouteSearchViewModel()
    @State private var showPickupSheet = false
    @State private var showDestinationSheet = false

    var body: some View {
        VStack(spacing: 0) {
            locationSelectors
            Divider().background(Color.divider)
            mainContent
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Find a Route")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPickupSheet) {
            LocationPickerSheet(
                title: "Select Pickup",
                activeField: .pickup,
                routeSearchViewModel: routeSearchViewModel,
                isPresented: $showPickupSheet
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showDestinationSheet) {
            LocationPickerSheet(
                title: "Select Destination",
                activeField: .destination,
                routeSearchViewModel: routeSearchViewModel,
                isPresented: $showDestinationSheet
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
    }

    private var locationSelectors: some View {
        HStack(spacing: 10) {
            locationButton(
                label: routeSearchViewModel.pickupText.isEmpty ? "Pickup" : routeSearchViewModel.pickupText,
                icon: "location.fill",
                iconColor: routeSearchViewModel.isUsingCurrentLocationForPickup ? Color.statusActive : (routeSearchViewModel.pickupLocation != nil ? Color.statusActive : Color.textTertiary),
                isFilled: routeSearchViewModel.pickupLocation != nil || routeSearchViewModel.isUsingCurrentLocationForPickup,
                systemIconOverride: routeSearchViewModel.isUsingCurrentLocationForPickup ? "location.fill" : nil,
                onTap: {
                    showPickupSheet = true
                },
                onClear: routeSearchViewModel.pickupLocation != nil || routeSearchViewModel.isUsingCurrentLocationForPickup ? {
                    routeSearchViewModel.clearPickup()
                } : nil
            )

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                    routeSearchViewModel.swapLocations()
                }
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Color.cardBackground)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.divider, lineWidth: 1))
            }
            .buttonStyle(.plain)

            locationButton(
                label: routeSearchViewModel.destinationText.isEmpty ? "Destination" : routeSearchViewModel.destinationText,
                icon: "mappin",
                iconColor: routeSearchViewModel.destinationLocation != nil ? Color.brandAccent : Color.textTertiary,
                isFilled: routeSearchViewModel.destinationLocation != nil,
                systemIconOverride: nil,
                onTap: {
                    showDestinationSheet = true
                },
                onClear: routeSearchViewModel.destinationLocation != nil ? {
                    routeSearchViewModel.clearDestination()
                } : nil
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appBackground)
    }

    private func locationButton(
        label: String,
        icon: String,
        iconColor: Color,
        isFilled: Bool,
        systemIconOverride: String?,
        onTap: @escaping () -> Void,
        onClear: (() -> Void)?
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: systemIconOverride ?? icon)
                    .font(.system(size: systemIconOverride != nil ? 11 : 8))
                    .foregroundStyle(iconColor)
                    .frame(width: 14)

                Text(label)
                    .font(.system(size: 14, weight: isFilled ? .medium : .regular))
                    .foregroundStyle(isFilled ? Color.textPrimary : Color.textTertiary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let clear = onClear {
                    Button(action: clear) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isFilled ? Color.brandAccent.opacity(0.4) : Color.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            if routeSearchViewModel.bothLocationsSelected {
                routesSection
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bus.fill")
                .font(.system(size: 38))
                .foregroundStyle(Color.brandAccent.opacity(0.4))
                .padding(.top, 60)

            Text("Where are you headed?")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Text("Select your pickup and destination\nto see available staff bus services.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }

    private var routesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                if let pickup = routeSearchViewModel.pickupLocation, let dest = routeSearchViewModel.destinationLocation {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: routeSearchViewModel.isUsingCurrentLocationForPickup ? 11 : 7))
                            .foregroundStyle(Color.statusActive)
                        Text(pickup.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.textTertiary)
                        Image(systemName: "mappin")
                            .font(.system(size: 7))
                            .foregroundStyle(Color.brandAccent)
                        Text(dest.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                Spacer()
                if routeSearchViewModel.isSearching {
                    ProgressView().tint(Color.brandAccent).scaleEffect(0.8)
                } else if !routeSearchViewModel.matchedRoutes.isEmpty {
                    Text("\(routeSearchViewModel.matchedRoutes.count) found")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                }
            }

            if routeSearchViewModel.isSearching {
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in skeletonCard }
                }
            } else if routeSearchViewModel.matchedRoutes.isEmpty {
                noRoutesCard
            } else {
                VStack(spacing: 12) {
                    ForEach(routeSearchViewModel.matchedRoutes) { route in routeCard(route) }
                }
            }
        }
    }

    private func routeCard(_ route: BusRoute) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(route.routeName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        Text(route.busNumber)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.brandAccent)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.brandAccent.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    Spacer()
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.statusWarning)
                        Text(String(format: "%.1f", route.rating))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                    }
                }

                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.textTertiary)
                        Text(route.driverName)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.textSecondary)
                    }

                    Circle()
                        .fill(Color.divider)
                        .frame(width: 3, height: 3)

                    HStack(spacing: 5) {
                        Image(systemName: route.vehicleType.lowercased() == "van" ? "car.fill" : "bus.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.brandAccent)
                        Text("\(route.vehicleBrand) \(route.vehicleType)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.brandAccent)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.brandAccent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
            .padding(16)

            Divider().padding(.horizontal, 16)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Morning")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                    Text("\(route.morningStartTime) – \(route.morningEndTime)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                }
                Spacer()
                Rectangle()
                    .fill(Color.divider)
                    .frame(width: 1, height: 32)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Evening")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                    Text("\(route.eveningStartTime) – \(route.eveningEndTime)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.horizontal, 16)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Est. Monthly Fee")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textTertiary)
                    Text("Rs. \(Int(route.estimatedMonthlyCost))")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(route.availableSeats) seats left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(seatColor(route.availableSeats))
                    Text("of \(route.capacity)")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.horizontal, 16)

            NavigationLink {
                RouteDetailView(
                    route: route,
                    pickupLocation: routeSearchViewModel.pickupLocation?.name ?? routeSearchViewModel.pickupText,
                    destinationLocation: routeSearchViewModel.destinationLocation?.name ?? routeSearchViewModel.destinationText
                )
            } label: {
                Text("View Route Details")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(route.availableSeats > 0 ? Color.brandAccent : Color.statusInactive)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(route.availableSeats == 0)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.divider, lineWidth: 1))
    }

    private func seatColor(_ seats: Int) -> Color {
        switch seats {
        case 0: return Color.statusDanger
        case 1...5: return Color.statusWarning
        default: return Color.statusActive
        }
    }

    private var skeletonCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10).fill(Color.surfaceBackground).frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.surfaceBackground).frame(height: 13).frame(maxWidth: 150)
                    RoundedRectangle(cornerRadius: 4).fill(Color.surfaceBackground).frame(height: 10).frame(maxWidth: 90)
                }
                Spacer()
            }
            RoundedRectangle(cornerRadius: 4).fill(Color.surfaceBackground).frame(height: 10).frame(maxWidth: 110)
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .redacted(reason: .placeholder)
    }

    private var noRoutesCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "bus.doubledecker")
                .font(.system(size: 34))
                .foregroundStyle(Color.brandAccent.opacity(0.45))
            Text("No services found")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Text("No staff bus currently covers this route.\nTry nearby stops or check back later.")
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct LocationPickerSheet: View {

    let title: String
    let activeField: ActiveSearchField
    @ObservedObject var routeSearchViewModel: RouteSearchViewModel
    @Binding var isPresented: Bool
    @FocusState private var searchFocused: Bool
    @State private var localQuery: String = ""
    @GestureState private var isDetectingDrag: Bool = false

    private var filteredList: [PredefinedLocation] {
        if localQuery.isEmpty { return routeSearchViewModel.predefinedLocations }
        return routeSearchViewModel.predefinedLocations.filter {
            $0.name.localizedCaseInsensitiveContains(localQuery) ||
            $0.area.localizedCaseInsensitiveContains(localQuery)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            Divider().background(Color.divider)
            searchBar
            Divider().background(Color.divider)
            locationList
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear {
            routeSearchViewModel.activeField = activeField
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                searchFocused = true
            }
        }
    }

    private var sheetHeader: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
            TextField("Search location...", text: $localQuery)
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)
                .tint(Color.brandAccent)
                .focused($searchFocused)
                .autocorrectionDisabled()
            if !localQuery.isEmpty {
                Button {
                    localQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(searchFocused ? Color.brandAccent.opacity(0.5) : Color.divider, lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .animation(.easeInOut(duration: 0.15), value: searchFocused)
    }

    private var locationList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                currentLocationRow
                Divider()
                if filteredList.isEmpty {
                    Text("No locations match your search")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(Array(filteredList.enumerated()), id: \.element.id) { index, location in
                        Button {
                            if isDetectingDrag { return }
                            routeSearchViewModel.selectLocation(location)
                            isPresented = false
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brandAccent.opacity(0.10))
                                        .frame(width: 38, height: 38)
                                    Image(systemName: "mappin.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.brandAccent)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(location.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.textPrimary)
                                    Text(location.area)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.textSecondary)
                                }
                                Spacer()
                                if (activeField == .pickup && routeSearchViewModel.pickupLocation?.id == location.id) ||
                                   (activeField == .destination && routeSearchViewModel.destinationLocation?.id == location.id) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.brandAccent)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 13)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < filteredList.count - 1 {
                            Divider().padding(.leading, 72)
                        }
                    }
                }
            }
        }
        .gesture(DragGesture().updating($isDetectingDrag) { _, state, _ in state = true })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var currentLocationRow: some View {
        Button {
            if activeField == .pickup {
                routeSearchViewModel.useCurrentLocationForPickupMocked()
            } else {
                routeSearchViewModel.useCurrentLocationForDestinationMocked()
            }
            isPresented = false
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.statusActive.opacity(0.13))
                        .frame(width: 38, height: 38)
                    Image(systemName: "location.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.statusActive)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use My Current Location")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text("Nearest stop matched automatically")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Dark") {
    NavigationStack { RouteSearchView() }
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    NavigationStack { RouteSearchView() }
        .preferredColorScheme(.light)
}
