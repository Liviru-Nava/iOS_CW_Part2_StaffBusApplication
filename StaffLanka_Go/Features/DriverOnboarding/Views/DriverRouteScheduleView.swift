//
//  DriverRouteScheduleView.swift
//  StaffLanka_Go
//  Created by Liviru Navaratna on 2026-04-07.
//

import SwiftUI
import MapKit

struct DriverRouteScheduleView: View {
    @StateObject var vm: DriverRouteScheduleViewModel

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    routeDetails
                    if vm.startCoordinate != nil || vm.endCoordinate != nil {
                        fitRouteButton
                    }
                    stopsSection
                    scheduleSection
                    pricingSection
                    submitButton
                }
                .padding(.horizontal, 0)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Route & Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: Binding(
            get: { vm.activeSearchTarget != nil },
            set: { if !$0 { vm.cancelSearch() } }
        )) {
            SearchMapSheet(vm: vm)
        }
        .fullScreenCover(isPresented: Binding(
            get: { vm.onboardingComplete },
            set: { vm.onboardingComplete = $0 }
        )) {
            DriverOnboardingSuccessView()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.13))
                    .frame(width: 80, height: 80)
                Image(systemName: "map.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.brandAccent)
            }

            Text("Your Journey and Time")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            Text("Set up your bus route stops and operating schedule")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var topBar: some View {
        HStack {
            Button { vm.showDriverMenu() } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.textPrimary)
            }
            .buttonStyle(.plain)
            Spacer()
            Text("Route Setup")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Button { vm.showNotifications() } label: {
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.textPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, safeTopPadding())
        .frame(height: safeTopPadding() + 44)
        .background(Color.surfaceBackground)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    private var routeDetails: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Route Details")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
            }
            VStack(spacing: 10) {
                locationButton(
                    icon: "location.fill",
                    iconColor: Color.statusActive,
                    label: "Starting Point",
                    value: vm.startingPoint,
                    isPinned: vm.startCoordinate != nil,
                    action: { vm.beginSearch(for: .start) },
                    clearAction: { vm.clearStart() }
                )
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.divider)
                        .frame(width: 1, height: 16)
                        .padding(.leading, 28)
                    Spacer()
                }
                locationButton(
                    icon: "mappin",
                    iconColor: Color.statusDanger,
                    label: "Ending Point",
                    value: vm.endingPoint,
                    isPinned: vm.endCoordinate != nil,
                    action: { vm.beginSearch(for: .end) },
                    clearAction: { vm.clearEnd() }
                )
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func locationButton(icon: String, iconColor: Color, label: String, value: String, isPinned: Bool, action: @escaping () -> Void, clearAction: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Button(action: action) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 15))
                            .foregroundStyle(iconColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                        Text(value.isEmpty ? "Tap to search or pin on map" : value)
                            .font(.system(size: 14, weight: value.isEmpty ? .regular : .semibold))
                            .foregroundStyle(value.isEmpty ? Color.textTertiary : Color.textPrimary)
                            .lineLimit(1)
                    }
                    Spacer()
                    if !isPinned {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                .padding(14)
                .background(Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isPinned ? Color.statusActive.opacity(0.4) : Color.divider, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if isPinned {
                Button(action: clearAction) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var fitRouteButton: some View {
        Button { vm.flyToRoute() } label: {
            HStack(spacing: 8) {
                Image(systemName: "scope").font(.system(size: 14))
                Text("Preview Route on Map").font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(Color.brandAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.brandAccent.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.brandAccent.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private var stopsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Route Stops")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(vm.stops.count) stop\(vm.stops.count == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }

            if vm.stops.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.brandAccent)
                    Text("No stops added yet.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(Array(vm.orderedStops.enumerated()), id: \.element.id) { index, stop in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle().fill(Color.brandAccent.opacity(0.13)).frame(width: 26, height: 26)
                                Text("\(index + 1)").font(.system(size: 11, weight: .bold)).foregroundStyle(Color.brandAccent)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(stop.name).font(.system(size: 13, weight: .medium)).foregroundStyle(Color.textPrimary)
                                if !stop.locationLabel.isEmpty {
                                    Text(stop.locationLabel).font(.system(size: 11)).foregroundStyle(Color.textTertiary).lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.surfaceBackground)
                        .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                    }
                    .onMove { sourceOffsets, destinationOffset in
                        vm.moveStop(from: sourceOffsets, to: destinationOffset)
                    }
                    .onDelete { offsets in
                        vm.removeStop(at: offsets)
                    }
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .frame(height: CGFloat(vm.stops.count) * 54)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .environment(\.editMode, .constant(.active))
            }

            Button {
                vm.beginSearch(for: .stop)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 15))
                    Text("Add Stop").font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.brandAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.brandAccent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.brandAccent.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    private var scheduleSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Schedule")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
            }

            daysRow

            tripRow(
                label: "Morning Trip",
                icon: "sunrise.fill",
                iconColor: Color.statusWarning,
                trip: $vm.morningTrip
            )

            tripRow(
                label: "Evening Trip",
                icon: "moon.fill",
                iconColor: Color.brandAccent,
                trip: $vm.eveningTrip
            )
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    private var daysRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Days of Operation")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textSecondary)
            HStack(spacing: 5) {
                ForEach(DayOfWeek.allCases) { day in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { vm.toggleDay(day) }
                    } label: {
                        Text(day.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(vm.selectedDays.contains(day) ? (day.isWeekend ? Color.statusWarning.opacity(0.18) : Color.brandAccent.opacity(0.18)) : Color.surfaceBackground)
                            .foregroundStyle(vm.selectedDays.contains(day) ? (day.isWeekend ? Color.statusWarning : Color.brandAccent) : Color.textTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(vm.selectedDays.contains(day) ? (day.isWeekend ? Color.statusWarning.opacity(0.4) : Color.brandAccent.opacity(0.4)) : Color.divider, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func tripRow(label: String, icon: String, iconColor: Color, trip: Binding<TripSchedule>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundStyle(iconColor)
                Text(label).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.textPrimary)
            }
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Set Est. Departure Time").font(.system(size: 10)).foregroundStyle(Color.textTertiary)
                    DatePicker("", selection: trip.departureTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(Color.brandAccent)
                        .onChange(of: trip.wrappedValue.departureTime) { _, _ in vm.updateArrivalTimes() }
                }
                Spacer()
                Rectangle().fill(Color.divider).frame(width: 1, height: 40)
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 3) {
                        Text("Est. Arrival Time").font(.system(size: 10)).foregroundStyle(Color.textTertiary)
                        Image(systemName: "wand.and.stars").font(.system(size: 9)).foregroundStyle(Color.brandAccent)
                    }
                    Text(vm.computedArrival(from: trip.wrappedValue.departureTime), style: .time)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var pricingSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Trip Pricing (LKR)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                priceInputField(label: "Morning Trip Only", placeholder: "e.g. 8500", text: $vm.morningPrice)
                priceInputField(label: "Evening Trip Only", placeholder: "e.g. 8500", text: $vm.eveningPrice)
                priceInputField(label: "Both Trips (Daily)", placeholder: "e.g. 14000", text: $vm.bothTripsPrice)
                
                if !vm.isPricingValid {
                    Text("Prices must be between 5,000 and 15,000. Both trips must be less than the sum of morning and evening.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.statusDanger)
                        .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }
    
    private func priceInputField(label: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textSecondary)
            
            Spacer()
            
            HStack(spacing: 6) {
                Text("Rs.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                
                TextField(placeholder, text: text)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .tint(Color.brandAccent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.divider, lineWidth: 1)
            )
        }
    }

    private var submitButton: some View {
        Button {
            Task { await vm.submitOnboarding() }
        } label: {
            ZStack {
                if vm.isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Text("Complete & Submit")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                vm.canSubmit
                ? LinearGradient.brand
                : LinearGradient(colors: [Color.statusInactive.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!vm.canSubmit || vm.isSubmitting)
        .padding(.horizontal, 16)
    }

    private var bottomPanel: some View {
        HStack {
            Button { vm.showPreviousRoute() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.textPrimary)
            }
            .buttonStyle(.plain)

            Spacer()

            if vm.canSubmit {
                Button {
                    Task { await vm.submitOnboarding() }
                } label: {
                    HStack(spacing: 6) {
                        if vm.isSubmitting {
                            ProgressView().tint(.white).scaleEffect(0.75)
                        } else {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 16))
                            Text("Submit").font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(LinearGradient.brand)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Button { vm.showNextRoute() } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.textPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, safeBottomPadding())
        .frame(minHeight: 56)
        .background(Color.surfaceBackground)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: -2)
    }

    private func safeTopPadding() -> CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.top ?? 44
    }

    private func safeBottomPadding() -> CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.bottom ?? 34
    }
}

struct SearchMapSheet: View {
    @ObservedObject var vm: DriverRouteScheduleViewModel
    @FocusState private var searchFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            RouteMapView(
                region: $vm.mapRegion,
                annotations: vm.allMapAnnotations,
                pendingPin: vm.mapPinnedCoordinate.map {
                    MapSearchResult(title: vm.mapPinnedLabel.isEmpty ? "Selected" : vm.mapPinnedLabel, subtitle: "pending", coordinate: $0)
                },
                onTap: { coord in vm.pinOnMap(coordinate: coord) }
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                searchHeader
                    .padding(.top, safeTopPadding())

                if !vm.mapSearchResults.isEmpty {
                    searchResultsList
                }

                Spacer()

                if vm.mapPinnedCoordinate != nil {
                    confirmBanner
                        .padding(.bottom, safeBottomPadding() + 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: vm.mapPinnedCoordinate != nil)
        }
        .onAppear { searchFocused = true }
    }

    private var searchHeader: some View {
        HStack(spacing: 10) {
            Button {
                vm.cancelSearch()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(searchFocused ? Color.brandAccent : Color.textTertiary)

                TextField(searchPlaceholder, text: $vm.mapSearchQuery)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                    .tint(Color.brandAccent)
                    .focused($searchFocused)
                    .onChange(of: vm.mapSearchQuery) { _, q in vm.searchLocations(query: q) }

                if vm.isSearching {
                    ProgressView().tint(Color.brandAccent).scaleEffect(0.8)
                } else if !vm.mapSearchQuery.isEmpty {
                    Button {
                        vm.mapSearchQuery = ""
                        vm.mapSearchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(searchFocused ? Color.brandAccent.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .padding(.horizontal, 16)
    }

    private var searchResultsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(vm.mapSearchResults) { result in
                    Button {
                        vm.selectSearchResult(result)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.brandAccent)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.textPrimary)
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 56)
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .frame(maxHeight: 280)
    }

    private var confirmBanner: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(confirmBannerLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                Text(vm.mapPinnedLabel.isEmpty ? "Location selected" : vm.mapPinnedLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                vm.confirmPin()
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 14))
                    Text("Confirm").font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(LinearGradient.brand)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.statusActive.opacity(0.3), lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private var confirmBannerLabel: String {
        switch vm.activeSearchTarget {
        case .start: return "Starting Point"
        case .end:   return "Ending Point"
        case .stop:  return "Route Stop"
        case nil:    return "Location"
        }
    }

    private var searchPlaceholder: String {
        switch vm.activeSearchTarget {
        case .start: return "Search for starting point…"
        case .end:   return "Search for ending point…"
        case .stop:  return "Search for stop…"
        case nil:    return "Search…"
        }
    }

    private func safeTopPadding() -> CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.top ?? 44
    }

    private func safeBottomPadding() -> CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.bottom ?? 34
    }
}

struct RouteMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var annotations: [MapSearchResult]
    var pendingPin: MapSearchResult?
    var onTap: (CLLocationCoordinate2D) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.showsCompass = true
        map.showsScale = true
        map.setRegion(region, animated: false)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        map.addGestureRecognizer(tap)
        context.coordinator.mapView = map
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        let threshold = 0.001
        if abs(map.region.center.latitude - region.center.latitude) > threshold ||
           abs(map.region.center.longitude - region.center.longitude) > threshold {
            map.setRegion(region, animated: true)
        }
        map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
        map.removeOverlays(map.overlays)
        var coords: [CLLocationCoordinate2D] = []
        for item in annotations { map.addAnnotation(RouteAnnotation(item: item)); coords.append(item.coordinate) }
        if let pin = pendingPin { map.addAnnotation(RouteAnnotation(item: pin)) }
        if coords.count >= 2 { map.addOverlay(MKPolyline(coordinates: coords, count: coords.count)) }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var onTap: (CLLocationCoordinate2D) -> Void
        weak var mapView: MKMapView?
        init(onTap: @escaping (CLLocationCoordinate2D) -> Void) { self.onTap = onTap }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let map = mapView else { return }
            let pt = g.location(in: map)
            for ann in map.annotations { if let v = map.view(for: ann), v.frame.contains(pt) { return } }
            onTap(map.convert(pt, toCoordinateFrom: map))
        }

        func mapView(_ map: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let ann = annotation as? RouteAnnotation else { return nil }
            let v = map.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: ann, reuseIdentifier: "pin")
            v.annotation = ann; v.canShowCallout = true; v.animatesWhenAdded = true
            switch ann.item.subtitle {
            case "Start":   v.markerTintColor = UIColor(Color.statusActive);   v.glyphImage = UIImage(systemName: "flag.fill")
            case "End":     v.markerTintColor = UIColor(Color.statusDanger);   v.glyphImage = UIImage(systemName: "mappin")
            case "pending": v.markerTintColor = UIColor(Color.brandAccent);    v.glyphImage = UIImage(systemName: "plus")
            default:        v.markerTintColor = UIColor(Color.brandSecondary); v.glyphImage = UIImage(systemName: "circle.fill")
            }
            return v
        }

        func mapView(_ map: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let poly = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
            let r = MKPolylineRenderer(polyline: poly)
            r.strokeColor = UIColor(Color.brandAccent).withAlphaComponent(0.7)
            r.lineWidth = 3; r.lineDashPattern = [8, 4]
            return r
        }
    }
}

class RouteAnnotation: NSObject, MKAnnotation {
    let item: MapSearchResult
    var coordinate: CLLocationCoordinate2D { item.coordinate }
    var title: String? { item.title }
    init(item: MapSearchResult) { self.item = item }
}

struct DriverOnboardingSuccessView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    Circle().fill(Color.statusActive.opacity(0.12)).frame(width: 110, height: 110)
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 50)).foregroundStyle(Color.statusActive)
                }
                VStack(spacing: 10) {
                    Text("You're All Set!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Text("Your driver profile has been submitted for review. You'll be notified once approved.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
                Button { dismiss() } label: {
                    Text("Back to Login")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(LinearGradient.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DriverRouteScheduleView(vm: DriverRouteScheduleViewModel())
    }
    .preferredColorScheme(.dark)
}
