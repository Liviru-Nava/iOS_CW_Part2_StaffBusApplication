//
//  DriverTripSimulationViewModel.swift
//  StaffLanka_Go
//

import Foundation
import MapKit
import Combine

struct SimulationRouteStop: Identifiable {
    let id = UUID()
    let stopDisplayName: String
    let coordinate: CLLocationCoordinate2D
    let textualInstructionToNextStop: String
}

struct SimulationPassengerStopRow: Identifiable {
    let id = UUID()
    let stopDisplayName: String
    let totalPassengersAtStop: Int
    let attendingPassengersCount: Int
    let unsurePassengersCount: Int
    let estimatedArrivalTimeLabel: String
    var hasBeenVisited: Bool
}

struct SimulationEnrolledPassenger: Identifiable {
    let id: String
    let fullName: String
    let assignedStopName: String
    let attendanceStatusLabel: String
}

@MainActor
final class DriverTripSimulationViewModel: ObservableObject {

    // Configurable — change this single value to adjust simulation length
    let simulationTotalDurationSeconds: Double = 90

    private let coordinateUpdateIntervalSeconds: Double = 0.4

    @Published var currentBusCoordinate: CLLocationCoordinate2D
    @Published var currentActiveStopIndex: Int = 0
    @Published var elapsedSimulationSeconds: Double = 0
    @Published var passengerStopRows: [SimulationPassengerStopRow] = []
    @Published var isInstructionsPanelVisible: Bool = false
    @Published var isSimulationComplete: Bool = false
    @Published var isFloatingPanelExpanded: Bool = false
    @Published var completedTripRecord: DriverHistoryTripRecord? = nil
    @Published var isCalculatingRoadRoute: Bool = true
    // Full road path from MKDirections — exposed so the View can draw MapPolyline
    @Published var roadPolylineCoordinates: [CLLocationCoordinate2D] = []

    // San Francisco stops — MKDirections will route along actual roads between these
    let allSimulationStops: [SimulationRouteStop] = [
        SimulationRouteStop(
            stopDisplayName: "Union Square",
            coordinate: CLLocationCoordinate2D(latitude: 37.7879, longitude: -122.4075),
            textualInstructionToNextStop: "Head southwest on Geary St toward Powell St, then continue onto Market St"
        ),
        SimulationRouteStop(
            stopDisplayName: "Civic Center",
            coordinate: CLLocationCoordinate2D(latitude: 37.7796, longitude: -122.4179),
            textualInstructionToNextStop: "Turn left onto Van Ness Ave, then right onto 16th St toward Guerrero St"
        ),
        SimulationRouteStop(
            stopDisplayName: "Mission Dolores",
            coordinate: CLLocationCoordinate2D(latitude: 37.7650, longitude: -122.4269),
            textualInstructionToNextStop: "Continue south on Dolores St, turn right onto 18th St then left onto Castro St"
        ),
        SimulationRouteStop(
            stopDisplayName: "Castro District",
            coordinate: CLLocationCoordinate2D(latitude: 37.7609, longitude: -122.4350),
            textualInstructionToNextStop: "Head south on Castro St, turn right onto 24th St, then left onto Church St"
        ),
        SimulationRouteStop(
            stopDisplayName: "Noe Valley",
            coordinate: CLLocationCoordinate2D(latitude: 37.7502, longitude: -122.4326),
            textualInstructionToNextStop: "Continue south on Church St, then merge onto Diamond St toward Bosworth St"
        ),
        SimulationRouteStop(
            stopDisplayName: "Glen Park",
            coordinate: CLLocationCoordinate2D(latitude: 37.7330, longitude: -122.4337),
            textualInstructionToNextStop: ""
        )
    ]

    // Dense road-following path built by MKDirections; the bus moves along this
    private var fullRoadPathCoordinates: [CLLocationCoordinate2D] = []
    // Which index in fullRoadPathCoordinates corresponds to arriving at each stop
    private var stopArrivalPathIndices: [Int] = []

    private var simulationTimer: Timer?
    private var firestoreTripId: String?
    private var sessionLabel: String = "Morning"
    private var enrolledPassengers: [SimulationEnrolledPassenger] = []
    private var stopArrivalTimeLabels: [String] = []

