//
//  DriverBusInfoViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-07.
//

import Foundation
import Combine

enum BusType: String, CaseIterable, Identifiable {
    case miniBus  = "Mini Bus"
    case van      = "Van"
    case largeBus = "Large Bus"
    var id: String { rawValue }
}

@MainActor
final class DriverBusInfoViewModel: ObservableObject {
    @Published var plateNumber: String = ""
    @Published var busName: String = ""
    @Published var busType: BusType = .miniBus
    @Published var capacity: String = ""

    var isPlateValid: Bool {
        plateNumber.trimmingCharacters(in: .whitespaces).count >= 4
    }

    var isCapacityValid: Bool {
        guard let val = Int(capacity) else { return false }
        return val > 0 && val <= 100
    }

    var canContinue: Bool {
        isPlateValid && isCapacityValid
    }
}
