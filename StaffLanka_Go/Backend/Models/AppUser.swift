//
//  AppUser.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-12.
//


import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var phoneNumber: String
    var fullName: String
    var emailAddress: String?
    var userRole: String
    var accountCreatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case phoneNumber      = "phone"
        case fullName         = "name"
        case emailAddress     = "email"
        case userRole         = "role"
        case accountCreatedAt = "createdAt"
    }
}
