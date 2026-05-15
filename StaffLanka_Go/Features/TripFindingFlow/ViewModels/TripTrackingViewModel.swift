//
//  TripTrackingViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-06.
//

import Foundation
import MapKit
import FirebaseFirestore
import Combine
import SwiftUI

@MainActor
final class TripTrackingViewModel: ObservableObject {

    @Published var driverCoordinate: CLLocationCoordinate2D? = nil
    @Published var locationUpdatedAt: Date? = nil
    @Published var tripCompleted: Bool = false
    @Published var cameraPosition: MapCameraPosition = .automatic

    private let tripId: String
    private let routeData: RouteModel?
    private let sessionLabel: String
    private let passengerPickupStopName: String
    private let passengerDropOffStopName: String
    private let routeDisplayName: String
    private let passengerFullName: String

    private let proximityAlertThresholdInMinutes: Int = 10

    nonisolated(unsafe) private var firestoreListener: ListenerRegistration?

    init(
        tripId: String,
        routeData: RouteModel?,
        sessionLabel: String,
        passengerPickupStopName: String,
        passengerDropOffStopName: String,
        routeDisplayName: String,
        passengerFullName: String
    ) {
        self.tripId = tripId
        self.routeData = routeData
        self.sessionLabel = sessionLabel
        self.passengerPickupStopName = passengerPickupStopName
        self.passengerDropOffStopName = passengerDropOffStopName
        self.routeDisplayName = routeDisplayName
        self.passengerFullName = passengerFullName
    }

    deinit { firestoreListener?.remove() }

    func startListeningToFirestoreTripUpdates() {
        NotificationManager.shared.resetProximityAlertFlags()
        firestoreListener?.remove()
        firestoreListener = TripService.shared.listenToTrip(tripId: tripId) { [weak self] updatedTrip in
            guard let self, let updatedTrip else { return }
            Task { @MainActor in
                self.handleIncomingTripUpdate(updatedTrip: updatedTrip)
            }
        }
    }

    private func handleIncomingTripUpdate(updatedTrip: TripModel) {
        if let freshCoordinate = updatedTrip.driverCoordinate {
            driverCoordinate = freshCoordinate
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: freshCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
        }

        locationUpdatedAt = updatedTrip.locationUpdatedAt

        let tripIsNowCompleted = updatedTrip.status == "completed"
        tripCompleted = tripIsNowCompleted

        if tripIsNowCompleted {
            PassengerLiveActivityManager.shared.endLiveActivityAfterTripCompletion()
            return
        }

        let currentStopIndex = updatedTrip.currentStopIndex ?? 0
        updatePassengerLiveActivityContent(currentStopIndex: currentStopIndex)
        evaluateProximityNotificationsForCurrentStopIndex(currentStopIndex: currentStopIndex)
    }

    private func evaluateProximityNotificationsForCurrentStopIndex(currentStopIndex: Int) {
        guard let routeData = routeData else { return }

        let allRouteStops = buildOrderedStopNamesFromRoute(routeData: routeData, sessionLabel: sessionLabel)
        guard !allRouteStops.isEmpty else { return }

        let safeCurrentStopIndex = min(currentStopIndex, allRouteStops.count - 1)

        // reversing the drop off point instead of using the pickup point names
        let indexOfPassengerPickupStop = allRouteStops.firstIndex(of: passengerPickupStopName) ?? allRouteStops.count - 1
        let indexOfPassengerDropOffStop = allRouteStops.firstIndex(of: passengerDropOffStopName) ?? allRouteStops.count - 1

        let passengerHasAlreadyBeenPickedUp = safeCurrentStopIndex > indexOfPassengerPickupStop

        let indexOfPassengerRelevantStop = passengerHasAlreadyBeenPickedUp
            ? indexOfPassengerDropOffStop
            : indexOfPassengerPickupStop

        let numberOfStopsRemainingUntilPassengerRelevantStop = max(
            indexOfPassengerRelevantStop - safeCurrentStopIndex,
            0
        )

        let totalNumberOfStopsInRoute = allRouteStops.count - 1
        let simulationTotalDurationMinutes = 90.0 / 60.0
        let minutesPerStop = totalNumberOfStopsInRoute > 0
            ? simulationTotalDurationMinutes / Double(totalNumberOfStopsInRoute)
            : 1.0
        let estimatedMinutesUntilPassengerRelevantStop = max(
            Int(Double(numberOfStopsRemainingUntilPassengerRelevantStop) * minutesPerStop),
            0
        )

        // For evening sessions the notification stop names need to reflect the reversed direction
        let relevantPickupLabel = sessionLabel == "Evening" ? passengerDropOffStopName : passengerPickupStopName
        let relevantDropOffLabel = sessionLabel == "Evening" ? passengerPickupStopName : passengerDropOffStopName

        NotificationManager.shared.evaluateAndFireProximityAlertIfNeeded(
            estimatedMinutesUntilRelevantStop: estimatedMinutesUntilPassengerRelevantStop,
            passengerHasAlreadyBeenPickedUp: passengerHasAlreadyBeenPickedUp,
            passengerPickupStopName: relevantPickupLabel,
            passengerDropOffStopName: relevantDropOffLabel,
            proximityThresholdInMinutes: proximityAlertThresholdInMinutes
        )
    }

