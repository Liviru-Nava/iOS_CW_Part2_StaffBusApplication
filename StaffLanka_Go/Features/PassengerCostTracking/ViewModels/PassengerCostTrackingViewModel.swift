//
//  PassengerCostTrackingViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import Combine
import Foundation
import SwiftUI


enum TripSession: String, CaseIterable, Identifiable {
    case morning = "Morning"
    case evening = "Evening"
    case both = "Both"
    var id: String {rawValue}
}

enum paymentStatus{
    case paid, unpaid, pending
}

struct ServiceRegistration: Identifiable {
    let id: UUID
    let routeName: String
    let pickup: String
    let destination: String
    let session: TripSession
    let monthlyFee: Double
    let daysElapsed: Int
    let totalDays: Int
    let currentMonthPaid: Bool
    let amountThisMonth: Double
}

struct MonthlyRecord: Identifiable {
    let id: UUID
    let monthLabel: String
    let monthDate: Date
    let routeName: String
    let pickup: String
    let destination: String
    let session: TripSession
    let amount: Double
    let isPaid: Bool
    let isGracePeriod: Bool
}

@MainActor
final class PassengerCostTrackingViewModel: ObservableObject {
    @Published var service: ServiceRegistration? = ServiceRegistration.mock
    @Published var monthlyRecords: [MonthlyRecord] = MonthlyRecord.mockHistory
    @Published var sessionFilter: TripSession? = nil
    @Published var sortByAmount: Bool = false
    @Published var showUnpaidOnly: Bool = false
    @Published var showPaymentSheet: Bool = false
    @Published var selectedRecord: MonthlyRecord? = nil
    @Published var payingCurrentMonth: Bool = false

    var hasService: Bool { service != nil }

    var filteredRecords: [MonthlyRecord] {
        var records = monthlyRecords
        if let filter = sessionFilter {
            records = records.filter { $0.session == filter }
        }
        if showUnpaidOnly {
            records = records.filter { !$0.isPaid }
        }
        if sortByAmount {
            records = records.sorted { $0.amount > $1.amount }
        }
        return records
    }

    func initiateCurrentMonthPayment() {
        payingCurrentMonth = true
        showPaymentSheet = true
    }

    func initiateRecordPayment(_ record: MonthlyRecord) {
        selectedRecord = record
        payingCurrentMonth = false
        showPaymentSheet = true
    }

    func confirmPayment() {
        showPaymentSheet = false
        selectedRecord = nil
        payingCurrentMonth = false
    }
}


extension ServiceRegistration {
    static let mock = ServiceRegistration(
        id: UUID(),
        routeName: "Colombo – Kandy Express",
        pickup: "Kadawatha Junction",
        destination: "Kandy City Bus Stand",
        session: .both,
        monthlyFee: 4800,
        daysElapsed: 18,
        totalDays: 30,
        currentMonthPaid: false,
        amountThisMonth: 2880
    )
}

extension MonthlyRecord {
    static let mockHistory: [MonthlyRecord] = {
        let cal = Calendar.current
        let now = Date()
        let sessions: [TripSession] = [.both, .morning, .evening, .both, .morning, .evening]
        let amounts: [Double]       = [4800, 4400, 4200, 4800, 4600, 4400]
        let routes  = Array(repeating: "Colombo – Kandy Express", count: 6)
        let pickups = Array(repeating: "Kadawatha Junction", count: 6)
        let drops   = Array(repeating: "Kandy City Bus Stand", count: 6)

        return (1...6).map { offset in
            let date = cal.date(byAdding: .month, value: -offset, to: now)!
            let isLastMonth = offset == 1
            let isPaid = isLastMonth ? false : true
            let isGrace = isLastMonth && !isPaid
            return MonthlyRecord(
                id: UUID(),
                monthLabel: date.formatted(.dateTime.month(.wide).year()),
                monthDate: date,
                routeName: routes[offset - 1],
                pickup: pickups[offset - 1],
                destination: drops[offset - 1],
                session: sessions[offset - 1],
                amount: amounts[offset - 1],
                isPaid: isPaid,
                isGracePeriod: isGrace
            )
        }
    }()
}
