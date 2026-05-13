//
//  AttendanceService.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-06.
//

import Foundation
import FirebaseFirestore

final class AttendanceService {

    static let shared = AttendanceService()
    private init() {}

    private let db = Firestore.firestore()
    private let collection = "attendance"

    // Mark or update attendance

    // Creates or overwrites the attendance document for a given passenger/route/session/date.
    // Uses a deterministic document ID so upserts are idempotent.
    func markAttendance(
        passengerId: String,
        routeId: String,
        requestId: String,
        session: String,
        date: Date,
        status: String           // "attending" | "absent"
    ) async throws {
        let dayStart = Calendar.current.startOfDay(for: date)
        let docId = "\(passengerId)_\(routeId)_\(session)_\(Int(dayStart.timeIntervalSince1970))"
        let now = Date()

        let data: [String: Any] = [
            "passengerId": passengerId,
            "routeId":     routeId,
            "requestId":   requestId,
            "session":     session,
            "tripDate":    Timestamp(date: dayStart),
            "status":      status,
            "markedAt":    Timestamp(date: now),
            "updatedAt":   Timestamp(date: now)
        ]

        try await db.collection(collection).document(docId).setData(data, merge: true)
        print(" [AttendanceService] \(session) attendance for \(passengerId) set to '\(status)'")
    }

    // Fetch attendance for a specific date

    func fetchAttendance(
        passengerId: String,
        routeId: String,
        session: String,
        date: Date
    ) async throws -> AttendanceModel? {
        let dayStart = Calendar.current.startOfDay(for: date)
        let docId = "\(passengerId)_\(routeId)_\(session)_\(Int(dayStart.timeIntervalSince1970))"
        let snapshot = try await db.collection(collection).document(docId).getDocument()
        guard snapshot.exists else { return nil }
        var model = try? snapshot.data(as: AttendanceModel.self)
        model?.id = snapshot.documentID
        return model
    }

    // Real-time listener for today's (or tomorrow's) attendance

    // Listens to the attendance document for `date` (defaults to next calendar day after 6 PM, today otherwise).
    func listenForAttendance(
        passengerId: String,
        routeId: String,
        session: String,
        date: Date,
        onChange: @escaping (AttendanceModel?) -> Void
    ) -> ListenerRegistration {
        let dayStart = Calendar.current.startOfDay(for: date)
        let docId = "\(passengerId)_\(routeId)_\(session)_\(Int(dayStart.timeIntervalSince1970))"
        print("[AttendanceService] Listening to attendance doc: \(docId)")
        return db.collection(collection).document(docId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print(" [AttendanceService] Listener error: \(error.localizedDescription)")
                    onChange(nil)
                    return
                }
                guard let snapshot, snapshot.exists else {
                    onChange(nil)
                    return
                }
                var model = try? snapshot.data(as: AttendanceModel.self)
                model?.id = snapshot.documentID
                onChange(model)
            }
    }

    // Listens to ALL attendance documents for a specific route, session, and date
    func listenForRouteAttendance(
        routeId: String,
        session: String,
        date: Date,
        onChange: @escaping ([AttendanceModel]) -> Void
    ) -> ListenerRegistration {
        let dayStart = Calendar.current.startOfDay(for: date)
        print("[AttendanceService] Listening for ALL attendance routeId: \(routeId), session: \(session), date: \(dayStart)")
        
        return db.collection(collection)
            .whereField("routeId", isEqualTo: routeId)
            .whereField("session", isEqualTo: session)
            .whereField("tripDate", isEqualTo: Timestamp(date: dayStart))
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print(" [AttendanceService] Route listener error: \(error.localizedDescription)")
                    onChange([])
                    return
                }
                guard let snapshot else {
                    onChange([])
                    return
                }
                let models = snapshot.documents.compactMap { doc -> AttendanceModel? in
                    var model = try? doc.data(as: AttendanceModel.self)
                    model?.id = doc.documentID
                    return model
                }
                onChange(models)
            }
    }

    // Helper: which date should attendance be marked for?

    // Returns tomorrow if the current time is after 6 PM (trip done for today), otherwise returns today.
    static func relevantDate() -> Date {
        let hour = Calendar.current.component(.hour, from: Date())
        let base = Date()
        if hour >= 18 {
            return Calendar.current.date(byAdding: .day, value: 1, to: base) ?? base
        }
        return base
    }
}
