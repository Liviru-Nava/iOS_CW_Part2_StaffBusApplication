//
//  JoinRequestView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-03.
//

import SwiftUI

struct JoinRequestView: View {

    @StateObject private var joinRequestViewModel: JoinRequestViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        pickupLocation: String,
        destinationLocation: String,
        routeName: String,
        routeId: String,
        driverId: String,
        stops: [String],
        morningDepartureTime: Date,
        eveningDepartureTime: Date,
        activeDays: [String],
        allowedSessions: [JoinRequestViewModel.TripSession] = JoinRequestViewModel.TripSession.allCases
    ) {
        _joinRequestViewModel = StateObject(wrappedValue: JoinRequestViewModel(
            pickupLocation:      pickupLocation,
            destinationLocation: destinationLocation,
            routeName:           routeName,
            routeId:             routeId,
            driverId:            driverId,
            stops:               stops,
            morningDepartureTime: morningDepartureTime,
            eveningDepartureTime: eveningDepartureTime,
            activeDays:          activeDays,
            allowedSessions:     allowedSessions
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                if joinRequestViewModel.isSubmitted {
                    successView
                } else {
                    formView
                }
            }
            .navigationTitle("Request to Join")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !joinRequestViewModel.isSubmitted {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Color.brandAccent)
                    }
                }
            }
        }
        .sheet(isPresented: $joinRequestViewModel.showPickupPicker) {
            JoinLocationPickerSheet(
                title: "Select Pickup",
                stops: joinRequestViewModel.stops,
                selected: $joinRequestViewModel.selectedPickup
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(20)
        }
        .sheet(isPresented: $joinRequestViewModel.showDestinationPicker) {
            JoinLocationPickerSheet(
                title: "Select Drop-off",
                stops: joinRequestViewModel.stops,
                selected: $joinRequestViewModel.selectedDestination
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(20)
        }
    }

    private var formView: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    routeInfoCard
                    journeySection
                    sessionSection
                    contactSection

                    if let errorMessage = joinRequestViewModel.submitError {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.statusDanger)
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.statusDanger)
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.statusDanger.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.statusDanger.opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }

            Divider().background(Color.divider)

            Button {
                joinRequestViewModel.submitRequest()
            } label: {
                ZStack {
                    HStack(spacing: 8) {
                        if joinRequestViewModel.isSubmitting {
                            ProgressView()
                                .tint(Color.brandPrimary)
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 13))
                        }
                        Text(joinRequestViewModel.isSubmitting ? "Sending..." : "Submit Request")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                .foregroundStyle(joinRequestViewModel.canSubmit ? Color.brandPrimary : Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(joinRequestViewModel.canSubmit ? Color.brandAccent : Color.statusInactive)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(!joinRequestViewModel.canSubmit)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.appBackground)
        }
    }

    private var routeInfoCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.brandAccent.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: "bus.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.brandAccent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Joining Route")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary)
                Text(joinRequestViewModel.routeName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.divider, lineWidth: 1))
    }

    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Journey Details")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: 0) {
                locationRow(
                    label: "Pickup",
                    value: joinRequestViewModel.selectedPickup,
                    placeholder: "Select pickup stop"
                ) {
                    joinRequestViewModel.showPickupPicker = true
                }
                Divider().padding(.leading, 16)
                locationRow(
                    label: "Drop-off",
                    value: joinRequestViewModel.selectedDestination,
                    placeholder: "Select drop-off stop"
                ) {
                    joinRequestViewModel.showDestinationPicker = true
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.divider, lineWidth: 1))
        }
    }

    private func locationRow(label: String, value: String, placeholder: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.brandAccent.opacity(0.10))
                        .frame(width: 32, height: 32)
                    Image(systemName: "mappin.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.brandAccent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                    Text(value.isEmpty ? placeholder : value)
                        .font(.system(size: 14, weight: value.isEmpty ? .regular : .medium))
                        .foregroundStyle(value.isEmpty ? Color.textTertiary : Color.textPrimary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var sessionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trip Session")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)

            HStack(spacing: 10) {
                ForEach(JoinRequestViewModel.TripSession.allCases, id: \.self) { tripSession in
                    sessionChip(tripSession)
                }
            }
        }
    }

    private func sessionChip(_ tripSession: JoinRequestViewModel.TripSession) -> some View {
        let isCurrentlySelected = joinRequestViewModel.selectedSession == tripSession
        let isDisabledForPassenger = joinRequestViewModel.isSessionDisabled(tripSession)
        return Button {
            if !isDisabledForPassenger {
                joinRequestViewModel.selectedSession = tripSession
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isDisabledForPassenger ? "lock.fill" : sessionIconName(tripSession))
                    .font(.system(size: 12))
                Text(tripSession.rawValue)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(
                isDisabledForPassenger
                    ? Color.textTertiary
                    : (isCurrentlySelected ? Color.brandPrimary : Color.textSecondary)
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                isDisabledForPassenger
                    ? Color.cardBackground.opacity(0.5)
                    : (isCurrentlySelected ? Color.brandAccent : Color.cardBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isDisabledForPassenger
                            ? Color.divider.opacity(0.4)
                            : (isCurrentlySelected ? Color.clear : Color.divider),
                        lineWidth: 1
                    )
            )
            .opacity(isDisabledForPassenger ? 0.45 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabledForPassenger)
        .animation(.easeInOut(duration: 0.15), value: joinRequestViewModel.selectedSession)
    }

    private func sessionIconName(_ tripSession: JoinRequestViewModel.TripSession) -> String {
        switch tripSession {
        case .morning: return "sunrise.fill"
        case .evening: return "moon.fill"
        case .both:    return "arrow.left.arrow.right"
        }
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Contact Details")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: 0) {
                inputRow(placeholder: "Phone Number *", text: $joinRequestViewModel.phone, keyboardType: .phonePad)
                Divider().padding(.leading, 16)
                inputRow(placeholder: "Name (Optional)", text: $joinRequestViewModel.name, keyboardType: .default)
                Divider().padding(.leading, 16)
                inputRow(placeholder: "Note for Driver (Optional)", text: $joinRequestViewModel.note, keyboardType: .default)
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.divider, lineWidth: 1))
        }
    }

    private func inputRow(placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 14))
            .foregroundStyle(Color.textPrimary)
            .tint(Color.brandAccent)
            .keyboardType(keyboardType)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
    }

    private var successView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.statusActive.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.statusActive)
            }

            VStack(spacing: 10) {
                Text("Request Sent!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text("Your request to join this route has been submitted.\nWe'll notify you once the driver approves.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.brandAccent)
                    Text("Calendar reminders will be added once the driver accepts your request.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.brandAccent.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 30)
            }
            .padding(.horizontal, 30)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.brandAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }

    }
}

