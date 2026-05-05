//
//  JoinRequestService.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-05.
//

import Foundation
import FirebaseFirestore

final class JoinRequestService {

    static let shared = JoinRequestService()
    private init() {}

    private let db = Firestore.firestore()
    private let collection = "joinRequests"

    @discardableResult
    func submitRequest(_ model: JoinRequestModel) async throws -> String {
        let ref = try db.collection(collection).addDocument(from: model)
        print("🟢 [JoinRequestService] Submitted request \(ref.documentID) to driver \(model.driverId)")
        return ref.documentID
    }

    func listenForPendingRequests(
        driverId: String,
        onChange: @escaping ([JoinRequestModel]) -> Void
    ) -> ListenerRegistration {
        print("🔵 [JoinRequestService] Attaching listener for driverId: \(driverId)")
        return db.collection(collection)
            .whereField("driverId", isEqualTo: driverId)
            .whereField("status",   isEqualTo: "pending")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("🔴 [JoinRequestService] Listener error: \(error.localizedDescription)")
                    return
                }
                guard let docs = snapshot?.documents else { return }
                let requests = docs.compactMap { doc -> JoinRequestModel? in
                    do {
                        var model = try doc.data(as: JoinRequestModel.self)
                        model.id = doc.documentID
                        return model
                    } catch {
                        print("🔴 [JoinRequestService] Decode error for \(doc.documentID): \(error)")
                        return nil
                    }
                }
                print("🟢 [JoinRequestService] Listener fired — \(requests.count) pending request(s)")
                onChange(requests)
            }
    }

    func updateStatus(requestId: String, status: String) async throws {
        try await db.collection(collection).document(requestId).updateData(["status": status])
        print("🟢 [JoinRequestService] Request \(requestId) updated to '\(status)'")
    }
}
