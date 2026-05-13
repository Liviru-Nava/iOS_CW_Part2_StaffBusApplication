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

    // Which sessions the passenger is permitted to select for this request
    // Computed from their current enrollment state before this sheet opens
    let allowedSessions: [TripSession]

    // Form state
    @Published var selectedPickup: String
    @Published var selectedDestination: String
    @Published var selectedSession: TripSession
    @Published var phone: String = ""
    @Published var name: String = ""
    @Published var note: String = ""

    // UI state
    @Published var isSubmitting: Bool = false
    @Published var isSubmitted: Bool = false
    @Published var submitError: String? = nil
    @Published var showPickupPicker: Bool = false
    @Published var showDestinationPicker: Bool = false
    @Published var calendarEventSchedulingCompleted: Bool = false

    // Route context
    let routeId: String
    let driverId: String
    let routeName: String
    let stops: [String]
    let routeMorningDepartureTime: Date
    let routeEveningDepartureTime: Date
    let routeActiveDays: [String]

    init(
        pickupLocation: String,
        destinationLocation: String,
        routeName: String,
        routeId: String,
        driverId: String,
        stops: [String],
        morningDepartureTime: Date,
        eveningDepartureTime: Date,
        activeDays: [String],
        allowedSessions: [TripSession]
    ) {
        self.selectedPickup            = pickupLocation
        self.selectedDestination       = destinationLocation
        self.routeName                 = routeName
        self.routeId                   = routeId
        self.driverId                  = driverId
        self.stops                     = stops
        self.routeMorningDepartureTime = morningDepartureTime
        self.routeEveningDepartureTime = eveningDepartureTime
        self.routeActiveDays           = activeDays
        self.allowedSessions           = allowedSessions

        // Default to the first allowed session
        // If only one session is allowed, it is pre-selected and the chip is locked
        self.selectedSession = allowedSessions.first ?? .both

        // Auto-populate phone from stored session
        let storedPhoneNumber = AuthManager.shared.storedPhoneNumber
        if !storedPhoneNumber.isEmpty {
            self.phone = storedPhoneNumber
        }

        // Auto-populate name only when it is a real name and not the default placeholder
        let storedName: String = {
            guard let userId = Auth.auth().currentUser?.uid else { return "" }
            return CoreDataManager.shared.fetchPassengerProfile(userId: userId)?.fullName ?? ""
        }()
        let nameIsPlaceholder = storedName.trimmingCharacters(in: .whitespaces).lowercased() == "new user"
        if !storedName.trimmingCharacters(in: .whitespaces).isEmpty && !nameIsPlaceholder {
            self.name = storedName
        }
    }

    // Whether a particular session chip should be disabled in the UI
    func isSessionDisabled(_ session: TripSession) -> Bool {
        !allowedSessions.contains(session)
    }

    var canSubmit: Bool {
        !phone.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedPickup.isEmpty &&
        !selectedDestination.isEmpty &&
        !isSubmitting &&
        allowedSessions.contains(selectedSession)
    }

    func submitRequest() {
        guard canSubmit else { return }
        isSubmitting = true
        submitError  = nil

        let authenticatedPassengerId = Auth.auth().currentUser?.uid
        let joinRequestModelToSubmit = JoinRequestModel(
            routeId:        routeId,
            driverId:       driverId,
            passengerId:    authenticatedPassengerId,
            passengerName:  name.trimmingCharacters(in: .whitespaces).isEmpty ? "Anonymous" : name.trimmingCharacters(in: .whitespaces),
            passengerPhone: phone.trimmingCharacters(in: .whitespaces),
            pickupStop:     selectedPickup,
            dropoffStop:    selectedDestination,
            session:        selectedSession.rawValue,
            note:           note.trimmingCharacters(in: .whitespaces),
            status:         "pending",
            createdAt:      Date()
        )

        Task {
            do {
                let firestoreDocumentId = try await JoinRequestService.shared.submitRequest(joinRequestModelToSubmit)
                print("[JoinRequestViewModel] Request submitted successfully, docId: \(firestoreDocumentId)")
                withAnimation(.spring(response: 0.4)) { self.isSubmitted = true }
                await scheduleCalendarRemindersForApprovedSessions()
            } catch {
                print("[JoinRequestViewModel] Submit failed: \(error.localizedDescription)")
                self.submitError = "Could not send request. Please try again."
            }
            self.isSubmitting = false
        }
    }

    private func scheduleCalendarRemindersForApprovedSessions() async {
        switch selectedSession {
        case .both:
            await EventKitManager.shared.schedulePassengerTripReminders(
                routeId: routeId, routeDisplayName: routeName,
                passengerPickupStopName: selectedPickup,
                morningDepartureTime: routeMorningDepartureTime,
                eveningDepartureTime: routeEveningDepartureTime,
                routeActiveDays: routeActiveDays
            )
        case .morning:
            await schedulePassengerSingleSessionReminder(sessionLabel: "Morning", sessionDepartureTime: routeMorningDepartureTime, pickupStopName: selectedPickup)
        case .evening:
            await schedulePassengerSingleSessionReminder(sessionLabel: "Evening", sessionDepartureTime: routeEveningDepartureTime, pickupStopName: selectedPickup)
        }
        calendarEventSchedulingCompleted = true
    }

    private func schedulePassengerSingleSessionReminder(sessionLabel: String, sessionDepartureTime: Date, pickupStopName: String) async {
        await EventKitManager.shared.schedulePassengerTripReminders(
            routeId: routeId, routeDisplayName: routeName,
            passengerPickupStopName: pickupStopName,
            morningDepartureTime: sessionDepartureTime,
            eveningDepartureTime: sessionDepartureTime,
            routeActiveDays: routeActiveDays
        )
    }
}
