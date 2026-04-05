//
//  SentRequestsViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import SwiftUI
import Combine

enum RequestStatus: String {
    case pending  = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
}

struct SentRequest: Identifiable {
    let id = UUID()
    let routeName: String
    let routeStart: String
    let routeEnd: String
    let driverName: String
    let pickupLocation: String
    let dropoffLocation: String
    let session: String
    let date: Date
    var status: RequestStatus
}

extension SentRequest {
    static let mockData: [SentRequest] = [
        SentRequest(
            routeName: "Kottawa → Colombo Fort",
            routeStart: "Kottawa", routeEnd: "Colombo Fort",
            driverName: "Kamal Perera",
            pickupLocation: "Kottawa Junction",
            dropoffLocation: "Colombo Fort",
            session: "Morning & Evening",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            status: .pending
        ),
        SentRequest(
            routeName: "Maharagama → Colombo Fort",
            routeStart: "Maharagama", routeEnd: "Colombo Fort",
            driverName: "Nimal Silva",
            pickupLocation: "Maharagama Town",
            dropoffLocation: "Union Place",
            session: "Morning Only",
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            status: .approved
        ),
        SentRequest(
            routeName: "Nugegoda → Colombo Fort",
            routeStart: "Nugegoda", routeEnd: "Colombo Fort",
            driverName: "Suresh Fernando",
            pickupLocation: "Nugegoda Junction",
            dropoffLocation: "Town Hall",
            session: "Evening Only",
            date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            status: .rejected
        ),
        SentRequest(
            routeName: "Battaramulla → Colombo Fort",
            routeStart: "Battaramulla", routeEnd: "Colombo Fort",
            driverName: "Rohan Perera",
            pickupLocation: "Battaramulla Stand",
            dropoffLocation: "Fort",
            session: "Morning Only",
            date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
            status: .approved
        )
    ]
}

@MainActor
final class SentRequestsViewModel: ObservableObject {
    @Published var requests: [SentRequest] = SentRequest.mockData
    @Published var selectedFilter: FilterOption = .all
    @Published var sortDescending: Bool = true

    enum FilterOption: String, CaseIterable {
        case all      = "All"
        case pending  = "Pending"
        case approved = "Approved"
        case rejected = "Rejected"
    }

    var filteredRequests: [SentRequest] {
        let filtered: [SentRequest]
        switch selectedFilter {
        case .all:      filtered = requests
        case .pending:  filtered = requests.filter { $0.status == .pending }
        case .approved: filtered = requests.filter { $0.status == .approved }
        case .rejected: filtered = requests.filter { $0.status == .rejected }
        }
        return filtered.sorted { sortDescending ? $0.date > $1.date : $0.date < $1.date }
    }

    var groupedRequests: [(String, [SentRequest])] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        var requestDictionary: [String: [SentRequest]] = [:]
        for request in filteredRequests {
            let key: String
            if Calendar.current.isDateInToday(request.date) {
                key = "Today"
            } else if Calendar.current.isDateInYesterday(request.date) {
                key = "Yesterday"
            } else {
                key = dateFormatter.string(from: request.date)
            }
            requestDictionary[key, default: []].append(request)
        }
        return requestDictionary.sorted { a, b in
            guard let dateA = a.value.first?.date, let dateB = b.value.first?.date else { return false }
            return sortDescending ? dateA > dateB : dateA < dateB
        }
    }

    func toggleSort() {
        sortDescending.toggle()
    }

    func statusColor(for status: RequestStatus) -> Color {
        switch status {
        case .pending:  return Color.statusWarning
        case .approved: return Color.statusActive
        case .rejected: return Color.statusDanger
        }
    }

    func statusIcon(for status: RequestStatus) -> String {
        switch status {
        case .pending:  return "clock.fill"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }
}
