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
    @State private var showFullMap = false
    @State private var showEnrollmentRestrictionAlert = false
    @State private var enrollmentRestrictionAlertMessage = ""
    @StateObject private var enrollmentCheckViewModel = PassengerEnrolledServicesViewModel()

    // Computed from enrollmentCheckViewModel — updated via onChange observers
    @State private var passengerHasBothEnrollmentActive = false
    @State private var passengerHasMorningActive = false
    @State private var passengerHasEveningActive = false

    // The sessions this passenger is allowed to select when requesting this route
    // nil means not yet computed (loading)
    private var allowedSessionsForThisRequest: [JoinRequestViewModel.TripSession] {
        if passengerHasBothEnrollmentActive { return [] }
        if passengerHasMorningActive && passengerHasEveningActive { return [] }
        if passengerHasMorningActive  { return [.evening] }
        if passengerHasEveningActive  { return [.morning] }
        return [.morning, .evening, .both]
    }

    // True when the passenger cannot request any more sessions at all
    private var passengerIsFullyEnrolled: Bool {
        passengerHasBothEnrollmentActive || (passengerHasMorningActive && passengerHasEveningActive)
    }

    // The alert message shown when the passenger is blocked from requesting
    private var enrollmentBlockMessage: String {
        if passengerHasBothEnrollmentActive {
            return "You are enrolled in a Morning & Evening (Both) service. Cancel your existing service first if you want to join a different one."
        }
        if passengerHasMorningActive && passengerHasEveningActive {
            return "You already have active Morning and Evening sessions. Cancel one of your existing sessions first before requesting a new one."
        }
        return ""
    }

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
                activeDays:           route.activeDays,
                allowedSessions:      allowedSessionsForThisRequest
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        .fullScreenCover(isPresented: $showFullMap) {
            FullRouteMapView(stops: routeDetailViewModel.mapStops, tripType: routeDetailViewModel.selectedTrip)
        }
        .onAppear {
            enrollmentCheckViewModel.startListening()
        }
        .onChange(of: enrollmentCheckViewModel.hasBothEnrollmentActive) { _, value in
            passengerHasBothEnrollmentActive = value
        }
        .onChange(of: enrollmentCheckViewModel.hasMorningActive) { _, value in
            passengerHasMorningActive = value
        }
        .onChange(of: enrollmentCheckViewModel.hasEveningActive) { _, value in
            passengerHasEveningActive = value
        }
        .alert("Enrollment Restricted", isPresented: $showEnrollmentRestrictionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(enrollmentRestrictionAlertMessage)
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

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.divider)
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Both Trips / Month")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textTertiary)
                    Text(routeDetailViewModel.bothPriceLabel)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                }

                Spacer()

                Button {
                    if passengerIsFullyEnrolled {
                        enrollmentRestrictionAlertMessage = enrollmentBlockMessage
                        showEnrollmentRestrictionAlert = true
                    } else if !route.isAcceptingRequests {
                        // button is disabled, no action needed
                    } else {
                        showJoinSheet = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: passengerIsFullyEnrolled ? "lock.fill" : "paperplane.fill")
                            .font(.system(size: 13))
                        Text(passengerIsFullyEnrolled ? "Already Enrolled" : "Request to Join")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(route.isAcceptingRequests && !passengerIsFullyEnrolled ? Color.brandAccent : Color.statusInactive)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(!route.isAcceptingRequests && !passengerIsFullyEnrolled)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.appBackground)
        }
    }
}

// FullRouteMapView and MapStop are kept here for scope compatibility

struct FullRouteMapView: View {
    let stops: [PassengerStop]
    let tripType: RouteDetailViewModel.TripType
    @Environment(\.dismiss) private var dismiss

    @State private var routePolyline: MKPolyline?

    var navigationBarTitle: String {
        tripType == .morning ? "Morning Route" : "Evening Route"
    }

    // Build ordered stops: for evening, reverse the list
    private var orderedStops: [PassengerStop] {
        tripType == .morning ? stops : stops.reversed()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FullRouteMapUIView(
                    stops: orderedStops,
                    routePolyline: $routePolyline
                )
                .ignoresSafeArea(edges: .bottom)
                .task { await calculateDirections() }
            }
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

