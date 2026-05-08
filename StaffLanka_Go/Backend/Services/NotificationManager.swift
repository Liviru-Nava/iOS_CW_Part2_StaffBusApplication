//
//  NotificationManager.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-05.
//

import Foundation
import UserNotifications
import CoreData
import FirebaseAuth
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private let coreDataViewContext = PersistenceController.shared.container.viewContext

    @Published var muteTripAlerts: Bool = UserDefaults.standard.bool(forKey: "muteTripAlerts")
    @Published var mutePassengerAlerts: Bool = UserDefaults.standard.bool(forKey: "mutePassengerAlerts")
    @Published var muteInAppNotifications: Bool = UserDefaults.standard.bool(forKey: "muteInAppNotifications")
    @Published var systemBannerAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    private var hasAlreadyFiredPickupProximityAlert: Bool = false
    private var hasAlreadyFiredDropoffProximityAlert: Bool = false

    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { permissionGranted, permissionError in
            if permissionGranted {
                print("Notification permissions granted.")
            } else if let permissionError = permissionError {
                print("Notification permissions error: \(permissionError.localizedDescription)")
            }
            DispatchQueue.main.async {
                self.refreshSystemBannerAuthorizationStatus()
            }
        }
    }

    func refreshSystemBannerAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.systemBannerAuthorizationStatus = settings.authorizationStatus
            }
        }
    }

    func scheduleNotification(
        title: String,
        body: String,
        actionType: String? = nil,
        referenceId: String? = nil,
        isTripAlert: Bool = false,
        explicitUserId: String? = nil
    ) {
        let resolvedUserId: String
        if let explicitUserId = explicitUserId, !explicitUserId.isEmpty {
            resolvedUserId = explicitUserId
        } else if let currentFirebaseUserId = Auth.auth().currentUser?.uid {
            resolvedUserId = currentFirebaseUserId
        } else {
            print("NotificationManager: skipping notification — no userId available. title: \(title)")
            return
        }

        if isTripAlert && muteTripAlerts { return }
        if !isTripAlert && mutePassengerAlerts { return }

        if !muteInAppNotifications {
            let newNotificationRecord = NotificationEntity(context: coreDataViewContext)
            newNotificationRecord.id = UUID()
            newNotificationRecord.title = title
            newNotificationRecord.body = body
            newNotificationRecord.timestamp = Date()
            newNotificationRecord.isRead = false
            newNotificationRecord.userId = resolvedUserId
            newNotificationRecord.actionType = actionType
            newNotificationRecord.referenceId = referenceId

            do {
                try coreDataViewContext.save()
            } catch {
                print("Failed to save in-app notification: \(error.localizedDescription)")
            }
        }

        let localNotificationContent = UNMutableNotificationContent()
        localNotificationContent.title = title
        localNotificationContent.body = body
        localNotificationContent.sound = .default

        let localNotificationRequest = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: localNotificationContent,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(localNotificationRequest)
    }

    func sendWelcomeLoginNotification(userDisplayName: String, userId: String) {
        scheduleNotification(
            title: "Welcome back, \(userDisplayName.isEmpty ? "there" : userDisplayName)!",
            body: "You have successfully signed in to StaffLanka Go. Have a safe commute.",
            actionType: "LOGIN_SUCCESS",
            isTripAlert: false,
            explicitUserId: userId
        )
    }

    func resetProximityAlertFlags() {
        hasAlreadyFiredPickupProximityAlert = false
        hasAlreadyFiredDropoffProximityAlert = false
    }

    func evaluateAndFireProximityAlertIfNeeded(
        estimatedMinutesUntilRelevantStop: Int,
        passengerHasAlreadyBeenPickedUp: Bool,
        passengerPickupStopName: String,
        passengerDropOffStopName: String,
        proximityThresholdInMinutes: Int = 10
    ) {
        guard estimatedMinutesUntilRelevantStop <= proximityThresholdInMinutes
                && estimatedMinutesUntilRelevantStop > 0 else { return }

        if !passengerHasAlreadyBeenPickedUp && !hasAlreadyFiredPickupProximityAlert {
            hasAlreadyFiredPickupProximityAlert = true
            scheduleNotification(
                title: "Bus Approaching Your Pickup Stop",
                body: "Your bus is approximately \(estimatedMinutesUntilRelevantStop) minute\(estimatedMinutesUntilRelevantStop == 1 ? "" : "s") away from \(passengerPickupStopName). Please be ready.",
                actionType: "BUS_APPROACHING_PICKUP",
                isTripAlert: true
            )
        }

        if passengerHasAlreadyBeenPickedUp && !hasAlreadyFiredDropoffProximityAlert {
            hasAlreadyFiredDropoffProximityAlert = true
            scheduleNotification(
                title: "Approaching Your Drop-off Stop",
                body: "Your destination \(passengerDropOffStopName) is approximately \(estimatedMinutesUntilRelevantStop) minute\(estimatedMinutesUntilRelevantStop == 1 ? "" : "s") away. Prepare to alight.",
                actionType: "BUS_APPROACHING_DROPOFF",
                isTripAlert: true
            )
        }
    }

    func toggleTripAlerts(isOn: Bool) {
        muteTripAlerts = !isOn
        UserDefaults.standard.set(!isOn, forKey: "muteTripAlerts")
    }

    func togglePassengerAlerts(isOn: Bool) {
        mutePassengerAlerts = !isOn
        UserDefaults.standard.set(!isOn, forKey: "mutePassengerAlerts")
    }

    func toggleInAppNotifications(isOn: Bool) {
        muteInAppNotifications = !isOn
        UserDefaults.standard.set(!isOn, forKey: "muteInAppNotifications")
    }
}
