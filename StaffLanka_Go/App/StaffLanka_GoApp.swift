//
//  StaffLanka_GoApp.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-03-23.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreData
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared.requestPermissions()
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }

    func application(
        _ application: UIApplication,
        open incomingURL: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return Auth.auth().canHandle(incomingURL)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        completionHandler(.newData)
    }
}

@main
struct StaffLanka_GoApp: App {
    @StateObject private var authManager = AuthManager.shared
    let persistenceController = PersistenceController.shared

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .task {
                    await refreshExpiredCalendarEventsIfNeeded()
                }
        }
    }

    // Checks whether the stored calendar events for the signed-in user's routes have expired
    private func refreshExpiredCalendarEventsIfNeeded() async {
        guard let userId = FirebaseAuth.Auth.auth().currentUser?.uid else { return }

        do {
            // Fetch accepted join requests for this user to find their enrolled routes
            let snapshot = try await FirebaseFirestore.Firestore.firestore()
                .collection("joinRequests")
                .whereField("passengerId", isEqualTo: userId)
                .whereField("status", isEqualTo: "accepted")
                .getDocuments()

            for document in snapshot.documents {
                let data = document.data()
                guard let routeId = data["routeId"] as? String,
                      let sessionLabel = data["session"] as? String,
                      let pickupStop = data["pickupStop"] as? String else { continue }

                guard let route = try? await RouteService.shared.fetchRoute(routeId: routeId) else { continue }

                let morningDeparture = route.scheduleEntries.first?.scheduledDepartureTime ?? Date()
                let eveningDeparture = route.scheduleEntries.count > 1
                    ? route.scheduleEntries[1].scheduledDepartureTime
                    : Date()
                let activeDays = route.scheduleEntries.first?.activeDays ?? []
                let routeDisplayName = "\(route.startName ?? route.startLocation.locationName) - \(route.endName ?? route.endLocation.locationName)"

                await EventKitManager.shared.rescheduleEventsIfMonthExpired(
                    routeId: routeId,
                    routeDisplayName: routeDisplayName,
                    passengerPickupStopName: pickupStop,
                    sessionLabel: sessionLabel,
                    morningDepartureTime: morningDeparture,
                    eveningDepartureTime: eveningDeparture,
                    routeActiveDays: activeDays
                )
            }
        } catch {
            print("[StaffLanka_GoApp] Calendar refresh check failed: \(error.localizedDescription)")
        }
    }
}
