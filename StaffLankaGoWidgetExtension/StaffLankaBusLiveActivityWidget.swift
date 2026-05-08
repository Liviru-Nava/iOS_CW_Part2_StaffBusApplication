//
//  StaffLankaBusLiveActivityWidget.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-08.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct StaffLankaGoLiveActivityWidget: Widget {

    var body: some WidgetConfiguration {

        ActivityConfiguration(for: StaffLankaGoTripActivityAttributes.self) { liveActivityContext in

            StaffLankaGoLockScreenLiveActivityView(
                tripAttributes: liveActivityContext.attributes,
                tripContentState: liveActivityContext.state
            )
            .activityBackgroundTint(Color(red: 0.05, green: 0.11, blue: 0.24))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { dynamicIslandContext in

            DynamicIsland {

                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "bus.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("StaffLanka Go")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                            Text(dynamicIslandContext.attributes.routeDisplayName)
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ETA")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("~\(dynamicIslandContext.state.estimatedMinutesUntilPassengerRelevantStop) min")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    StaffLankaGoExpandedDynamicIslandBottomView(
                        tripContentState: dynamicIslandContext.state
                    )
                    .padding(.bottom, 8)
                }

            } compactLeading: {
                Image(systemName: "bus.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)

            } compactTrailing: {
                Text("~\(dynamicIslandContext.state.estimatedMinutesUntilPassengerRelevantStop)m")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

            } minimal: {
                Image(systemName: "bus.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .widgetURL(URL(string: "stafflankago://trip"))
            .keylineTint(Color(red: 0.55, green: 0.76, blue: 1.00))
        }
    }
}

struct StaffLankaGoLockScreenLiveActivityView: View {

    let tripAttributes: StaffLankaGoTripActivityAttributes
    let tripContentState: StaffLankaGoTripActivityAttributes.OngoingTripContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            tripHeaderRow

            Divider()
                .overlay(Color.white.opacity(0.25))

            tripProgressDetailRow

            stopsRemainingRow
        }
        .padding(16)
    }

    private var tripHeaderRow: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.55, green: 0.76, blue: 1.00).opacity(0.20))
                    .frame(width: 38, height: 38)
                Image(systemName: "bus.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 0.55, green: 0.76, blue: 1.00))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("StaffLanka Go")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Text(tripContentState.sessionLabel + " Route")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.70))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("~\(tripContentState.estimatedMinutesUntilPassengerRelevantStop) min")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.55, green: 0.76, blue: 1.00))
                Text(tripContentState.passengerHasAlreadyBeenPickedUp ? "to drop-off" : "to your stop")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.60))
            }
        }
    }

    private var tripProgressDetailRow: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("CURRENT STOP")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.50))
                    .kerning(0.6)
                Text(tripContentState.nameOfCurrentBusStop)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(tripContentState.passengerHasAlreadyBeenPickedUp ? "DROP-OFF" : "YOUR STOP")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.50))
                    .kerning(0.6)
                Text(
                    tripContentState.passengerHasAlreadyBeenPickedUp
                        ? tripContentState.passengerDropOffStopName
                        : tripContentState.passengerPickupStopName
                )
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.55, green: 0.76, blue: 1.00))
                .lineLimit(1)
            }
        }
    }

    private var stopsRemainingRow: some View {
        HStack(spacing: 6) {
            Image(
                systemName: tripContentState.passengerHasAlreadyBeenPickedUp
                    ? "arrow.down.to.line.circle.fill"
                    : "figure.stand.line.dotted.figure.stand"
            )
            .font(.system(size: 12))
            .foregroundStyle(Color(red: 0.55, green: 0.76, blue: 1.00))

            let stopsRemainingCount = tripContentState.numberOfStopsRemainingUntilPassengerRelevantStop

            if stopsRemainingCount == 0 {
                Text(
                    tripContentState.passengerHasAlreadyBeenPickedUp
                        ? "Arriving at your drop-off now"
                        : "The bus is arriving at your stop now"
                )
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
            } else {
                Text(
                    "\(stopsRemainingCount) stop\(stopsRemainingCount == 1 ? "" : "s") away"
                )
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)

                Text(
                    tripContentState.passengerHasAlreadyBeenPickedUp
                        ? "to reach your drop-off point"
                        : "to reach your pickup location"
                )
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()
        }
    }
}

struct StaffLankaGoExpandedDynamicIslandBottomView: View {

    let tripContentState: StaffLankaGoTripActivityAttributes.OngoingTripContentState

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text("CURRENT STOP")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .kerning(0.5)
                Text(tripContentState.nameOfCurrentBusStop)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer()

            VStack(spacing: 4) {
                Image(systemName: "chevron.right.2")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.50))
                Text(
                    "\(tripContentState.numberOfStopsRemainingUntilPassengerRelevantStop) stop\(tripContentState.numberOfStopsRemainingUntilPassengerRelevantStop == 1 ? "" : "s")"
                )
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(tripContentState.passengerHasAlreadyBeenPickedUp ? "DROP-OFF" : "YOUR STOP")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .kerning(0.5)
                Text(
                    tripContentState.passengerHasAlreadyBeenPickedUp
                        ? tripContentState.passengerDropOffStopName
                        : tripContentState.passengerPickupStopName
                )
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.55, green: 0.76, blue: 1.00))
                .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
    }
}
