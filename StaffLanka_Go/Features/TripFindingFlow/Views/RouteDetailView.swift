//
//  RouteDetailView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-02.
//

import SwiftUI
import MapKit

struct RouteDetailView: View {

    let route: PassengerRouteResult
    let pickupLocation: String
    let destinationLocation: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var routeDetailViewModel: RouteDetailViewModel
    @State private var showJoinSheet = false
    @State private var showAllReviews = false
    @State private var showFullMap = false

    init(route: PassengerRouteResult, pickupLocation: String, destinationLocation: String) {
        self.route = route
        self.pickupLocation = pickupLocation
        self.destinationLocation = destinationLocation
        _routeDetailViewModel = StateObject(wrappedValue: RouteDetailViewModel(
            route: route,
            pickupLocation: pickupLocation,
            destinationLocation: destinationLocation
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            mainScrollContent
            bottomBar
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Text(routeDetailViewModel.displayStart)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                    Text(routeDetailViewModel.displayEnd)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: routeDetailViewModel.shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.brandAccent)
                }
            }
        }
        // Pass all schedule data into JoinRequestView so EventKitManager can create accurate events
        .sheet(isPresented: $showJoinSheet) {
            JoinRequestView(
                pickupLocation:       pickupLocation,
                destinationLocation:  destinationLocation,
                routeName:            route.routeName,
                routeId:              route.id,
                driverId:             route.driverId,
                stops:                routeDetailViewModel.mapStops.map { $0.name },
                morningDepartureTime: route.morningDeparture,
                eveningDepartureTime: route.eveningDeparture,
                activeDays:           route.activeDays
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showAllReviews) {
            AllReviewsSheet()
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        .fullScreenCover(isPresented: $showFullMap) {
            FullRouteMapView(stops: routeDetailViewModel.mapStops, tripType: routeDetailViewModel.selectedTrip)
        }
    }

    private var mainScrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                mapSection
                driverVehicleSection
                tripDetailsSection
                pricingSection
                stopsSection
                reviewsSection
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }

    private var mapSection: some View {
        ZStack(alignment: .bottomTrailing) {
            Map {
                ForEach(routeDetailViewModel.mapStops) { stop in
                    Annotation(stop.name, coordinate: stop.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.brandAccent)
                                .frame(width: 10, height: 10)
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 2)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .allowsHitTesting(false)

            Button {
                showFullMap = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 11))
                    Text("Full Map")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.65))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(12)
        }
    }

    private var driverVehicleSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                driverAvatar
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(route.driverName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    HStack(spacing: 4) {
                        Image(systemName: route.isAcceptingRequests ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(route.isAcceptingRequests ? Color.statusActive : Color.statusDanger)
                        Text(route.isAcceptingRequests ? "Accepting Requests" : "Not Accepting")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(route.isAcceptingRequests ? Color.statusActive : Color.statusDanger)
                    }
                }
                Spacer()
            }
            .padding(16)

            Divider().padding(.horizontal, 16)

            VStack(spacing: 0) {
                infoRow(label: "Bus Name",     value: route.busName)
                Divider().padding(.leading, 16)
                infoRow(label: "Vehicle Type", value: route.busType)
                Divider().padding(.leading, 16)
                infoRow(label: "License Plate", value: route.plateNumber)
                Divider().padding(.leading, 16)
                infoRow(label: "Capacity",     value: "\(route.capacity) seats")
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.divider, lineWidth: 1))
    }

    @ViewBuilder
    private var driverAvatar: some View {
        if let base64PhotoString = route.profilePhotoBase64,
           let decodedImageData = Data(base64Encoded: base64PhotoString, options: .ignoreUnknownCharacters),
           let decodedUIImage = UIImage(data: decodedImageData) {
            Image(uiImage: decodedUIImage)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        } else {
            ZStack {
                Circle()
                    .fill(LinearGradient.brand)
                Text(routeDetailViewModel.driverInitials)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.white)
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var tripDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Service Schedule")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 12) {
                scheduleCell(
                    icon: "sunrise.fill",
                    iconColor: Color.statusWarning,
                    label: "Morning",
                    time: routeDetailViewModel.morningSchedule
                )
                scheduleCell(
                    icon: "moon.fill",
                    iconColor: Color.brandAccent,
                    label: "Evening",
                    time: routeDetailViewModel.eveningSchedule
                )
            }

            if !route.activeDays.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                    Text(routeDetailViewModel.activeDaysLabel)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    private func scheduleCell(icon: String, iconColor: Color, label: String, time: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
            }
            Text(time)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.divider, lineWidth: 1))
    }

    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trip Pricing (LKR)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                priceRow(label: "Morning Trip",       value: routeDetailViewModel.morningPriceLabel, icon: "sunrise.fill",                 iconColor: Color.statusWarning)
                Divider().padding(.leading, 16)
                priceRow(label: "Evening Trip",       value: routeDetailViewModel.eveningPriceLabel, icon: "moon.fill",                    iconColor: Color.brandAccent)
                Divider().padding(.leading, 16)
                priceRow(label: "Both Trips (Daily)", value: routeDetailViewModel.bothPriceLabel,    icon: "arrow.triangle.2.circlepath",   iconColor: Color.statusActive)
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.divider, lineWidth: 1))
        }
    }

    private func priceRow(label: String, value: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var stopsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Stops")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                let allRouteStops = routeDetailViewModel.mapStops
                ForEach(Array(allRouteStops.enumerated()), id: \.element.id) { stopIndex, stop in
                    HStack(spacing: 14) {
                        VStack(spacing: 0) {
                            if stopIndex == 0 {
                                Color.clear.frame(width: 2, height: 10)
                            } else {
                                Rectangle()
                                    .fill(Color.brandAccent.opacity(0.3))
                                    .frame(width: 2, height: 10)
                            }

                            ZStack {
                                if stopIndex == 0 || stopIndex == allRouteStops.count - 1 {
                                    Circle()
                                        .fill(Color.brandAccent)
                                        .frame(width: 12, height: 12)
                                } else {
                                    Circle()
                                        .strokeBorder(Color.brandAccent, lineWidth: 2)
                                        .frame(width: 10, height: 10)
                                }
                            }

                            if stopIndex < allRouteStops.count - 1 {
                                Rectangle()
                                    .fill(Color.brandAccent.opacity(0.3))
                                    .frame(width: 2, height: 10)
                            } else {
                                Color.clear.frame(width: 2, height: 10)
                            }
                        }
                        .frame(width: 20)

                        Text(stop.name)
                            .font(.system(
                                size: stopIndex == 0 || stopIndex == allRouteStops.count - 1 ? 14 : 13,
                                weight: stopIndex == 0 || stopIndex == allRouteStops.count - 1 ? .semibold : .regular
                            ))
                            .foregroundStyle(
                                stopIndex == 0 || stopIndex == allRouteStops.count - 1
                                    ? Color.textPrimary
                                    : Color.textSecondary
                            )

                        Spacer()

                        if stop.name == pickupLocation {
                            Text("Your Pickup")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.statusActive)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.statusActive.opacity(0.12))
                                .clipShape(Capsule())
                        } else if stop.name == destinationLocation {
                            Text("Your Drop-off")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.brandAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.brandAccent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.divider, lineWidth: 1))
        }
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Passenger Reviews")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.statusWarning.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "star.slash.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.statusWarning)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("No Reviews Yet")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text("This driver hasn't received any reviews from passengers yet.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.divider, lineWidth: 1))
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.divider)
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Both Trips / Day")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textTertiary)
                    Text(routeDetailViewModel.bothPriceLabel)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                }

                Spacer()

                Button {
                    showJoinSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 13))
                        Text("Request to Join")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(route.isAcceptingRequests ? Color.brandAccent : Color.statusInactive)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(!route.isAcceptingRequests)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.appBackground)
        }
    }
}

