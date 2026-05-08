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

    func fetchAllRoutes() async throws -> [RouteModel] {
        print("🔵 [RouteService] fetchAllRoutes — querying '\(routesCollectionPath)' collection")
        let snapshot = try await firestoreDatabase
            .collection(routesCollectionPath)
            .getDocuments()
        print("🟢 [RouteService] fetchAllRoutes — got \(snapshot.documents.count) raw document(s)")

        var decoded: [RouteModel] = []
        for doc in snapshot.documents {
            do {
                let route = try doc.data(as: RouteModel.self)
                print("   ✅ Decoded route \(doc.documentID): start='\(route.startLocation.locationName)' end='\(route.endLocation.locationName)' stops=\(route.routeStops.count) schedules=\(route.scheduleEntries.count)")
                decoded.append(route)
            } catch {
                print("   ❌ Failed to decode route \(doc.documentID): \(error.localizedDescription)")
                print("      Raw data keys: \(doc.data().keys.sorted())")
            }
        }
        return decoded
    }

    func fetchRoutes(from startLocationName: String, to endLocationName: String) async throws -> [RouteModel] {
        let snapshot = try await firestoreDatabase
            .collection(routesCollectionPath)
            .whereField("startName", isEqualTo: startLocationName)
            .whereField("endName", isEqualTo: endLocationName)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: RouteModel.self) }
    }
}

