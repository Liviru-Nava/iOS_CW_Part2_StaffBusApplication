//
//  RouteDetailViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-03.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

@MainActor
final class RouteDetailViewModel: ObservableObject {

    @Published var selectedTrip: TripType = .morning

    let route: PassengerRouteResult
    let pickupLocation: String
    let destinationLocation: String

    enum TripType {
        case morning, evening
    }

    init(route: PassengerRouteResult, pickupLocation: String, destinationLocation: String) {
        self.route = route
        self.pickupLocation = pickupLocation
        self.destinationLocation = destinationLocation
    }

    // Display helpers

    var routeStart: String { route.origin }
    var routeEnd: String   { route.destination }

    var displayStart: String { selectedTrip == .morning ? routeStart : routeEnd }
    var displayEnd: String   { selectedTrip == .morning ? routeEnd   : routeStart }

    var currentTripTime: String {
        selectedTrip == .morning ? route.morningScheduleLabel : route.eveningScheduleLabel
    }

    var morningSchedule: String { route.morningScheduleLabel }
    var eveningSchedule: String { route.eveningScheduleLabel }

    var driverInitials: String {
        let parts = route.driverName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(route.driverName.prefix(2)).uppercased()
    }

    var vehicleLabel: String { "\(route.busName) (\(route.busType))" }

    var capacityLabel: String { "\(route.capacity) seats total" }

    var morningPriceLabel: String  { "Rs. \(Int(route.morningPrice))" }
    var eveningPriceLabel: String  { "Rs. \(Int(route.eveningPrice))" }
    var bothPriceLabel: String     { "Rs. \(Int(route.bothTripsPrice))" }


    var monthlyFeeLabel: String { "Rs. \(Int(route.bothTripsPrice * 22))" }

    var isJoinable: Bool { route.isAcceptingRequests }

    var vehicleIcon: String {
        route.busType.lowercased().contains("van") ? "car.fill" : "bus.fill"
    }

    var shareText: String {
        "Check out this staff bus route from \(routeStart) to \(routeEnd) on StaffLanka Go!"
    }

    var activeDaysLabel: String {
        route.activeDays.joined(separator: ", ")
    }

    var mapStops: [PassengerStop] { route.stops }
}
