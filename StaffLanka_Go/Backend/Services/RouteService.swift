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

    func createRoute(routeRecord: RouteRecord) async throws -> String {
        let newRouteDocumentReference = try firestoreDatabase
            .collection(routesCollectionPath)
            .addDocument(from: routeRecord)

        return newRouteDocumentReference.documentID
    }
}
