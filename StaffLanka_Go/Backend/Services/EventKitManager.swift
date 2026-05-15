//
//  EventKitManager.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-08.
//

import Foundation
import EventKit

final class EventKitManager {

    static let shared = EventKitManager()

    private let eventKitStore = EKEventStore()
    private let storedEventIdentifiersKey = "stafflanka_eventkit_stored_identifiers"

    // UserDefaults keys for the end-of-month expiry date stored per route
    // Format: "stafflanka_eventkit_expiry_<routeId>"
    private func expiryDateKey(routeId: String) -> String {
        "stafflanka_eventkit_expiry_\(routeId)"
    }

    private init() {}

    // Requests write-only calendar access on full access on earlier versions
    func requestCalendarWriteAccessIfNeeded() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                return try await eventKitStore.requestWriteOnlyAccessToEvents()
            } catch {
                print("[EventKitManager] Write-only access request failed: \(error.localizedDescription)")
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventKitStore.requestAccess(to: .event) { granted, error in
                    if let error { print("[EventKitManager] Legacy access request failed: \(error.localizedDescription)") }
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // Schedules calendar events for a passenger after their request has been accepted by the driver.
    // sessionLabel must be "Morning", "Evening", or "Both".
    // Events recur weekly until the last day of the current calendar month.
    // Returns the count of events successfully saved.
    @discardableResult
    func schedulePassengerEventsOnAcceptance(
        routeId: String,
        routeDisplayName: String,
        passengerPickupStopName: String,
        sessionLabel: String,
        morningDepartureTime: Date,
        eveningDepartureTime: Date,
        routeActiveDays: [String]
    ) async -> Int {
        guard await requestCalendarWriteAccessIfNeeded() else {
            print("[EventKitManager] Calendar access denied — passenger events not scheduled")
            return 0
        }

        let recurrenceWeekdays = routeActiveDays
            .compactMap { convertDayStringToEKWeekday($0) }
            .map { EKRecurrenceDayOfWeek($0) }

        guard !recurrenceWeekdays.isEmpty else {
            print("[EventKitManager] No valid active days — aborting passenger event creation")
            return 0
        }

        let monthEndDate = endOfCurrentMonth()
        var savedCount = 0

        if sessionLabel == "Morning" || sessionLabel == "Both" {
            let identifier = createAndSaveEvent(
                title: "StaffLanka Go — \(routeDisplayName) (Morning)",
                location: passengerPickupStopName,
                startDate: morningDepartureTime,
                endDate: Calendar.current.date(byAdding: .minute, value: 60, to: morningDepartureTime) ?? morningDepartureTime,
                alarmOffset: -30 * 60,
                recurrenceWeekdays: recurrenceWeekdays,
                recurrenceEndDate: monthEndDate,
                notes: "Morning pickup at \(passengerPickupStopName). Be ready at least 5 minutes before departure."
            )
            if let identifier {
                UserDefaults.standard.set([identifier], forKey: "stafflanka_eventkit_\(routeId)_morning")
                savedCount += 1
            }
        }

        if sessionLabel == "Evening" || sessionLabel == "Both" {
            let identifier = createAndSaveEvent(
                title: "StaffLanka Go — \(routeDisplayName) (Evening)",
                location: passengerPickupStopName,
                startDate: eveningDepartureTime,
                endDate: Calendar.current.date(byAdding: .minute, value: 60, to: eveningDepartureTime) ?? eveningDepartureTime,
                alarmOffset: -30 * 60,
                recurrenceWeekdays: recurrenceWeekdays,
                recurrenceEndDate: monthEndDate,
                notes: "Evening pickup at \(passengerPickupStopName). Be ready at least 5 minutes before departure."
            )
            if let identifier {
                UserDefaults.standard.set([identifier], forKey: "stafflanka_eventkit_\(routeId)_evening")
                savedCount += 1
            }
        }

        // Store the expiry date so the monthly refresh logic can detect when to reschedule
        UserDefaults.standard.set(monthEndDate, forKey: expiryDateKey(routeId: routeId))
        appendIdentifiersToUserDefaults(newIdentifiers: [
            UserDefaults.standard.stringArray(forKey: "stafflanka_eventkit_\(routeId)_morning") ?? [],
            UserDefaults.standard.stringArray(forKey: "stafflanka_eventkit_\(routeId)_evening") ?? []
        ].flatMap { $0 })

        print("[EventKitManager] Passenger events saved: \(savedCount) for session '\(sessionLabel)'")
        return savedCount
    }

    // Schedules calendar events for the driver once their first passenger has been accepted.
    // Events recur weekly until the last day of the current calendar month.
    @discardableResult
    func scheduleDriverEventsOnFirstPassengerAccepted(
        routeId: String,
        routeStartLocationName: String,
        routeEndLocationName: String,
        morningDepartureTime: Date,
        morningEstimatedArrivalTime: Date,
        eveningDepartureTime: Date,
        eveningEstimatedArrivalTime: Date,
        routeActiveDays: [String]
    ) async -> Int {
        guard await requestCalendarWriteAccessIfNeeded() else {
            print("[EventKitManager] Calendar access denied — driver events not scheduled")
            return 0
        }

        let recurrenceWeekdays = routeActiveDays
            .compactMap { convertDayStringToEKWeekday($0) }
            .map { EKRecurrenceDayOfWeek($0) }

        guard !recurrenceWeekdays.isEmpty else {
            print("[EventKitManager] No valid active days — aborting driver event creation")
            return 0
        }

        let routeLabel = "\(routeStartLocationName) → \(routeEndLocationName)"
        let monthEndDate = endOfCurrentMonth()
        var savedCount = 0

        let morningIdentifier = createAndSaveEvent(
            title: "StaffLanka Go Route — \(routeLabel) (Morning)",
            location: routeStartLocationName,
            startDate: morningDepartureTime,
            endDate: morningEstimatedArrivalTime,
            alarmOffset: -60 * 60,
            recurrenceWeekdays: recurrenceWeekdays,
            recurrenceEndDate: monthEndDate,
            notes: "Morning operating day. Depart from \(routeStartLocationName) on schedule."
        )
        if morningIdentifier != nil { savedCount += 1 }

        let eveningIdentifier = createAndSaveEvent(
            title: "StaffLanka Go Route — \(routeLabel) (Evening)",
            location: routeEndLocationName,
            startDate: eveningDepartureTime,
            endDate: eveningEstimatedArrivalTime,
            alarmOffset: -60 * 60,
            recurrenceWeekdays: recurrenceWeekdays,
            recurrenceEndDate: monthEndDate,
            notes: "Evening operating day. Return trip from \(routeEndLocationName) on schedule."
        )
        if eveningIdentifier != nil { savedCount += 1 }

        let newIdentifiers = [morningIdentifier, eveningIdentifier].compactMap { $0 }
        appendIdentifiersToUserDefaults(newIdentifiers: newIdentifiers)
        UserDefaults.standard.set(monthEndDate, forKey: expiryDateKey(routeId: routeId))

        print("[EventKitManager] Driver events saved: \(savedCount)")
        return savedCount
    }

    // Called at app launch. If the stored recurrence end date for a route has passed,
    // the events for that month have ended and new ones need to be created for the current month.
    // The caller provides all the parameters needed to recreate the events.
    func rescheduleEventsIfMonthExpired(
        routeId: String,
        routeDisplayName: String,
        passengerPickupStopName: String,
        sessionLabel: String,
        morningDepartureTime: Date,
        eveningDepartureTime: Date,
        routeActiveDays: [String]
    ) async {
        let expiryKey = expiryDateKey(routeId: routeId)
        guard let storedExpiry = UserDefaults.standard.object(forKey: expiryKey) as? Date else {
            // No expiry stored means no events were ever scheduled — nothing to refresh
            return
        }

        // If the stored expiry is still in the future, events are still active
        guard storedExpiry < Date() else { return }

        print("[EventKitManager] Events for route \(routeId) expired on \(storedExpiry) — rescheduling for current month")

        // Remove any leftover event identifiers from the previous month
        removeCalendarEventsForRoute(routeId: routeId, sessionLabel: sessionLabel)

        // Create fresh events for the current month
        await schedulePassengerEventsOnAcceptance(
            routeId: routeId,
            routeDisplayName: routeDisplayName,
            passengerPickupStopName: passengerPickupStopName,
            sessionLabel: sessionLabel,
            morningDepartureTime: morningDepartureTime,
            eveningDepartureTime: eveningDepartureTime,
            routeActiveDays: routeActiveDays
        )
    }

    // Removes all StaffLanka Go calendar events saved by this app.
    func removeAllStoredStaffLankaCalendarEvents() {
        let storedIdentifiers = loadIdentifiersFromUserDefaults()
        var removalCount = 0
        for identifier in storedIdentifiers {
            if let event = eventKitStore.event(withIdentifier: identifier) {
                do {
                    try eventKitStore.remove(event, span: .futureEvents)
                    removalCount += 1
                } catch {
                    print("[EventKitManager] Failed to remove event \(identifier): \(error.localizedDescription)")
                }
            }
        }
        UserDefaults.standard.removeObject(forKey: storedEventIdentifiersKey)
        print("[EventKitManager] Removed \(removalCount) calendar event(s)")
    }

    func removeCalendarEventsForRoute(routeId: String, sessionLabel: String) {
        let morningKey = "stafflanka_eventkit_\(routeId)_morning"
        let eveningKey = "stafflanka_eventkit_\(routeId)_evening"

        switch sessionLabel {
        case "Morning":
            removeEventsForStorageKey(morningKey)
        case "Evening":
            removeEventsForStorageKey(eveningKey)
        default:
            removeEventsForStorageKey(morningKey)
            removeEventsForStorageKey(eveningKey)
        }
    }

    // Returns the last second of the last day of the current calendar month
    private func endOfCurrentMonth() -> Date {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfNextMonth = calendar.date(
            byAdding: .month, value: 1,
            to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        ) else { return now }
        // Subtract one second to land at 23:59:59 of the last day of the current month
        return startOfNextMonth.addingTimeInterval(-1)
    }

    // Unified internal helper that creates and saves a single EKEvent with a weekly recurrence
    // ending on the given recurrenceEndDate. Returns the event identifier on success.
    private func createAndSaveEvent(
        title: String,
        location: String?,
        startDate: Date,
        endDate: Date,
        alarmOffset: TimeInterval,
        recurrenceWeekdays: [EKRecurrenceDayOfWeek],
        recurrenceEndDate: Date,
        notes: String
    ) -> String? {
        let event = EKEvent(eventStore: eventKitStore)
        event.title     = title
        event.location  = location
        event.notes     = notes
        event.startDate = startDate
        event.endDate   = endDate
        event.calendar  = eventKitStore.defaultCalendarForNewEvents

        let recurrenceRule = EKRecurrenceRule(
            recurrenceWith: .weekly,
            interval: 1,
            daysOfTheWeek: recurrenceWeekdays,
            daysOfTheMonth: nil,
            monthsOfTheYear: nil,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil,
            end: EKRecurrenceEnd(end: recurrenceEndDate)
        )
        event.recurrenceRules = [recurrenceRule]
        event.addAlarm(EKAlarm(relativeOffset: alarmOffset))

        do {
            try eventKitStore.save(event, span: .futureEvents)
            return event.eventIdentifier
        } catch {
            print("[EventKitManager] Failed to save event '\(title)': \(error.localizedDescription)")
            return nil
        }
    }

    private func convertDayStringToEKWeekday(_ day: String) -> EKWeekday? {
        switch day {
        case "Mon": return .monday
        case "Tue": return .tuesday
        case "Wed": return .wednesday
        case "Thu": return .thursday
        case "Fri": return .friday
        case "Sat": return .saturday
        case "Sun": return .sunday
        default:
            print("[EventKitManager] Unrecognised day string '\(day)'")
            return nil
        }
    }

    private func appendIdentifiersToUserDefaults(newIdentifiers: [String]) {
        var existing = loadIdentifiersFromUserDefaults()
        existing.append(contentsOf: newIdentifiers)
        UserDefaults.standard.set(existing, forKey: storedEventIdentifiersKey)
    }

    private func loadIdentifiersFromUserDefaults() -> [String] {
        UserDefaults.standard.stringArray(forKey: storedEventIdentifiersKey) ?? []
    }

    private func removeEventsForStorageKey(_ key: String) {
        let identifiers = UserDefaults.standard.stringArray(forKey: key) ?? []
        for identifier in identifiers {
            if let event = eventKitStore.event(withIdentifier: identifier) {
                try? eventKitStore.remove(event, span: .futureEvents)
            }
        }
        UserDefaults.standard.removeObject(forKey: key)
    }
}
