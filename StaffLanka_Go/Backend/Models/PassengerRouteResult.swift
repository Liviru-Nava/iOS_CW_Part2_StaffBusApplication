//
//  PassengerRouteResult.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-05.
//

import Foundation
import CoreLocation


struct PassengerRouteResult: Identifiable {
    let id: String                       // Firestore route document ID
    let driverId: String
    let driverName: String
    let plateNumber: String
    let busName: String
    let busType: String
    let capacity: Int
    let isAcceptingRequests: Bool
    let origin: String                   // startingLocation.name
    let destination: String              // endingLocation.name
    let stops: [PassengerStop]           // ordered intermediate stops with coordinates
    let morningDeparture: Date
    let morningArrival: Date
    let eveningDeparture: Date
    let eveningArrival: Date
    let activeDays: [String]
    let morningPrice: Double
    let eveningPrice: Double
    let bothTripsPrice: Double
    let profilePhotoBase64: String?

    var routeName: String { "\(origin) → \(destination)" }

    var morningScheduleLabel: String {
        "\(PassengerRouteResult.timeString(from: morningDeparture)) – \(PassengerRouteResult.timeString(from: morningArrival))"
    }

    var eveningScheduleLabel: String {
        "\(PassengerRouteResult.timeString(from: eveningDeparture)) – \(PassengerRouteResult.timeString(from: eveningArrival))"
    }

    static func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

struct PassengerStop: Identifiable {
    let id: String          // stop name used as stable identifier
    let name: String
    let coordinate: CLLocationCoordinate2D
}

extension PassengerRouteResult {

    static func build(from route: RouteModel, driver: DriverModel) -> PassengerRouteResult? {
        guard let routeId = route.id else {
            print(" [PassengerRouteResult] build() — route missing document ID, skipping")
            return nil
        }
        guard route.scheduleEntries.count >= 2 else {
            print(" [PassengerRouteResult] build() — route \(routeId) has \(route.scheduleEntries.count) schedule entry(ies), need ≥ 2")
            return nil
        }

        let morningEntry = route.scheduleEntries[0]
        let eveningEntry = route.scheduleEntries[1]

        print(" [PassengerRouteResult] build() — route \(routeId) | driver: \(driver.fullName)")
        print("   Morning: dep=\(morningEntry.scheduledDepartureTime) arr=\(String(describing: morningEntry.scheduledArrivalTime))")
        print("   Evening: dep=\(eveningEntry.scheduledDepartureTime) arr=\(String(describing: eveningEntry.scheduledArrivalTime))")
        print("   Prices: morning=\(String(describing: route.morningPrice)) evening=\(String(describing: route.eveningPrice)) both=\(String(describing: route.bothTripsPrice))")
        print("   Intermediate stops: \(route.routeStops.count)")

        let allStops = buildStops(from: route, routeId: routeId)

        return PassengerRouteResult(
            id: routeId,
            driverId: driver.id ?? route.ownerDriverId,
            driverName: driver.fullName,
            plateNumber: driver.busInformation.plateNumber,
            busName: driver.busInformation.busName,
            busType: driver.busInformation.busType,
            capacity: driver.busInformation.passengerCapacity,
            isAcceptingRequests: driver.isAcceptingRequests ?? true,
            origin: route.startLocation.locationName,
            destination: route.endLocation.locationName,
            stops: allStops,
            morningDeparture: morningEntry.scheduledDepartureTime,
            morningArrival: morningEntry.scheduledArrivalTime ?? morningEntry.scheduledDepartureTime,
            eveningDeparture: eveningEntry.scheduledDepartureTime,
            eveningArrival: eveningEntry.scheduledArrivalTime ?? eveningEntry.scheduledDepartureTime,
            activeDays: morningEntry.activeDays,
            morningPrice: route.morningPrice ?? 0,
            eveningPrice: route.eveningPrice ?? 0,
            bothTripsPrice: route.bothTripsPrice ?? 0,
            profilePhotoBase64: driver.profilePhotoBase64
        )
    }

    static func buildPartial(from route: RouteModel) -> PassengerRouteResult? {
        guard let routeId = route.id else {
            print(" [PassengerRouteResult] buildPartial() — route missing document ID")
            return nil
        }
        guard route.scheduleEntries.count >= 2 else {
            print(" [PassengerRouteResult] buildPartial() — route \(routeId) has insufficient schedule entries")
            return nil
        }

        print("[PassengerRouteResult] buildPartial() — building from route data only (driver doc unreadable) | route \(routeId)")

        let morningEntry = route.scheduleEntries[0]
        let eveningEntry = route.scheduleEntries[1]
        let allStops = buildStops(from: route, routeId: routeId)

        return PassengerRouteResult(
            id: routeId,
            driverId: route.ownerDriverId,
            driverName: "Driver",               // placeholder — fix Firestore rules to populate
            plateNumber: "—",                   // placeholder
            busName: "Staff Bus",               // placeholder
            busType: "Bus",                     // placeholder
            capacity: 0,                        // placeholder
            isAcceptingRequests: true,
            origin: route.startLocation.locationName,
            destination: route.endLocation.locationName,
            stops: allStops,
            morningDeparture: morningEntry.scheduledDepartureTime,
            morningArrival: morningEntry.scheduledArrivalTime ?? morningEntry.scheduledDepartureTime,
            eveningDeparture: eveningEntry.scheduledDepartureTime,
            eveningArrival: eveningEntry.scheduledArrivalTime ?? eveningEntry.scheduledDepartureTime,
            activeDays: morningEntry.activeDays,
            morningPrice: route.morningPrice ?? 0,
            eveningPrice: route.eveningPrice ?? 0,
            bothTripsPrice: route.bothTripsPrice ?? 0,
            profilePhotoBase64: nil
        )
    }

    // Shared stop builder

    private static func buildStops(from route: RouteModel, routeId: String) -> [PassengerStop] {
        let startStop = PassengerStop(
            id: "start_\(routeId)",
            name: route.startLocation.locationName,
            coordinate: CLLocationCoordinate2D(
                latitude: route.startLocation.latitude,
                longitude: route.startLocation.longitude
            )
        )
        let intermediateStops: [PassengerStop] = route.routeStops
            .sorted { $0.stopOrder < $1.stopOrder }
            .map { stop in
                PassengerStop(
                    id: "stop_\(stop.stopOrder)_\(routeId)",
                    name: stop.stopName,
                    coordinate: CLLocationCoordinate2D(
                        latitude: stop.latitude,
                        longitude: stop.longitude
                    )
                )
            }
        let endStop = PassengerStop(
            id: "end_\(routeId)",
            name: route.endLocation.locationName,
            coordinate: CLLocationCoordinate2D(
                latitude: route.endLocation.latitude,
                longitude: route.endLocation.longitude
            )
        )
        return [startStop] + intermediateStops + [endStop]
    }
}
