//
//  TripTrackingViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-06.
//

import Foundation
import MapKit
import FirebaseFirestore
import Combine
import SwiftUI

@MainActor
final class TripTrackingViewModel: ObservableObject {

    @Published var driverCoordinate: CLLocationCoordinate2D? = nil
    @Published var locationUpdatedAt: Date? = nil
    @Published var tripCompleted: Bool = false
    @Published var cameraPosition: MapCameraPosition = .automatic

    private let tripId: String
    nonisolated(unsafe) private var listener: ListenerRegistration?

    init(tripId: String) {
        self.tripId = tripId
    }

    deinit { listener?.remove() }

    func startListening() {
        listener?.remove()
        listener = TripService.shared.listenToTrip(tripId: tripId) { [weak self] trip in
            guard let self, let trip else { return }
            Task { @MainActor in
                if let coord = trip.driverCoordinate {
                    self.driverCoordinate = coord
                    self.cameraPosition = .region(
                        MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        )
                    )
                }
                self.locationUpdatedAt = trip.locationUpdatedAt
                self.tripCompleted = trip.status == "completed"
            }
        }
    }
}
