//
//  StaffLankaBusLiveActivityAttributes.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-08.
//

import ActivityKit
import Foundation

struct StaffLankaGoTripActivityAttributes: ActivityAttributes {

    public typealias ContentState = StaffLankaGoTripActivityAttributes.OngoingTripContentState

    public struct OngoingTripContentState: Codable, Hashable {

        var estimatedMinutesUntilPassengerRelevantStop: Int

        var nameOfCurrentBusStop: String

        var numberOfStopsRemainingUntilPassengerRelevantStop: Int

        var sessionLabel: String

        var passengerHasAlreadyBeenPickedUp: Bool

        var passengerPickupStopName: String

        var passengerDropOffStopName: String
    }

    var routeDisplayName: String

    var passengerFullName: String
}