// ReviewCard, AllReviewsSheet, FullRouteMapView, and MapStop are defined below.
// They were originally co-located in this file and must remain here to stay in scope.

struct ReviewCard: View {
    let name: String
    let rating: Int
    let date: String
    let comment: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.brandAccent.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Text(String(name.prefix(1)))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.brandAccent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(date)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textTertiary)
                }
                Spacer()
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { starIndex in
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(starIndex < rating ? Color.statusWarning : Color.divider)
                    }
                }
            }
            Text(comment)
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(3)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(width: 260)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.divider, lineWidth: 1))
    }
}

struct AllReviewsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let allPassengerReviews: [(name: String, rating: Int, date: String, comment: String)] = [
        ("Kamal P.", 5, "2 days ago", "Great driver, always on time and safe driving. Highly recommend this service."),
        ("Sarah W.", 4, "1 week ago", "Comfortable seats. AC could be slightly cooler sometimes, but overall decent."),
        ("Nuwan J.", 5, "3 weeks ago", "Very reliable daily commute. Doesn't miss any stops and communicates delays."),
        ("Amila D.", 5, "1 month ago", "Excellent service. The bus is always clean."),
        ("Kasun M.", 3, "2 months ago", "Good, but sometimes arrives 5 mins late."),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        reviewsList
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Passenger Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.brandAccent)
                }
            }
        }
    }

    private var reviewsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(allPassengerReviews.enumerated()), id: \.offset) { reviewIndex, review in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.brandAccent.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Text(String(review.name.prefix(1)))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.brandAccent)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(review.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.textPrimary)
                            Text(review.date)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.textTertiary)
                        }
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { starIndex in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(starIndex < review.rating ? Color.statusWarning : Color.divider)
                            }
                        }
                    }
                    Text(review.comment)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(3)
                }
                .padding(.vertical, 16)

                if reviewIndex < allPassengerReviews.count - 1 {
                    Divider().background(Color.divider)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct FullRouteMapView: View {
    let stops: [PassengerStop]
    let tripType: RouteDetailViewModel.TripType
    @Environment(\.dismiss) private var dismiss

    var navigationBarTitle: String {
        tripType == .morning ? "Morning Route" : "Evening Route"
    }

    var body: some View {
        NavigationStack {
            Map {
                ForEach(stops) { stop in
                    Annotation(stop.name, coordinate: stop.coordinate) {
                        VStack(spacing: 2) {
                            Text(stop.name)
                                .font(.system(size: 9, weight: .medium))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .shadow(radius: 1)
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.brandAccent)
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(navigationBarTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        }
    }
}

// Kept for compatibility with any existing code that references MapStop directly
struct MapStop: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
}

// Preview

#Preview("Dark") {
    let sampleStop = PassengerStop(
        id: "start",
        name: "Sample Start",
        coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
    )
    let sampleRoute = PassengerRouteResult(
        id: "preview",
        driverId: "driver1",
        driverName: "K. Perera",
        plateNumber: "SL-B 1384",
        busName: "Toyota Bus",
        busType: "Large Bus",
        capacity: 40,
        isAcceptingRequests: true,
        origin: "Colombo Fort",
        destination: "Maharagama",
        stops: [sampleStop],
        morningDeparture: Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date()) ?? Date(),
        morningArrival:   Calendar.current.date(bySettingHour: 7, minute: 45, second: 0, of: Date()) ?? Date(),
        eveningDeparture: Calendar.current.date(bySettingHour: 17, minute: 30, second: 0, of: Date()) ?? Date(),
        eveningArrival:   Calendar.current.date(bySettingHour: 18, minute: 45, second: 0, of: Date()) ?? Date(),
        activeDays: ["Mon", "Tue", "Wed", "Thu", "Fri"],
        morningPrice: 7500,
        eveningPrice: 7500,
        bothTripsPrice: 12000,
        profilePhotoBase64: nil
    )
    NavigationStack {
        RouteDetailView(route: sampleRoute, pickupLocation: "Colombo Fort", destinationLocation: "Maharagama")
    }
    .preferredColorScheme(.dark)
}
