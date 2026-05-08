//
//  Untitled.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-08.
//

import ActivityKit
import Foundation
import Combine

@MainActor
final class PassengerLiveActivityManager: ObservableObject {

    static let shared = PassengerLiveActivityManager()
    private init() {}

    private var currentlyRunningLiveActivity: Activity<StaffLankaGoTripActivityAttributes>? = nil

    func startLiveActivityForPassengerTrip(
        routeDisplayName: String,
        passengerFullName: String,
        sessionLabel: String,
        passengerPickupStopName: String,
        passengerDropOffStopName: String,
        estimatedMinutesUntilPickup: Int,
        nameOfCurrentBusStop: String,
        numberOfStopsUntilPickup: Int
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[PassengerLiveActivityManager] Live Activities are not enabled on this device or in Settings.")
            return
        }

        endCurrentLiveActivityImmediately()

        let tripAttributes = StaffLankaGoTripActivityAttributes(
            routeDisplayName: routeDisplayName,
            passengerFullName: passengerFullName
        )

        let initialContentState = StaffLankaGoTripActivityAttributes.OngoingTripContentState(
            estimatedMinutesUntilPassengerRelevantStop: estimatedMinutesUntilPickup,
            nameOfCurrentBusStop: nameOfCurrentBusStop,
            numberOfStopsRemainingUntilPassengerRelevantStop: numberOfStopsUntilPickup,
            sessionLabel: sessionLabel,
            passengerHasAlreadyBeenPickedUp: false,
            passengerPickupStopName: passengerPickupStopName,
            passengerDropOffStopName: passengerDropOffStopName
        )

        let activityContent = ActivityContent(
            state: initialContentState,
            staleDate: Calendar.current.date(byAdding: .minute, value: 45, to: Date())
        )

        do {
            let launchedActivity = try Activity<StaffLankaGoTripActivityAttributes>.request(
                attributes: tripAttributes,
                content: activityContent,
                pushType: nil
            )
            currentlyRunningLiveActivity = launchedActivity
            print("[PassengerLiveActivityManager] Live Activity started successfully — id: \(launchedActivity.id)")
        } catch {
            print("[PassengerLiveActivityManager] Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    func updateLiveActivityWithCurrentBusProgress(
        nameOfCurrentBusStop: String,
        estimatedMinutesUntilPassengerRelevantStop: Int,
        numberOfStopsRemainingUntilPassengerRelevantStop: Int,
        passengerHasAlreadyBeenPickedUp: Bool,
        sessionLabel: String,
        passengerPickupStopName: String,
        passengerDropOffStopName: String
    ) {
        guard let activeActivity = currentlyRunningLiveActivity else {
            print("[PassengerLiveActivityManager] No active Live Activity to update.")
            return
        }

        let updatedContentState = StaffLankaGoTripActivityAttributes.OngoingTripContentState(
            estimatedMinutesUntilPassengerRelevantStop: estimatedMinutesUntilPassengerRelevantStop,
            nameOfCurrentBusStop: nameOfCurrentBusStop,
            numberOfStopsRemainingUntilPassengerRelevantStop: numberOfStopsRemainingUntilPassengerRelevantStop,
            sessionLabel: sessionLabel,
            passengerHasAlreadyBeenPickedUp: passengerHasAlreadyBeenPickedUp,
            passengerPickupStopName: passengerPickupStopName,
            passengerDropOffStopName: passengerDropOffStopName
        )

        let updatedActivityContent = ActivityContent(
            state: updatedContentState,
            staleDate: Calendar.current.date(byAdding: .minute, value: 45, to: Date())
        )

        Task {
            await activeActivity.update(updatedActivityContent)
            print("[PassengerLiveActivityManager] Live Activity updated — current stop: \(nameOfCurrentBusStop), stops remaining: \(numberOfStopsRemainingUntilPassengerRelevantStop), picked up: \(passengerHasAlreadyBeenPickedUp)")
        }
    }

    func endLiveActivityAfterTripCompletion() {
        guard let activeActivity = currentlyRunningLiveActivity else { return }

        Task {
            await activeActivity.end(nil, dismissalPolicy: .after(Date().addingTimeInterval(10)))
            print("[PassengerLiveActivityManager] Live Activity ended after trip completion.")
        }

        currentlyRunningLiveActivity = nil
    }

    private func endCurrentLiveActivityImmediately() {
        guard let activeActivity = currentlyRunningLiveActivity else { return }
        Task {
            await activeActivity.end(nil, dismissalPolicy: .immediate)
        }
        currentlyRunningLiveActivity = nil
    }
}