    private func calculateDirections() async {
        guard orderedStops.count >= 2 else { return }
        var waypoints = orderedStops.map(\.coordinate)
        var allCoordinates: [CLLocationCoordinate2D] = []

        for i in 0..<(waypoints.count - 1) {
            let request = MKDirections.Request()
            request.source      = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[i]))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[i + 1]))
            request.transportType = .automobile
            do {
                let directions = MKDirections(request: request)
                let response = try await directions.calculate()
                if let firstRoute = response.routes.first {
                    let count = firstRoute.polyline.pointCount
                    var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: count)
                    firstRoute.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: count))
                    if i > 0 && !coords.isEmpty { coords.removeFirst() }
                    allCoordinates.append(contentsOf: coords)
                }
            } catch {
                // Fallback: straight line between waypoints
                if i > 0 { allCoordinates.append(waypoints[i]) } else { allCoordinates.append(waypoints[i]) }
                allCoordinates.append(waypoints[i + 1])
            }
        }
        routePolyline = MKPolyline(coordinates: allCoordinates, count: allCoordinates.count)
    }
}


struct FullRouteMapUIView: UIViewRepresentable {
    let stops: [PassengerStop]
    @Binding var routePolyline: MKPolyline?

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.showsCompass = true

        // Fit map to all stops
        if stops.count >= 2 {
            var region = MKCoordinateRegion(
                coordinates: stops.map(\.coordinate),
                insets: UIEdgeInsets(top: 60, left: 40, bottom: 60, right: 40)
            )
            map.setRegion(region, animated: false)
        } else if let first = stops.first {
            map.setRegion(
                MKCoordinateRegion(center: first.coordinate,
                                   span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)),
                animated: false)
        }
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
        map.removeOverlays(map.overlays)

        for (index, stop) in stops.enumerated() {
            let ann = FullRouteAnnotation(
                title: stop.name,
                subtitle: index == 0 ? "Start"
                        : index == stops.count - 1 ? "End"
                        : "Stop \(index)",
                stopIndex: index,
                totalStops: stops.count,
                coordinate: stop.coordinate
            )
            map.addAnnotation(ann)
        }

        if let poly = routePolyline {
            map.addOverlay(poly)
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ map: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let ann = annotation as? FullRouteAnnotation else { return nil }
            let v = map.dequeueReusableAnnotationView(withIdentifier: "fullpin")
                    as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: ann, reuseIdentifier: "fullpin")
            v.annotation     = ann
            v.canShowCallout = true
            v.animatesWhenAdded = true

            if ann.subtitle == "Start" {
                v.markerTintColor = UIColor.systemGreen
                v.glyphImage = UIImage(systemName: "flag.fill")
                v.titleVisibility = .visible
            } else if ann.subtitle == "End" {
                v.markerTintColor = UIColor.systemRed
                v.glyphImage = UIImage(systemName: "flag.checkered")
                v.titleVisibility = .visible
            } else {
                v.markerTintColor = UIColor.systemBlue
                v.glyphText       = "\(ann.stopIndex)"
                v.titleVisibility = .adaptive
            }
            return v
        }

        func mapView(_ map: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let poly = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
            let r = MKPolylineRenderer(polyline: poly)
            r.strokeColor = UIColor.systemBlue.withAlphaComponent(0.75)
            r.lineWidth = 4
            r.lineCap = .round
            r.lineJoin = .round
            return r
        }
    }
}

class FullRouteAnnotation: NSObject, MKAnnotation {
    var title: String?
    var subtitle: String?
    let stopIndex: Int
    let totalStops: Int
    var coordinate: CLLocationCoordinate2D

    init(title: String, subtitle: String, stopIndex: Int, totalStops: Int, coordinate: CLLocationCoordinate2D) {
        self.title      = title
        self.subtitle   = subtitle
        self.stopIndex  = stopIndex
        self.totalStops = totalStops
        self.coordinate = coordinate
    }
}


extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D], insets: UIEdgeInsets = .zero) {
        guard !coordinates.isEmpty else {
            self = MKCoordinateRegion()
            return
        }
        let minLat = coordinates.map(\.latitude).min()!
        let maxLat = coordinates.map(\.latitude).max()!
        let minLon = coordinates.map(\.longitude).min()!
        let maxLon = coordinates.map(\.longitude).max()!
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                            longitude: (minLon + maxLon) / 2)
        let spanLat = max((maxLat - minLat) * 1.4, 0.01)
        let spanLon = max((maxLon - minLon) * 1.4, 0.01)
        self = MKCoordinateRegion(center: center,
                                  span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon))
    }
}

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
