// PassengerRouteResultTests.swift
// StaffLanka_GoTests

import XCTest
import CoreLocation
@testable import StaffLanka_Go

final class PassengerRouteResultTests: XCTestCase {

    // Verifies that timeString formats a Date into a 12-hour hh:mm a string
    // using the en_US_POSIX locale so the output is always predictable.
    func testTimeString_ForMidnightDate_ReturnsTwelveAmLabel() {
        var calendarForTest = Calendar(identifier: .gregorian)
        calendarForTest.timeZone = TimeZone(identifier: "Asia/Colombo")!
        var dateComponentsForMidnight = DateComponents()
        dateComponentsForMidnight.year = 2026
        dateComponentsForMidnight.month = 1
        dateComponentsForMidnight.day = 1
        dateComponentsForMidnight.hour = 0
        dateComponentsForMidnight.minute = 0

        let midnightDateValue = calendarForTest.date(from: dateComponentsForMidnight)!
        let resultTimeLabel = PassengerRouteResult.timeString(from: midnightDateValue)

        XCTAssertEqual(
            resultTimeLabel,
            "12:00 AM",
            "Expected timeString to format midnight as 12:00 AM."
        )
    }

    // Verifies that timeString correctly formats noon as 12:00 PM.
    func testTimeString_ForNoonDate_ReturnsTwelvePmLabel() {
        var calendarForTest = Calendar(identifier: .gregorian)
        calendarForTest.timeZone = TimeZone(identifier: "Asia/Colombo")!
        var dateComponentsForNoon = DateComponents()
        dateComponentsForNoon.year = 2026
        dateComponentsForNoon.month = 6
        dateComponentsForNoon.day = 15
        dateComponentsForNoon.hour = 12
        dateComponentsForNoon.minute = 0

        let noonDateValue = calendarForTest.date(from: dateComponentsForNoon)!
        let resultTimeLabel = PassengerRouteResult.timeString(from: noonDateValue)

        XCTAssertEqual(
            resultTimeLabel,
            "12:00 PM",
            "Expected timeString to format noon as 12:00 PM."
        )
    }

    // Verifies that morningScheduleLabel combines departure and arrival strings
    // separated by an en-dash and spaces.
    func testMorningScheduleLabel_CombinesDepartureAndArrivalWithDash() {
        var calendarForTest = Calendar(identifier: .gregorian)
        calendarForTest.timeZone = TimeZone(identifier: "Asia/Colombo")!

        var morningDepartureComponents = DateComponents()
        morningDepartureComponents.year = 2026
        morningDepartureComponents.month = 3
        morningDepartureComponents.day = 10
        morningDepartureComponents.hour = 6
        morningDepartureComponents.minute = 30
        let morningDepartureDateValue = calendarForTest.date(from: morningDepartureComponents)!

        var morningArrivalComponents = DateComponents()
        morningArrivalComponents.year = 2026
        morningArrivalComponents.month = 3
        morningArrivalComponents.day = 10
        morningArrivalComponents.hour = 8
        morningArrivalComponents.minute = 0
        let morningArrivalDateValue = calendarForTest.date(from: morningArrivalComponents)!

        let passengerRouteResultInstance = PassengerRouteResult(
            id: "result_schedule_test",
            driverId: "driver_sch_001",
            driverName: "Test Driver",
            plateNumber: "WP TST 0001",
            busName: "Test Bus",
            busType: "Mini",
            capacity: 20,
            isAcceptingRequests: true,
            origin: "Kandy",
            destination: "Colombo",
            stops: [],
            morningDeparture: morningDepartureDateValue,
            morningArrival: morningArrivalDateValue,
            eveningDeparture: morningDepartureDateValue,
            eveningArrival: morningArrivalDateValue,
            activeDays: ["Monday"],
            morningPrice: 100.0,
            eveningPrice: 100.0,
            bothTripsPrice: 190.0,
            profilePhotoBase64: nil
        )

        let morningScheduleLabelValue = passengerRouteResultInstance.morningScheduleLabel

        XCTAssertTrue(
            morningScheduleLabelValue.contains("06:30 AM"),
            "Expected morningScheduleLabel to contain the departure time 06:30 AM."
        )
        XCTAssertTrue(
            morningScheduleLabelValue.contains("08:00 AM"),
            "Expected morningScheduleLabel to contain the arrival time 08:00 AM."
        )
        XCTAssertTrue(
            morningScheduleLabelValue.contains("–"),
            "Expected morningScheduleLabel to separate times with an en-dash."
        )
    }

    // Verifies that a route with no intermediate stops has an empty stops array.
    func testPassengerRouteResult_WithNoIntermediateStops_HasEmptyStopsArray() {
        let passengerRouteResultInstance = PassengerRouteResult(
            id: "result_no_stops",
            driverId: "driver_nst_001",
            driverName: "No Stops Driver",
            plateNumber: "WP NST 0000",
            busName: "Direct Express",
            busType: "Coach",
            capacity: 30,
            isAcceptingRequests: false,
            origin: "Colombo",
            destination: "Galle",
            stops: [],
            morningDeparture: Date(),
            morningArrival: Date(),
            eveningDeparture: Date(),
            eveningArrival: Date(),
            activeDays: [],
            morningPrice: 300.0,
            eveningPrice: 300.0,
            bothTripsPrice: 560.0,
            profilePhotoBase64: nil
        )

        XCTAssertTrue(
            passengerRouteResultInstance.stops.isEmpty,
            "Expected the stops array to be empty when no intermediate stops are provided."
        )
        XCTAssertFalse(
            passengerRouteResultInstance.isAcceptingRequests,
            "Expected isAcceptingRequests to be false when set to false."
        )
    }
}
