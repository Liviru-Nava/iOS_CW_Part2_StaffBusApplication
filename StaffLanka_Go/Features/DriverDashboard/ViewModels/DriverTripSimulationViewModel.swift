//
//  DriverTripSimulationViewModel.swift
//  StaffLanka_Go
//

import Foundation
import MapKit
import Combine
import FirebaseAuth

// One physical stop along the simulated SF route
struct SimulationRouteStop: Identifiable {
    let id = UUID()
    let stopDisplayName: String
    let coordinate: CLLocationCoordinate2D
    let textualInstructionToNextStop: String
}

// Per-stop row shown in the floating passenger panel
struct SimulationPassengerStopRow: Identifiable {
    let id = UUID()
    let stopDisplayName: String
    let totalPassengersAtStop: Int
    let attendingPassengersCount: Int
    let unsurePassengersCount: Int
    let estimatedArrivalTimeLabel: String
    var hasBeenVisited: Bool
}

// Lightweight passenger record used during simulation
struct SimulationEnrolledPassenger: Identifiable {
    let id: String
    let fullName: String
    let assignedStopName: String
    let attendanceStatusLabel: String   // "attending" | "absent" | "not marked"
}

@MainActor
final class DriverTripSimulationViewModel: ObservableObject {

    // Configurable total simulation duration in seconds
    let simulationTotalDurationSeconds: Double = 90

    // How frequently the bus coordinate updates (smaller = smoother)
    private let coordinateUpdateIntervalSeconds: Double = 0.4

    @Published var currentBusCoordinate: CLLocationCoordinate2D
    @Published var currentActiveStopIndex: Int = 0
    @Published var elapsedSimulationSeconds: Double = 0
    @Published var passengerStopRows: [SimulationPassengerStopRow] = []
    @Published var isInstructionsPanelVisible: Bool = false
    @Published var isSimulationComplete: Bool = false
    @Published var isFloatingPanelExpanded: Bool = true
    @Published var completedTripRecord: DriverHistoryTripRecord? = nil

