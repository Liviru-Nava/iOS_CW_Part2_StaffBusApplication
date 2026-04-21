//
//  DriverBusInfo.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-12.
//


import Foundation
import FirebaseFirestore

struct DriverBusInfo: Codable {
    var plateNumber: String
    var busName: String
    var busType: String
    var passengerCapacity: Int
}

struct DriverRecord: Codable, Identifiable {
    @DocumentID var id: String?
    var fullName: String
    var licenseNumber: String
    var busInformation: DriverBusInfo
    var assignedRouteId: String
    var driverCreatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case fullName          = "fullName"
        case licenseNumber     = "licenseNumber"
        case busInformation    = "bus"
        case assignedRouteId   = "routeId"
        case driverCreatedAt   = "createdAt"
    }
}
