//
//  TripHistoryStore.swift
//  StaffLanka_Go
//

import Foundation
import Combine

final class TripHistoryStore: ObservableObject {

    static let shared = TripHistoryStore()

    @Published var completedTripRecords: [DriverHistoryTripRecord] = []

    private init() {}

    func appendCompletedTrip(_ newTripRecord: DriverHistoryTripRecord) {
        completedTripRecords.insert(newTripRecord, at: 0)
    }
}
