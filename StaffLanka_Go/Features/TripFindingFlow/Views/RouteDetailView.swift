//
//  RouteDetailView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-02.
//

import SwiftUI
import MapKit

struct RouteDetailView: View {

    let route: BusRoute
    let pickupLocation: String
    let destinationLocation: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var routeDetailViewModel: RouteDetailViewModel
    @State private var showJoinSheet = false
    @State private var showAllReviews = false
    @State private var showFullMap = false

    init(route: BusRoute, pickupLocation: String, destinationLocation: String) {
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
        .sheet(isPresented: $showJoinSheet) {
            JoinRequestView(
                pickupLocation: pickupLocation,
                destinationLocation: destinationLocation,
                routeName: route.routeName
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showAllReviews) {
            AllReviewsSheet(rating: route.rating)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        .fullScreenCover(isPresented: $showFullMap) {
            FullRouteMapView(route: route, tripType: routeDetailViewModel.selectedTrip)
        }
    }

    private var mainScrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                mapSection
                driverVehicleSection
                tripDetailsSection
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
        let stops = route.stops.compactMap { stop -> MapStop? in
            guard let coord = routeDetailViewModel.coordinate(for: stop) else { return nil }
            return MapStop(id: stop, name: stop, coordinate: coord)
        }
        return ZStack(alignment: .bottomTrailing) {
            Map {
                ForEach(stops) { stop in
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
                ZStack {
                    Circle()
                        .fill(LinearGradient.brand)
                        .frame(width: 52, height: 52)
                    Text(String(route.driverName.prefix(2)).uppercased())
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(route.driverName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.statusWarning)
                        Text(String(format: "%.1f", route.rating))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        Text("rating")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Spacer()

                Button {
                    let cleaned = route.driverPhone.replacingOccurrences(of: " ", with: "")
                    if let url = URL(string: "tel://\(cleaned)"),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.statusActive.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "phone.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.statusActive)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider().padding(.horizontal, 16)

            VStack(spacing: 0) {
                infoRow(label: "Vehicle", value: "\(route.vehicleBrand) \(route.vehicleType)")
                Divider().padding(.leading, 16)
                infoRow(label: "License Plate", value: route.busNumber)
                Divider().padding(.leading, 16)
                infoRow(label: "Capacity", value: "\(route.currentPassengers)/\(route.capacity) seats")
            }
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.divider, lineWidth: 1))
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
                scheduleCell(icon: "sunrise.fill", iconColor: Color.statusWarning, label: "Morning", time: routeDetailViewModel.morningSchedule)
                scheduleCell(icon: "moon.fill", iconColor: Color.brandAccent, label: "Evening", time: routeDetailViewModel.eveningSchedule)
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

    private var stopsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Stops")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(route.stops.enumerated()), id: \.offset) { index, stop in
                    HStack(spacing: 14) {
                        VStack(spacing: 0) {
                            if index == 0 {
                                Color.clear.frame(width: 2, height: 10)
                            } else {
                                Rectangle()
                                    .fill(Color.brandAccent.opacity(0.3))
                                    .frame(width: 2, height: 10)
                            }

                            ZStack {
                                if index == 0 || index == route.stops.count - 1 {
                                    Circle()
                                        .fill(Color.brandAccent)
                                        .frame(width: 12, height: 12)
                                } else {
                                    Circle()
                                        .strokeBorder(Color.brandAccent, lineWidth: 2)
                                        .frame(width: 10, height: 10)
                                }
                            }

                            if index < route.stops.count - 1 {
                                Rectangle()
                                    .fill(Color.brandAccent.opacity(0.3))
                                    .frame(width: 2, height: 10)
                            } else {
                                Color.clear.frame(width: 2, height: 10)
                            }
                        }
                        .frame(width: 20)

                        Text(stop)
                            .font(.system(size: index == 0 || index == route.stops.count - 1 ? 14 : 13,
                                         weight: index == 0 || index == route.stops.count - 1 ? .semibold : .regular))
                            .foregroundStyle(index == 0 || index == route.stops.count - 1 ? Color.textPrimary : Color.textSecondary)

                        Spacer()

                        if stop == pickupLocation {
                            Text("Your Pickup")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.statusActive)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.statusActive.opacity(0.12))
                                .clipShape(Capsule())
                        } else if stop == destinationLocation {
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
            HStack {
                Text("Passenger Reviews")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button {
                    showAllReviews = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.statusWarning)
                        Text(String(format: "%.1f", route.rating))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ReviewCard(name: "Kamal P.", rating: 5, date: "2 days ago", comment: "Great driver, always on time and safe driving.")
                    ReviewCard(name: "Sarah W.", rating: 4, date: "1 week ago", comment: "Comfortable seats. AC could be slightly cooler.")
                    ReviewCard(name: "Nuwan J.", rating: 5, date: "3 weeks ago", comment: "Very reliable daily commute. Highly recommended!")
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.divider)
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly Fee")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textTertiary)
                    Text("Rs. \(Int(route.estimatedMonthlyCost))")
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
                    .background(route.availableSeats > 0 ? Color.brandAccent : Color.statusInactive)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(route.availableSeats == 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.appBackground)
        }
    }

}

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
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(i < rating ? Color.statusWarning : Color.divider)
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
    let rating: Double
    @Environment(\.dismiss) private var dismiss

    private let reviews: [(name: String, rating: Int, date: String, comment: String)] = [
        ("Kamal P.", 5, "2 days ago", "Great driver, always on time and safe driving. Highly recommend this service for anyone commuting to Colombo."),
        ("Sarah W.", 4, "1 week ago", "Comfortable seats. AC could be slightly cooler sometimes, but overall a decent experience."),
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
                        ratingHeader
                        reviewsList
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("All Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.brandAccent)
                }
            }
        }
    }

