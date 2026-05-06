//
//  DriverTripSimulationView.swift
//  StaffLanka_Go
//

import SwiftUI
import MapKit

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
            if simulationViewModel.isCalculatingRoadRoute {
                routeCalculationLoadingOverlay
            }
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
                withAnimation(.easeInOut(duration: 0.5)) { showCompletionOverlay = true }
            }
        }
        .onChange(of: simulationViewModel.currentBusCoordinate.latitude) { _, _ in
            withAnimation(.easeInOut(duration: 0.35)) {
                mapCameraPosition = .region(MKCoordinateRegion(
                    center: simulationViewModel.currentBusCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
                ))
            }
        }
    }

    // Map with bus annotation, stop pins, and the actual road polyline
    private var mapLayer: some View {
        Map(position: $mapCameraPosition) {

            // Road polyline drawn once MKDirections has finished calculating
            if !simulationViewModel.roadPolylineCoordinates.isEmpty {
                MapPolyline(coordinates: simulationViewModel.roadPolylineCoordinates)
                    .stroke(Color.brandAccent.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }

            // Animated bus annotation
            Annotation("Bus", coordinate: simulationViewModel.currentBusCoordinate) {
                ZStack {
                    Circle()
                        .fill(Color.statusActive.opacity(0.22))
                        .frame(width: 52, height: 52)
                    Image(systemName: "bus.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.statusActive)
                        .clipShape(Circle())
                }
                .shadow(color: Color.statusActive.opacity(0.5), radius: 6, x: 0, y: 3)
                .animation(.easeInOut(duration: 0.35), value: simulationViewModel.currentBusCoordinate.latitude)
            }

            // Stop pin annotations
            ForEach(Array(simulationViewModel.allSimulationStops.enumerated()), id: \.element.id) { stopIndex, stop in
                let isFirstStop = stopIndex == 0
                let isLastStop = stopIndex == simulationViewModel.allSimulationStops.count - 1
                let hasBeenVisited = stopIndex <= simulationViewModel.currentActiveStopIndex

                Annotation(stop.stopDisplayName, coordinate: stop.coordinate) {
                    ZStack {
                        Circle()
                            .fill(hasBeenVisited ? Color.statusActive.opacity(0.25) : Color.brandAccent.opacity(0.18))
                            .frame(width: 36, height: 36)
                        if isLastStop {
                            Image(systemName: "flag.checkered.2.crossed")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.statusDanger)
                        } else if isFirstStop {
                            Image(systemName: "figure.stand")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.statusActive)
                        } else {
                            Circle()
                                .fill(hasBeenVisited ? Color.statusActive : Color.brandAccent)
                                .frame(width: 13, height: 13)
                        }
                    }
                    .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 1.5))
                    .shadow(radius: 3)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    // Translucent loading screen shown while MKDirections calculates the road path
    private var routeCalculationLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.4)
                    .tint(.white)
                Text("Calculating Road Route…")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Finding the best road path through all stops")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    // Top-right directions toggle button + the expandable instruction card
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
                        Text(simulationViewModel.isInstructionsPanelVisible ? "Hide Directions" : "Directions")
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

    // Bottom floating panel — starts collapsed so the map is fully visible
    private var floatingPassengerPanel: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {

                // Drag handle row with expand/collapse chevron button
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.textTertiary.opacity(0.5))
                        .frame(width: 36, height: 4)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                            simulationViewModel.isFloatingPanelExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: simulationViewModel.isFloatingPanelExpanded ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.brandAccent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 6)

                // Status row — always visible
                panelStatusRow
                    .padding(.horizontal, 18)
                    .padding(.bottom, 10)

                // Expandable section — stop list + progress bar
                if simulationViewModel.isFloatingPanelExpanded {
                    panelProgressRow
                        .padding(.horizontal, 18)
                        .padding(.bottom, 10)

                    Divider().padding(.horizontal, 18)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 5) {
                            ForEach(simulationViewModel.passengerStopRows) { stopRow in
                                passengerStopRowView(stopRow: stopRow)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 240)

                    Divider().padding(.horizontal, 18)
                }

                // Close / In-progress button
                Button { dismiss() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: simulationViewModel.isSimulationComplete ? "checkmark.circle.fill" : "hourglass")
                            .font(.system(size: 14, weight: .semibold))
                        Text(simulationViewModel.isSimulationComplete ? "Close Simulation" : "Trip In Progress…")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        simulationViewModel.isSimulationComplete
                            ? LinearGradient(colors: [Color.statusActive, Color.statusActive.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.statusInactive.opacity(0.45)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
                .disabled(!simulationViewModel.isSimulationComplete)
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 18)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.2), radius: 18, x: 0, y: -5)
            .padding(.horizontal, 12)
            .padding(.bottom, 24)
        }
    }

    // Compact one-line status always shown at the top of the panel
    private var panelStatusRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(simulationViewModel.isSimulationComplete ? Color.statusActive : Color.statusWarning)
                .frame(width: 7, height: 7)
            Text("\(sessionLabel) — Stop \(simulationViewModel.currentActiveStopIndex + 1)/\(simulationViewModel.allSimulationStops.count) · \(simulationViewModel.currentActiveStopName)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            Spacer()
            Text("\(simulationViewModel.elapsedTimeDisplayLabel) / \(simulationViewModel.totalDurationDisplayLabel)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.brandAccent)
        }
    }

    // Progress bar shown only when the panel is expanded
    private var panelProgressRow: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Color.divider).frame(height: 5)
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient.brand)
                    .frame(width: geometry.size.width * simulationViewModel.simulationProgressFraction, height: 5)
                    .animation(.linear(duration: 0.4), value: simulationViewModel.simulationProgressFraction)
            }
        }
        .frame(height: 5)
    }

    private func passengerStopRowView(stopRow: SimulationPassengerStopRow) -> some View {
        let isCurrentStop = stopRow.stopDisplayName == simulationViewModel.currentActiveStopName
        let hasBeenVisited = stopRow.hasBeenVisited

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(hasBeenVisited ? Color.statusActive.opacity(0.15) : (isCurrentStop ? Color.brandAccent.opacity(0.15) : Color.surfaceBackground))
                    .frame(width: 34, height: 34)
                Image(systemName: hasBeenVisited ? "checkmark.circle.fill" : (isCurrentStop ? "location.fill" : "mappin.circle"))
                    .font(.system(size: 14))
                    .foregroundStyle(hasBeenVisited ? Color.statusActive : (isCurrentStop ? Color.brandAccent : Color.textTertiary))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(stopRow.stopDisplayName)
                    .font(.system(size: 13, weight: isCurrentStop ? .bold : .medium))
                    .foregroundStyle(hasBeenVisited || isCurrentStop ? Color.textPrimary : Color.textSecondary)
                HStack(spacing: 8) {
                    if stopRow.attendingPassengersCount > 0 {
                        Label("\(stopRow.attendingPassengersCount) attending", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.statusActive)
                    }
                    if stopRow.unsurePassengersCount > 0 {
                        Label("\(stopRow.unsurePassengersCount) not sure", systemImage: "questionmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.statusWarning)
                    }
                    if stopRow.totalPassengersAtStop == 0 {
                        Text("No passengers")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(stopRow.estimatedArrivalTimeLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isCurrentStop ? Color.brandAccent : Color.textSecondary)
                Text("ETA")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(isCurrentStop ? Color.brandAccent.opacity(0.07) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(isCurrentStop ? Color.brandAccent.opacity(0.25) : Color.clear, lineWidth: 1))
    }

    // Full-screen completion overlay with stats and paginated passenger list
    private var tripCompletionOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
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

                        PaginatedPassengerSummaryView(
                            passengerPickupList: tripRecord.passengerPickupList,
                            enrolledPassengers: enrolledPassengers
                        )
                    }

                    Button { dismiss() } label: {
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
}

// Paginated passenger summary used inside the completion overlay
struct PaginatedPassengerSummaryView: View {

    let passengerPickupList: [DriverTripPassengerPickupRecord]
    let enrolledPassengers: [SimulationEnrolledPassenger]

    private let pageSize = 5
    @State private var currentlyVisiblePageCount = 1

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
                    ForEach(visibleRows) { row in passengerSummaryRow(row: row) }
                }

                if visibleRows.count < allPassengerSummaryRows.count {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { currentlyVisiblePageCount += 1 }
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
                Circle().fill(Color.brandAccent.opacity(0.12)).frame(width: 36, height: 36)
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
            Image(systemName: wasPickedUp ? "checkmark.circle.fill" : "xmark.circle.fill").font(.system(size: 9))
            Text(wasPickedUp ? "Boarded" : "Not Boarded").font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(wasPickedUp ? Color.statusActive : Color.statusDanger)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background((wasPickedUp ? Color.statusActive : Color.statusDanger).opacity(0.1))
        .clipShape(Capsule())
    }

    private func attendanceBadge(status: String) -> some View {
        let isAttending = status == "attending"
        let color: Color = isAttending ? Color.brandAccent : (status == "absent" ? Color.statusWarning : Color.textTertiary)
        let label = isAttending ? "Attending" : (status == "absent" ? "Absent" : "Not Marked")
        return Text(label)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }
}

struct PassengerTripSummaryRow: Identifiable {
    let id = UUID()
    let passengerFullName: String
    let boardingStopName: String
    let attendanceStatusLabel: String
    let wasPickedUp: Bool
}
