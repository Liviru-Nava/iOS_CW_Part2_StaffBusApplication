//
//  DriverTripDetailView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-09.

import SwiftUI
import MapKit

struct DriverTripDetailView: View {

    let tripRecord: DriverHistoryTripRecord
    @State private var selectedDetailDisplayMode: DriverTripDetailDisplayMode = .textView
    @State private var tripRoutePolyline: MKPolyline? = nil
    @State private var isCalculatingMapRoute: Bool = false

    private var sessionDisplayColor: Color {
        tripRecord.sessionType == "Morning" ? Color.statusWarning : Color.brandAccent
    }

    private var sessionIconName: String {
        tripRecord.sessionType == "Morning" ? "sunrise.fill" : "moon.fill"
    }

    private var completionStatusColor: Color {
        tripRecord.completionStatus == .completed ? Color.statusActive : Color.statusWarning
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                tripHeaderCard
                    .padding(.top, 8)
                displayModeToggle
                performanceSummarySection
                if selectedDetailDisplayMode == .textView {
                    stopsTimelineSection
                } else {
                    mapRouteSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 48)
        }
        .background(Color.appBackground)
        .navigationTitle(tripRecord.tripDate.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedDetailDisplayMode) { _, newMode in
            if newMode == .mapView && tripRoutePolyline == nil {
                Task { await buildPolylineFromStopsTimeline() }
            }
        }
    }

    private var tripHeaderCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient.brand
                .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: sessionIconName)
                            .font(.system(size: 22))
                            .foregroundStyle(Color.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(tripRecord.sessionType == "Morning" ? "Morning Trip" : "Evening Trip")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.white)
                        Text(tripRecord.tripDate.formatted(date: .long, time: .omitted))
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.70))
                    }

                    Spacer()

                    completionStatusHeaderBadge
                }

                Rectangle()
                    .fill(Color.white.opacity(0.18))
                    .frame(height: 1)

                HStack(spacing: 0) {
                    headerTimeCell(labelText: "Start", timeText: tripRecord.scheduledStartTime)
                    Rectangle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 1, height: 28)
                        .padding(.horizontal, 16)
                    headerTimeCell(labelText: "End", timeText: tripRecord.actualEndTime)
                    Rectangle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 1, height: 28)
                        .padding(.horizontal, 16)
                    headerTimeCell(labelText: "Duration", timeText: "\(tripRecord.performanceSummary.tripDurationInMinutes) min")
                    Spacer()
                }
            }
            .padding(18)
        }
    }

    private var completionStatusHeaderBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: tripRecord.completionStatus == .completed ? "checkmark.circle.fill" : "clock.fill")
                .font(.system(size: 11))
            Text(tripRecord.completionStatus.rawValue)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.18))
        .clipShape(Capsule())
    }

    private func headerTimeCell(labelText: String, timeText: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(labelText)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.60))
            Text(timeText)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
        }
    }

    private var displayModeToggle: some View {
        HStack(spacing: 0) {
            displayModeToggleButton(
                labelText: "Stop Details",
                iconName: "list.bullet",
                targetMode: .textView
            )
            displayModeToggleButton(
                labelText: "Map View",
                iconName: "map.fill",
                targetMode: .mapView
            )
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.divider, lineWidth: 1)
        )
    }

    private func displayModeToggleButton(labelText: String, iconName: String, targetMode: DriverTripDetailDisplayMode) -> some View {
        let isActiveMode = selectedDetailDisplayMode == targetMode
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedDetailDisplayMode = targetMode
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .semibold))
                Text(labelText)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(isActiveMode ? Color.brandAccent : Color.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(isActiveMode ? Color.brandAccent.opacity(0.13) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 11))
        }
        .buttonStyle(.plain)
    }

    private var performanceSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeaderLabel(titleText: "Trip Performance", iconName: "chart.bar.fill")

            HStack(spacing: 12) {
                performanceStatCard(
                    iconName: "mappin.circle.fill",
                    iconColor: Color.brandAccent,
                    statValue: "\(tripRecord.performanceSummary.totalStopCount)",
                    statLabel: "Total Stops"
                )
                performanceStatCard(
                    iconName: "checkmark.circle.fill",
                    iconColor: Color.statusActive,
                    statValue: "\(tripRecord.performanceSummary.completedStopCount)",
                    statLabel: "Completed"
                )
                performanceStatCard(
                    iconName: "person.2.fill",
                    iconColor: Color.statusWarning,
                    statValue: "\(tripRecord.performanceSummary.totalPassengersPickedUp)",
                    statLabel: "Passengers"
                )
                performanceStatCard(
                    iconName: "timer",
                    iconColor: Color.statusInfo,
                    statValue: "\(tripRecord.performanceSummary.tripDurationInMinutes)m",
                    statLabel: "Duration"
                )
            }
        }
    }

    private func performanceStatCard(iconName: String, iconColor: Color, statValue: String, statLabel: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.13))
                    .frame(width: 38, height: 38)
                Image(systemName: iconName)
                    .font(.system(size: 15))
                    .foregroundStyle(iconColor)
            }
            VStack(spacing: 1) {
                Text(statValue)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text(statLabel)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var stopsTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeaderLabel(titleText: "Stops Timeline", iconName: "point.topleft.down.to.point.bottomright.curvepath.fill")

            VStack(spacing: 0) {
                ForEach(Array(tripRecord.stopsTimeline.enumerated()), id: \.element.id) { index, stopRecord in
                    stopTimelineRow(
                        stopRecord: stopRecord,
                        isFirstStop: index == 0,
                        isLastStop: index == tripRecord.stopsTimeline.count - 1
                    )
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func stopTimelineRow(stopRecord: DriverTripStopRecord, isFirstStop: Bool, isLastStop: Bool) -> some View {
        let isCompleted = stopRecord.stopStatus == .completed
        let dotColor: Color = isCompleted ? Color.statusActive : Color.statusInactive

        return HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                if !isFirstStop {
                    Rectangle()
                        .fill(Color.divider)
                        .frame(width: 2, height: 16)
                } else {
                    Spacer().frame(height: 16)
                }
                ZStack {
                    Circle()
                        .fill(dotColor.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Circle()
                        .fill(dotColor)
                        .frame(width: 10, height: 10)
                }
                if !isLastStop {
                    Rectangle()
                        .fill(Color.divider)
                        .frame(width: 2)
                        .frame(minHeight: 20)
                }
            }
            .frame(width: 52)
            .padding(.leading, 14)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(stopRecord.stopName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isCompleted ? Color.textPrimary : Color.textTertiary)
                    Text(stopRecord.timeReached)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.vertical, 16)

                Spacer()

                stopStatusPill(isCompleted: isCompleted)
                    .padding(.trailing, 16)
            }
        }
    }

    private func stopStatusPill(isCompleted: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "minus.circle.fill")
                .font(.system(size: 10))
            Text(isCompleted ? "Completed" : "Skipped")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(isCompleted ? Color.statusActive : Color.statusInactive)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isCompleted ? Color.statusActive : Color.statusInactive).opacity(0.12))
        .clipShape(Capsule())
    }

    // Real map built from the stops timeline stored in the trip record
    private var mapRouteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeaderLabel(titleText: "Route Map", iconName: "map.fill")

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)

                if isCalculatingMapRoute {
                    VStack(spacing: 12) {
                        ProgressView().tint(Color.brandAccent)
                        Text("Building route map…")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .frame(height: 320)
                } else if tripRecord.stopsTimeline.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "map")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.textTertiary)
                        Text("No stop data available for this trip.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .frame(height: 320)
                } else {
                    tripHistoryMapView
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.divider, lineWidth: 1)
            )
        }
    }

    // MapKit view populated from stopsTimeline stop names matched against route coordinate data
    // Since DriverTripStopRecord only stores names and times, we geocode each stop name for display
    private var tripHistoryMapView: some View {
        TripHistoryRouteMapView(
            stopsTimeline: tripRecord.stopsTimeline,
            prebuiltPolyline: tripRoutePolyline
        )
    }

    // Attempts to build a road polyline by geocoding stop names from the timeline
    private func buildPolylineFromStopsTimeline() async {
        guard !tripRecord.stopsTimeline.isEmpty else { return }
        isCalculatingMapRoute = true

        var geocodedCoordinates: [CLLocationCoordinate2D] = []

        for stopRecord in tripRecord.stopsTimeline {
            let geocoder = CLGeocoder()
            if let placemark = try? await geocoder.geocodeAddressString(stopRecord.stopName + ", Sri Lanka"),
               let location = placemark.first?.location {
                geocodedCoordinates.append(location.coordinate)
            }
        }

        guard geocodedCoordinates.count >= 2 else {
            isCalculatingMapRoute = false
            return
        }

        var allPathCoordinates: [CLLocationCoordinate2D] = []
        for legIndex in 0 ..< geocodedCoordinates.count - 1 {
            let directionsRequest = MKDirections.Request()
            directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: geocodedCoordinates[legIndex]))
            directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: geocodedCoordinates[legIndex + 1]))
            directionsRequest.transportType = .automobile

            if let calculatedRoute = try? await MKDirections(request: directionsRequest).calculate().routes.first {
                var legCoords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: calculatedRoute.polyline.pointCount)
                calculatedRoute.polyline.getCoordinates(&legCoords, range: NSRange(location: 0, length: calculatedRoute.polyline.pointCount))
                if legIndex > 0 { legCoords = Array(legCoords.dropFirst()) }
                allPathCoordinates.append(contentsOf: legCoords)
            } else {
                allPathCoordinates.append(contentsOf: [geocodedCoordinates[legIndex], geocodedCoordinates[legIndex + 1]])
            }
        }

        tripRoutePolyline = MKPolyline(coordinates: allPathCoordinates, count: allPathCoordinates.count)
        isCalculatingMapRoute = false
    }

    private func sectionHeaderLabel(titleText: String, iconName: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.brandAccent)
            Text(titleText)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.textPrimary)
        }
    }
}

