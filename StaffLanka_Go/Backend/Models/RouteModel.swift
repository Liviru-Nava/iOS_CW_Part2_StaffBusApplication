//
//  RouteLocationData.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-12.
//


import Foundation
import FirebaseFirestore

struct RouteLocationData: Codable {
    var locationName: String
    var latitude: Double
    var longitude: Double

    enum CodingKeys: String, CodingKey {
        case locationName = "name"
        case latitude
        case longitude
    }
}

struct RouteStopData: Codable {
    var stopName: String
    var latitude: Double
    var longitude: Double
    var stopOrder: Int

    enum CodingKeys: String, CodingKey {
        case stopName  = "name"
        case latitude
        case longitude
        case stopOrder = "order"
    }
}

struct RouteScheduleData: Codable {
    var scheduledDepartureTime: Date
    var scheduledArrivalTime: Date?
    var activeDays: [String]

    enum CodingKeys: String, CodingKey {
        case scheduledDepartureTime = "departureTime"
        case scheduledArrivalTime   = "arrivalTime"
        case activeDays             = "days"
    }
}

struct RouteModel: Codable, Identifiable {
    @DocumentID var id: String?
    var ownerDriverId: String
    var startLocation: RouteLocationData
    var endLocation: RouteLocationData
    var routeStops: [RouteStopData]
    var scheduleEntries: [RouteScheduleData]
    var morningPrice: Double?
    var eveningPrice: Double?
    var bothTripsPrice: Double?
    var pricePerTrip: Double?
    var routeCreatedAt: Date

    enum CodingKeys: String, CodingKey {
        case ownerDriverId  = "driverId"
        case startLocation  = "startingLocation"
        case endLocation    = "endingLocation"
        case routeStops     = "stops"
        case scheduleEntries = "schedule"
        case morningPrice   = "morningPrice"
        case eveningPrice   = "eveningPrice"
        case bothTripsPrice = "bothTripsPrice"
        case pricePerTrip   = "pricePerTrip"
        case routeCreatedAt = "createdAt"
    }
}
