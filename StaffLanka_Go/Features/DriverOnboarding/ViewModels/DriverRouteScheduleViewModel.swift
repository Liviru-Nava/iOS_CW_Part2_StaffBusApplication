//
//  DriverRouteScheduleViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-07.
//

import Foundation
import SwiftUI
import Combine
import MapKit
import FirebaseAuth
import FirebaseFirestore


struct MapSearchResult: Identifiable {
    let id: UUID
    var title: String
    var subtitle: String
    var coordinate: CLLocationCoordinate2D

    init(id: UUID = UUID(), title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}

enum SearchTarget {
    case start, end, stop
}

struct RouteStop: Identifiable {
    let id: UUID
    var name: String
    var locationLabel: String
    var order: Int
    var coordinate: CLLocationCoordinate2D?

    init(id: UUID = UUID(), name: String = "", locationLabel: String = "", order: Int = 0, coordinate: CLLocationCoordinate2D? = nil) {
        self.id = id
        self.name = name
        self.locationLabel = locationLabel
        self.order = order
        self.coordinate = coordinate
    }
}

struct TripSchedule {
    var departureTime: Date
    var estimatedArrivalTime: Date

    init(departureTime: Date = Date()) {
        self.departureTime = departureTime
        self.estimatedArrivalTime = departureTime
    }
}

enum DayOfWeek: String, CaseIterable, Identifiable {
    case monday    = "Mon"
    case tuesday   = "Tue"
    case wednesday = "Wed"
    case thursday  = "Thu"
    case friday    = "Fri"
    case saturday  = "Sat"
    case sunday    = "Sun"
    var id: String { rawValue }
    var isWeekend: Bool { self == .saturday || self == .sunday }
}


@MainActor
final class DriverRouteScheduleViewModel: ObservableObject {

    private let upstreamPersonalInfoViewModel: DriverPersonalInfoViewModel
    private let upstreamBusInfoViewModel: DriverBusInfoViewModel

    init(
        personalInfoViewModel: DriverPersonalInfoViewModel? = nil,
        busInfoViewModel: DriverBusInfoViewModel? = nil
    ) {
        self.upstreamPersonalInfoViewModel = personalInfoViewModel ?? DriverPersonalInfoViewModel()
        self.upstreamBusInfoViewModel = busInfoViewModel ?? DriverBusInfoViewModel()
    }

    @Published var morningPrice: String = ""
    @Published var eveningPrice: String = ""
    @Published var bothTripsPrice: String = ""

    @Published var submissionErrorMessage: String? = nil

    @Published var startingPoint: String = ""
    @Published var endingPoint: String = ""
    @Published var startCoordinate: CLLocationCoordinate2D? = nil
    @Published var endCoordinate: CLLocationCoordinate2D? = nil

    @Published var activeSearchTarget: SearchTarget? = nil
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), // Colombo, Sri Lanka
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    @Published var mapPinnedCoordinate: CLLocationCoordinate2D? = nil
    @Published var mapPinnedLabel: String = ""
    @Published var mapSearchQuery: String = ""
    @Published var mapSearchResults: [MapSearchResult] = []
    @Published var isSearching: Bool = false