    private var ratingHeader: some View {
        VStack(spacing: 8) {
            Text(String(format: "%.1f", rating))
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(Color.textPrimary)
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(i < Int(rating) ? Color.statusWarning : Color.divider)
                }
            }
            Text("Based on passenger feedback")
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var reviewsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(reviews.enumerated()), id: \.offset) { index, review in
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
                            ForEach(0..<5, id: \.self) { i in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(i < review.rating ? Color.statusWarning : Color.divider)
                            }
                        }
                    }
                    Text(review.comment)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(3)
                }
                .padding(.vertical, 16)

                if index < reviews.count - 1 {
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
    let route: BusRoute
    let tripType: RouteDetailViewModel.TripType
    @Environment(\.dismiss) private var dismiss

    private let coords: [String: CLLocationCoordinate2D] = [
        "Colombo Fort": CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8428),
        "Pettah Bus Stand": CLLocationCoordinate2D(latitude: 6.9355, longitude: 79.8503),
        "Maradana": CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
        "Borella": CLLocationCoordinate2D(latitude: 6.9147, longitude: 79.8774),
        "Nugegoda": CLLocationCoordinate2D(latitude: 6.8728, longitude: 79.8889),
        "Maharagama": CLLocationCoordinate2D(latitude: 6.8484, longitude: 79.9266),
        "Battaramulla": CLLocationCoordinate2D(latitude: 6.9046, longitude: 79.9196),
        "Rajagiriya": CLLocationCoordinate2D(latitude: 6.9050, longitude: 79.8960),
        "Kottawa": CLLocationCoordinate2D(latitude: 6.8380, longitude: 79.9680),
        "Kaduwela": CLLocationCoordinate2D(latitude: 6.9284, longitude: 79.9803),
        "Malabe": CLLocationCoordinate2D(latitude: 6.9063, longitude: 79.9726),
        "Athurugiriya": CLLocationCoordinate2D(latitude: 6.8787, longitude: 79.9913),
    ]

    var mapStops: [MapStop] {
        route.stops.compactMap { stop in
            guard let coord = coords[stop] else { return nil }
            return MapStop(id: stop, name: stop, coordinate: coord)
        }
    }

    var navTitle: String {
        tripType == .morning ? "Morning Route" : "Evening Route"
    }

    var body: some View {
        NavigationStack {
            Map {
                ForEach(mapStops) { stop in
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
            .navigationTitle(navTitle)
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

struct MapStop: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
}

#Preview("Dark") {
    NavigationStack {
        RouteDetailView(
            route: BusRoute(
                busNumber: "SL-B 1384",
                routeName: "Colombo Fort → Maharagama",
                origin: "Colombo Fort",
                destination: "Maharagama",
                driverName: "K. Perera",
                driverPhone: "+94 77 111 2222",
                vehicleBrand: "Ashok Leyland",
                vehicleType: "Bus",
                capacity: 40,
                currentPassengers: 32,
                rating: 4.3,
                morningStartTime: "06:30 AM",
                morningEndTime: "07:45 AM",
                eveningStartTime: "05:30 PM",
                eveningEndTime: "06:45 PM",
                estimatedMonthlyCost: 3500,
                stops: ["Colombo Fort", "Pettah Bus Stand", "Maradana", "Borella", "Nugegoda", "Maharagama"]
            ),
            pickupLocation: "Borella",
            destinationLocation: "Maharagama"
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    NavigationStack {
        RouteDetailView(
            route: BusRoute(
                busNumber: "SL-B 1384",
                routeName: "Colombo Fort → Maharagama",
                origin: "Colombo Fort",
                destination: "Maharagama",
                driverName: "K. Perera",
                driverPhone: "+94 77 111 2222",
                vehicleBrand: "Ashok Leyland",
                vehicleType: "Bus",
                capacity: 40,
                currentPassengers: 32,
                rating: 4.3,
                morningStartTime: "06:30 AM",
                morningEndTime: "07:45 AM",
                eveningStartTime: "05:30 PM",
                eveningEndTime: "06:45 PM",
                estimatedMonthlyCost: 3500,
                stops: ["Colombo Fort", "Pettah Bus Stand", "Maradana", "Borella", "Nugegoda", "Maharagama"]
            ),
            pickupLocation: "Borella",
            destinationLocation: "Maharagama"
        )
    }
    .preferredColorScheme(.light)
}
