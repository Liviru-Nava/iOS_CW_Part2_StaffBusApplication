//
//  RouteSearchViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-02.
//

import Foundation
import CoreLocation
import Combine

struct PredefinedLocation: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let area: String
    let coordinate: CLLocationCoordinate2D

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PredefinedLocation, rhs: PredefinedLocation) -> Bool { lhs.id == rhs.id }
}

struct BusRoute: Identifiable {
    let id = UUID()
    let busNumber: String
    let routeName: String
    let origin: String
    let destination: String
    let driverName: String
    let driverPhone: String
    let vehicleBrand: String
    let vehicleType: String
    let capacity: Int
    let currentPassengers: Int
    let rating: Double
    let morningStartTime: String
    let morningEndTime: String
    let eveningStartTime: String
    let eveningEndTime: String
    let estimatedMonthlyCost: Double
    let stops: [String]

    var availableSeats: Int { capacity - currentPassengers }
}

enum ActiveSearchField {
    case pickup, destination
}

@MainActor
final class RouteSearchViewModel: ObservableObject {

    @Published var pickupText: String = ""
    @Published var destinationText: String = ""
    @Published var pickupLocation: PredefinedLocation? = nil
    @Published var destinationLocation: PredefinedLocation? = nil
    @Published var activeField: ActiveSearchField = .pickup
    @Published var isUsingCurrentLocationForPickup: Bool = false
    @Published var matchedRoutes: [BusRoute] = []
    @Published var isSearching: Bool = false
    @Published var showSuggestions: Bool = false

    private let proximityThresholdMeters: Double = 2000

