//
//  DriverEarningsViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class DriverEarningsViewModel: ObservableObject {

    enum PaymentDeadlineStatusType {
        case paid, gracePeriodActive, overdue
    }

    struct PassengerPaymentRecord: Identifiable {
        let id = UUID()
        let passengerFullName: String
        let boardingStopName: String
        let routeServiceType: TripSession
        let monthlyFeeAmount: Int
        let hasPassengerPaid: Bool
    }

    struct MonthlyEarningsSummary {
        let monthDisplayLabel: String
        let totalEarningsAmount: Int
        let totalCollectedAmount: Int
        let totalPendingAmount: Int
        let passengerPaymentRecords: [PassengerPaymentRecord]
        let paymentDeadlineDisplayText: String
        let gracePeriodDisplayText: String
        let currentDeadlineStatusType: PaymentDeadlineStatusType
    }

    private let aprilEarningsSummary = MonthlyEarningsSummary(
        monthDisplayLabel: "April 2026",
        totalEarningsAmount: 210_000,
        totalCollectedAmount: 160_000,
        totalPendingAmount: 50_000,
        passengerPaymentRecords: [
            PassengerPaymentRecord(passengerFullName: "Amali Fernando", boardingStopName: "Nugegoda Junction", routeServiceType: .both, monthlyFeeAmount: 14_000, hasPassengerPaid: true),
            PassengerPaymentRecord(passengerFullName: "Ruwan Perera", boardingStopName: "Maharagama Town", routeServiceType: .morning, monthlyFeeAmount: 8_500, hasPassengerPaid: true),
            PassengerPaymentRecord(passengerFullName: "Nimal Silva", boardingStopName: "Borella", routeServiceType: .both, monthlyFeeAmount: 14_000, hasPassengerPaid: false),
            PassengerPaymentRecord(passengerFullName: "Kalyani Jayawardena", boardingStopName: "Borella", routeServiceType: .evening, monthlyFeeAmount: 8_500, hasPassengerPaid: true),
            PassengerPaymentRecord(passengerFullName: "Thilak Rajapaksa", boardingStopName: "Nugegoda Junction", routeServiceType: .morning, monthlyFeeAmount: 8_500, hasPassengerPaid: false),
            PassengerPaymentRecord(passengerFullName: "Saman Bandara", boardingStopName: "Maharagama Town", routeServiceType: .both, monthlyFeeAmount: 14_000, hasPassengerPaid: true),
            PassengerPaymentRecord(passengerFullName: "Dilrukshi Wijesinghe", boardingStopName: "Borella", routeServiceType: .morning, monthlyFeeAmount: 8_500, hasPassengerPaid: true),
            PassengerPaymentRecord(passengerFullName: "Prasad Gunasekara", boardingStopName: "Nugegoda Junction", routeServiceType: .both, monthlyFeeAmount: 14_000, hasPassengerPaid: false),
            PassengerPaymentRecord(passengerFullName: "Iresha Dissanayake", boardingStopName: "Maharagama Town", routeServiceType: .evening, monthlyFeeAmount: 8_500, hasPassengerPaid: false),
            PassengerPaymentRecord(passengerFullName: "Chamara Liyanage", boardingStopName: "Borella", routeServiceType: .both, monthlyFeeAmount: 14_000, hasPassengerPaid: false),
            PassengerPaymentRecord(passengerFullName: "Madhavi Rathnayake", boardingStopName: "Nugegoda Junction", routeServiceType: .morning, monthlyFeeAmount: 8_500, hasPassengerPaid: true),
            PassengerPaymentRecord(passengerFullName: "Ajith Kumara", boardingStopName: "Maharagama Town", routeServiceType: .both, monthlyFeeAmount: 14_000, hasPassengerPaid: true),
        ],
        paymentDeadlineDisplayText: "April 30, 2026",
        gracePeriodDisplayText: "Grace period active until May 7, 2026",
        currentDeadlineStatusType: .gracePeriodActive
    )

    private let marchEarningsSummary = MonthlyEarningsSummary(
        monthDisplayLabel: "March 2026",
        totalEarningsAmount: 198_000,
        totalCollectedAmount: 198_000,
        totalPendingAmount: 0,
        passengerPaymentRecords: [
            PassengerPaymentRecord(passengerFullName: "Amali Fernando", boardingStopName: "Nugegoda Junction", routeServiceType: .both, monthlyFeeAmount: 14_000, hasPassengerPaid: true),
            PassengerPaymentRecord(passengerFullName: "Ruwan Perera", boardingStopName: "Maharagama Town", routeServiceType: .morning, monthlyFeeAmount: 8_500, hasPassengerPaid: true),
            PassengerPaymentRecord(passengerFullName: "Nimal Silva", boardingStopName: "Borella", routeServiceType: .both, monthlyFeeAmount: 14_000, hasPassengerPaid: true),
            PassengerPaymentRecord(passengerFullName: "Kalyani Jayawardena", boardingStopName: "Borella", routeServiceType: .evening, monthlyFeeAmount: 8_500, hasPassengerPaid: true),
            PassengerPaymentRecord(passengerFullName: "Thilak Rajapaksa", boardingStopName: "Nugegoda Junction", routeServiceType: .morning, monthlyFeeAmount: 8_500, hasPassengerPaid: true),
        ],
        paymentDeadlineDisplayText: "March 31, 2026",
        gracePeriodDisplayText: "All payments settled",
        currentDeadlineStatusType: .paid
    )

    private let februaryEarningsSummary = MonthlyEarningsSummary(
        monthDisplayLabel: "February 2026",
        totalEarningsAmount: 185_000,
        totalCollectedAmount: 162_000,
        totalPendingAmount: 23_000,
        passengerPaymentRecords: [
            PassengerPaymentRecord(passengerFullName: "Amali Fernando", boardingStopName: "Nugegoda Junction", routeServiceType: .both, monthlyFeeAmount: 14_000, hasPassengerPaid: true),
            PassengerPaymentRecord(passengerFullName: "Ruwan Perera", boardingStopName: "Maharagama Town", routeServiceType: .morning, monthlyFeeAmount: 8_500, hasPassengerPaid: false),
            PassengerPaymentRecord(passengerFullName: "Nimal Silva", boardingStopName: "Borella", routeServiceType: .both, monthlyFeeAmount: 14_000, hasPassengerPaid: false),
            PassengerPaymentRecord(passengerFullName: "Kalyani Jayawardena", boardingStopName: "Borella", routeServiceType: .evening, monthlyFeeAmount: 8_500, hasPassengerPaid: true),
        ],
        paymentDeadlineDisplayText: "February 28, 2026",
        gracePeriodDisplayText: "Overdue – payment deadline has passed",
        currentDeadlineStatusType: .overdue
    )

    @Published var selectedMonthForEarningsDisplay: String = "April 2026"

    let availableMonthDisplayLabels: [String] = ["April 2026", "March 2026", "February 2026"]

    private var currentMonthSummary: MonthlyEarningsSummary {
        switch selectedMonthForEarningsDisplay {
        case "March 2026": return marchEarningsSummary
        case "February 2026": return februaryEarningsSummary
        default: return aprilEarningsSummary
        }
    }

    var totalEarningsForSelectedMonth: Int {
        currentMonthSummary.totalEarningsAmount
    }
    var totalCollectedAmountForSelectedMonth: Int {
        currentMonthSummary.totalCollectedAmount
    }
    var totalPendingAmountForSelectedMonth: Int {
        currentMonthSummary.totalPendingAmount
    }

    var listOfPassengerPaymentStatuses: [PassengerPaymentRecord] {
        currentMonthSummary.passengerPaymentRecords
    }

    var numberOfPaidPassengers: Int {
        currentMonthSummary.passengerPaymentRecords.filter {
            $0.hasPassengerPaid
        }.count
    }
    var numberOfUnpaidPassengers: Int {
        currentMonthSummary.passengerPaymentRecords.filter {
            !$0.hasPassengerPaid
        }.count
    }
    var totalPassengerCount: Int {
        currentMonthSummary.passengerPaymentRecords.count
    }

    var paymentDeadlineDisplayText: String {
        currentMonthSummary.paymentDeadlineDisplayText
    }
    var gracePeriodDisplayText: String {
        currentMonthSummary.gracePeriodDisplayText
    }
    var currentPaymentDeadlineStatusType: PaymentDeadlineStatusType {
        currentMonthSummary.currentDeadlineStatusType
    }

    var morningTripsTotalEarnings: Int {
        currentMonthSummary.passengerPaymentRecords
            .filter { $0.routeServiceType == .morning || $0.routeServiceType == .both }
            .reduce(0) { accumulator, record in
                accumulator + (record.routeServiceType == .both ? 7_000 : record.monthlyFeeAmount)
            }
    }

    var eveningTripsTotalEarnings: Int {
        currentMonthSummary.passengerPaymentRecords
            .filter { $0.routeServiceType == .evening || $0.routeServiceType == .both }
            .reduce(0) { accumulator, record in
                accumulator + (record.routeServiceType == .both ? 7_000 : record.monthlyFeeAmount)
            }
    }

    var bothTripsCombinedEarnings: Int {
        currentMonthSummary.passengerPaymentRecords
            .filter { $0.routeServiceType == .both }
            .reduce(0) { $0 + $1.monthlyFeeAmount }
    }

    func selectMonth(monthLabel: String) {
        selectedMonthForEarningsDisplay = monthLabel
    }
}
