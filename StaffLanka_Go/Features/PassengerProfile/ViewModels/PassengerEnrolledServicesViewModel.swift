//
//  PassengerEnrolledServicesViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import SwiftUI
import Combine

enum EnrolledSessionType {
    case morning
    case evening
    case both
}

struct EnrolledSessionInfo {
    let startTime: String
    let endTime: String
    let driverName: String
    let vehicleBrand: String
    let vehicleType: String
    let licensePlate: String
}

struct EnrolledService: Identifiable {
    let id = UUID()
    let routeName: String
    let routeStart: String
    let routeEnd: String
    let session: EnrolledSessionType
    let morning: EnrolledSessionInfo?
    let evening: EnrolledSessionInfo?
    let monthlyFee: Double
    var isActive: Bool
    var cancelledDate: Date? = nil
}

extension EnrolledService {
    static let mockActive: [EnrolledService] = [
        EnrolledService(
            routeName: "Kottawa → Colombo Fort",
            routeStart: "Kottawa",
            routeEnd: "Colombo Fort",
            session: .both,
            morning: EnrolledSessionInfo(
                startTime: "6:15 AM", endTime: "7:45 AM",
                driverName: "Kamal Perera",
                vehicleBrand: "Toyota", vehicleType: "Bus",
                licensePlate: "ND-4029"
            ),
            evening: EnrolledSessionInfo(
                startTime: "5:30 PM", endTime: "7:00 PM",
                driverName: "Kamal Perera",
                vehicleBrand: "Toyota", vehicleType: "Bus",
                licensePlate: "ND-4029"
            ),
            monthlyFee: 5000.0,
            isActive: true
        )
    ]

    static let mockPast: [EnrolledService] = [
        EnrolledService(
            routeName: "Maharagama → Colombo Fort",
            routeStart: "Maharagama",
            routeEnd: "Colombo Fort",
            session: .morning,
            morning: EnrolledSessionInfo(
                startTime: "6:45 AM", endTime: "8:15 AM",
                driverName: "Nimal Silva",
                vehicleBrand: "Ashok Leyland", vehicleType: "Bus",
                licensePlate: "NC-1029"
            ),
            evening: nil,
            monthlyFee: 4500.0,
            isActive: false,
            cancelledDate: Calendar.current.date(byAdding: .month, value: -2, to: Date())
        ),
        EnrolledService(
            routeName: "Nugegoda → Colombo Fort",
            routeStart: "Nugegoda",
            routeEnd: "Colombo Fort",
            session: .evening,
            morning: nil,
            evening: EnrolledSessionInfo(
                startTime: "5:00 PM", endTime: "6:30 PM",
                driverName: "Suresh Fernando",
                vehicleBrand: "Toyota", vehicleType: "Van",
                licensePlate: "WP-9812"
            ),
            monthlyFee: 3800.0,
            isActive: false,
            cancelledDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())
        )
    ]
}

@MainActor
final class PassengerEnrolledServicesViewModel: ObservableObject {
    @Published var activeServices: [EnrolledService] = EnrolledService.mockActive
    @Published var pastServices: [EnrolledService] = EnrolledService.mockPast
    @Published var showingPast: Bool = false
    @Published var serviceToCancel: EnrolledService? = nil
    @Published var sessionToCancel: EnrolledSessionType? = nil
    @Published var showCancelAlert: Bool = false
    @Published var showCancelOptions: Bool = false

    var hasMorningActive: Bool {
        activeServices.contains { $0.session == .morning || $0.session == .both }
    }

    var hasEveningActive: Bool {
        activeServices.contains { $0.session == .evening || $0.session == .both }
    }

    func sessionLabel(_ session: EnrolledSessionType) -> String {
        switch session {
        case .morning: return "Morning Only"
        case .evening: return "Evening Only"
        case .both:    return "Morning & Evening"
        }
    }

    func cancelAlertMessage() -> String {
        guard let service = serviceToCancel else { return "" }
        switch sessionToCancel {
        case .morning:
            return "Cancel your morning enrollment for \(service.routeName)? This cannot be undone."
        case .evening:
            return "Cancel your evening enrollment for \(service.routeName)? This cannot be undone."
        default:
            return "Cancel your entire enrollment for \(service.routeName)? This cannot be undone."
        }
    }

    func requestCancel(service: EnrolledService, session: EnrolledSessionType) {
        serviceToCancel = service
        sessionToCancel = session
        showCancelAlert = true
    }

    func requestCancelOptions(service: EnrolledService) {
        serviceToCancel = service
        showCancelOptions = true
    }

    func handleCancelChoice(_ session: EnrolledSessionType) {
        sessionToCancel = session
        handleCancel()
    }

    func handleCancel() {
        guard let service = serviceToCancel,
              let index = activeServices.firstIndex(where: { $0.id == service.id }) else { return }

        switch sessionToCancel {
        case .morning where service.evening != nil:
            activeServices[index] = EnrolledService(
                routeName: service.routeName, routeStart: service.routeStart, routeEnd: service.routeEnd,
                session: .evening, morning: nil, evening: service.evening,
                monthlyFee: service.monthlyFee, isActive: true
            )
            pastServices.insert(EnrolledService(
                routeName: service.routeName, routeStart: service.routeStart, routeEnd: service.routeEnd,
                session: .morning, morning: service.morning, evening: nil,
                monthlyFee: service.monthlyFee, isActive: false, cancelledDate: Date()
            ), at: 0)

        case .evening where service.morning != nil:
            activeServices[index] = EnrolledService(
                routeName: service.routeName, routeStart: service.routeStart, routeEnd: service.routeEnd,
                session: .morning, morning: service.morning, evening: nil,
                monthlyFee: service.monthlyFee, isActive: true
            )
            pastServices.insert(EnrolledService(
                routeName: service.routeName, routeStart: service.routeStart, routeEnd: service.routeEnd,
                session: .evening, morning: nil, evening: service.evening,
                monthlyFee: service.monthlyFee, isActive: false, cancelledDate: Date()
            ), at: 0)

        default:
            activeServices.remove(at: index)
            pastServices.insert(EnrolledService(
                routeName: service.routeName, routeStart: service.routeStart, routeEnd: service.routeEnd,
                session: service.session, morning: service.morning, evening: service.evening,
                monthlyFee: service.monthlyFee, isActive: false, cancelledDate: Date()
            ), at: 0)
        }

        serviceToCancel = nil
        sessionToCancel = nil
        showCancelAlert = false
        showCancelOptions = false
    }
}
