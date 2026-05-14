//
//  DataModelTests.swift
//  StaffLanka_GoTests
//
//  Created by Liviru Navaratna on 2026-05-14.
//

import XCTest
import CoreLocation
@testable import StaffLanka_Go

final class DataModelTests: XCTestCase {

    //  RouteLocationData

    // Verifies that RouteLocationData stores its properties without mutation.
    func testRouteLocationData_StoresPropertiesCorrectly() {
        var routeLocationDataInstance = RouteLocationData(
            locationName: "Colombo Fort",
            latitude: 6.9344,
            longitude: 79.8428
        )

        XCTAssertEqual(routeLocationDataInstance.locationName, "Colombo Fort")
        XCTAssertEqual(routeLocationDataInstance.latitude, 6.9344, accuracy: 0.0001)
        XCTAssertEqual(routeLocationDataInstance.longitude, 79.8428, accuracy: 0.0001)
    }

    //  RouteStopData

    // Verifies that RouteStopData retains the stop order index correctly.
    func testRouteStopData_RetainsStopOrderIndex() {
        var routeStopDataInstance = RouteStopData(
            stopName: "Nugegoda",
            latitude: 6.8716,
            longitude: 79.8876,
            stopOrder: 3
        )

        XCTAssertEqual(routeStopDataInstance.stopOrder, 3)
        XCTAssertEqual(routeStopDataInstance.stopName, "Nugegoda")
    }

    //  RouteModel

    // Verifies that a RouteModel constructed with all required fields can be
    // read back without data loss.
    func testRouteModel_ConstructedWithAllFields_RetainsValues() throws {
        let startLocationData = RouteLocationData(locationName: "Kandy", latitude: 7.2906, longitude: 80.6337)
        let endLocationData = RouteLocationData(locationName: "Colombo", latitude: 6.9271, longitude: 79.8612)
        let stopEntry = RouteStopData(stopName: "Kadugannawa", latitude: 7.2500, longitude: 80.5200, stopOrder: 1)
        let knownCreationDate = Date(timeIntervalSince1970: 1_700_000_000)

        var routeModelInstance = RouteModel(
            ownerDriverId: "driver_abc_123",
            startLocation: startLocationData,
            endLocation: endLocationData,
            routeStops: [stopEntry],
            scheduleEntries: [],
            morningPrice: 150.0,
            eveningPrice: 150.0,
            bothTripsPrice: 280.0,
            pricePerTrip: nil,
            routeCreatedAt: knownCreationDate,
            startName: "Kandy",
            endName: "Colombo"
        )

        XCTAssertEqual(routeModelInstance.ownerDriverId, "driver_abc_123")
        XCTAssertEqual(routeModelInstance.startLocation.locationName, "Kandy")
        XCTAssertEqual(routeModelInstance.endLocation.locationName, "Colombo")
        XCTAssertEqual(routeModelInstance.routeStops.count, 1)
        let unwrappedMorningPrice = try XCTUnwrap(routeModelInstance.morningPrice)
        let unwrappedBothTripsPrice = try XCTUnwrap(routeModelInstance.bothTripsPrice)
        XCTAssertEqual(unwrappedMorningPrice, 150.0, accuracy: 0.01)
        XCTAssertEqual(unwrappedBothTripsPrice, 280.0, accuracy: 0.01)
        XCTAssertNil(routeModelInstance.pricePerTrip)
        XCTAssertEqual(routeModelInstance.routeCreatedAt, knownCreationDate)
    }

    // Verifies that the optional fields on RouteModel default to nil when omitted.
    func testRouteModel_OptionalPriceFields_DefaultToNilWhenNotProvided() {
        let startLocationData = RouteLocationData(locationName: "Galle", latitude: 6.0535, longitude: 80.2210)
        let endLocationData = RouteLocationData(locationName: "Matara", latitude: 5.9549, longitude: 80.5550)

        var routeModelInstance = RouteModel(
            ownerDriverId: "driver_xyz_456",
            startLocation: startLocationData,
            endLocation: endLocationData,
            routeStops: [],
            scheduleEntries: [],
            morningPrice: nil,
            eveningPrice: nil,
            bothTripsPrice: nil,
            pricePerTrip: nil,
            routeCreatedAt: Date(),
            startName: nil,
            endName: nil
        )

        XCTAssertNil(routeModelInstance.morningPrice)
        XCTAssertNil(routeModelInstance.eveningPrice)
        XCTAssertNil(routeModelInstance.bothTripsPrice)
        XCTAssertNil(routeModelInstance.startName)
        XCTAssertNil(routeModelInstance.endName)
    }

    //  TripModel

