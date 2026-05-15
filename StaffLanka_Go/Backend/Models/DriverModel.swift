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
 
//collection name in firebase is "drivers"
struct DriverModel: Codable, Identifiable {
    @DocumentID var id: String?
    var fullName: String
    var licenseNumber: String
    var busInformation: DriverBusInfo
    var assignedRouteId: String
    var driverCreatedAt: Date
    var serviceStatus: String?
    var isAcceptingRequests: Bool?
    // Stores the driver profile photo as a Base64 encoded string inside Firestore
    var profilePhotoBase64: String?
 
    enum CodingKeys: String, CodingKey {
        case fullName              = "fullName"
        case licenseNumber         = "licenseNumber"
        case busInformation        = "bus"
        case assignedRouteId       = "routeId"
        case driverCreatedAt       = "createdAt"
        case serviceStatus         = "serviceStatus"
        case isAcceptingRequests   = "isAcceptingRequests"
        case profilePhotoBase64    = "profilePhotoBase64"
    }
}
