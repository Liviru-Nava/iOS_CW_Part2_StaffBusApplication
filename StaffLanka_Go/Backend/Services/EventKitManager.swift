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

    // Key used to persist created event identifiers in UserDefaults
    private let userDefaultsStoredEventIdentifiersKey = "stafflanka_eventkit_stored_identifiers"

    private init() {}

    // Requests write-only calendar access on iOS 17+, full access on earlier versions
    func requestCalendarWriteAccessIfNeeded() async -> Bool {
        print("[EventKitManager] requestCalendarWriteAccessIfNeeded called")
        
        if #available(iOS 17.0, *) {
            do {
                let accessWasGranted = try await eventKitStore.requestWriteOnlyAccessToEvents()
                return accessWasGranted
            } catch {
                print("[EventKitManager] Write-only access request failed: \(error.localizedDescription)")
                return false
            }
        } else {
            return await withCheckedContinuation { checkedContinuation in
                eventKitStore.requestAccess(to: .event) { accessGranted, requestError in
                    if let requestError {
                        print("[EventKitManager] Legacy access request failed: \(requestError.localizedDescription)")
                    }
                    checkedContinuation.resume(returning: accessGranted)
                }
            }
        }
    }

    // Creates two recurring calendar events (morning + evening) for an approved passenger.
    // Should be called once a join request is submitted successfully.
    // Returns the count of events successfully saved.
    @discardableResult
    func schedulePassengerTripReminders(
        routeId: String,
        routeDisplayName: String,
        passengerPickupStopName: String,
        morningDepartureTime: Date,
        eveningDepartureTime: Date,
        routeActiveDays: [String]
    ) async -> Int {

        let calendarAccessGranted = await requestCalendarWriteAccessIfNeeded()
        guard calendarAccessGranted else {
            print("[EventKitManager] Calendar access denied — passenger trip reminders not scheduled")
            return 0
        }

        let recurrenceWeekdayList = routeActiveDays.compactMap { convertDayStringToEKWeekday($0) }
            .map { EKRecurrenceDayOfWeek($0) }

        guard !recurrenceWeekdayList.isEmpty else {
            print("[EventKitManager] No valid active days found — aborting passenger event creation")
            return 0
        }

        var totalEventsSaved = 0

        // Morning session event
        let morningEventIdentifier = createAndSavePassengerCalendarEvent(
            eventTitle: "StaffLanka Go — \(routeDisplayName) (Morning)",
            pickupStopLocation: passengerPickupStopName,
            eventStartDate: morningDepartureTime,
            estimatedTripDurationMinutes: 60,
            alarmOffsetMinutesBeforeStart: -30,
            recurrenceWeekdays: recurrenceWeekdayList,
            eventNotes: "Morning pickup at \(passengerPickupStopName). Be ready at least 5 minutes before departure."
        )
        if morningEventIdentifier != nil { totalEventsSaved += 1 }

        // Evening session event
        let eveningEventIdentifier = createAndSavePassengerCalendarEvent(
            eventTitle: "StaffLanka Go — \(routeDisplayName) (Evening)",
            pickupStopLocation: passengerPickupStopName,
            eventStartDate: eveningDepartureTime,
            estimatedTripDurationMinutes: 60,
            alarmOffsetMinutesBeforeStart: -30,
            recurrenceWeekdays: recurrenceWeekdayList,
            eventNotes: "Evening pickup at \(passengerPickupStopName). Be ready at least 5 minutes before departure."
        )
        if eveningEventIdentifier != nil { totalEventsSaved += 1 }

        // Persist both identifiers so they can be removed later if needed
        if let morningIdentifier = morningEventIdentifier {
            UserDefaults.standard.set([morningIdentifier], forKey: "stafflanka_eventkit_\(routeId)_morning")
        }
        if let eveningIdentifier = eveningEventIdentifier {
            UserDefaults.standard.set([eveningIdentifier], forKey: "stafflanka_eventkit_\(routeId)_evening")
        }

        print("[EventKitManager] Passenger trip reminders saved: \(totalEventsSaved) event(s)")
        return totalEventsSaved
    }

    // Creates two recurring calendar events (morning + evening) for a newly onboarded driver.
    // Should be called at the end of submitOnboarding() in DriverRouteScheduleViewModel.
    // Returns the count of events successfully saved.
    @discardableResult
    func scheduleDriverOperatingDayReminders(
        routeStartLocationName: String,
        routeEndLocationName: String,
        morningDepartureTime: Date,
        morningEstimatedArrivalTime: Date,
        eveningDepartureTime: Date,
        eveningEstimatedArrivalTime: Date,
        routeActiveDays: [String]
    ) async -> Int {

        let calendarAccessGranted = await requestCalendarWriteAccessIfNeeded()
        guard calendarAccessGranted else {
            print("[EventKitManager] Calendar access denied — driver operating reminders not scheduled")
            return 0
        }

        let recurrenceWeekdayList = routeActiveDays.compactMap { convertDayStringToEKWeekday($0) }
            .map { EKRecurrenceDayOfWeek($0) }

        guard !recurrenceWeekdayList.isEmpty else {
            print("[EventKitManager] No valid active days found — aborting driver event creation")
            return 0
        }

        let routeDisplayLabel = "\(routeStartLocationName) → \(routeEndLocationName)"
        var totalEventsSaved = 0

        // Morning operating day event
        let morningEventIdentifier = createAndSaveDriverCalendarEvent(
            eventTitle: "StaffLanka Go Route — \(routeDisplayLabel) (Morning)",
            eventStartDate: morningDepartureTime,
            eventEndDate: morningEstimatedArrivalTime,
            alarmOffsetMinutesBeforeStart: -60,
            recurrenceWeekdays: recurrenceWeekdayList,
            eventNotes: "Morning operating day. Depart from \(routeStartLocationName) on schedule."
        )
        if morningEventIdentifier != nil { totalEventsSaved += 1 }

        // Evening operating day event
        let eveningEventIdentifier = createAndSaveDriverCalendarEvent(
            eventTitle: "StaffLanka Go Route — \(routeDisplayLabel) (Evening)",
            eventStartDate: eveningDepartureTime,
            eventEndDate: eveningEstimatedArrivalTime,
            alarmOffsetMinutesBeforeStart: -60,
            recurrenceWeekdays: recurrenceWeekdayList,
            eventNotes: "Evening operating day. Return trip from \(routeEndLocationName) on schedule."
        )
        if eveningEventIdentifier != nil { totalEventsSaved += 1 }

        let newIdentifiers = [morningEventIdentifier, eveningEventIdentifier].compactMap { $0 }
        appendIdentifiersToUserDefaults(newEventIdentifiers: newIdentifiers)

        print("[EventKitManager] Driver operating day reminders saved: \(totalEventsSaved) event(s)")
        return totalEventsSaved
    }

    // Removes all StaffLanka Go calendar events that were previously saved by this app.
    // Used when the user logs out or deletes their account.
    func removeAllStoredStaffLankaCalendarEvents() {
        let storedIdentifiers = loadIdentifiersFromUserDefaults()
        var removalCount = 0
        for savedEventIdentifier in storedIdentifiers {
            if let existingCalendarEvent = eventKitStore.event(withIdentifier: savedEventIdentifier) {
                do {
                    try eventKitStore.remove(existingCalendarEvent, span: .futureEvents)
                    removalCount += 1
                } catch {
                    print("[EventKitManager] Failed to remove event \(savedEventIdentifier): \(error.localizedDescription)")
                }
            }
        }
        UserDefaults.standard.removeObject(forKey: userDefaultsStoredEventIdentifiersKey)
        print("[EventKitManager] Removed \(removalCount) calendar event(s)")
    }

    // Internal helper: builds and saves a passenger calendar event. Returns the event identifier on success.
    private func createAndSavePassengerCalendarEvent(
        eventTitle: String,
        pickupStopLocation: String,
        eventStartDate: Date,
        estimatedTripDurationMinutes: Int,
        alarmOffsetMinutesBeforeStart: Int,
        recurrenceWeekdays: [EKRecurrenceDayOfWeek],
        eventNotes: String
    ) -> String? {

        let calendarEvent = EKEvent(eventStore: eventKitStore)
        calendarEvent.title = eventTitle
        calendarEvent.location = pickupStopLocation
        calendarEvent.notes = eventNotes
        calendarEvent.startDate = eventStartDate
        calendarEvent.endDate = Calendar.current.date(
            byAdding: .minute,
            value: estimatedTripDurationMinutes,
            to: eventStartDate
        ) ?? eventStartDate
        calendarEvent.calendar = eventKitStore.defaultCalendarForNewEvents

        let weeklyRecurrenceRule = EKRecurrenceRule(
            recurrenceWith: .weekly,
            interval: 1,
            daysOfTheWeek: recurrenceWeekdays,
            daysOfTheMonth: nil,
            monthsOfTheYear: nil,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil,
            end: nil
        )
        calendarEvent.recurrenceRules = [weeklyRecurrenceRule]

        let preEventAlarm = EKAlarm(relativeOffset: TimeInterval(alarmOffsetMinutesBeforeStart * 60))
        calendarEvent.addAlarm(preEventAlarm)

        do {
            try eventKitStore.save(calendarEvent, span: .futureEvents)
            return calendarEvent.eventIdentifier
        } catch {
            print("[EventKitManager] Failed to save passenger calendar event '\(eventTitle)': \(error.localizedDescription)")
            return nil
        }
    }

    // Internal helper: builds and saves a driver calendar event. Returns the event identifier on success.
    private func createAndSaveDriverCalendarEvent(
        eventTitle: String,
        eventStartDate: Date,
        eventEndDate: Date,
        alarmOffsetMinutesBeforeStart: Int,
        recurrenceWeekdays: [EKRecurrenceDayOfWeek],
        eventNotes: String
    ) -> String? {

        let calendarEvent = EKEvent(eventStore: eventKitStore)
        calendarEvent.title = eventTitle
        calendarEvent.notes = eventNotes
        calendarEvent.startDate = eventStartDate
        calendarEvent.endDate = eventEndDate
        calendarEvent.calendar = eventKitStore.defaultCalendarForNewEvents

        let weeklyRecurrenceRule = EKRecurrenceRule(
            recurrenceWith: .weekly,
            interval: 1,
            daysOfTheWeek: recurrenceWeekdays,
            daysOfTheMonth: nil,
            monthsOfTheYear: nil,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil,
            end: nil
        )
        calendarEvent.recurrenceRules = [weeklyRecurrenceRule]

        let preEventAlarm = EKAlarm(relativeOffset: TimeInterval(alarmOffsetMinutesBeforeStart * 60))
        calendarEvent.addAlarm(preEventAlarm)

        do {
            try eventKitStore.save(calendarEvent, span: .futureEvents)
            return calendarEvent.eventIdentifier
        } catch {
            print("[EventKitManager] Failed to save driver calendar event '\(eventTitle)': \(error.localizedDescription)")
            return nil
        }
    }

    // Maps the app's day abbreviation strings to EKWeekday values
    private func convertDayStringToEKWeekday(_ dayAbbreviationString: String) -> EKWeekday? {
        switch dayAbbreviationString {
        case "Mon": return .monday
        case "Tue": return .tuesday
        case "Wed": return .wednesday
        case "Thu": return .thursday
        case "Fri": return .friday
        case "Sat": return .saturday
        case "Sun": return .sunday
        default:
            print("[EventKitManager] Unrecognised day string '\(dayAbbreviationString)' — skipping")
            return nil
        }
    }

    // Appends new event identifiers into UserDefaults for later cleanup
    private func appendIdentifiersToUserDefaults(newEventIdentifiers: [String]) {
        var existingIdentifiers = loadIdentifiersFromUserDefaults()
        existingIdentifiers.append(contentsOf: newEventIdentifiers)
        UserDefaults.standard.set(existingIdentifiers, forKey: userDefaultsStoredEventIdentifiersKey)
    }

    // Loads all previously stored event identifiers from UserDefaults
    private func loadIdentifiersFromUserDefaults() -> [String] {
        return UserDefaults.standard.stringArray(forKey: userDefaultsStoredEventIdentifiersKey) ?? []
    }
    
    //Remove calendar event
    func removeCalendarEventsForRoute(routeId: String, sessionLabel: String) {
        let morningStorageKey = "stafflanka_eventkit_\(routeId)_morning"
        let eveningStorageKey = "stafflanka_eventkit_\(routeId)_evening"

        switch sessionLabel {
        case "Morning":
            removeEventsForStorageKey(morningStorageKey)
        case "Evening":
            removeEventsForStorageKey(eveningStorageKey)
        default:
            removeEventsForStorageKey(morningStorageKey)
            removeEventsForStorageKey(eveningStorageKey)
        }
    }

    private func removeEventsForStorageKey(_ storageKey: String) {
        let storedIdentifiers = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
        for savedEventIdentifier in storedIdentifiers {
            if let existingCalendarEvent = eventKitStore.event(withIdentifier: savedEventIdentifier) {
                try? eventKitStore.remove(existingCalendarEvent, span: .futureEvents)
            }
        }
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