    init() {
        currentBusCoordinate = allSimulationStops.first?.coordinate
            ?? CLLocationCoordinate2D(latitude: 37.7879, longitude: -122.4075)
    }

    deinit { simulationTimer?.invalidate() }

    func startSimulation(routeId: String, driverId: String, session: String, passengers: [SimulationEnrolledPassenger]) {
        sessionLabel = session
        enrolledPassengers = passengers
        currentActiveStopIndex = 0
        elapsedSimulationSeconds = 0
        isSimulationComplete = false
        isCalculatingRoadRoute = true
        stopArrivalTimeLabels = Array(repeating: "--:--", count: allSimulationStops.count)
        stopArrivalTimeLabels[0] = formattedCurrentTime()

        buildInitialPassengerStopRows(passengers: passengers)

        Task {
            // Build the road route first, then start the Firestore trip and timer
            await buildRoadRouteAlongActualRoads()
            isCalculatingRoadRoute = false

            do {
                let tripId = try await TripService.shared.startTrip(routeId: routeId, driverId: driverId, session: session)
                firestoreTripId = tripId
                print("🟢 [SimulationVM] Trip started in Firestore id: \(tripId)")
            } catch {
                print("🔴 [SimulationVM] Firestore startTrip error: \(error.localizedDescription)")
            }

            startSimulationTimer()
        }
    }

