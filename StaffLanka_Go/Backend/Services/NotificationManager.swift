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
    private let context = PersistenceController.shared.container.viewContext
    
    // UserDefaults settings backing the toggles in Profile
    @Published var muteTripAlerts: Bool = UserDefaults.standard.bool(forKey: "muteTripAlerts")
    @Published var mutePassengerAlerts: Bool = UserDefaults.standard.bool(forKey: "mutePassengerAlerts")
    
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permissions granted.")
            } else if let error = error {
                print("Notification permissions error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(title: String, body: String, actionType: String? = nil, referenceId: String? = nil, isTripAlert: Bool = false) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Check user settings before sending
        if isTripAlert && muteTripAlerts { return }
        if !isTripAlert && mutePassengerAlerts { return }
        
        // 1. Create UNNotification UI Alert
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        
        // 2. Save identical record to Core Data
        let newNotification = NotificationEntity(context: context)
        newNotification.id = UUID()
        newNotification.title = title
        newNotification.body = body
        newNotification.timestamp = Date()
        newNotification.isRead = false
        newNotification.userId = userId
        newNotification.actionType = actionType
        newNotification.referenceId = referenceId
        
        do {
            try context.save()
        } catch {
            print("Failed to save local notification: \(error.localizedDescription)")
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
}