    @Published var stops: [RouteStop] = []
    @Published var selectedDays: Set<DayOfWeek> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    @Published var morningTrip: TripSchedule = TripSchedule(
        departureTime: Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date()) ?? Date()
    )
    @Published var eveningTrip: TripSchedule = TripSchedule(
        departureTime: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
    )
    @Published var showAddStop: Bool = false
    @Published var newStopName: String = ""
    @Published var newStopLocation: String = ""
    @Published var isSubmitting: Bool = false
    @Published var onboardingComplete: Bool = false

    private let travelMinutesPerStop: Int = 8
    private var activeSearchTask: Task<Void, Never>?


    var isRouteValid: Bool {
        !startingPoint.trimmingCharacters(in: .whitespaces).isEmpty &&
        !endingPoint.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isPricingValid: Bool {
        guard let morning = Double(morningPrice),
              let evening = Double(eveningPrice),
              let both = Double(bothTripsPrice) else {
            return false
        }
        
        let isValidRange = { (price: Double) -> Bool in
            price >= 5000 && price <= 15000
        }
        
        return isValidRange(morning) && isValidRange(evening) && isValidRange(both) && (both < (morning + evening))
    }

    var canSubmit: Bool {
        isRouteValid && !selectedDays.isEmpty && isPricingValid
    }

    var orderedStops: [RouteStop] {
        stops.sorted { $0.order < $1.order }
    }

    var allMapAnnotations: [MapSearchResult] {
        var annotations: [MapSearchResult] = []
        if let startCoord = startCoordinate {
            annotations.append(MapSearchResult(
                title: startingPoint.isEmpty ? "Start" : startingPoint,
                subtitle: "Start",
                coordinate: startCoord
            ))
        }
        for stop in orderedStops {
            if let stopCoord = stop.coordinate {
                annotations.append(MapSearchResult(title: stop.name, subtitle: "Stop", coordinate: stopCoord))
            }
        }
        if let endCoord = endCoordinate {
            annotations.append(MapSearchResult(
                title: endingPoint.isEmpty ? "End" : endingPoint,
                subtitle: "End",
                coordinate: endCoord
            ))
        }
        return annotations
    }


    func computedArrival(from departureTime: Date) -> Date {
        let totalTravelMinutes = (stops.count + 1) * travelMinutesPerStop
        return Calendar.current.date(byAdding: .minute, value: totalTravelMinutes, to: departureTime) ?? departureTime
    }

    func updateArrivalTimes() {
        morningTrip.estimatedArrivalTime = computedArrival(from: morningTrip.departureTime)
        eveningTrip.estimatedArrivalTime = computedArrival(from: eveningTrip.departureTime)
    }


    func addStop() {
        let trimmedName = newStopName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        let newStop = RouteStop(
            name: trimmedName,
            locationLabel: newStopLocation.trimmingCharacters(in: .whitespaces),
            order: stops.count
        )
        stops.append(newStop)
        newStopName = ""
        showAddStop = false
        updateArrivalTimes()
    }

    func removeStop(at offsets: IndexSet) {
        stops.remove(atOffsets: offsets)
        for index in stops.indices { stops[index].order = index }
        updateArrivalTimes()
    }

    func moveStop(from sourceOffsets: IndexSet, to destinationOffset: Int) {
        stops.move(fromOffsets: sourceOffsets, toOffset: destinationOffset)
        for index in stops.indices { stops[index].order = index }
        updateArrivalTimes()
    }


    func toggleDay(_ day: DayOfWeek) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }


    func clearStart() {
        startCoordinate = nil
        startingPoint   = ""
    }

    func clearEnd() {
        endCoordinate = nil
        endingPoint   = ""
    }

    func beginSearch(for searchTarget: SearchTarget) {
        activeSearchTarget = searchTarget
        mapPinnedCoordinate = nil
        mapPinnedLabel = ""
        mapSearchQuery = ""
        mapSearchResults = []
    }

    func cancelSearch() {
        activeSearchTarget = nil
        mapPinnedCoordinate = nil
        mapPinnedLabel = ""
        mapSearchQuery = ""
        mapSearchResults = []
    }

    func flyToRoute() {
        var routeCoordinates: [CLLocationCoordinate2D] = []
        if let startCoord = startCoordinate { routeCoordinates.append(startCoord) }
        routeCoordinates += orderedStops.compactMap { $0.coordinate }
        if let endCoord = endCoordinate { routeCoordinates.append(endCoord) }
        guard routeCoordinates.count >= 2 else { return }

        let latitudes  = routeCoordinates.map { $0.latitude }
        let longitudes = routeCoordinates.map { $0.longitude }
        let minLatitude  = latitudes.min()!;  let maxLatitude  = latitudes.max()!
        let minLongitude = longitudes.min()!; let maxLongitude = longitudes.max()!

        let centerCoordinate = CLLocationCoordinate2D(
            latitude:  (minLatitude  + maxLatitude)  / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        let paddedSpan = MKCoordinateSpan(
            latitudeDelta:  (maxLatitude  - minLatitude)  * 1.4 + 0.02,
            longitudeDelta: (maxLongitude - minLongitude) * 1.4 + 0.02
        )
        mapRegion = MKCoordinateRegion(center: centerCoordinate, span: paddedSpan)
    }

    func pinOnMap(coordinate tappedCoordinate: CLLocationCoordinate2D) {
        mapPinnedCoordinate = tappedCoordinate
        mapPinnedLabel = ""
        Task {
            do {
                let tappedLocation = CLLocation(latitude: tappedCoordinate.latitude,
                                                longitude: tappedCoordinate.longitude)
                let reverseGeocodeRequest = MKReverseGeocodingRequest(location: tappedLocation)
                let mapItems = try await reverseGeocodeRequest?.mapItems ?? []
                if let firstItem = mapItems.first {
                    let resolvedName = firstItem.name
                        ?? firstItem.address?.shortAddress
                        ?? firstItem.address?.fullAddress
                        ?? "Selected location"
                    self.mapPinnedLabel = resolvedName
                }
            } catch {
                self.mapPinnedLabel = "Selected location"
            }
        }
    }

    func confirmPin() {
        guard let pinnedCoordinate = mapPinnedCoordinate else { return }
        let resolvedLabel = mapPinnedLabel.isEmpty ? "Pinned location" : mapPinnedLabel
        switch activeSearchTarget {
        case .start:
            startCoordinate = pinnedCoordinate
            startingPoint   = resolvedLabel
        case .end:
            endCoordinate = pinnedCoordinate
            endingPoint   = resolvedLabel
        case .stop:
            let newStop = RouteStop(
                name: resolvedLabel,
                locationLabel: resolvedLabel,
                order: stops.count,
                coordinate: pinnedCoordinate
            )
            stops.append(newStop)
            updateArrivalTimes()
        case nil:
            break
        }
        cancelSearch()
    }

    func selectSearchResult(_ selectedResult: MapSearchResult) {
        mapPinnedCoordinate = selectedResult.coordinate
        mapPinnedLabel      = selectedResult.title
        mapRegion = MKCoordinateRegion(
            center: selectedResult.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapSearchResults = []
        mapSearchQuery   = selectedResult.title
    }

    func searchLocations(query searchQuery: String) {
        activeSearchTask?.cancel()
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            mapSearchResults = []
            return
        }
        isSearching = true
        activeSearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let localSearchRequest = MKLocalSearch.Request()
            localSearchRequest.naturalLanguageQuery = searchQuery
            localSearchRequest.region = mapRegion
            let fetchedItems = (try? await MKLocalSearch(request: localSearchRequest).start())?.mapItems ?? []
            guard !Task.isCancelled else { return }
            mapSearchResults = fetchedItems.prefix(8).map { mapItem in
                let subtitleText = mapItem.address?.shortAddress ?? mapItem.address?.fullAddress ?? ""
                return MapSearchResult(
                    title: mapItem.name ?? "",
                    subtitle: subtitleText,
                    coordinate: mapItem.location.coordinate
                )
            }
            isSearching = false
        }
    }


    func showDriverMenu()    {}
    func showNotifications() {}
    func showPreviousRoute() {}
    func showNextRoute()     {}


    func submitOnboarding() async {
        guard canSubmit else { return }
        guard let authenticatedUserId = Auth.auth().currentUser?.uid else {
            submissionErrorMessage = "You must be signed in to complete registration."
            return
        }

        isSubmitting = true
        submissionErrorMessage = nil

        do {
            let routeStopDataList: [RouteStopData] = orderedStops.enumerated().map { stopIndex, routeStop in
                RouteStopData(
                    stopName: routeStop.name,
                    latitude: routeStop.coordinate?.latitude ?? 0.0,
                    longitude: routeStop.coordinate?.longitude ?? 0.0,
                    stopOrder: stopIndex
                )
            }

            let morningScheduleEntry = RouteScheduleData(
                scheduledDepartureTime: morningTrip.departureTime,
                scheduledArrivalTime: morningTrip.estimatedArrivalTime,
                activeDays: selectedDays.map { $0.rawValue }
            )
            let eveningScheduleEntry = RouteScheduleData(
                scheduledDepartureTime: eveningTrip.departureTime,
                scheduledArrivalTime: eveningTrip.estimatedArrivalTime,
                activeDays: selectedDays.map { $0.rawValue }
            )

            let mPrice = Double(morningPrice) ?? 0.0
            let ePrice = Double(eveningPrice) ?? 0.0
            let bPrice = Double(bothTripsPrice) ?? 0.0

            let newRouteRecord = RouteModel(
                id: nil,
                ownerDriverId: authenticatedUserId,
                startLocation: RouteLocationData(
                    locationName: startingPoint,
                    latitude: startCoordinate?.latitude ?? 0.0,
                    longitude: startCoordinate?.longitude ?? 0.0
                ),
                endLocation: RouteLocationData(
                    locationName: endingPoint,
                    latitude: endCoordinate?.latitude ?? 0.0,
                    longitude: endCoordinate?.longitude ?? 0.0
                ),
                routeStops: routeStopDataList,
                scheduleEntries: [morningScheduleEntry, eveningScheduleEntry],
                morningPrice: mPrice,
                eveningPrice: ePrice,
                bothTripsPrice: bPrice,
                pricePerTrip: nil,
                routeCreatedAt: Date(),
                startName: startingPoint,
                endName: endingPoint
            )


            let createdRouteId = try await RouteService.shared.createRoute(routeRecord: newRouteRecord)

            let busInfoForDriver = DriverBusInfo(
                plateNumber: upstreamBusInfoViewModel.plateNumber,
                busName: upstreamBusInfoViewModel.busName,
                busType: upstreamBusInfoViewModel.busType.rawValue,
                passengerCapacity: Int(upstreamBusInfoViewModel.capacity) ?? 0
            )

            let newDriverRecord = DriverModel(
                id: authenticatedUserId,
                fullName: upstreamPersonalInfoViewModel.fullName,
                licenseNumber: upstreamPersonalInfoViewModel.licenseNumber,
                busInformation: busInfoForDriver,
                assignedRouteId: createdRouteId,
                driverCreatedAt: Date()
            )

            try await DriverService.shared.createDriver(driverRecord: newDriverRecord)

            try await UserService.shared.updateUserRoleAndName(
                userId: authenticatedUserId,
                updatedRole: "driver",
                fullName: upstreamPersonalInfoViewModel.fullName
            )

            await AuthManager.shared.refreshUserRoleFromFirestore(userId: authenticatedUserId)

            isSubmitting = false
            onboardingComplete = true

        } catch {
            submissionErrorMessage = error.localizedDescription
            isSubmitting = false
        }
    }
}