    // Verifies that driverCoordinate returns nil when latitude and longitude are both nil.
    func testTripModel_DriverCoordinate_ReturnsNilWhenLocationIsAbsent() {
        let tripModelInstance = TripModel(
            routeId: "route_001",
            driverId: "driver_001",
            session: "Morning",
            tripDate: Date(),
            status: "active",
            startedAt: Date(),
            endedAt: nil,
            driverLatitude: nil,
            driverLongitude: nil,
            locationUpdatedAt: nil,
            currentStopIndex: nil
        )

        XCTAssertNil(
            tripModelInstance.driverCoordinate,
            "Expected driverCoordinate to be nil when latitude and longitude are both absent."
        )
    }

    // Verifies that driverCoordinate returns a valid coordinate when both values are set.
    func testTripModel_DriverCoordinate_ReturnsCLLocationCoordinate2DWhenBothValuesPresent() {
        let expectedLatitudeValue = 6.9271
        let expectedLongitudeValue = 79.8612

        let tripModelInstance = TripModel(
            routeId: "route_002",
            driverId: "driver_002",
            session: "Evening",
            tripDate: Date(),
            status: "active",
            startedAt: Date(),
            endedAt: nil,
            driverLatitude: expectedLatitudeValue,
            driverLongitude: expectedLongitudeValue,
            locationUpdatedAt: nil,
            currentStopIndex: nil
        )

        XCTAssertNotNil(
            tripModelInstance.driverCoordinate,
            "Expected driverCoordinate to return a value when latitude and longitude are both set."
        )
        XCTAssertEqual(
            tripModelInstance.driverCoordinate?.latitude ?? 0.0,
            expectedLatitudeValue,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            tripModelInstance.driverCoordinate?.longitude ?? 0.0,
            expectedLongitudeValue,
            accuracy: 0.0001
        )
    }

    // Verifies that driverCoordinate returns nil when only latitude is present.
    func testTripModel_DriverCoordinate_ReturnsNilWhenOnlyLatitudeIsSet() {
        let tripModelInstance = TripModel(
            routeId: "route_003",
            driverId: "driver_003",
            session: "Morning",
            tripDate: Date(),
            status: "active",
            startedAt: Date(),
            endedAt: nil,
            driverLatitude: 6.9271,
            driverLongitude: nil,
            locationUpdatedAt: nil,
            currentStopIndex: nil
        )

        XCTAssertNil(
            tripModelInstance.driverCoordinate,
            "Expected driverCoordinate to be nil when longitude is absent."
        )
    }

    //  UserModel

    // Verifies that a UserModel stores all fields including the optional email.
    func testUserModel_StoresAllFieldsIncludingOptionalEmail() {
        let userCreationDate = Date(timeIntervalSince1970: 1_680_000_000)

        let userModelInstance = UserModel(
            phoneNumber: "+94711234567",
            fullName: "Kasun Perera",
            emailAddress: "kasun@example.com",
            userRole: "passenger",
            accountCreatedAt: userCreationDate
        )

        XCTAssertEqual(userModelInstance.phoneNumber, "+94711234567")
        XCTAssertEqual(userModelInstance.fullName, "Kasun Perera")
        XCTAssertEqual(userModelInstance.emailAddress, "kasun@example.com")
        XCTAssertEqual(userModelInstance.userRole, "passenger")
        XCTAssertEqual(userModelInstance.accountCreatedAt, userCreationDate)
    }

    // Verifies that email is nil when omitted from UserModel.
    func testUserModel_EmailAddress_IsNilWhenNotProvided() {
        let userModelInstance = UserModel(
            phoneNumber: "+94721234567",
            fullName: "Nimali Silva",
            emailAddress: nil,
            userRole: "driver",
            accountCreatedAt: Date()
        )

        XCTAssertNil(
            userModelInstance.emailAddress,
            "Expected emailAddress to be nil when it is not provided."
        )
    }

    //  JoinRequestModel

    // Verifies that JoinRequestModel stores all required and optional fields.
    func testJoinRequestModel_StoresAllRequiredAndOptionalFields() {
        let joinRequestCreationDate = Date(timeIntervalSince1970: 1_700_000_100)

        let joinRequestModelInstance = JoinRequestModel(
            routeId: "route_aaa",
            driverId: "driver_bbb",
            passengerId: "passenger_ccc",
            passengerName: "Amal Fernando",
            passengerPhone: "+94761234567",
            pickupStop: "Maharagama",
            dropoffStop: "Colombo Fort",
            session: "Both",
            note: "Please wait at the junction",
            status: "pending",
            createdAt: joinRequestCreationDate,
            cancelledSession: nil,
            cancelledBy: nil
        )

        XCTAssertEqual(joinRequestModelInstance.routeId, "route_aaa")
        XCTAssertEqual(joinRequestModelInstance.passengerId, "passenger_ccc")
        XCTAssertEqual(joinRequestModelInstance.session, "Both")
        XCTAssertEqual(joinRequestModelInstance.status, "pending")
        XCTAssertNil(joinRequestModelInstance.cancelledSession)
        XCTAssertNil(joinRequestModelInstance.cancelledBy)
    }