// Standalone map view for trip history — pins each completed stop and draws the polyline
struct TripHistoryRouteMapView: View {

    let stopsTimeline: [DriverTripStopRecord]
    let prebuiltPolyline: MKPolyline?

    @State private var geocodedStopCoordinates: [String: CLLocationCoordinate2D] = [:]
    @State private var mapCameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $mapCameraPosition) {
            if let polyline = prebuiltPolyline {
                MapPolyline(polyline)
                    .stroke(Color.brandAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }

            ForEach(Array(stopsTimeline.enumerated()), id: \.element.id) { index, stopRecord in
                if let coordinate = geocodedStopCoordinates[stopRecord.stopName] {
                    let isFirstStop = index == 0
                    let isLastStop = index == stopsTimeline.count - 1

                    Annotation(stopRecord.stopName, coordinate: coordinate) {
                        ZStack {
                            Circle()
                                .fill(isFirstStop ? Color.statusActive.opacity(0.2) : (isLastStop ? Color.statusDanger.opacity(0.2) : Color.brandAccent.opacity(0.18)))
                                .frame(width: 32, height: 32)
                            if isFirstStop {
                                Image(systemName: "flag.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.statusActive)
                            } else if isLastStop {
                                Image(systemName: "flag.checkered.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.statusDanger)
                            } else {
                                Text("\(index)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color.brandAccent)
                                    .clipShape(Circle())
                            }
                        }
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.7), lineWidth: 1.5))
                        .shadow(radius: 3)
                    }
                }
            }
        }
        .mapStyle(.standard)
        .task {
            await geocodeAllStops()
        }
    }

    private func geocodeAllStops() async {
        var coordinateMap: [String: CLLocationCoordinate2D] = [:]
        for stopRecord in stopsTimeline {
            guard coordinateMap[stopRecord.stopName] == nil else { continue }
            let geocoder = CLGeocoder()
            if let placemark = try? await geocoder.geocodeAddressString(stopRecord.stopName + ", Sri Lanka"),
               let location = placemark.first?.location {
                coordinateMap[stopRecord.stopName] = location.coordinate
            }
        }
        geocodedStopCoordinates = coordinateMap

        if let firstCoordinate = coordinateMap.values.first {
            mapCameraPosition = .region(MKCoordinateRegion(
                center: firstCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
            ))
        }
    }
}