    // San Francisco simulation stops — each must be visited before the final destination
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
            textualInstructionToNextStop: "Continue south on Church St, then merge onto Diamond St heading toward Bosworth St"
        ),
        SimulationRouteStop(
            stopDisplayName: "Glen Park",
            coordinate: CLLocationCoordinate2D(latitude: 37.7330, longitude: -122.4337),
            textualInstructionToNextStop: ""
        )
    ]

    private var simulationTimer: Timer?
    private var firestoreTripId: String?
    private var sessionLabel: String = "Morning"
    private var enrolledPassengers: [SimulationEnrolledPassenger] = []
    private var stopArrivalTimeLabels: [String] = []

    init() {
        currentBusCoordinate = allSimulationStops.first?.coordinate ?? CLLocationCoordinate2D(latitude: 37.7879, longitude: -122.4075)
    }

    deinit {
        simulationTimer?.invalidate()
    }

    // Begins the simulation, creates a Firestore trip document
    func startSimulation(routeId: String, driverId: String, session: String, passengers: [SimulationEnrolledPassenger]) {
        sessionLabel = session
        enrolledPassengers = passengers
        currentActiveStopIndex = 0
        elapsedSimulationSeconds = 0
        isSimulationComplete = false
        stopArrivalTimeLabels = Array(repeating: "--:--", count: allSimulationStops.count)
        stopArrivalTimeLabels[0] = formattedCurrentTime()

        buildInitialPassengerStopRows(passengers: passengers)

        Task {
            do {
                let tripId = try await TripService.shared.startTrip(routeId: routeId, driverId: driverId, session: session)
                self.firestoreTripId = tripId
                print("🟢 [SimulationVM] Trip started in Firestore, id: \(tripId)")
            } catch {
                print("🔴 [SimulationVM] Firestore startTrip error: \(error.localizedDescription)")
            }
        }

        simulationTimer = Timer.scheduledTimer(withTimeInterval: coordinateUpdateIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.advanceSimulation()
            }
        }
    }

    // Called every tick by the timer
    private func advanceSimulation() {
        elapsedSimulationSeconds += coordinateUpdateIntervalSeconds

        let overallProgress = min(elapsedSimulationSeconds / simulationTotalDurationSeconds, 1.0)
        let totalLegs = allSimulationStops.count - 1
        let legDurationSeconds = simulationTotalDurationSeconds / Double(totalLegs)
        let currentLegIndex = min(Int(elapsedSimulationSeconds / legDurationSeconds), totalLegs - 1)
        let progressWithinCurrentLeg = (elapsedSimulationSeconds - Double(currentLegIndex) * legDurationSeconds) / legDurationSeconds

        let legStartCoordinate = allSimulationStops[currentLegIndex].coordinate
        let legEndCoordinate = allSimulationStops[currentLegIndex + 1].coordinate

        currentBusCoordinate = CLLocationCoordinate2D(
            latitude: legStartCoordinate.latitude + (legEndCoordinate.latitude - legStartCoordinate.latitude) * progressWithinCurrentLeg,
            longitude: legStartCoordinate.longitude + (legEndCoordinate.longitude - legStartCoordinate.longitude) * progressWithinCurrentLeg
        )

        // Detect arrival at a new stop (within first 10% of the leg = just arrived at start of leg)
        let newStopIndex = progressWithinCurrentLeg < 0.1 ? currentLegIndex : currentLegIndex
        if newStopIndex > currentActiveStopIndex || (currentLegIndex == totalLegs - 1 && progressWithinCurrentLeg >= 0.98) {
            markStopAsVisited(stopIndex: min(newStopIndex + 1, allSimulationStops.count - 1))
        }

        updateEstimatedArrivalTimesForFutureStops(overallProgress: overallProgress)

        if let tripId = firestoreTripId {
            Task {
                try? await TripService.shared.updateDriverLocation(tripId: tripId, location: currentBusCoordinate)
            }
        }

        if overallProgress >= 1.0 {
            completeSimulation()
        }
    }

    private func markStopAsVisited(stopIndex: Int) {
        guard stopIndex < allSimulationStops.count, stopIndex > currentActiveStopIndex else { return }
        currentActiveStopIndex = stopIndex
        stopArrivalTimeLabels[stopIndex] = formattedCurrentTime()

        for rowIndex in passengerStopRows.indices {
            if passengerStopRows[rowIndex].stopDisplayName == allSimulationStops[stopIndex].stopDisplayName {
                passengerStopRows[rowIndex].hasBeenVisited = true
                passengerStopRows[rowIndex] = SimulationPassengerStopRow(
                    stopDisplayName: passengerStopRows[rowIndex].stopDisplayName,
                    totalPassengersAtStop: passengerStopRows[rowIndex].totalPassengersAtStop,
                    attendingPassengersCount: passengerStopRows[rowIndex].attendingPassengersCount,
                    unsurePassengersCount: passengerStopRows[rowIndex].unsurePassengersCount,
                    estimatedArrivalTimeLabel: stopArrivalTimeLabels[stopIndex],
                    hasBeenVisited: true
                )
            }
        }
    }

    private func updateEstimatedArrivalTimesForFutureStops(overallProgress: Double) {
        let remainingSeconds = simulationTotalDurationSeconds * (1.0 - overallProgress)
        let totalLegs = allSimulationStops.count - 1
        let secondsPerLeg = simulationTotalDurationSeconds / Double(totalLegs)

        for stopIndex in (currentActiveStopIndex + 1)..<allSimulationStops.count {
            let secondsUntilThisStop = Double(stopIndex) * secondsPerLeg - elapsedSimulationSeconds
            let estimatedDate = Date().addingTimeInterval(max(secondsUntilThisStop, 0))
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "hh:mm a"
            stopArrivalTimeLabels[stopIndex] = timeFormatter.string(from: estimatedDate)
        }

        for rowIndex in passengerStopRows.indices {
            if let matchingStopIndex = allSimulationStops.firstIndex(where: { $0.stopDisplayName == passengerStopRows[rowIndex].stopDisplayName }) {
                if !passengerStopRows[rowIndex].hasBeenVisited {
                    passengerStopRows[rowIndex] = SimulationPassengerStopRow(
                        stopDisplayName: passengerStopRows[rowIndex].stopDisplayName,
                        totalPassengersAtStop: passengerStopRows[rowIndex].totalPassengersAtStop,
                        attendingPassengersCount: passengerStopRows[rowIndex].attendingPassengersCount,
                        unsurePassengersCount: passengerStopRows[rowIndex].unsurePassengersCount,
                        estimatedArrivalTimeLabel: stopArrivalTimeLabels[matchingStopIndex],
                        hasBeenVisited: false
                    )
                }
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

    // Distribute enrolled passengers across stops for the simulation display
    private func buildInitialPassengerStopRows(passengers: [SimulationEnrolledPassenger]) {
        var stopRowMap: [String: (attending: Int, unsure: Int)] = [:]
        for stop in allSimulationStops {
            stopRowMap[stop.stopDisplayName] = (attending: 0, unsure: 0)
        }

        // Spread passengers evenly across intermediate stops
        let intermediateStops = allSimulationStops.dropFirst().dropLast()
        for (passengerIndex, passenger) in passengers.enumerated() {
            let assignedStopName: String
            if !passenger.assignedStopName.isEmpty,
               allSimulationStops.contains(where: { $0.stopDisplayName == passenger.assignedStopName }) {
                assignedStopName = passenger.assignedStopName
            } else {
                assignedStopName = intermediateStops[passengerIndex % intermediateStops.count].stopDisplayName
            }

            if passenger.attendanceStatusLabel == "attending" {
                stopRowMap[assignedStopName]?.attending += 1
            } else {
                stopRowMap[assignedStopName]?.unsure += 1
            }
        }

        passengerStopRows = allSimulationStops.enumerated().map { stopIndex, stop in
            let counts = stopRowMap[stop.stopDisplayName] ?? (attending: 0, unsure: 0)
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

        let durationInMinutes = max(Int(simulationTotalDurationSeconds / 60), 1)

        let performanceSummary = DriverTripPerformanceSummary(
            totalStopCount: allSimulationStops.count,
            completedStopCount: allSimulationStops.count,
            totalPassengersPickedUp: enrolledPassengers.count,
            tripDurationInMinutes: durationInMinutes
        )

        return DriverHistoryTripRecord(
            tripDate: Date(),
            sessionType: sessionLabel == "Morning" ? .morning : .evening,
            completionStatus: .autoCompleted,
            scheduledStartTime: stopArrivalTimeLabels.first ?? "--:--",
            actualEndTime: timeFormatter.string(from: Date()),
            stopsTimeline: stopsTimeline,
            passengerPickupList: passengerPickupList,
            performanceSummary: performanceSummary
        )
    }

    var simulationProgressFraction: Double {
        min(elapsedSimulationSeconds / simulationTotalDurationSeconds, 1.0)
    }

    var elapsedTimeDisplayLabel: String {
        let minutes = Int(elapsedSimulationSeconds) / 60
        let seconds = Int(elapsedSimulationSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var totalDurationDisplayLabel: String {
        let minutes = Int(simulationTotalDurationSeconds) / 60
        let seconds = Int(simulationTotalDurationSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var currentActiveStopName: String {
        allSimulationStops[safe: currentActiveStopIndex]?.stopDisplayName ?? "—"
    }

    var currentLegInstruction: String {
        allSimulationStops[safe: currentActiveStopIndex]?.textualInstructionToNextStop ?? ""
    }

    private func formattedCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: Date())
    }
}

// Safe subscript to avoid out-of-bounds crashes
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
