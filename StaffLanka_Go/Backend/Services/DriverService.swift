//
//  DriverService.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-12.
//


import Foundation
import FirebaseFirestore

final class DriverService {

    static let shared = DriverService()
    private init() {}

    private let firestoreDatabase = Firestore.firestore()
    private let driversCollectionPath = "drivers"

    func createDriver(driverRecord: DriverRecord) async throws {
        guard let driverUserId = driverRecord.id else {
            throw DriverServiceError.missingDriverId
        }

        let driverDocumentReference = firestoreDatabase
            .collection(driversCollectionPath)
            .document(driverUserId)

        try driverDocumentReference.setData(from: driverRecord)
    }
}

enum DriverServiceError: LocalizedError {
    case missingDriverId

    var errorDescription: String? {
        switch self {
        case .missingDriverId:
            return "Driver record is missing a valid user ID."
        }
    }
}
