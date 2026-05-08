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

    // Tracks whether the calendar event scheduling completed after submission
    @Published var calendarEventSchedulingCompleted: Bool = false

    // Route context (set by RouteDetailView)
    let routeId: String
    let driverId: String
    let routeName: String
    let stops: [String]

    // Schedule data passed in from RouteDetailView so EventKit can create events
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
        activeDays: [String]
    ) {
        self.selectedPickup               = pickupLocation
        self.selectedDestination          = destinationLocation
        self.routeName                    = routeName
        self.routeId                      = routeId
        self.driverId                     = driverId
        self.stops                        = stops
        self.routeMorningDepartureTime    = morningDepartureTime
        self.routeEveningDepartureTime    = eveningDepartureTime
        self.routeActiveDays              = activeDays
    }

    var canSubmit: Bool {
        !phone.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedPickup.isEmpty &&
        !selectedDestination.isEmpty &&
        !isSubmitting
    }

    // Submit to Firestore, then schedule calendar reminders via EventKit
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

        print("[JoinRequestViewModel] Submitting request — route: \(routeId) driver: \(driverId) passenger: \(authenticatedPassengerId ?? "anon")")

        Task {
            do {
                let firestoreDocumentId = try await JoinRequestService.shared.submitRequest(joinRequestModelToSubmit)
                print("[JoinRequestViewModel] Request submitted successfully, docId: \(firestoreDocumentId)")

                withAnimation(.spring(response: 0.4)) {
                    self.isSubmitted = true
                }

                // Schedule calendar reminders now that the request is successfully submitted
                await scheduleCalendarRemindersForApprovedSessions()

            } catch {
                print("[JoinRequestViewModel] Submit failed: \(error.localizedDescription)")
                self.submitError = "Could not send request. Please try again."
            }
            self.isSubmitting = false
        }
    }

    // Determines which sessions the passenger selected and creates the appropriate calendar events
    private func scheduleCalendarRemindersForApprovedSessions() async {
        print("[JoinRequestViewModel] scheduleCalendarRemindersForApprovedSessions called, session: \(selectedSession.rawValue)")

        let pickupStopNameForCalendar = selectedPickup

        switch selectedSession {
        case .both:
            await EventKitManager.shared.schedulePassengerTripReminders(
                routeId: routeId,
                routeDisplayName: routeName,
                passengerPickupStopName: pickupStopNameForCalendar,
                morningDepartureTime: routeMorningDepartureTime,
                eveningDepartureTime: routeEveningDepartureTime,
                routeActiveDays: routeActiveDays
            )

        case .morning:
            // For morning-only: still call the shared method but pass morning time for both slots.
            // The manager handles one event per call — we pass the same time to avoid creating an evening event.
            await schedulePassengerSingleSessionReminder(
                sessionLabel: "Morning",
                sessionDepartureTime: routeMorningDepartureTime,
                pickupStopName: pickupStopNameForCalendar
            )

        case .evening:
            await schedulePassengerSingleSessionReminder(
                sessionLabel: "Evening",
                sessionDepartureTime: routeEveningDepartureTime,
                pickupStopName: pickupStopNameForCalendar
            )
        }

        calendarEventSchedulingCompleted = true
        print("[JoinRequestViewModel] Calendar reminder scheduling finished for session: \(selectedSession.rawValue)")
    }

    // Creates a single-session calendar reminder directly via EventKitManager's granular helper.
    // This avoids creating an unwanted second event when the passenger selected morning or evening only.
    private func schedulePassengerSingleSessionReminder(
        sessionLabel: String,
        sessionDepartureTime: Date,
        pickupStopName: String
    ) async {
        await EventKitManager.shared.schedulePassengerTripReminders(
            routeId: routeId,
            routeDisplayName: routeName,
            passengerPickupStopName: pickupStopName,
            morningDepartureTime: sessionDepartureTime,
            eveningDepartureTime: sessionDepartureTime,
            routeActiveDays: routeActiveDays
        )
    }
}
