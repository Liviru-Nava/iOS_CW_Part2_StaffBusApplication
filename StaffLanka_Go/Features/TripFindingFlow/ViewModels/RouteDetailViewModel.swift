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

    private let route: BusRoute
    let pickupLocation: String
    let destinationLocation: String

    enum TripType {
        case morning, evening
    }

    init(route: BusRoute, pickupLocation: String, destinationLocation: String) {
        self.route = route
        self.pickupLocation = pickupLocation
        self.destinationLocation = destinationLocation
    }

    var routeStart: String {
        route.routeName.components(separatedBy: " → ").first ?? route.routeName
    }

    var routeEnd: String {
        let parts = route.routeName.components(separatedBy: " → ")
        return parts.count > 1 ? parts.last ?? "" : ""
    }

    var displayStart: String {
        selectedTrip == .morning ? routeStart : routeEnd
    }

    var displayEnd: String {
        selectedTrip == .morning ? routeEnd : routeStart
    }

    var currentTripTime: String {
        selectedTrip == .morning
            ? "\(route.morningStartTime) – \(route.morningEndTime)"
            : "\(route.eveningStartTime) – \(route.eveningEndTime)"
    }

    var morningSchedule: String {
        "\(route.morningStartTime) – \(route.morningEndTime)"
    }

    var eveningSchedule: String {
        "\(route.eveningStartTime) – \(route.eveningEndTime)"
    }

    var driverInitials: String {
        String(route.driverName.prefix(2)).uppercased()
    }

    var vehicleLabel: String {
        "\(route.vehicleBrand) \(route.vehicleType)"
    }

    var capacityLabel: String {
        "\(route.currentPassengers)/\(route.capacity) seats"
    }

    var monthlyCostLabel: String {
        "Rs. \(Int(route.estimatedMonthlyCost))"
    }

    var seatStatusColor: Color {
        switch route.availableSeats {
        case 0: return .statusDanger
        case 1...5: return .statusWarning
        default: return .statusActive
        }
    }

    var seatLabel: String {
        route.availableSeats == 0 ? "Full" : "\(route.availableSeats) seats left"
    }

    var vehicleIcon: String {
        route.vehicleType.lowercased() == "van" ? "car.fill" : "bus.fill"
    }

    var shareText: String {
        "Check out this staff bus route from \(routeStart) to \(routeEnd) on GoSync!"
    }

    var isJoinable: Bool {
        route.availableSeats > 0
    }

    //added a few samples for UI view
    func coordinate(for stop: String) -> CLLocationCoordinate2D? {
        let coords: [String: CLLocationCoordinate2D] = [
            "Colombo Fort":     CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8428),
            "Pettah Bus Stand": CLLocationCoordinate2D(latitude: 6.9355, longitude: 79.8503),
            "Maradana":         CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
            "Borella":          CLLocationCoordinate2D(latitude: 6.9147, longitude: 79.8774),
            "Nugegoda":         CLLocationCoordinate2D(latitude: 6.8728, longitude: 79.8889),
            "Maharagama":       CLLocationCoordinate2D(latitude: 6.8484, longitude: 79.9266),
            "Battaramulla":     CLLocationCoordinate2D(latitude: 6.9046, longitude: 79.9196),
            "Rajagiriya":       CLLocationCoordinate2D(latitude: 6.9050, longitude: 79.8960),
            "Kottawa":          CLLocationCoordinate2D(latitude: 6.8380, longitude: 79.9680),
            "Kaduwela":         CLLocationCoordinate2D(latitude: 6.9284, longitude: 79.9803),
            "Malabe":           CLLocationCoordinate2D(latitude: 6.9063, longitude: 79.9726),
            "Athurugiriya":     CLLocationCoordinate2D(latitude: 6.8787, longitude: 79.9913),
        ]
        return coords[stop]
    }

    func mapStops(for stops: [String]) -> [MapStop] {
        stops.compactMap { stop in
            guard let coord = coordinate(for: stop) else { return nil }
            return MapStop(id: stop, name: stop, coordinate: coord)
        }
    }

    func openPhoneCall() {
        let cleaned = route.driverPhone.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel://\(cleaned)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
