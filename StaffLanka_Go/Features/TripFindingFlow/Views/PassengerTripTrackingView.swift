//
//  PassengerTripTrackingView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-06.
//

import SwiftUI
import MapKit

struct PassengerTripTrackingView: View {

    let tripId: String
    let routeData: RouteModel?
    let driverName: String
    let plateNumber: String
    let session: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: TripTrackingViewModel

    init(
        tripId: String,
        routeData: RouteModel?,
        driverName: String,
        plateNumber: String,
        session: String
    ) {
        self.tripId      = tripId
        self.routeData   = routeData
        self.driverName  = driverName
        self.plateNumber = plateNumber
        self.session     = session
        _vm = StateObject(wrappedValue: TripTrackingViewModel(tripId: tripId))
    }

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
            headerOverlay
            if vm.tripCompleted {
                completedOverlay
            }
        }
        .ignoresSafeArea()
        .onAppear { vm.startListening() }
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $vm.cameraPosition) {
            UserAnnotation()

            if let coord = vm.driverCoordinate {
                Annotation("Driver", coordinate: coord) {
                    ZStack {
                        Circle()
                            .fill(Color.statusActive.opacity(0.25))
                            .frame(width: 44, height: 44)
                        Image(systemName: "bus.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.statusActive)
                    }
                    .shadow(radius: 4)
                }
            }

            if let route = routeData {
                Annotation(route.startLocation.locationName,
                           coordinate: CLLocationCoordinate2D(
                            latitude: route.startLocation.latitude,
                            longitude: route.startLocation.longitude)) {
                    Circle().fill(Color.statusActive).frame(width: 12, height: 12)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                }
                ForEach(route.routeStops, id: \.stopName) { stop in
                    Annotation(stop.stopName,
                               coordinate: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)) {
                        Circle().fill(Color.brandAccent).frame(width: 10, height: 10)
                            .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                    }
                }
                Annotation(route.endLocation.locationName,
                           coordinate: CLLocationCoordinate2D(
                            latitude: route.endLocation.latitude,
                            longitude: route.endLocation.longitude)) {
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.statusDanger)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    // MARK: - Header overlay

    private var headerOverlay: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.textSecondary)
                            .background(Circle().fill(Color.cardBackground))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    VStack(spacing: 2) {
                        Text("Live Tracking")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                        HStack(spacing: 4) {
                            Circle().fill(Color.statusActive).frame(width: 6, height: 6)
                            Text("Active")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.statusActive)
                        }
                    }

                    Spacer()

                    Circle().fill(Color.clear).frame(width: 28, height: 28)
                }

                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Color.brandAccent.opacity(0.15)).frame(width: 42, height: 42)
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.brandAccent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(driverName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        Text(plateNumber)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textSecondary)
                    }
                    Spacer()
                    Text(session)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.brandAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.brandAccent.opacity(0.12))
                        .clipShape(Capsule())
                }

                if let updated = vm.locationUpdatedAt {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.textTertiary)
                        Text("Location updated \(updated.formatted(.relative(presentation: .numeric)))")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 16)
            .background(
                Color.cardBackground
                    .opacity(0.95)
                    .clipShape(RoundedRectangle(cornerRadius: 0))
            )

            Spacer()
        }
    }

    // MARK: - Trip completed overlay

    private var completedOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.statusActive)
                Text("Trip Completed")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("The driver has reached the destination.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))
                Button { dismiss() } label: {
                    Text("Close")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 140)
                        .padding(.vertical, 13)
                        .background(Color.brandAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(30)
        }
    }
}
