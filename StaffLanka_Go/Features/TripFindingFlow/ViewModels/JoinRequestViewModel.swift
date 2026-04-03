//
//  JoinRequestViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-03.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class JoinRequestViewModel: ObservableObject {

    enum TripSession: String, CaseIterable {
        case morning = "Morning"
        case evening = "Evening"
        case both    = "Both"
    }

    @Published var selectedPickup: String
    @Published var selectedDestination: String
    @Published var selectedSession: TripSession = .both
    @Published var phone: String = ""
    @Published var name: String = ""
    @Published var note: String = ""
    @Published var isSubmitted: Bool = false
    @Published var showPickupPicker: Bool = false
    @Published var showDestinationPicker: Bool = false

    let routeName: String

    //added a few samples for the UI
    let stops: [String] = [
        "Colombo Fort", "Pettah Bus Stand", "Maradana", "Borella",
        "Nugegoda", "Maharagama", "Battaramulla", "Rajagiriya",
        "Kottawa", "Kaduwela", "Malabe", "Athurugiriya"
    ]

    init(pickupLocation: String, destinationLocation: String, routeName: String) {
        self.selectedPickup = pickupLocation
        self.selectedDestination = destinationLocation
        self.routeName = routeName
    }

    var canSubmit: Bool {
        !phone.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedPickup.isEmpty &&
        !selectedDestination.isEmpty
    }

    func submitRequest() {
        guard canSubmit else { return }
        withAnimation(.spring(response: 0.4)) {
            isSubmitted = true
        }
    }
}