    // Requests driving routes from MKDirections for every consecutive stop pair
    // and assembles the results into one continuous road-following coordinate array
    private func buildRoadRouteAlongActualRoads() async {
        var assembledPathCoordinates: [CLLocationCoordinate2D] = []
        var assembledStopArrivalIndices: [Int] = [0] // stop 0 is always at index 0

        for legIndex in 0 ..< allSimulationStops.count - 1 {
            let legStartStop = allSimulationStops[legIndex]
            let legEndStop = allSimulationStops[legIndex + 1]

            let directionsRequest = MKDirections.Request()
            directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: legStartStop.coordinate))
            directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: legEndStop.coordinate))
            directionsRequest.transportType = .automobile

            if let calculatedRoute = try? await MKDirections(request: directionsRequest).calculate().routes.first {
                var legCoordinates = calculatedRoute.polyline.extractCoordinates()
                // Drop the first point on legs after the first to avoid duplicating the junction stop
                if legIndex > 0 { legCoordinates = Array(legCoordinates.dropFirst()) }
                assembledPathCoordinates.append(contentsOf: legCoordinates)
                print("🟢 [SimulationVM] Leg \(legIndex) road route: \(legCoordinates.count) points")
            } else {
                // Fallback: linear interpolation if MKDirections fails for this leg
                let fallbackPoints = linearInterpolatedCoordinates(
                    from: legStartStop.coordinate,
                    to: legEndStop.coordinate,
                    stepCount: 40
                )
                let pointsToAdd = legIndex > 0 ? Array(fallbackPoints.dropFirst()) : fallbackPoints
                assembledPathCoordinates.append(contentsOf: pointsToAdd)
                print("🟡 [SimulationVM] Leg \(legIndex) using linear fallback")
            }

            assembledStopArrivalIndices.append(assembledPathCoordinates.count - 1)
        }

        fullRoadPathCoordinates = assembledPathCoordinates
        stopArrivalPathIndices = assembledStopArrivalIndices
        roadPolylineCoordinates = assembledPathCoordinates
        print("🟢 [SimulationVM] Full road path: \(assembledPathCoordinates.count) total coordinates")
    }

    private func linearInterpolatedCoordinates(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, stepCount: Int) -> [CLLocationCoordinate2D] {
        (0 ... stepCount).map { step in
            let fraction = Double(step) / Double(stepCount)
            return CLLocationCoordinate2D(
                latitude: from.latitude + (to.latitude - from.latitude) * fraction,
                longitude: from.longitude + (to.longitude - from.longitude) * fraction
            )
        }
    }

    private func startSimulationTimer() {
        simulationTimer?.invalidate()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: coordinateUpdateIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.advanceSimulation() }
        }
    }

    // Advances the bus position by stepping through fullRoadPathCoordinates proportionally to elapsed time
    private func advanceSimulation() {
        guard !fullRoadPathCoordinates.isEmpty else { return }

        elapsedSimulationSeconds += coordinateUpdateIntervalSeconds
        let overallProgress = min(elapsedSimulationSeconds / simulationTotalDurationSeconds, 1.0)

        let targetPathIndex = min(
            Int(overallProgress * Double(fullRoadPathCoordinates.count - 1)),
            fullRoadPathCoordinates.count - 1
        )
        currentBusCoordinate = fullRoadPathCoordinates[targetPathIndex]

        // Check whether the bus has reached each stop's corresponding path index
        for (stopIndex, arrivalPathIndex) in stopArrivalPathIndices.enumerated() {
            if targetPathIndex >= arrivalPathIndex && currentActiveStopIndex < stopIndex {
                markStopAsVisited(stopIndex: stopIndex)
            }
        }

        updateEstimatedArrivalTimesForFutureStops(overallProgress: overallProgress)

        if let tripId = firestoreTripId {
            Task { try? await TripService.shared.updateDriverLocation(tripId: tripId, location: currentBusCoordinate) }
        }

        if overallProgress >= 1.0 { completeSimulation() }
    }

    private func markStopAsVisited(stopIndex: Int) {
        guard stopIndex < allSimulationStops.count, stopIndex > currentActiveStopIndex else { return }
        currentActiveStopIndex = stopIndex
        stopArrivalTimeLabels[stopIndex] = formattedCurrentTime()

        let visitedStopName = allSimulationStops[stopIndex].stopDisplayName
        if let rowIndex = passengerStopRows.firstIndex(where: { $0.stopDisplayName == visitedStopName }) {
            let existingRow = passengerStopRows[rowIndex]
            passengerStopRows[rowIndex] = SimulationPassengerStopRow(
                stopDisplayName: existingRow.stopDisplayName,
                totalPassengersAtStop: existingRow.totalPassengersAtStop,
                attendingPassengersCount: existingRow.attendingPassengersCount,
                unsurePassengersCount: existingRow.unsurePassengersCount,
                estimatedArrivalTimeLabel: stopArrivalTimeLabels[stopIndex],
                hasBeenVisited: true
            )
        }
    }

    private func updateEstimatedArrivalTimesForFutureStops(overallProgress: Double) {
        let secondsPerLeg = simulationTotalDurationSeconds / Double(allSimulationStops.count - 1)

        for stopIndex in (currentActiveStopIndex + 1) ..< allSimulationStops.count {
            let secondsUntilStop = Double(stopIndex) * secondsPerLeg - elapsedSimulationSeconds
            let estimatedArrivalDate = Date().addingTimeInterval(max(secondsUntilStop, 0))
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "hh:mm a"
            stopArrivalTimeLabels[stopIndex] = timeFormatter.string(from: estimatedArrivalDate)
        }

        for rowIndex in passengerStopRows.indices {
            guard !passengerStopRows[rowIndex].hasBeenVisited else { continue }
            if let matchingStopIndex = allSimulationStops.firstIndex(where: {
                $0.stopDisplayName == passengerStopRows[rowIndex].stopDisplayName
            }) {
                let existingRow = passengerStopRows[rowIndex]
                passengerStopRows[rowIndex] = SimulationPassengerStopRow(
                    stopDisplayName: existingRow.stopDisplayName,
                    totalPassengersAtStop: existingRow.totalPassengersAtStop,
                    attendingPassengersCount: existingRow.attendingPassengersCount,
                    unsurePassengersCount: existingRow.unsurePassengersCount,
                    estimatedArrivalTimeLabel: stopArrivalTimeLabels[matchingStopIndex],
                    hasBeenVisited: false
                )
            }
        }
    }

    private func completeSimulation() {
        guard !isSimulationComplete else { return }
        simulationTimer?.invalidate()
        simulationTimer = nil
        isSimulationComplete = true
        currentActiveStopIndex = allSimulationStops.count - 1
        currentBusCoordinate = allSimulationStops.last!.coordinate

        if let tripId = firestoreTripId {
            Task {
                do {
                    try await TripService.shared.finishTrip(tripId: tripId)
                    print("🟢 [SimulationVM] Trip finished in Firestore")
                } catch {
                    print("🔴 [SimulationVM] finishTrip error: \(error.localizedDescription)")
                }
            }
        }

        let builtTripRecord = buildCompletedTripHistoryRecord()
        completedTripRecord = builtTripRecord
        TripHistoryStore.shared.appendCompletedTrip(builtTripRecord)

        NotificationManager.shared.scheduleNotification(
            title: "Trip Completed",
            body: "Your \(sessionLabel.lowercased()) trip has ended. Great work!",
            actionType: "TRIP_END",
            isTripAlert: true
        )
    }

    private func buildInitialPassengerStopRows(passengers: [SimulationEnrolledPassenger]) {
        var stopCountMap: [String: (attending: Int, unsure: Int)] = [:]
        for stop in allSimulationStops { stopCountMap[stop.stopDisplayName] = (0, 0) }

        let intermediateStops = Array(allSimulationStops.dropFirst().dropLast())
        for (passengerIndex, passenger) in passengers.enumerated() {
            let assignedStopName: String
            if !passenger.assignedStopName.isEmpty,
               allSimulationStops.contains(where: { $0.stopDisplayName == passenger.assignedStopName }) {
                assignedStopName = passenger.assignedStopName
            } else {
                assignedStopName = intermediateStops[passengerIndex % intermediateStops.count].stopDisplayName
            }
            if passenger.attendanceStatusLabel == "attending" {
                stopCountMap[assignedStopName]?.attending += 1
            } else {
                stopCountMap[assignedStopName]?.unsure += 1
            }
        }

        passengerStopRows = allSimulationStops.enumerated().map { stopIndex, stop in
            let counts = stopCountMap[stop.stopDisplayName] ?? (0, 0)
            return SimulationPassengerStopRow(
                stopDisplayName: stop.stopDisplayName,
                totalPassengersAtStop: counts.attending + counts.unsure,
                attendingPassengersCount: counts.attending,
                unsurePassengersCount: counts.unsure,
                estimatedArrivalTimeLabel: stopIndex == 0 ? formattedCurrentTime() : "--:--",
                hasBeenVisited: stopIndex == 0
            )
        }
    }

    private func buildCompletedTripHistoryRecord() -> DriverHistoryTripRecord {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"

        let stopsTimeline = allSimulationStops.enumerated().map { stopIndex, stop in
            DriverTripStopRecord(
                stopName: stop.stopDisplayName,
                timeReached: stopArrivalTimeLabels[safe: stopIndex] ?? formattedCurrentTime(),
                stopStatus: .completed
            )
        }

        let passengerPickupList = enrolledPassengers.map { passenger in
            DriverTripPassengerPickupRecord(
                passengerFullName: passenger.fullName,
                boardingStopName: passenger.assignedStopName.isEmpty ? "Union Square" : passenger.assignedStopName
            )
        }

        return DriverHistoryTripRecord(
            tripDate: Date(),
            sessionType: sessionLabel == "Morning" ? .morning : .evening,
            completionStatus: .autoCompleted,
            scheduledStartTime: stopArrivalTimeLabels.first ?? "--:--",
            actualEndTime: timeFormatter.string(from: Date()),
            stopsTimeline: stopsTimeline,
            passengerPickupList: passengerPickupList,
            performanceSummary: DriverTripPerformanceSummary(
                totalStopCount: allSimulationStops.count,
                completedStopCount: allSimulationStops.count,
                totalPassengersPickedUp: enrolledPassengers.count,
                tripDurationInMinutes: max(Int(simulationTotalDurationSeconds / 60), 1)
            )
        )
    }

    var simulationProgressFraction: Double { min(elapsedSimulationSeconds / simulationTotalDurationSeconds, 1.0) }

    var elapsedTimeDisplayLabel: String {
        String(format: "%02d:%02d", Int(elapsedSimulationSeconds) / 60, Int(elapsedSimulationSeconds) % 60)
    }

    var totalDurationDisplayLabel: String {
        String(format: "%02d:%02d", Int(simulationTotalDurationSeconds) / 60, Int(simulationTotalDurationSeconds) % 60)
    }

    var currentActiveStopName: String { allSimulationStops[safe: currentActiveStopIndex]?.stopDisplayName ?? "—" }

    var currentLegInstruction: String { allSimulationStops[safe: currentActiveStopIndex]?.textualInstructionToNextStop ?? "" }

    private func formattedCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: Date())
    }
}

// Extracts CLLocationCoordinate2D array from an MKPolyline
extension MKPolyline {
    func extractCoordinates() -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

// Safe subscript used throughout the VM to avoid index out-of-bounds crashes
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