    // Verifies that cancelledSession and cancelledBy can hold values after a cancellation.
    func testJoinRequestModel_CancellationFields_StoreValuesCorrectly() {
        var joinRequestModelInstance = JoinRequestModel(
            routeId: "route_ddd",
            driverId: "driver_eee",
            passengerId: "passenger_fff",
            passengerName: "Priya Jayawardena",
            passengerPhone: "+94751234567",
            pickupStop: "Nugegoda",
            dropoffStop: "Pettah",
            session: "Both",
            note: "",
            status: "cancelled",
            createdAt: Date(),
            cancelledSession: "Morning",
            cancelledBy: "passenger"
        )

        XCTAssertEqual(joinRequestModelInstance.cancelledSession, "Morning")
        XCTAssertEqual(joinRequestModelInstance.cancelledBy, "passenger")
    }

    //  AttendanceModel

    // Verifies that AttendanceModel correctly stores the status and session values.
    func testAttendanceModel_StoresStatusAndSessionCorrectly() {
        let attendanceMarkedDate = Date(timeIntervalSince1970: 1_700_010_000)
        let attendanceTripDate = Date(timeIntervalSince1970: 1_699_920_000)

        let attendanceModelInstance = AttendanceModel(
            passengerId: "passenger_ggg",
            routeId: "route_hhh",
            requestId: "request_iii",
            session: "Morning",
            tripDate: attendanceTripDate,
            status: "attending",
            markedAt: attendanceMarkedDate,
            updatedAt: attendanceMarkedDate
        )

        XCTAssertEqual(attendanceModelInstance.passengerId, "passenger_ggg")
        XCTAssertEqual(attendanceModelInstance.session, "Morning")
        XCTAssertEqual(attendanceModelInstance.status, "attending")
        XCTAssertEqual(attendanceModelInstance.tripDate, attendanceTripDate)
    }

    //  PassengerRouteResult

    // Verifies that routeName computes the correct formatted origin-to-destination string.
    func testPassengerRouteResult_RouteName_FormatsOriginAndDestinationCorrectly() {
        let morningDepartureDate = Date(timeIntervalSince1970: 1_700_000_000)
        let morningArrivalDate = Date(timeIntervalSince1970: 1_700_003_600)
        let eveningDepartureDate = Date(timeIntervalSince1970: 1_700_050_000)
        let eveningArrivalDate = Date(timeIntervalSince1970: 1_700_053_600)

        let passengerRouteResultInstance = PassengerRouteResult(
            id: "result_001",
            driverId: "driver_jjj",
            driverName: "Ruwan Bandara",
            plateNumber: "WP CAA 1234",
            busName: "Sri Lanka Travels",
            busType: "Mini Bus",
            capacity: 25,
            isAcceptingRequests: true,
            origin: "Kandy",
            destination: "Colombo",
            stops: [],
            morningDeparture: morningDepartureDate,
            morningArrival: morningArrivalDate,
            eveningDeparture: eveningDepartureDate,
            eveningArrival: eveningArrivalDate,
            activeDays: ["Monday", "Tuesday", "Wednesday"],
            morningPrice: 200.0,
            eveningPrice: 200.0,
            bothTripsPrice: 380.0,
            profilePhotoBase64: nil
        )

        XCTAssertEqual(
            passengerRouteResultInstance.routeName,
            "Kandy → Colombo",
            "Expected routeName to combine origin and destination with an arrow separator."
        )
    }

    // Verifies that PassengerStop uses the name as its stable identifier.
    func testPassengerStop_UsesNameAsIdentifier() {
        let passengerStopInstance = PassengerStop(
            id: "Nugegoda",
            name: "Nugegoda",
            coordinate: CLLocationCoordinate2D(latitude: 6.8716, longitude: 79.8876)
        )

        XCTAssertEqual(
            passengerStopInstance.id,
            "Nugegoda",
            "Expected the PassengerStop id to match the stop name."
        )
        XCTAssertEqual(passengerStopInstance.name, "Nugegoda")
    }

    //  DriverModel

    // Verifies that DriverModel stores bus information nested within the struct.
    func testDriverModel_StoresBusInformationCorrectly() {
        let driverBusInfoInstance = DriverBusInfo(
            plateNumber: "WP CAB 5678",
            busName: "Highland Express",
            busType: "Coach",
            passengerCapacity: 40
        )

        let driverModelInstance = DriverModel(
            fullName: "Sunil Rathnayake",
            licenseNumber: "LK-2024-001234",
            busInformation: driverBusInfoInstance,
            assignedRouteId: "route_kkk",
            driverCreatedAt: Date(),
            serviceStatus: "active",
            isAcceptingRequests: true,
            profilePhotoBase64: nil
        )

        XCTAssertEqual(driverModelInstance.busInformation.plateNumber, "WP CAB 5678")
        XCTAssertEqual(driverModelInstance.busInformation.passengerCapacity, 40)
        XCTAssertEqual(driverModelInstance.fullName, "Sunil Rathnayake")
        XCTAssertTrue(driverModelInstance.isAcceptingRequests ?? false)
    }
}