    private func updatePassengerLiveActivityContent(currentStopIndex: Int) {
        guard let routeData = routeData else { return }

        let allRouteStops = buildOrderedStopNamesFromRoute(routeData: routeData, sessionLabel: sessionLabel)

        guard !allRouteStops.isEmpty else { return }

        let safeCurrentStopIndex = min(currentStopIndex, allRouteStops.count - 1)
        let nameOfCurrentBusStop = allRouteStops[safeCurrentStopIndex]

        let indexOfPassengerPickupStop = allRouteStops.firstIndex(of: passengerPickupStopName) ?? allRouteStops.count - 1
        let indexOfPassengerDropOffStop = allRouteStops.firstIndex(of: passengerDropOffStopName) ?? allRouteStops.count - 1

        let passengerHasAlreadyBeenPickedUp = safeCurrentStopIndex > indexOfPassengerPickupStop

        let indexOfPassengerRelevantStop = passengerHasAlreadyBeenPickedUp
            ? indexOfPassengerDropOffStop
            : indexOfPassengerPickupStop

        let numberOfStopsRemainingUntilPassengerRelevantStop = max(
            indexOfPassengerRelevantStop - safeCurrentStopIndex,
            0
        )

        let totalNumberOfStopsInRoute = allRouteStops.count - 1
        let simulationTotalDurationMinutes = 90.0 / 60.0
        let minutesPerStop = totalNumberOfStopsInRoute > 0
            ? simulationTotalDurationMinutes / Double(totalNumberOfStopsInRoute)
            : 1.0
        let estimatedMinutesUntilPassengerRelevantStop = max(
            Int(Double(numberOfStopsRemainingUntilPassengerRelevantStop) * minutesPerStop),
            0
        )

        PassengerLiveActivityManager.shared.updateLiveActivityWithCurrentBusProgress(
            nameOfCurrentBusStop: nameOfCurrentBusStop,
            estimatedMinutesUntilPassengerRelevantStop: estimatedMinutesUntilPassengerRelevantStop,
            numberOfStopsRemainingUntilPassengerRelevantStop: numberOfStopsRemainingUntilPassengerRelevantStop,
            passengerHasAlreadyBeenPickedUp: passengerHasAlreadyBeenPickedUp,
            sessionLabel: sessionLabel,
            passengerPickupStopName: passengerPickupStopName,
            passengerDropOffStopName: passengerDropOffStopName
        )
    }

    private func buildOrderedStopNamesFromRoute(routeData: RouteModel, sessionLabel: String) -> [String] {
        let startStopName = routeData.startName ?? routeData.startLocation.locationName
        let endStopName = routeData.endName ?? routeData.endLocation.locationName
        let intermediateStopNames = routeData.routeStops
            .sorted(by: { $0.stopOrder < $1.stopOrder })
            .map(\.stopName)

        var orderedStopNames = [startStopName] + intermediateStopNames + [endStopName]

        // Evening trips run the route in reverse — passengers board at what was the morning drop-off
        if sessionLabel == "Evening" {
            orderedStopNames.reverse()
        }

        return orderedStopNames
    }

    func startLiveActivityWhenPassengerBeginsTracking() {
        guard let routeData = routeData else { return }

        let allRouteStops = buildOrderedStopNamesFromRoute(routeData: routeData, sessionLabel: sessionLabel)

        // For evening sessions the ordered list is already reversed, so passengerPickupStopName
        // refers to the stop the passenger boards at in the evening direction.
        let indexOfPassengerPickupStop = allRouteStops.firstIndex(of: passengerPickupStopName) ?? 1
        let numberOfStopsUntilPickup = max(indexOfPassengerPickupStop, 0)

        let simulationTotalDurationMinutes = 90.0 / 60.0
        let totalNumberOfStopsInRoute = max(allRouteStops.count - 1, 1)
        let minutesPerStop = simulationTotalDurationMinutes / Double(totalNumberOfStopsInRoute)
        let estimatedMinutesUntilPickup = max(Int(Double(numberOfStopsUntilPickup) * minutesPerStop), 1)

        let displayNameForRoute = (routeData.startName ?? routeData.startLocation.locationName)
            + " → "
            + (routeData.endName ?? routeData.endLocation.locationName)

        PassengerLiveActivityManager.shared.startLiveActivityForPassengerTrip(
            routeDisplayName: displayNameForRoute,
            passengerFullName: passengerFullName,
            sessionLabel: sessionLabel,
            passengerPickupStopName: passengerPickupStopName,
            passengerDropOffStopName: passengerDropOffStopName,
            estimatedMinutesUntilPickup: estimatedMinutesUntilPickup,
            nameOfCurrentBusStop: allRouteStops.first ?? passengerPickupStopName,
            numberOfStopsUntilPickup: numberOfStopsUntilPickup
        )
    }
}
