//
//  PaymentService.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-05.
//

import Foundation
import FirebaseFirestore

// Handles writing payment records to Firestore
// Each payment document records who paid, to which driver, for which enrollment, for which month
final class PaymentService {

    static let shared = PaymentService()
    private init() {}

    private let firestoreDatabase = Firestore.firestore()
    private let paymentsCollectionPath = "payments"

    // Records a simulated payment to the payments collection
    // Also updates paymentStatus on the joinRequest document so the driver sees it immediately
    func recordPayment(
        passengerId: String,
        passengerName: String,
        driverId: String,
        joinRequestDocumentId: String,
        sessionLabel: String,
        monthLabel: String,
        monthYear: String,
        amountPaid: Double
    ) async throws {
        let paymentDocumentData: [String: Any] = [
            "passengerId":       passengerId,
            "passengerName":     passengerName,
            "driverId":          driverId,
            "joinRequestId":     joinRequestDocumentId,
            "session":           sessionLabel,
            "monthLabel":        monthLabel,
            "monthYear":         monthYear,
            "amount":            amountPaid,
            "paidAt":            Timestamp(date: Date()),
            "status":            "paid"
        ]

        try await firestoreDatabase
            .collection(paymentsCollectionPath)
            .addDocument(data: paymentDocumentData)

        // Update the paymentStatus field on the joinRequest so the driver's manage passengers list
        // immediately reflects the paid status
        try await firestoreDatabase
            .collection("joinRequests")
            .document(joinRequestDocumentId)
            .updateData(["paymentStatus": "paid"])

        print("[PaymentService] Payment recorded — passenger: \(passengerId) driver: \(driverId) month: \(monthYear) amount: \(amountPaid)")
    }

    // Fetches all payment records for a specific driver, optionally filtered to a specific month
    // monthYear format: "2026-05" (yyyy-MM)
    func fetchDriverPayments(driverId: String, monthYear: String?) async throws -> [PaymentRecord] {
        var query: Query = firestoreDatabase
            .collection(paymentsCollectionPath)
            .whereField("driverId", isEqualTo: driverId)

        if let monthYear {
            query = query.whereField("monthYear", isEqualTo: monthYear)
        }

        let snapshot = try await query.getDocuments()
        let records = snapshot.documents.compactMap { document -> PaymentRecord? in
            let data = document.data()
            guard
                let passengerId   = data["passengerId"]   as? String,
                let passengerName = data["passengerName"] as? String,
                let driverIdValue = data["driverId"]      as? String,
                let joinRequestId = data["joinRequestId"] as? String,
                let session       = data["session"]       as? String,
                let monthLabelStr = data["monthLabel"]    as? String,
                let monthYearStr  = data["monthYear"]     as? String,
                let amount        = data["amount"]        as? Double,
                let timestamp     = data["paidAt"]        as? Timestamp
            else { return nil }

            return PaymentRecord(
                id:              document.documentID,
                passengerId:     passengerId,
                passengerName:   passengerName,
                driverId:        driverIdValue,
                joinRequestId:   joinRequestId,
                sessionLabel:    session,
                monthLabel:      monthLabelStr,
                monthYear:       monthYearStr,
                amountPaid:      amount,
                paidAt:          timestamp.dateValue()
            )
        }

        print("[PaymentService] Fetched \(records.count) payment(s) for driver \(driverId) month: \(monthYear ?? "all")")
        return records
    }

    // Fetches all payment records for a specific passenger
    func fetchPassengerPayments(passengerId: String) async throws -> [PaymentRecord] {
        let snapshot = try await firestoreDatabase
            .collection(paymentsCollectionPath)
            .whereField("passengerId", isEqualTo: passengerId)
            .getDocuments()

        let records = snapshot.documents.compactMap { document -> PaymentRecord? in
            let data = document.data()
            guard
                let passengerIdValue = data["passengerId"]   as? String,
                let passengerName    = data["passengerName"] as? String,
                let driverIdValue    = data["driverId"]      as? String,
                let joinRequestId    = data["joinRequestId"] as? String,
                let session          = data["session"]       as? String,
                let monthLabelStr    = data["monthLabel"]    as? String,
                let monthYearStr     = data["monthYear"]     as? String,
                let amount           = data["amount"]        as? Double,
                let timestamp        = data["paidAt"]        as? Timestamp
            else { return nil }

            return PaymentRecord(
                id:            document.documentID,
                passengerId:   passengerIdValue,
                passengerName: passengerName,
                driverId:      driverIdValue,
                joinRequestId: joinRequestId,
                sessionLabel:  session,
                monthLabel:    monthLabelStr,
                monthYear:     monthYearStr,
                amountPaid:    amount,
                paidAt:        timestamp.dateValue()
            )
        }
        // Sort descending by paidAt client-side — avoids the Firestore composite index requirement
        return records.sorted { $0.paidAt > $1.paidAt }
    }
}

// Simple value type representing a payment record from Firestore collection name payments
struct PaymentRecord: Identifiable {
    let id: String
    let passengerId: String
    let passengerName: String
    let driverId: String
    let joinRequestId: String
    let sessionLabel: String
    let monthLabel: String
    let monthYear: String
    let amountPaid: Double
    let paidAt: Date
}
