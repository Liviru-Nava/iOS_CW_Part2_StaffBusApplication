//
//  PassengerDashboardViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-01.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class PassengerDashboardViewModel: ObservableObject {

    @Published var userName: String = "New User"
    @Published var selectedTrip: TripTab = .morning
    @Published var hasMorningService: Bool = false
    @Published var hasEveningService: Bool = false
    @Published var pickupLocation: String = ""
    @Published var dropoffLocation: String = ""

    enum TripTab {
        case morning, evening
    }

    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var noServiceTitle: String {
        selectedTrip == .morning ? "No Morning Service" : "No Evening Service"
    }

    var noServiceSubtitle: String {
        selectedTrip == .morning
            ? "No active bus service registered for your morning commute"
            : "No active bus service registered for your evening commute"
    }

    var findRouteTitle: String {
        selectedTrip == .morning ? "Find a Morning Route" : "Find an Evening Route"
    }

    var activeService: Bool {
        selectedTrip == .morning ? hasMorningService : hasEveningService
    }

    func searchRoutes() {
    }
}
