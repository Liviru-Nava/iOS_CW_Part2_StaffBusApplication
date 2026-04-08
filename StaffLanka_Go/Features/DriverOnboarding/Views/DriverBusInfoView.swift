//
//  DriverBusInfoView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-07.
//

import SwiftUI

struct DriverBusInfoView: View {
    let personalInfoViewModel: DriverPersonalInfoViewModel

    @StateObject private var busInfoViewModel = DriverBusInfoViewModel()
    @FocusState private var focusedField: Field?
    @State private var navigateToRoute = false

    enum Field { case plate, busName, capacity }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    headerSection
                    formSection
                    continueButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Bus Information")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $navigateToRoute) {
            DriverRouteScheduleView(vm: DriverRouteScheduleViewModel())
        }
        .onTapGesture { focusedField = nil }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.13))
                    .frame(width: 80, height: 80)
                Image(systemName: "bus.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.brandAccent)
            }

            Text("Your Vehicle")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            Text("Tell us about the vehicle you'll be operating")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var formSection: some View {
        VStack(spacing: 20) {
            busInputField(
                label: "License Plate Number",
                placeholder: "e.g. ND-4029",
                text: $busInfoViewModel.plateNumber,
                icon: "rectangle.and.text.magnifyingglass",
                keyboard: .default,
                field: .plate,
                isValid: busInfoViewModel.isPlateValid || busInfoViewModel.plateNumber.isEmpty
            )

            busInputField(
                label: "Bus Name (Optional)",
                placeholder: "e.g. City Express",
                text: $busInfoViewModel.busName,
                icon: "tag.fill",
                keyboard: .default,
                field: .busName,
                isValid: true
            )

            busTypePicker

            busInputField(
                label: "Passenger Capacity",
                placeholder: "e.g. 40",
                text: $busInfoViewModel.capacity,
                icon: "person.2.fill",
                keyboard: .numberPad,
                field: .capacity,
                isValid: busInfoViewModel.isCapacityValid || busInfoViewModel.capacity.isEmpty
            )
        }
    }

    private func busInputField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        icon: String,
        keyboard: UIKeyboardType,
        field: Field,
        isValid: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(focusedField == field ? Color.brandAccent : Color.textTertiary)
                    .frame(width: 20)

                TextField(placeholder, text: text)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                    .keyboardType(keyboard)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: field)
                    .tint(Color.brandAccent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        !isValid ? Color.statusDanger :
                        focusedField == field ? Color.brandAccent.opacity(0.6) : Color.divider,
                        lineWidth: focusedField == field || !isValid ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: focusedField)
        }
    }

    private var busTypePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bus Type")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            HStack(spacing: 8) {
                ForEach(BusType.allCases) { type in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            busInfoViewModel.busType = type
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: busTypeIcon(type))
                                .font(.system(size: 12, weight: .medium))
                            Text(type.rawValue)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            busInfoViewModel.busType == type
                            ? Color.brandAccent.opacity(0.15)
                            : Color.cardBackground
                        )
                        .foregroundStyle(
                            busInfoViewModel.busType == type
                            ? Color.brandAccent
                            : Color.textSecondary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    busInfoViewModel.busType == type
                                    ? Color.brandAccent.opacity(0.5)
                                    : Color.divider,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func busTypeIcon(_ type: BusType) -> String {
        switch type {
        case .miniBus:  return "bus.fill"
        case .van:      return "car.fill"
        case .largeBus: return "bus.doubledecker.fill"
        }
    }

    private var continueButton: some View {
        Button {
            navigateToRoute = true
        } label: {
            HStack(spacing: 8) {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                busInfoViewModel.canContinue
                ? LinearGradient.brand
                : LinearGradient(colors: [Color.statusInactive.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!busInfoViewModel.canContinue)
    }
}

#Preview {
    NavigationStack {
        DriverBusInfoView(personalInfoViewModel: DriverPersonalInfoViewModel())
    }
    .preferredColorScheme(.dark)
}
