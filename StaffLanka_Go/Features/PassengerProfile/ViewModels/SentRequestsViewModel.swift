//
//  SentRequestsViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-05.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

enum RequestStatus: String {
    case pending  = "Pending"
    case accepted = "Accepted"
    case rejected = "Rejected"
    case cancelled = "Cancelled"
}

struct SentRequest: Identifiable {
    let id: String
    let routeName: String
    let routeStart: String
    let routeEnd: String
    let driverName: String
    let pickupLocation: String
    let dropoffLocation: String
    let session: String
    let submittedDate: Date
    var status: RequestStatus
}

@MainActor
final class SentRequestsViewModel: ObservableObject {

    @Published var allLoadedRequests: [SentRequest] = []
    @Published var selectedFilter: FilterOption = .all
    @Published var sortDescending: Bool = true
    @Published var isLoadingRequests: Bool = false
    @Published var loadErrorMessage: String? = nil

    enum FilterOption: String, CaseIterable {
        case all       = "All"
        case pending   = "Pending"
        case accepted  = "Accepted"
        case rejected  = "Rejected"
        case cancelled = "Cancelled"
    }

    // nonisolated storage so deinit can safely remove the Firestore listener
    nonisolated(unsafe) private var firestoreListenerRegistration: ListenerRegistration?

    deinit {
        firestoreListenerRegistration?.remove()
    }

    var filteredAndSortedRequests: [SentRequest] {
        let filteredRequests: [SentRequest]
        switch selectedFilter {
        case .all:       filteredRequests = allLoadedRequests
        case .pending:   filteredRequests = allLoadedRequests.filter { $0.status == .pending }
        case .accepted:  filteredRequests = allLoadedRequests.filter { $0.status == .accepted }
        case .rejected:  filteredRequests = allLoadedRequests.filter { $0.status == .rejected }
        case .cancelled: filteredRequests = allLoadedRequests.filter { $0.status == .cancelled }
        }
        return filteredRequests.sorted { sortDescending ? $0.submittedDate > $1.submittedDate : $0.submittedDate < $1.submittedDate }
    }

    // Groups the filtered requests by date label (Today / Yesterday / formatted date)
    var groupedRequests: [(String, [SentRequest])] {
        let abbreviatedDateFormatter = DateFormatter()
        abbreviatedDateFormatter.dateStyle = .medium

        var requestDictionary: [String: [SentRequest]] = [:]
        for request in filteredAndSortedRequests {
            let groupKey: String
            if Calendar.current.isDateInToday(request.submittedDate) {
                groupKey = "Today"
            } else if Calendar.current.isDateInYesterday(request.submittedDate) {
                groupKey = "Yesterday"
            } else {
                groupKey = abbreviatedDateFormatter.string(from: request.submittedDate)
            }
            requestDictionary[groupKey, default: []].append(request)
        }
        return requestDictionary.sorted { firstGroup, secondGroup in
            guard let firstDate = firstGroup.value.first?.submittedDate,
                  let secondDate = secondGroup.value.first?.submittedDate else { return false }
            return sortDescending ? firstDate > secondDate : firstDate < secondDate
        }
    }

    func toggleSort() {
        sortDescending.toggle()
    }

    // Starts a real-time Firestore listener for all join requests submitted by the current user
    func startListeningForUserRequests() {
        guard let currentPassengerId = Auth.auth().currentUser?.uid else {
            print("[SentRequestsVM] No authenticated user — cannot load sent requests")
            return
        }

        isLoadingRequests = true
        firestoreListenerRegistration?.remove()

        firestoreListenerRegistration = Firestore.firestore()
            .collection("joinRequests")
            .whereField("passengerId", isEqualTo: currentPassengerId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, listenerError in
                guard let self else { return }
                if let listenerError {
                    print("[SentRequestsVM] Listener error: \(listenerError.localizedDescription)")
                    Task { @MainActor in
                        self.loadErrorMessage = "Could not load requests. Please try again."
                        self.isLoadingRequests = false
                    }
                    return
                }
                guard let snapshotDocuments = snapshot?.documents else { return }

                Task {
                    await self.buildRequestModels(fromDocuments: snapshotDocuments)
                }
            }
    }

    // Builds SentRequest models from Firestore documents, fetching route/driver names as needed
    private func buildRequestModels(fromDocuments documents: [QueryDocumentSnapshot]) async {
        var builtRequests: [SentRequest] = []

        for document in documents {
            let documentData = document.data()
            let documentId = document.documentID

            let routeId        = documentData["routeId"]      as? String ?? ""
            let driverId       = documentData["driverId"]     as? String ?? ""
            let pickupStop     = documentData["pickupStop"]   as? String ?? ""
            let dropoffStop    = documentData["dropoffStop"]  as? String ?? ""
            let sessionString  = documentData["session"]      as? String ?? "Both"
            let statusString   = documentData["status"]       as? String ?? "pending"

            // createdAt is stored as a Firestore Timestamp
            let submittedDate: Date
            if let firestoreTimestamp = documentData["createdAt"] as? Timestamp {
                submittedDate = firestoreTimestamp.dateValue()
            } else {
                submittedDate = Date()
            }

            let mappedStatus: RequestStatus
            switch statusString {
            case "accepted":  mappedStatus = .accepted
            case "rejected":  mappedStatus = .rejected
            case "cancelled": mappedStatus = .cancelled
            default:          mappedStatus = .pending
            }

            // Fetch route details to get start and end location names
            var routeStartName = "Unknown"
            var routeEndName   = "Unknown"
            if !routeId.isEmpty,
               let fetchedRoute = try? await RouteService.shared.fetchRoute(routeId: routeId) {
                routeStartName = fetchedRoute.startLocation.locationName
                routeEndName   = fetchedRoute.endLocation.locationName
            }

            // Fetch driver details to get the driver name
            var driverDisplayName = "Driver"
            if !driverId.isEmpty,
               let fetchedDriver = try? await DriverService.shared.fetchDriver(driverId: driverId) {
                driverDisplayName = fetchedDriver.fullName
            }

            let builtRequest = SentRequest(
                id:               documentId,
                routeName:        "\(routeStartName) → \(routeEndName)",
                routeStart:       routeStartName,
                routeEnd:         routeEndName,
                driverName:       driverDisplayName,
                pickupLocation:   pickupStop,
                dropoffLocation:  dropoffStop,
                session:          sessionString,
                submittedDate:    submittedDate,
                status:           mappedStatus
            )
            builtRequests.append(builtRequest)
        }

        self.allLoadedRequests = builtRequests
        self.isLoadingRequests = false
        print("[SentRequestsVM] Loaded \(builtRequests.count) request(s) for current user")
    }

    func statusColor(for status: RequestStatus) -> Color {
        switch status {
        case .pending:   return Color.statusWarning
        case .accepted:  return Color.statusActive
        case .rejected:  return Color.statusDanger
        case .cancelled: return Color.statusInactive
        }
    }

    func statusIcon(for status: RequestStatus) -> String {
        switch status {
        case .pending:   return "clock.fill"
        case .accepted:  return "checkmark.circle.fill"
        case .rejected:  return "xmark.circle.fill"
        case .cancelled: return "minus.circle.fill"
        }
    }
}
