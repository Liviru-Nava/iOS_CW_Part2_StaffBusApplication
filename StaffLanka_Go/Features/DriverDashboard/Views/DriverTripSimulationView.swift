//
//  DriverTripSimulationView.swift
//  StaffLanka_Go
//

import SwiftUI
import MapKit
import CoreLocation

struct DriverTripSimulationView: View {

    let routeId: String
    let driverId: String
    let sessionLabel: String
    let enrolledPassengers: [SimulationEnrolledPassenger]

    @StateObject private var simulationViewModel = DriverTripSimulationViewModel()
    @State private var mapCameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7609, longitude: -122.4213),
            span: MKCoordinateSpan(latitudeDelta: 0.09, longitudeDelta: 0.09)
        )
    )
    @State private var showCompletionOverlay: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            mapLayer
            floatingInstructionsPanel
            floatingPassengerPanel
            if showCompletionOverlay {
                tripCompletionOverlay
            }
        }
        .ignoresSafeArea()
        .onAppear {
            simulationViewModel.startSimulation(
                routeId: routeId,
                driverId: driverId,
                session: sessionLabel,
                passengers: enrolledPassengers
            )
        }
        .onChange(of: simulationViewModel.isSimulationComplete) { _, isComplete in
            if isComplete {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showCompletionOverlay = true
                }
            }
        }
        .onChange(of: LatLon(lat: simulationViewModel.currentBusCoordinate.latitude,
                             lon: simulationViewModel.currentBusCoordinate.longitude)) { _, newLatLon in
            let newCoordinate = CLLocationCoordinate2D(latitude: newLatLon.lat, longitude: newLatLon.lon)
            withAnimation(.easeInOut(duration: 0.35)) {
                mapCameraPosition = .region(
                    MKCoordinateRegion(
                        center: newCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
                    )
                )
            }
        }
    }

    // MARK: - Map layer with bus annotation and all stop pins

    private var mapLayer: some View {
        Map(position: $mapCameraPosition) {

            Annotation("Bus", coordinate: simulationViewModel.currentBusCoordinate) {
                ZStack {
                    Circle()
                        .fill(Color.statusActive.opacity(0.22))
                        .frame(width: 50, height: 50)
                    Image(systemName: "bus.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(width: 36, height: 36)
                        .background(Color.statusActive)
                        .clipShape(Circle())
                }
                .shadow(color: Color.statusActive.opacity(0.5), radius: 6, x: 0, y: 3)
            }

            ForEach(Array(simulationViewModel.allSimulationStops.enumerated()), id: \.element.id) { stopIndex, stop in
                let isFirstStop = stopIndex == 0
                let isLastStop = stopIndex == simulationViewModel.allSimulationStops.count - 1
                let hasBeenVisited = stopIndex <= simulationViewModel.currentActiveStopIndex

                Annotation(stop.stopDisplayName, coordinate: stop.coordinate) {
                    ZStack {
                        Circle()
                            .fill(hasBeenVisited ? Color.statusActive.opacity(0.2) : Color.brandAccent.opacity(0.15))
                            .frame(width: 34, height: 34)
                        if isLastStop {
                            Image(systemName: "flag.checkered.2.crossed")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.statusDanger)
                        } else if isFirstStop {
                            Image(systemName: "figure.stand")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.statusActive)
                        } else {
                            Circle()
                                .fill(hasBeenVisited ? Color.statusActive : Color.brandAccent)
                                .frame(width: 12, height: 12)
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    // MARK: - Floating instructions toggle + panel

    private var floatingInstructionsPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        simulationViewModel.isInstructionsPanelVisible.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: simulationViewModel.isInstructionsPanelVisible ? "eye.slash.fill" : "map.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(simulationViewModel.isInstructionsPanelVisible ? "Hide Directions" : "Show Directions")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.brandAccent)
                    .clipShape(Capsule())
                    .shadow(color: Color.brandAccent.opacity(0.4), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)

            if simulationViewModel.isInstructionsPanelVisible && !simulationViewModel.currentLegInstruction.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.turn.up.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.brandAccent)
                    Text(simulationViewModel.currentLegInstruction)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.brandAccent.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()
        }
    }

    // MARK: - Floating bottom passenger panel

    private var floatingPassengerPanel: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {

                // Drag handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.textTertiary.opacity(0.4))
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            simulationViewModel.isFloatingPanelExpanded.toggle()
                        }
                    }

                // Panel header with progress
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(sessionLabel) Trip — Live")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.textPrimary)
                            Text("Stop \(simulationViewModel.currentActiveStopIndex + 1) of \(simulationViewModel.allSimulationStops.count) — \(simulationViewModel.currentActiveStopName)")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                        Text("\(simulationViewModel.elapsedTimeDisplayLabel) / \(simulationViewModel.totalDurationDisplayLabel)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.brandAccent)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.divider)
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient.brand)
                                .frame(width: geometry.size.width * simulationViewModel.simulationProgressFraction, height: 5)
                                .animation(.linear(duration: 0.4), value: simulationViewModel.simulationProgressFraction)
                        }
                    }
                    .frame(height: 5)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)

                if simulationViewModel.isFloatingPanelExpanded {
                    Divider()
                        .padding(.horizontal, 18)
                        .padding(.top, 12)

                    // Stop list with passenger attendance rows
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 6) {
                            ForEach(simulationViewModel.passengerStopRows) { stopRow in
                                passengerStopRowView(stopRow: stopRow)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                    }
                    .frame(maxHeight: 280)
                }

                // End trip button — active only when simulation is complete
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: simulationViewModel.isSimulationComplete ? "checkmark.circle.fill" : "hourglass")
                            .font(.system(size: 14, weight: .semibold))
                        Text(simulationViewModel.isSimulationComplete ? "Close Simulation" : "Trip In Progress...")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        simulationViewModel.isSimulationComplete
                        ? LinearGradient(colors: [Color.statusActive, Color.statusActive.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.statusInactive.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
                .disabled(!simulationViewModel.isSimulationComplete)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: -4)
            .padding(.horizontal, 12)
            .padding(.bottom, 24)
        }
    }

    private func passengerStopRowView(stopRow: SimulationPassengerStopRow) -> some View {
        let isCurrentStop = stopRow.stopDisplayName == simulationViewModel.currentActiveStopName
        let hasBeenVisited = stopRow.hasBeenVisited

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(hasBeenVisited ? Color.statusActive.opacity(0.15) : (isCurrentStop ? Color.brandAccent.opacity(0.15) : Color.surfaceBackground))
                    .frame(width: 36, height: 36)
                Image(systemName: hasBeenVisited ? "checkmark.circle.fill" : (isCurrentStop ? "location.fill" : "mappin.circle"))
                    .font(.system(size: 15))
                    .foregroundStyle(hasBeenVisited ? Color.statusActive : (isCurrentStop ? Color.brandAccent : Color.textTertiary))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(stopRow.stopDisplayName)
                    .font(.system(size: 13, weight: isCurrentStop ? .bold : .medium))
                    .foregroundStyle(hasBeenVisited || isCurrentStop ? Color.textPrimary : Color.textSecondary)
                HStack(spacing: 8) {
                    if stopRow.attendingPassengersCount > 0 {
                        Label("\(stopRow.attendingPassengersCount) attending", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.statusActive)
                    }
                    if stopRow.unsurePassengersCount > 0 {
                        Label("\(stopRow.unsurePassengersCount) not sure", systemImage: "questionmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.statusWarning)
                    }
                    if stopRow.totalPassengersAtStop == 0 {
                        Text("No passengers")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(stopRow.estimatedArrivalTimeLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isCurrentStop ? Color.brandAccent : Color.textSecondary)
                Text("ETA")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isCurrentStop ? Color.brandAccent.opacity(0.07) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isCurrentStop ? Color.brandAccent.opacity(0.25) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Trip completion overlay

    private var tripCompletionOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 10) {
                        ZStack {
                            Circle().fill(Color.statusActive.opacity(0.2)).frame(width: 72, height: 72)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(Color.statusActive)
                        }
                        Text("Trip Complete!")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Your \(sessionLabel.lowercased()) session has ended.")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding(.top, 20)

                    // Stats row
                    if let tripRecord = simulationViewModel.completedTripRecord {
                        HStack(spacing: 0) {
                            completionStatCell(value: "\(tripRecord.performanceSummary.totalStopCount)", label: "Stops")
                            Rectangle().fill(Color.white.opacity(0.2)).frame(width: 1, height: 36)
                            completionStatCell(value: "\(tripRecord.performanceSummary.totalPassengersPickedUp)", label: "Passengers")
                            Rectangle().fill(Color.white.opacity(0.2)).frame(width: 1, height: 36)
                            completionStatCell(value: "\(tripRecord.performanceSummary.tripDurationInMinutes)m", label: "Duration")
                        }
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Paginated passenger attendance summary
                        passengerSummarySection(tripRecord: tripRecord)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.brandPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.brandAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 22)
            }
            .background(Color.cardBackground.opacity(0.97))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 16)
            .padding(.vertical, 60)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private func completionStatCell(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
    }

    private func passengerSummarySection(tripRecord: DriverHistoryTripRecord) -> some View {
        PaginatedPassengerSummaryView(
            passengerPickupList: tripRecord.passengerPickupList,
            enrolledPassengers: enrolledPassengers
        )
    }
}

// MARK: - Paginated passenger summary shown in the completion overlay

struct PaginatedPassengerSummaryView: View {

    let passengerPickupList: [DriverTripPassengerPickupRecord]
    let enrolledPassengers: [SimulationEnrolledPassenger]

    private let pageSize: Int = 5
    @State private var currentlyVisiblePageCount: Int = 1

    private var allPassengerSummaryRows: [PassengerTripSummaryRow] {
        enrolledPassengers.map { passenger in
            let wasPickedUp = passengerPickupList.contains { $0.passengerFullName == passenger.fullName }
            return PassengerTripSummaryRow(
                passengerFullName: passenger.fullName,
                boardingStopName: passenger.assignedStopName.isEmpty ? "Union Square" : passenger.assignedStopName,
                attendanceStatusLabel: passenger.attendanceStatusLabel,
                wasPickedUp: wasPickedUp
            )
        }
    }

    private var visibleRows: [PassengerTripSummaryRow] {
        Array(allPassengerSummaryRows.prefix(currentlyVisiblePageCount * pageSize))
    }

    private var hasMoreRowsToShow: Bool {
        visibleRows.count < allPassengerSummaryRows.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Passenger Summary")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            if allPassengerSummaryRows.isEmpty {
                Text("No enrolled passengers for this session.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textTertiary)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(spacing: 6) {
                    ForEach(visibleRows) { row in
                        passengerSummaryRow(row: row)
                    }
                }

                if hasMoreRowsToShow {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentlyVisiblePageCount += 1
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("Load more")
                                .font(.system(size: 13, weight: .semibold))
                            Text("(\(allPassengerSummaryRows.count - visibleRows.count) remaining)")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.textTertiary)
                        }
                        .foregroundStyle(Color.brandAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.brandAccent.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func passengerSummaryRow(row: PassengerTripSummaryRow) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.12))
                    .frame(width: 36, height: 36)
                Text(String(row.passengerFullName.prefix(1)))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.brandAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(row.passengerFullName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(row.boardingStopName)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                pickedUpBadge(wasPickedUp: row.wasPickedUp)
                attendanceBadge(status: row.attendanceStatusLabel)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func pickedUpBadge(wasPickedUp: Bool) -> some View {
        HStack(spacing: 3) {
            Image(systemName: wasPickedUp ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 9))
            Text(wasPickedUp ? "Boarded" : "Not Boarded")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(wasPickedUp ? Color.statusActive : Color.statusDanger)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background((wasPickedUp ? Color.statusActive : Color.statusDanger).opacity(0.1))
        .clipShape(Capsule())
    }

    private func attendanceBadge(status: String) -> some View {
        let isAttending = status == "attending"
        let isAbsent = status == "absent"
        let color: Color = isAttending ? Color.brandAccent : (isAbsent ? Color.statusWarning : Color.textTertiary)
        let label = isAttending ? "Attending" : (isAbsent ? "Absent" : "Not Marked")

        return Text(label)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }
}

// Supporting row model for the completion overlay
struct PassengerTripSummaryRow: Identifiable {
    let id = UUID()
    let passengerFullName: String
    let boardingStopName: String
    let attendanceStatusLabel: String
    let wasPickedUp: Bool
}

// Equatable wrapper used to observe coordinate changes in onChange
private struct LatLon: Equatable {
    let lat: CLLocationDegrees
    let lon: CLLocationDegrees
}