// Location Picker Sheet (stop names from the real route)

struct JoinLocationPickerSheet: View {

    let title: String
    let stops: [String]
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss
    @FocusState private var searchFocused: Bool
    @State private var localQuery: String = ""
    @GestureState private var isDetectingDrag: Bool = false

    var filtered: [String] {
        localQuery.isEmpty ? stops : stops.filter { $0.localizedCaseInsensitiveContains(localQuery) }
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            Divider().background(Color.divider)
            searchBar
            Divider().background(Color.divider)
            locationList
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                searchFocused = true
            }
        }
    }

    private var sheetHeader: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
            TextField("Search stop...", text: $localQuery)
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)
                .tint(Color.brandAccent)
                .focused($searchFocused)
                .autocorrectionDisabled()
            if !localQuery.isEmpty {
                Button {
                    localQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(searchFocused ? Color.brandAccent.opacity(0.5) : Color.divider, lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .animation(.easeInOut(duration: 0.15), value: searchFocused)
    }

    private var locationList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                if filtered.isEmpty {
                    Text("No stops match your search")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(Array(filtered.enumerated()), id: \.element) { stopIndex, stopName in
                        Button {
                            if isDetectingDrag { return }
                            selected = stopName
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brandAccent.opacity(0.10))
                                        .frame(width: 38, height: 38)
                                    Image(systemName: "mappin.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.brandAccent)
                                }
                                Text(stopName)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                if selected == stopName {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.brandAccent)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 13)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if stopIndex < filtered.count - 1 {
                            Divider().padding(.leading, 72)
                        }
                    }
                }
            }
        }
        .gesture(DragGesture().updating($isDetectingDrag) { _, state, _ in state = true })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Dark mode") {
    JoinRequestView(
        pickupLocation: "Borella",
        destinationLocation: "Maharagama",
        routeName: "Colombo Fort → Maharagama",
        routeId: "preview_route",
        driverId: "preview_driver",
        stops: ["Colombo Fort", "Borella", "Nugegoda", "Maharagama"],
        morningDepartureTime: Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date()) ?? Date(),
        eveningDepartureTime: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date(),
        activeDays: ["Mon", "Tue", "Wed", "Thu", "Fri"]
    )
    .preferredColorScheme(.dark)
}

#Preview("Light mode") {
    JoinRequestView(
        pickupLocation: "Borella",
        destinationLocation: "Maharagama",
        routeName: "Colombo Fort → Maharagama",
        routeId: "preview_route",
        driverId: "preview_driver",
        stops: ["Colombo Fort", "Borella", "Nugegoda", "Maharagama"],
        morningDepartureTime: Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date()) ?? Date(),
        eveningDepartureTime: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date(),
        activeDays: ["Mon", "Tue", "Wed", "Thu", "Fri"]
    )
    .preferredColorScheme(.light)
}
