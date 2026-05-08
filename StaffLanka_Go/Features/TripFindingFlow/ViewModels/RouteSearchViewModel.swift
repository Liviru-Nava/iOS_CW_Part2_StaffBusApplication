//
//  RouteSearchViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-02.
//

import Foundation
import CoreLocation
import Combine
import FirebaseFirestore
import FirebaseAuth

struct PredefinedLocation: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let area: String

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PredefinedLocation, rhs: PredefinedLocation) -> Bool { lhs.id == rhs.id }
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

    @Published var matchedRoutes: [PassengerRouteResult] = []
    @Published var isSearching: Bool = false
    @Published var showSuggestions: Bool = false
    @Published var searchError: String? = nil

    @Published var availableLocations: [PredefinedLocation] = []
    @Published var isLoadingLocations: Bool = false

    init() {
        Task { await loadAvailableLocations() }
    }

    func loadAvailableLocations() async {
        let currentUserId = Auth.auth().currentUser?.uid ?? "NOT_AUTHENTICATED"
        print("[INFO] [RouteSearch] loadAvailableLocations — currentUserId: \(currentUserId)")

        isLoadingLocations = true
        do {
            let routes = try await RouteService.shared.fetchAllRoutes()
            print("[SUCCESS] [RouteSearch] Fetched \(routes.count) route(s) from Firestore")

            var nameSet = Set<String>()
            var locations: [PredefinedLocation] = []
            for route in routes {
                let startName = route.startLocation.locationName
                let endName   = route.endLocation.locationName
                print("[INFO] Route \(route.id ?? "NO_ID"): '\(startName)' -> '\(endName)' | driverId: \(route.ownerDriverId)")

                if !startName.isEmpty, nameSet.insert(startName).inserted {
                    locations.append(PredefinedLocation(name: startName, area: "Route Start"))
                }
                if !endName.isEmpty, nameSet.insert(endName).inserted {
                    locations.append(PredefinedLocation(name: endName, area: "Route End"))
                }
                // Also expose intermediate stop names so a passenger can search by stop
                for stop in route.routeStops where !stop.stopName.isEmpty {
                    if nameSet.insert(stop.stopName).inserted {
                        locations.append(PredefinedLocation(name: stop.stopName, area: "Route Stop"))
                    }
                }
            }
            self.availableLocations = locations.sorted { $0.name < $1.name }
            print("[SUCCESS] [RouteSearch] \(locations.count) unique location(s) loaded for picker: \(locations.map { $0.name })")
        } catch {
            print("[ERROR] [RouteSearch] loadAvailableLocations FAILED: \(error.localizedDescription)")
        }
        isLoadingLocations = false
    }

    private func loadRoutes() {
        guard let pickup = pickupLocation, let destination = destinationLocation else { return }

        print("\n[INFO] [RouteSearch] loadRoutes — pickup: '\(pickup.name)' -> destination: '\(destination.name)'")

        isSearching = true
        searchError = nil
        matchedRoutes = []

        Task {
            do {
                let allRoutes = try await RouteService.shared.fetchAllRoutes()
                print("[SUCCESS] [RouteSearch] Total routes in Firestore: \(allRoutes.count)")

                let matchingRoutes = allRoutes.filter { route in
                    var sequence: [String] = []
                    sequence.append(route.startLocation.locationName.localizedCaseInsensitiveCompare(pickup.name) == .orderedSame ? pickup.name.lowercased() : route.startLocation.locationName.lowercased())
                    
                    let sortedStops = route.routeStops.sorted { $0.stopOrder < $1.stopOrder }
                    sequence.append(contentsOf: sortedStops.map { $0.stopName.lowercased() })
                    
                    sequence.append(route.endLocation.locationName.localizedCaseInsensitiveCompare(destination.name) == .orderedSame ? destination.name.lowercased() : route.endLocation.locationName.lowercased())
                    
                    let pQuery = pickup.name.lowercased()
                    let dQuery = destination.name.lowercased()
                    
                    if let pIndex = sequence.firstIndex(of: pQuery), let dIndex = sequence.lastIndex(of: dQuery) {
                        return pIndex < dIndex // Must be traveling in the correct direction
                    }
                    return false
                }
                print("[WARNING] [RouteSearch] Matching routes after filter: \(matchingRoutes.count)")

                var results: [PassengerRouteResult] = []

                for route in matchingRoutes {
                    let routeId = route.id ?? "NO_ID"
                    print("\n[INFO] [RouteSearch] Processing route \(routeId) | driverId: \(route.ownerDriverId)")

                    guard route.isAcceptable else {
                        print("[WARNING] [RouteSearch] Route \(routeId) skipped — only \(route.scheduleEntries.count) schedule entry(ies), need >= 2")
                        continue
                    }

                    do {
                        print("[INFO] [RouteSearch] Fetching driver document: drivers/\(route.ownerDriverId)")
                        let driver = try await DriverService.shared.fetchDriver(driverId: route.ownerDriverId)
                        print("[SUCCESS] [RouteSearch] Driver fetched: '\(driver.fullName)' | bus: '\(driver.busInformation.busName)' | plate: '\(driver.busInformation.plateNumber)'")
                        
                        guard driver.isAcceptingRequests == true else {
                            print("[WARNING] [RouteSearch] Driver \(driver.fullName) is not accepting requests, skipping.")
                            continue
                        }

                        if let result = PassengerRouteResult.build(from: route, driver: driver) {
                            print("[SUCCESS] [RouteSearch] PassengerRouteResult built successfully for route \(routeId)")
                            results.append(result)
                        } else {
                            print("[ERROR] [RouteSearch] PassengerRouteResult.build() returned nil for route \(routeId)")
                        }
                    } catch {
                        print("[ERROR] [RouteSearch] Driver fetch FAILED for \(route.ownerDriverId): \(error.localizedDescription)")
                        print("[WARNING] [RouteSearch] Building partial result from route data only (no driver info)")

                        if let partialResult = PassengerRouteResult.buildPartial(from: route) {
                            results.append(partialResult)
                            print("[INFO] [RouteSearch] Partial PassengerRouteResult added for route \(routeId)")
                        }
                    }
                }

                self.matchedRoutes = results
                print("\n[SUCCESS] [RouteSearch] Final matched results: \(results.count) route card(s) to display")

            } catch {
                self.searchError = "Could not load routes. Please try again."
                print("[ERROR] [RouteSearch] loadRoutes FAILED (outer): \(error.localizedDescription)")
            }
            self.isSearching = false
        }
    }

    var activeSuggestions: [PredefinedLocation] {
        let query = activeField == .pickup ? pickupText : destinationText
        guard !query.isEmpty else { return [] }
        return availableLocations.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.area.localizedCaseInsensitiveContains(query)
        }
    }

    var bothLocationsSelected: Bool {
        pickupLocation != nil && destinationLocation != nil
    }

    func selectLocation(_ location: PredefinedLocation) {
        print("[INFO] [RouteSearch] selectLocation '\(location.name)' for field: \(activeField == .pickup ? "pickup" : "destination")")
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

    func clearPickup() {
        pickupLocation = nil
        pickupText = ""
        isUsingCurrentLocationForPickup = false
        matchedRoutes = []
        searchError = nil
    }

    func clearDestination() {
        destinationLocation = nil
        destinationText = ""
        matchedRoutes = []
        searchError = nil
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
}

private extension RouteModel {
    var isAcceptable: Bool {
        scheduleEntries.count >= 2
    }
}
