//
//  RouteService.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-12.
//


import Foundation
import FirebaseFirestore

final class RouteService {

    static let shared = RouteService()
    private init() {}

    private let firestoreDatabase = Firestore.firestore()
    private let routesCollectionPath = "routes"

    func createRoute(routeRecord: RouteModel) async throws -> String {
        let newRouteDocumentReference = try firestoreDatabase
            .collection(routesCollectionPath)
            .addDocument(from: routeRecord)

        return newRouteDocumentReference.documentID
    }

    func fetchRoute(routeId: String) async throws -> RouteModel {
        let routeDocumentSnapshot = try await firestoreDatabase
            .collection(routesCollectionPath)
            .document(routeId)
            .getDocument()

        return try routeDocumentSnapshot.data(as: RouteModel.self)
    }

    func updateRoute(routeId: String, updatedRecord: RouteModel) async throws {
        let _ = try firestoreDatabase
            .collection(routesCollectionPath)
            .document(routeId)
        try await firestoreDatabase
            .collection(routesCollectionPath)
            .document(routeId)
            .setData(from: updatedRecord, merge: true)
    }
}
