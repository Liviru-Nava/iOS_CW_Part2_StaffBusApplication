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
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
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
        guard let morningPriceDouble = Double(morningPrice),
              let eveningPriceDouble = Double(eveningPrice),
              let bothTripsPriceDouble = Double(bothTripsPrice) else {
            return false
        }

        let isPriceInValidRange = { (priceValue: Double) -> Bool in
            priceValue >= 5000 && priceValue <= 15000
        }

        return isPriceInValidRange(morningPriceDouble) &&
               isPriceInValidRange(eveningPriceDouble) &&
               isPriceInValidRange(bothTripsPriceDouble) &&
               (bothTripsPriceDouble < (morningPriceDouble + eveningPriceDouble))
    }

    var canSubmit: Bool {
        isRouteValid && !selectedDays.isEmpty && isPricingValid
    }

    var orderedStops: [RouteStop] {
        stops.sorted { $0.order < $1.order }
    }

    var allMapAnnotations: [MapSearchResult] {
        var allAnnotationItems: [MapSearchResult] = []
        if let resolvedStartCoordinate = startCoordinate {
            allAnnotationItems.append(MapSearchResult(
                title: startingPoint.isEmpty ? "Start" : startingPoint,
                subtitle: "Start",
                coordinate: resolvedStartCoordinate
            ))
        }
        for routeStop in orderedStops {
            if let resolvedStopCoordinate = routeStop.coordinate {
                allAnnotationItems.append(MapSearchResult(title: routeStop.name, subtitle: "Stop", coordinate: resolvedStopCoordinate))
            }
        }
        if let resolvedEndCoordinate = endCoordinate {
            allAnnotationItems.append(MapSearchResult(
                title: endingPoint.isEmpty ? "End" : endingPoint,
                subtitle: "End",
                coordinate: resolvedEndCoordinate
            ))
        }
        return allAnnotationItems
    }


    func computedArrival(from departureTime: Date) -> Date {
        let totalTravelMinutesForAllStops = (stops.count + 1) * travelMinutesPerStop
        return Calendar.current.date(byAdding: .minute, value: totalTravelMinutesForAllStops, to: departureTime) ?? departureTime
    }

    func updateArrivalTimes() {
        morningTrip.estimatedArrivalTime = computedArrival(from: morningTrip.departureTime)
        eveningTrip.estimatedArrivalTime = computedArrival(from: eveningTrip.departureTime)
    }


    func addStop() {
        let trimmedStopName = newStopName.trimmingCharacters(in: .whitespaces)
        guard !trimmedStopName.isEmpty else { return }
        let newRouteStop = RouteStop(
            name: trimmedStopName,
            locationLabel: newStopLocation.trimmingCharacters(in: .whitespaces),
            order: stops.count
        )
        stops.append(newRouteStop)
        newStopName = ""
        showAddStop = false
        updateArrivalTimes()
    }

    func removeStop(at offsets: IndexSet) {
        stops.remove(atOffsets: offsets)
        for stopIndex in stops.indices { stops[stopIndex].order = stopIndex }
        updateArrivalTimes()
    }

    func moveStop(from sourceOffsets: IndexSet, to destinationOffset: Int) {
        stops.move(fromOffsets: sourceOffsets, toOffset: destinationOffset)
        for stopIndex in stops.indices { stops[stopIndex].order = stopIndex }
        updateArrivalTimes()
    }


    func toggleDay(_ dayOfWeek: DayOfWeek) {
        if selectedDays.contains(dayOfWeek) {
            selectedDays.remove(dayOfWeek)
        } else {
            selectedDays.insert(dayOfWeek)
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
        var allRouteCoordinates: [CLLocationCoordinate2D] = []
        if let resolvedStartCoordinate = startCoordinate { allRouteCoordinates.append(resolvedStartCoordinate) }
        allRouteCoordinates += orderedStops.compactMap { $0.coordinate }
        if let resolvedEndCoordinate = endCoordinate { allRouteCoordinates.append(resolvedEndCoordinate) }
        guard allRouteCoordinates.count >= 2 else { return }

        let allLatitudes  = allRouteCoordinates.map { $0.latitude }
        let allLongitudes = allRouteCoordinates.map { $0.longitude }
        let minimumLatitude  = allLatitudes.min()!;  let maximumLatitude  = allLatitudes.max()!
        let minimumLongitude = allLongitudes.min()!; let maximumLongitude = allLongitudes.max()!

        let routeCenterCoordinate = CLLocationCoordinate2D(
            latitude:  (minimumLatitude  + maximumLatitude)  / 2,
            longitude: (minimumLongitude + maximumLongitude) / 2
        )
        let paddedCoordinateSpan = MKCoordinateSpan(
            latitudeDelta:  (maximumLatitude  - minimumLatitude)  * 1.4 + 0.02,
            longitudeDelta: (maximumLongitude - minimumLongitude) * 1.4 + 0.02
        )
        mapRegion = MKCoordinateRegion(center: routeCenterCoordinate, span: paddedCoordinateSpan)
    }

    func pinOnMap(coordinate tappedCoordinate: CLLocationCoordinate2D) {
        mapPinnedCoordinate = tappedCoordinate
        mapPinnedLabel = ""
        Task {
            do {
                let tappedCLLocation = CLLocation(latitude: tappedCoordinate.latitude,
                                                  longitude: tappedCoordinate.longitude)
                let reverseGeocodeRequest = MKReverseGeocodingRequest(location: tappedCLLocation)
                let resolvedMapItems = try await reverseGeocodeRequest?.mapItems ?? []
                if let firstResolvedMapItem = resolvedMapItems.first {
                    let resolvedLocationName = firstResolvedMapItem.name
                        ?? firstResolvedMapItem.address?.shortAddress
                        ?? firstResolvedMapItem.address?.fullAddress
                        ?? "Selected location"
                    self.mapPinnedLabel = resolvedLocationName
                }
            } catch {
                self.mapPinnedLabel = "Selected location"
            }
        }
    }

    func confirmPin() {
        guard let confirmedPinnedCoordinate = mapPinnedCoordinate else { return }
        let resolvedPinnedLabel = mapPinnedLabel.isEmpty ? "Pinned location" : mapPinnedLabel
        switch activeSearchTarget {
        case .start:
            startCoordinate = confirmedPinnedCoordinate
            startingPoint   = resolvedPinnedLabel
        case .end:
            endCoordinate = confirmedPinnedCoordinate
            endingPoint   = resolvedPinnedLabel
        case .stop:
            let newPinnedStop = RouteStop(
                name: resolvedPinnedLabel,
                locationLabel: resolvedPinnedLabel,
                order: stops.count,
                coordinate: confirmedPinnedCoordinate
            )
            stops.append(newPinnedStop)
            updateArrivalTimes()
        case nil:
            break
        }
        cancelSearch()
    }

    func selectSearchResult(_ selectedSearchResult: MapSearchResult) {
        mapPinnedCoordinate = selectedSearchResult.coordinate
        mapPinnedLabel      = selectedSearchResult.title
        mapRegion = MKCoordinateRegion(
            center: selectedSearchResult.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapSearchResults = []
        mapSearchQuery   = selectedSearchResult.title
    }

    func searchLocations(query searchQueryString: String) {
        activeSearchTask?.cancel()
        guard !searchQueryString.trimmingCharacters(in: .whitespaces).isEmpty else {
            mapSearchResults = []
            return
        }
        isSearching = true
        activeSearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let localSearchRequest = MKLocalSearch.Request()
            localSearchRequest.naturalLanguageQuery = searchQueryString
            localSearchRequest.region = mapRegion
            let fetchedMapItems = (try? await MKLocalSearch(request: localSearchRequest).start())?.mapItems ?? []
            guard !Task.isCancelled else { return }
            mapSearchResults = fetchedMapItems.prefix(8).map { fetchedMapItem in
                let subtitleText = fetchedMapItem.address?.shortAddress ?? fetchedMapItem.address?.fullAddress ?? ""
                return MapSearchResult(
                    title: fetchedMapItem.name ?? "",
                    subtitle: subtitleText,
                    coordinate: fetchedMapItem.location.coordinate
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

            let morningPriceDouble = Double(morningPrice) ?? 0.0
            let eveningPriceDouble = Double(eveningPrice) ?? 0.0
            let bothTripsPriceDouble = Double(bothTripsPrice) ?? 0.0

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
                morningPrice: morningPriceDouble,
                eveningPrice: eveningPriceDouble,
                bothTripsPrice: bothTripsPriceDouble,
                pricePerTrip: nil,
                routeCreatedAt: Date(),
                startName: startingPoint,
                endName: endingPoint
            )

            let createdRouteId = try await RouteService.shared.createRoute(routeRecord: newRouteRecord)

            let busInfoForDriverRecord = DriverBusInfo(
                plateNumber: upstreamBusInfoViewModel.plateNumber,
                busName: upstreamBusInfoViewModel.busName,
                busType: upstreamBusInfoViewModel.busType.rawValue,
                passengerCapacity: Int(upstreamBusInfoViewModel.capacity) ?? 0
            )

            let newDriverRecord = DriverModel(
                id: authenticatedUserId,
                fullName: upstreamPersonalInfoViewModel.fullName,
                licenseNumber: upstreamPersonalInfoViewModel.licenseNumber,
                busInformation: busInfoForDriverRecord,
                assignedRouteId: createdRouteId,
                driverCreatedAt: Date(),
                serviceStatus: "active",
                isAcceptingRequests: true
            )

            try await DriverService.shared.createDriver(driverRecord: newDriverRecord)

            try await UserService.shared.updateUserRoleAndName(
                userId: authenticatedUserId,
                updatedRole: "driver",
                fullName: upstreamPersonalInfoViewModel.fullName
            )

            await AuthManager.shared.refreshUserRoleFromFirestore(userId: authenticatedUserId)

            // Schedule recurring calendar reminders for both operating sessions
            await scheduleDriverCalendarRemindersAfterOnboarding()

            isSubmitting = false
            onboardingComplete = true

        } catch {
            submissionErrorMessage = error.localizedDescription
            isSubmitting = false
        }
    }

    // Creates recurring calendar events for the driver's morning and evening operating schedule
    private func scheduleDriverCalendarRemindersAfterOnboarding() async {
        let activeDayStrings = selectedDays.map { $0.rawValue }

        await EventKitManager.shared.scheduleDriverOperatingDayReminders(
            routeStartLocationName: startingPoint,
            routeEndLocationName: endingPoint,
            morningDepartureTime: morningTrip.departureTime,
            morningEstimatedArrivalTime: morningTrip.estimatedArrivalTime,
            eveningDepartureTime: eveningTrip.departureTime,
            eveningEstimatedArrivalTime: eveningTrip.estimatedArrivalTime,
            routeActiveDays: activeDayStrings
        )

        print("[DriverRouteScheduleViewModel] Driver calendar reminders scheduled for route: \(startingPoint) → \(endingPoint)")
    }
}