    //added a few locations for UI view
    let predefinedLocations: [PredefinedLocation] = [
        PredefinedLocation(name: "Colombo Fort", area: "Colombo 01", coordinate: CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8428)),
        PredefinedLocation(name: "Pettah Bus Stand", area: "Colombo 11", coordinate: CLLocationCoordinate2D(latitude: 6.9355, longitude: 79.8503)),
        PredefinedLocation(name: "Maradana", area: "Colombo 10", coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)),
        PredefinedLocation(name: "Borella", area: "Colombo 08", coordinate: CLLocationCoordinate2D(latitude: 6.9147, longitude: 79.8774)),
        PredefinedLocation(name: "Nugegoda", area: "Colombo 10", coordinate: CLLocationCoordinate2D(latitude: 6.8728, longitude: 79.8889)),
        PredefinedLocation(name: "Maharagama", area: "Western Province", coordinate: CLLocationCoordinate2D(latitude: 6.8484, longitude: 79.9266)),
        PredefinedLocation(name: "Battaramulla", area: "Western Province", coordinate: CLLocationCoordinate2D(latitude: 6.9046, longitude: 79.9196)),
        PredefinedLocation(name: "Rajagiriya", area: "Western Province", coordinate: CLLocationCoordinate2D(latitude: 6.9050, longitude: 79.8960)),
        PredefinedLocation(name: "Kottawa", area: "Western Province", coordinate: CLLocationCoordinate2D(latitude: 6.8380, longitude: 79.9680)),
        PredefinedLocation(name: "Kaduwela", area: "Western Province", coordinate: CLLocationCoordinate2D(latitude: 6.9284, longitude: 79.9803)),
        PredefinedLocation(name: "Malabe", area: "Western Province", coordinate: CLLocationCoordinate2D(latitude: 6.9063, longitude: 79.9726)),
        PredefinedLocation(name: "Athurugiriya", area: "Western Province", coordinate: CLLocationCoordinate2D(latitude: 6.8787, longitude: 79.9913)),
    ]

    //added a few routes for ui view
    private let allRoutes: [BusRoute] = [
        BusRoute(
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
        BusRoute(
            busNumber: "SL-B 1540",
            routeName: "Colombo Fort → Malabe",
            origin: "Colombo Fort",
            destination: "Malabe",
            driverName: "S. Fernando",
            driverPhone: "+94 77 333 4444",
            vehicleBrand: "Toyota",
            vehicleType: "Van",
            capacity: 14,
            currentPassengers: 0,
            rating: 4.7,
            morningStartTime: "06:45 AM",
            morningEndTime: "08:00 AM",
            eveningStartTime: "05:45 PM",
            eveningEndTime: "07:00 PM",
            estimatedMonthlyCost: 4200,
            stops: ["Colombo Fort", "Pettah Bus Stand", "Rajagiriya", "Battaramulla", "Malabe"]
        ),
        BusRoute(
            busNumber: "SL-B 1760",
            routeName: "Nugegoda → Kaduwela",
            origin: "Nugegoda",
            destination: "Kaduwela",
            driverName: "R. Jayasinghe",
            driverPhone: "+94 77 555 6666",
            vehicleBrand: "Mitsubishi",
            vehicleType: "Van",
            capacity: 12,
            currentPassengers: 7,
            rating: 4.1,
            morningStartTime: "07:00 AM",
            morningEndTime: "08:30 AM",
            eveningStartTime: "06:00 PM",
            eveningEndTime: "07:30 PM",
            estimatedMonthlyCost: 3800,
            stops: ["Nugegoda", "Rajagiriya", "Battaramulla", "Kaduwela"]
        ),
        BusRoute(
            busNumber: "SL-B 1920",
            routeName: "Colombo Fort → Athurugiriya",
            origin: "Colombo Fort",
            destination: "Athurugiriya",
            driverName: "T. Silva",
            driverPhone: "+94 77 777 8888",
            vehicleBrand: "Ashok Leyland",
            vehicleType: "Bus",
            capacity: 50,
            currentPassengers: 30,
            rating: 4.5,
            morningStartTime: "07:15 AM",
            morningEndTime: "08:50 AM",
            eveningStartTime: "06:15 PM",
            eveningEndTime: "07:50 PM",
            estimatedMonthlyCost: 4500,
            stops: ["Colombo Fort", "Maradana", "Borella", "Rajagiriya", "Malabe", "Athurugiriya"]
        ),
    ]

    var activeSuggestions: [PredefinedLocation] {
        let query = activeField == .pickup ? pickupText : destinationText
        guard !query.isEmpty else { return [] }
        return predefinedLocations.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.area.localizedCaseInsensitiveContains(query)
        }
    }

    var bothLocationsSelected: Bool {
        pickupLocation != nil && destinationLocation != nil
    }

    func closestLocation(to coordinate: CLLocationCoordinate2D) -> PredefinedLocation? {
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return predefinedLocations
            .map { loc -> (PredefinedLocation, Double) in
                let locCL = CLLocation(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
                return (loc, userLocation.distance(from: locCL))
            }
            .filter { $0.1 <= proximityThresholdMeters }
            .min(by: { $0.1 < $1.1 })?
            .0
    }

    func selectLocation(_ location: PredefinedLocation) {
        if activeField == .pickup {
            pickupLocation = location
            pickupText = location.name
            isUsingCurrentLocationForPickup = false
            if destinationLocation == nil {
                activeField = .destination
                showSuggestions = false
            } else {
                showSuggestions = false
                loadRoutes()
            }
        } else {
            destinationLocation = location
            destinationText = location.name
            showSuggestions = false
            if pickupLocation != nil {
                loadRoutes()
            }
        }
    }

    func useCurrentLocationForPickup(coordinate: CLLocationCoordinate2D) {
        if let closest = closestLocation(to: coordinate) {
            pickupLocation = closest
            pickupText = closest.name
            isUsingCurrentLocationForPickup = true
            activeField = .destination
            showSuggestions = false
            if destinationLocation != nil {
                loadRoutes()
            }
        }
    }

    func useCurrentLocationForPickupMocked() {
        let sampleCoordinate = CLLocationCoordinate2D(latitude: 6.9050, longitude: 79.8960)
        useCurrentLocationForPickup(coordinate: sampleCoordinate)
    }

    func useCurrentLocationForDestination(coordinate: CLLocationCoordinate2D) {
        if let closest = closestLocation(to: coordinate) {
            destinationLocation = closest
            destinationText = closest.name
            activeField = .destination
            showSuggestions = false
            if pickupLocation != nil {
                loadRoutes()
            }
        }
    }

    func useCurrentLocationForDestinationMocked() {
        let sampleCoordinate = CLLocationCoordinate2D(latitude: 6.8484, longitude: 79.9266)
        useCurrentLocationForDestination(coordinate: sampleCoordinate)
    }

    func clearPickup() {
        pickupLocation = nil
        pickupText = ""
        isUsingCurrentLocationForPickup = false
        matchedRoutes = []
    }

    func clearDestination() {
        destinationLocation = nil
        destinationText = ""
        matchedRoutes = []
    }

    func swapLocations() {
        let tempLocation = pickupLocation
        let tempText = pickupText
        pickupLocation = destinationLocation
        pickupText = destinationText
        destinationLocation = tempLocation
        destinationText = tempText
        isUsingCurrentLocationForPickup = false
        if bothLocationsSelected { loadRoutes() }
    }

    private func loadRoutes() {
        guard let pickup = pickupLocation, let destination = destinationLocation else { return }
        isSearching = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self else { return }
            self.matchedRoutes = self.allRoutes.filter { route in
                let pickupIndex = route.stops.firstIndex(of: pickup.name)
                let destinationIndex = route.stops.firstIndex(of: destination.name)
                if let pi = pickupIndex, let di = destinationIndex {
                    return pi < di
                }
                return false
            }
            self.isSearching = false
        }
    }
}
