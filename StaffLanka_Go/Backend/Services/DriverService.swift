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

    func createDriver(driverRecord: DriverModel) async throws {
        guard let driverUserId = driverRecord.id else {
            throw DriverServiceError.missingDriverId
        }

        let driverDocumentReference = firestoreDatabase
            .collection(driversCollectionPath)
            .document(driverUserId)

        try driverDocumentReference.setData(from: driverRecord)
    }

    func fetchDriver(driverId: String) async throws -> DriverModel {
        let driverDocumentReference = firestoreDatabase
            .collection(driversCollectionPath)
            .document(driverId)

        let snapshot = try await driverDocumentReference.getDocument()
        guard snapshot.exists else {
            throw DriverServiceError.driverNotFound
        }

        return try snapshot.data(as: DriverModel.self)
    }

    func updateDriver(driverId: String, updatedRecord: DriverModel) async throws {
        let driverDocumentReference = firestoreDatabase
            .collection(driversCollectionPath)
            .document(driverId)

        try driverDocumentReference.setData(from: updatedRecord, merge: true)
    }
}

enum DriverServiceError: LocalizedError {
    case missingDriverId
    case driverNotFound

    var errorDescription: String? {
        switch self {
        case .missingDriverId:
            return "Driver record is missing a valid user ID."
        case .driverNotFound:
            return "Driver record not found."
        }
    }
}
