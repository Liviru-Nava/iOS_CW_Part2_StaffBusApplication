//
//  CoreDataManager.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-08.
//

import CoreData
import Foundation
import Combine
 
@MainActor
final class CoreDataManager: ObservableObject {
 
    static let shared = CoreDataManager()
 
    private let context: NSManagedObjectContext
 
    private init() {
        context = PersistenceController.shared.container.viewContext
    }
 
    //saving helper
    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("[CoreDataManager] Save failed: \(error.localizedDescription)")
        }
    }
 
    //Passenger profile
     func savePassengerProfile(userId: String, fullName: String, phoneNumber: String, emailAddress: String) {
        let entity = fetchPassengerProfileEntity(userId: userId) ?? PassengerProfileEntity(context: context)
        entity.userId       = userId
        entity.fullName     = fullName
        entity.phoneNumber  = phoneNumber
        entity.emailAddress = emailAddress
        entity.cachedAt     = Date()
        saveContext()
    }
 
    func fetchPassengerProfile(userId: String) -> PassengerProfileEntity? {
        fetchPassengerProfileEntity(userId: userId)
    }
 
    private func fetchPassengerProfileEntity(userId: String) -> PassengerProfileEntity? {
        let request = PassengerProfileEntity.fetchRequest()
        request.predicate  = NSPredicate(format: "userId == %@", userId)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }
 
    // Save Driver profile
     func saveDriverProfile(
        userId: String,
        fullName: String,
        phoneNumber: String,
        emailAddress: String,
        licenseNumber: String,
        busName: String,
        plateNumber: String,
        profilePhotoData: Data?
    ) {
        let entity = fetchDriverProfileEntity(userId: userId) ?? DriverProfileEntity(context: context)
        entity.userId           = userId
        entity.fullName         = fullName
        entity.phoneNumber      = phoneNumber
        entity.emailAddress     = emailAddress
        entity.licenseNumber    = licenseNumber
        entity.busName          = busName
        entity.plateNumber      = plateNumber
        entity.cachedAt         = Date()
        saveContext()
    }
 
    func fetchDriverProfile(userId: String) -> DriverProfileEntity? {
        fetchDriverProfileEntity(userId: userId)
    }
 
    private func fetchDriverProfileEntity(userId: String) -> DriverProfileEntity? {
        let request = DriverProfileEntity.fetchRequest()
        request.predicate  = NSPredicate(format: "userId == %@", userId)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }
 
    // Trip information
    func saveCachedTrip(
        tripId: String,
        userId: String,
        userRole: String,
        routeName: String,
        session: String,
        tripDate: Date,
        status: String,
        fareAmount: Double
    ) {
        let entity      = fetchCachedTripEntity(tripId: tripId) ?? CachedTripEntity(context: context)
        entity.tripId    = tripId
        entity.userId    = userId
        entity.userRole  = userRole
        entity.routeName = routeName
        entity.session   = session
        entity.tripDate  = tripDate
        entity.status    = status
        entity.fareAmount = fareAmount
        entity.cachedAt  = Date()
        saveContext()
    }
 
    func fetchCachedTrips(userId: String) -> [CachedTripEntity] {
        let request = CachedTripEntity.fetchRequest()
        request.predicate       = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "tripDate", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
 
    private func fetchCachedTripEntity(tripId: String) -> CachedTripEntity? {
        let request = CachedTripEntity.fetchRequest()
        request.predicate  = NSPredicate(format: "tripId == %@", tripId)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }
 
    // Notifications
     func fetchNotifications(userId: String) -> [NotificationEntity] {
        let request = NotificationEntity.fetchRequest()
        request.predicate       = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
 
    func markNotificationRead(id: UUID) {
        let request = NotificationEntity.fetchRequest()
        request.predicate  = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        guard let entity = (try? context.fetch(request))?.first else { return }
        entity.isRead = true
        saveContext()
    }
 
    // Function to delete cache data
 
    func deleteCachedTrips(userId: String) {
        let request = CachedTripEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        (try? context.fetch(request))?.forEach { context.delete($0) }
        saveContext()
    }
 
    func deleteNotifications(userId: String) {
        let request = NotificationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        (try? context.fetch(request))?.forEach { context.delete($0) }
        saveContext()
    }
 
    func deletePassengerProfile(userId: String) {
        if let entity = fetchPassengerProfileEntity(userId: userId) {
            context.delete(entity)
            saveContext()
        }
    }
 
    func deleteDriverProfile(userId: String) {
        if let entity = fetchDriverProfileEntity(userId: userId) {
            context.delete(entity)
            saveContext()
        }
    }
 
    //Full wipe of cache core data

    func deleteAllLocalData(userId: String) {
        deletePassengerProfile(userId: userId)
        deleteDriverProfile(userId: userId)
        deleteCachedTrips(userId: userId)
        deleteNotifications(userId: userId)
    }
}
