// StaffLanka Go — Created by Liviru Navaratna

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
    var activeDays: [String]

    enum CodingKeys: String, CodingKey {
        case scheduledDepartureTime = "departureTime"
        case activeDays             = "days"
    }
}

struct RouteRecord: Codable, Identifiable {
    @DocumentID var id: String?
    var ownerDriverId: String
    var startLocation: RouteLocationData
    var endLocation: RouteLocationData
    var routeStops: [RouteStopData]
    var scheduleEntries: [RouteScheduleData]
    var pricePerTrip: Double
    var routeCreatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerDriverId  = "driverId"
        case startLocation
        case endLocation
        case routeStops     = "stops"
        case scheduleEntries = "schedule"
        case pricePerTrip
        case routeCreatedAt = "createdAt"
    }
}
