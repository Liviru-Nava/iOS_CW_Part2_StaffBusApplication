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
    let passengerPickupStopName: String
    let passengerDropOffStopName: String
    let passengerFullName: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var tripTrackingViewModel: TripTrackingViewModel

    @State private var simulatorTestPanelIsVisible: Bool = false

    init(
        tripId: String,
        routeData: RouteModel?,
        driverName: String,
        plateNumber: String,
        session: String,
        passengerPickupStopName: String,
        passengerDropOffStopName: String,
        passengerFullName: String
    ) {
        self.tripId = tripId
        self.routeData = routeData
        self.driverName = driverName
        self.plateNumber = plateNumber
        self.session = session
        self.passengerPickupStopName = passengerPickupStopName
        self.passengerDropOffStopName = passengerDropOffStopName
        self.passengerFullName = passengerFullName

        let displayNameForRoute: String
        if let route = routeData {
            displayNameForRoute = (route.startName ?? route.startLocation.locationName)
                + " → "
                + (route.endName ?? route.endLocation.locationName)
        } else {
            displayNameForRoute = session + " Route"
        }

        _tripTrackingViewModel = StateObject(
            wrappedValue: TripTrackingViewModel(
                tripId: tripId,
                routeData: routeData,
                sessionLabel: session,
                passengerPickupStopName: passengerPickupStopName,
                passengerDropOffStopName: passengerDropOffStopName,
                routeDisplayName: displayNameForRoute,
                passengerFullName: passengerFullName
            )
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
            headerOverlay
            simulatorTestFloatingToggleButton
            if simulatorTestPanelIsVisible {
                simulatorTestPanel
            }
            if tripTrackingViewModel.tripCompleted {
                completedOverlay
            }
        }
        .ignoresSafeArea()
        .onAppear {
            tripTrackingViewModel.startLiveActivityWhenPassengerBeginsTracking()
            tripTrackingViewModel.startListeningToFirestoreTripUpdates()
        }
    }

    private var simulatorTestFloatingToggleButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        simulatorTestPanelIsVisible.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text(simulatorTestPanelIsVisible ? "Hide Tests" : "Test LA")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.55, green: 0.30, blue: 0.90))
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.30), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.bottom, simulatorTestPanelIsVisible ? 330 : 40)
                .animation(.spring(response: 0.35, dampingFraction: 0.78), value: simulatorTestPanelIsVisible)
            }
        }
    }

    private var simulatorTestPanel: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 0) {

                HStack(spacing: 8) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(red: 0.55, green: 0.30, blue: 0.90))
                    Text("Simulator Live Activity Tests")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text("DEBUG ONLY")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color(red: 0.55, green: 0.30, blue: 0.90))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 4)

                Text("Tap a button, then press Command+L to lock the simulator and see the Live Activity banner.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)

                Divider().padding(.horizontal, 18)

                VStack(spacing: 10) {

                    simulatorTestActionButton(
                        buttonLabel: "1. Start Live Activity (Pre-Pickup)",
                        buttonSubtitle: "Bus at Fort, 15 min, 2 stops to your pickup at Wattala",
                        buttonAccentColor: Color.statusActive
                    ) {
                        PassengerLiveActivityManager.shared.startLiveActivityForPassengerTrip(
                            routeDisplayName: "Fort → Kaduwela",
                            passengerFullName: passengerFullName.isEmpty ? "Test Passenger" : passengerFullName,
                            sessionLabel: session.isEmpty ? "Morning" : session,
                            passengerPickupStopName: passengerPickupStopName.isEmpty ? "Wattala" : passengerPickupStopName,
                            passengerDropOffStopName: passengerDropOffStopName.isEmpty ? "Kaduwela" : passengerDropOffStopName,
                            estimatedMinutesUntilPickup: 15,
                            nameOfCurrentBusStop: "Fort",
                            numberOfStopsUntilPickup: 2
                        )
                    }

                    simulatorTestActionButton(
                        buttonLabel: "2. Update — Bus Closer (Pre-Pickup)",
                        buttonSubtitle: "Bus now at Slave Island, 8 min, 1 stop remaining",
                        buttonAccentColor: Color.statusWarning
                    ) {
                        PassengerLiveActivityManager.shared.updateLiveActivityWithCurrentBusProgress(
                            nameOfCurrentBusStop: "Slave Island",
                            estimatedMinutesUntilPassengerRelevantStop: 8,
                            numberOfStopsRemainingUntilPassengerRelevantStop: 1,
                            passengerHasAlreadyBeenPickedUp: false,
                            sessionLabel: session.isEmpty ? "Morning" : session,
                            passengerPickupStopName: passengerPickupStopName.isEmpty ? "Wattala" : passengerPickupStopName,
                            passengerDropOffStopName: passengerDropOffStopName.isEmpty ? "Kaduwela" : passengerDropOffStopName
                        )
                    }

                    simulatorTestActionButton(
                        buttonLabel: "3. Update — Passenger Picked Up",
                        buttonSubtitle: "Bus at Wattala, now heading to drop-off, 2 stops away",
                        buttonAccentColor: Color.brandAccent
                    ) {
                        PassengerLiveActivityManager.shared.updateLiveActivityWithCurrentBusProgress(
                            nameOfCurrentBusStop: "Wattala",
                            estimatedMinutesUntilPassengerRelevantStop: 15,
                            numberOfStopsRemainingUntilPassengerRelevantStop: 2,
                            passengerHasAlreadyBeenPickedUp: true,
                            sessionLabel: session.isEmpty ? "Morning" : session,
                            passengerPickupStopName: passengerPickupStopName.isEmpty ? "Wattala" : passengerPickupStopName,
                            passengerDropOffStopName: passengerDropOffStopName.isEmpty ? "Kaduwela" : passengerDropOffStopName
                        )
                    }

                    simulatorTestActionButton(
                        buttonLabel: "4. End Live Activity",
                        buttonSubtitle: "Simulates trip completion — banner disappears after 10 seconds",
                        buttonAccentColor: Color.statusDanger
                    ) {
                        PassengerLiveActivityManager.shared.endLiveActivityAfterTripCompletion()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 18)
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color(red: 0.55, green: 0.30, blue: 0.90).opacity(0.35), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: -4)
            .padding(.horizontal, 14)
            .padding(.bottom, 32)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func simulatorTestActionButton(
        buttonLabel: String,
        buttonSubtitle: String,
        buttonAccentColor: Color,
        buttonAction: @escaping () -> Void
    ) -> some View {
        Button(action: buttonAction) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(buttonAccentColor.opacity(0.18))
                    .frame(width: 4, height: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text(buttonLabel)
                        .font(.appFootnoteSemibold)
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(buttonSubtitle)
                        .font(.appCaption2)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "play.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(buttonAccentColor)
                    .padding(8)
                    .background(buttonAccentColor.opacity(0.12))
                    .clipShape(Circle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var mapLayer: some View {
        Map(position: $tripTrackingViewModel.cameraPosition) {
            UserAnnotation()

            if let coord = tripTrackingViewModel.driverCoordinate {
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
                    .accessibilityLabel("Close trip tracking")
                    .accessibilityHint("Returns to the passenger dashboard")

                    Spacer()

                    VStack(spacing: 2) {
                        Text("Live Tracking")
                            .font(.appCalloutBold)
                            .foregroundStyle(Color.textPrimary)
                        HStack(spacing: 4) {
                            Circle().fill(Color.statusActive).frame(width: 6, height: 6)
                                .accessibilityHidden(true)
                            Text("Active")
                                .font(.appCaption2Semibold)
                                .foregroundStyle(Color.statusActive)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Live tracking active")

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
                            .font(.appCalloutSemibold)
                            .foregroundStyle(Color.textPrimary)
                        Text(plateNumber)
                            .font(.appCaption)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Driver: \(driverName), plate \(plateNumber)")
                    Spacer()
                    Text(session)
                        .font(.appCaptionSemibold)
                        .foregroundStyle(Color.brandAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.brandAccent.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(session) session")
                }

                if let updated = tripTrackingViewModel.locationUpdatedAt {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.textTertiary)
                            .accessibilityHidden(true)
                        Text("Location updated \(updated.formatted(.relative(presentation: .numeric)))")
                            .font(.appCaption2)
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

    private var completedOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.statusActive)
                    .accessibilityHidden(true)
                Text("Trip Completed")
                    .font(.appTitle3)
                    .foregroundStyle(.white)
                Text("The driver has reached the destination.")
                    .font(.appCallout)
                    .foregroundStyle(.white.opacity(0.8))
                Button { dismiss() } label: {
                    Text("Close")
                        .font(.appBodySemibold)
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 140)
                        .padding(.vertical, 13)
                        .background(Color.brandAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
                .accessibilityHint("Dismisses the trip completed screen")
            }
            .padding(30)
        }
    }
}
