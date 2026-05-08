//
//  JoinRequestViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-03.
//

import Foundation
import Combine
import SwiftUI
import FirebaseAuth

@MainActor
final class JoinRequestViewModel: ObservableObject {

    enum TripSession: String, CaseIterable {
        case morning = "Morning"
        case evening = "Evening"
        case both    = "Both"
    }

    // Form state
    @Published var selectedPickup: String
    @Published var selectedDestination: String
    @Published var selectedSession: TripSession = .both
    @Published var phone: String = ""
    @Published var name: String = ""
    @Published var note: String = ""

    // UI state
    @Published var isSubmitting: Bool = false
    @Published var isSubmitted: Bool = false
    @Published var submitError: String? = nil
    @Published var showPickupPicker: Bool = false
    @Published var showDestinationPicker: Bool = false

    // Route context (set by RouteDetailView)
    let routeId: String
    let driverId: String
    let routeName: String

    let stops: [String]

    init(
        pickupLocation: String,
        destinationLocation: String,
        routeName: String,
        routeId: String,
        driverId: String,
        stops: [String]
    ) {
        self.selectedPickup      = pickupLocation
        self.selectedDestination = destinationLocation
        self.routeName           = routeName
        self.routeId             = routeId
        self.driverId            = driverId
        self.stops               = stops
    }

    var canSubmit: Bool {
        !phone.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedPickup.isEmpty &&
        !selectedDestination.isEmpty &&
        !isSubmitting
    }

    // Submit to Firestore

    func submitRequest() {
        guard canSubmit else { return }
        isSubmitting = true
        submitError  = nil

        let passengerId = Auth.auth().currentUser?.uid
        let model = JoinRequestModel(
            routeId:        routeId,
            driverId:       driverId,
            passengerId:    passengerId,
            passengerName:  name.trimmingCharacters(in: .whitespaces).isEmpty ? "Anonymous" : name.trimmingCharacters(in: .whitespaces),
            passengerPhone: phone.trimmingCharacters(in: .whitespaces),
            pickupStop:     selectedPickup,
            dropoffStop:    selectedDestination,
            session:        selectedSession.rawValue,
            note:           note.trimmingCharacters(in: .whitespaces),
            status:         "pending",
            createdAt:      Date()
        )

        print("🔵 [JoinRequestVM] Submitting request — route: \(routeId) driver: \(driverId) passenger: \(passengerId ?? "anon")")

        Task {
            do {
                let docId = try await JoinRequestService.shared.submitRequest(model)
                print("🟢 [JoinRequestVM] Request submitted successfully, docId: \(docId)")
                withAnimation(.spring(response: 0.4)) {
                    self.isSubmitted = true
                }
            } catch {
                print("🔴 [JoinRequestVM] Submit failed: \(error.localizedDescription)")
                self.submitError = "Could not send request. Please try again."
            }
            self.isSubmitting = false
        }
    }
}