struct PaginatedTripPassengerDetailView: View {

    let passengerPickupList: [DriverTripPassengerPickupRecord]

    private let rowsPerPage = 10
    @State private var visiblePageCount = 1

    private var boardedPassengers: [DriverTripPassengerPickupRecord] { passengerPickupList }
    private var notBoardedPassengers: [DriverTripPassengerPickupRecord] = []

    private var allRows: [DriverTripPassengerPickupRecord] { boardedPassengers + notBoardedPassengers }
    private var visibleRows: [DriverTripPassengerPickupRecord] { Array(allRows.prefix(visiblePageCount * rowsPerPage)) }
    private var hasMoreToShow: Bool { visibleRows.count < allRows.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.brandAccent)
                Text("Passenger Pickups")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(boardedPassengers.count) boarded")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.statusActive)
            }

            if allRows.isEmpty {
                Text("No passengers enrolled for this session.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textTertiary)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(visibleRows.enumerated()), id: \.element.id) { rowIndex, passengerRecord in
                        passengerDetailRow(record: passengerRecord, isBoarded: boardedPassengers.contains { $0.id == passengerRecord.id })
                        if rowIndex < visibleRows.count - 1 {
                            Divider().padding(.horizontal, 16)
                        }
                    }
                }
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if hasMoreToShow {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { visiblePageCount += 1 }
                    } label: {
                        HStack(spacing: 6) {
                            Text("Load more")
                                .font(.system(size: 13, weight: .semibold))
                            Text("(\(allRows.count - visibleRows.count) remaining)")
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

    private func passengerDetailRow(record: DriverTripPassengerPickupRecord, isBoarded: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.12))
                    .frame(width: 38, height: 38)
                Text(String(record.passengerFullName.prefix(1)))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.brandAccent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(record.passengerFullName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.brandAccent)
                    Text(record.boardingStopName)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: isBoarded ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 11))
                Text(isBoarded ? "Boarded" : "Not Boarded")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(isBoarded ? Color.statusActive : Color.statusDanger)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((isBoarded ? Color.statusActive : Color.statusDanger).opacity(0.11))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
