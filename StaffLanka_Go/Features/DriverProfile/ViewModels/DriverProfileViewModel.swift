//
//  DriverProfileViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//

import SwiftUI
import Combine

@MainActor
final class DriverProfileViewModel: ObservableObject {

    enum PassengerFilterType: String, CaseIterable, Identifiable {
        case active = "Active"
        case inactive = "Inactive"
        var id: String { rawValue }
    }

    enum PassengerSessionType: String {
        case morningOnly = "Morning Only"
        case eveningOnly = "Evening Only"
        case bothSessions = "Both"
    }

    enum PassengerPaymentStatusType: String {
        case paid = "Paid"
        case pending = "Pending"
    }

    enum PassengerInactiveReasonType: String {
        case notPaid = "Not Paid"
        case removed = "Removed"
    }

    enum PassengerRequestSessionPreference: String {
        case morningOnly = "Morning Only"
        case eveningOnly = "Evening Only"
        case bothSessions = "Both"
    }

    enum BusVehicleType: String {
        case miniBus = "Mini Bus"
        case van = "Van"
        case largeBus = "Large Bus"
    }

    enum DeadlineStatusType {
        case paid, gracePeriodActive, overdue
    }

    struct DriverProfileInformation {
        var driverFullName: String
        var driverPhoneNumber: String
        var driverLicenseNumber: String
    }

    struct BusVehicleDetails {
        var busPlateNumber: String
        var busDisplayName: String
        var busVehicleType: BusVehicleType
        var busPassengerCapacity: Int
    }

    struct RouteStopEntry: Identifiable {
        let id = UUID()
        let stopPositionIndex: Int
        let stopDisplayName: String
    }

    struct RouteInformation {
        var routeStartingPointName: String
        var routeEndingPointName: String
        var orderedListOfRouteStops: [RouteStopEntry]
    }

    struct TripScheduleTime {
        var departureTime: String
        var estimatedArrivalTime: String
    }

    struct ScheduleDetailsInformation {
        var morningTripSchedule: TripScheduleTime
        var eveningTripSchedule: TripScheduleTime
    }

    struct PricingDetailsInformation {
        var morningOnlyMonthlyFee: Int
        var eveningOnlyMonthlyFee: Int
        var bothSessionsMonthlyFee: Int
    }

    struct PassengerJoinRequest: Identifiable {
        let id = UUID()
        let passengerFullName: String
        let requestedPickupStopName: String
        let requestedDropOffLocationName: String
        let preferredSessionType: PassengerRequestSessionPreference
    }

    struct ActivePassengerEntry: Identifiable {
        let id = UUID()
        let passengerFullName: String
        let boardingStopName: String
        let enrolledSessionType: PassengerSessionType
        let currentPaymentStatus: PassengerPaymentStatusType
    }

    struct InactivePassengerEntry: Identifiable {
        let id = UUID()
        let passengerFullName: String
        let inactiveReasonType: PassengerInactiveReasonType
    }

    struct DriverReviewEntry: Identifiable {
        let id = UUID()
        let reviewerPassengerName: String
        let reviewRatingOutOfFive: Double
        let reviewCommentText: String
    }

    @Published var driverProfileInformationValues = DriverProfileInformation(
        driverFullName: "Kamal Perera",
        driverPhoneNumber: "+94 71 456 7890",
        driverLicenseNumber: "B1234567"
    )

    @Published var driverAvailabilityStatusIsOnline: Bool = true
    @Published var driverAcceptingRequestsState: Bool = true

    @Published var busDetailsInformationValues = BusVehicleDetails(
        busPlateNumber: "WP CAB-4892",
        busDisplayName: "Kamal Express",
        busVehicleType: .miniBus,
        busPassengerCapacity: 28
    )

    @Published var routeInformationValues = RouteInformation(
        routeStartingPointName: "Nugegoda Junction",
        routeEndingPointName: "World Trade Center",
        orderedListOfRouteStops: [
            RouteStopEntry(stopPositionIndex: 1, stopDisplayName: "Nugegoda Junction"),
            RouteStopEntry(stopPositionIndex: 2, stopDisplayName: "Maharagama Town"),
            RouteStopEntry(stopPositionIndex: 3, stopDisplayName: "Borella"),
            RouteStopEntry(stopPositionIndex: 4, stopDisplayName: "Fort Railway Station"),
            RouteStopEntry(stopPositionIndex: 5, stopDisplayName: "World Trade Center"),
        ]
    )

    @Published var scheduleDetailsValues = ScheduleDetailsInformation(
        morningTripSchedule: TripScheduleTime(departureTime: "6:30 AM", estimatedArrivalTime: "7:45 AM"),
        eveningTripSchedule: TripScheduleTime(departureTime: "5:00 PM", estimatedArrivalTime: "6:15 PM")
    )

    @Published var pricingDetailsValues = PricingDetailsInformation(
        morningOnlyMonthlyFee: 8500,
        eveningOnlyMonthlyFee: 8500,
        bothSessionsMonthlyFee: 14000
    )

    @Published var passengerRequestsList: [PassengerJoinRequest] = [
        PassengerJoinRequest(passengerFullName: "Amali Fernando", requestedPickupStopName: "Maharagama Town", requestedDropOffLocationName: "World Trade Center", preferredSessionType: .bothSessions),
        PassengerJoinRequest(passengerFullName: "Ruwan Jayasekara", requestedPickupStopName: "Borella", requestedDropOffLocationName: "World Trade Center", preferredSessionType: .morningOnly),
        PassengerJoinRequest(passengerFullName: "Sachini Wijesinghe", requestedPickupStopName: "Nugegoda Junction", requestedDropOffLocationName: "Fort Railway Station", preferredSessionType: .eveningOnly),
    ]

    @Published var activePassengersList: [ActivePassengerEntry] = [
        ActivePassengerEntry(passengerFullName: "Nimal Siriwardena", boardingStopName: "Nugegoda Junction", enrolledSessionType: .bothSessions, currentPaymentStatus: .paid),
        ActivePassengerEntry(passengerFullName: "Sanduni Rathnayake", boardingStopName: "Maharagama Town", enrolledSessionType: .morningOnly, currentPaymentStatus: .paid),
        ActivePassengerEntry(passengerFullName: "Chamara Dissanayake", boardingStopName: "Borella", enrolledSessionType: .eveningOnly, currentPaymentStatus: .pending),
        ActivePassengerEntry(passengerFullName: "Dilani Gunawardena", boardingStopName: "Nugegoda Junction", enrolledSessionType: .bothSessions, currentPaymentStatus: .paid),
        ActivePassengerEntry(passengerFullName: "Kasun Priyantha", boardingStopName: "Maharagama Town", enrolledSessionType: .morningOnly, currentPaymentStatus: .pending),
        ActivePassengerEntry(passengerFullName: "Iresha Perera", boardingStopName: "Borella", enrolledSessionType: .bothSessions, currentPaymentStatus: .paid),
    ]

    @Published var inactivePassengersList: [InactivePassengerEntry] = [
        InactivePassengerEntry(passengerFullName: "Tharaka Bandara", inactiveReasonType: .notPaid),
        InactivePassengerEntry(passengerFullName: "Malini Senanayake", inactiveReasonType: .removed),
    ]

    @Published var driverReviewsList: [DriverReviewEntry] = [
        DriverReviewEntry(reviewerPassengerName: "Nimal Siriwardena", reviewRatingOutOfFive: 5.0, reviewCommentText: "Very punctual and professional driver. Always on time!"),
        DriverReviewEntry(reviewerPassengerName: "Sanduni Rathnayake", reviewRatingOutOfFive: 4.5, reviewCommentText: "Comfortable ride. The bus is always clean."),
        DriverReviewEntry(reviewerPassengerName: "Dilani Gunawardena", reviewRatingOutOfFive: 4.0, reviewCommentText: "Good service overall. Occasionally a few minutes late."),
        DriverReviewEntry(reviewerPassengerName: "Iresha Perera", reviewRatingOutOfFive: 5.0, reviewCommentText: "Excellent driver! Highly recommended."),
    ]

    @Published var selectedPassengerFilterType: PassengerFilterType = .active
    @Published var isEditingDriverProfile: Bool = false
    @Published var isEditingBusDetails: Bool = false
    @Published var isEditingPricingDetails: Bool = false
    @Published var showSignOutConfirmationAlert: Bool = false

    @Published var editingDriverFullName: String = ""
    @Published var editingDriverPhoneNumber: String = ""
    @Published var editingDriverLicenseNumber: String = ""
    @Published var editingBusPlateNumber: String = ""
    @Published var editingBusDisplayName: String = ""
    @Published var editingBusPassengerCapacity: String = ""
    @Published var editingMorningOnlyFee: String = ""
    @Published var editingEveningOnlyFee: String = ""
    @Published var editingBothSessionsFee: String = ""

    var driverProfileInitialsText: String {
        let nameParts = driverProfileInformationValues.driverFullName.split(separator: " ")
        if nameParts.count >= 2 {
            return "\(nameParts[0].prefix(1))\(nameParts[1].prefix(1))".uppercased()
        }
        return String(driverProfileInformationValues.driverFullName.prefix(2)).uppercased()
    }

    var averageDriverRatingValue: Double {
        guard !driverReviewsList.isEmpty else { return 0 }
        let totalRating = driverReviewsList.reduce(0.0) { $0 + $1.reviewRatingOutOfFive }
        return totalRating / Double(driverReviewsList.count)
    }

    func openDriverProfileEditMode() {
        editingDriverFullName = driverProfileInformationValues.driverFullName
        editingDriverPhoneNumber = driverProfileInformationValues.driverPhoneNumber
        editingDriverLicenseNumber = driverProfileInformationValues.driverLicenseNumber
        isEditingDriverProfile = true
    }

    func saveDriverProfileEdits() {
        if !editingDriverFullName.trimmingCharacters(in: .whitespaces).isEmpty {
            driverProfileInformationValues.driverFullName = editingDriverFullName
        }
        driverProfileInformationValues.driverPhoneNumber = editingDriverPhoneNumber
        driverProfileInformationValues.driverLicenseNumber = editingDriverLicenseNumber
        isEditingDriverProfile = false
    }

    func cancelDriverProfileEdits() {
        isEditingDriverProfile = false
    }

    func openBusDetailsEditMode() {
        editingBusPlateNumber = busDetailsInformationValues.busPlateNumber
        editingBusDisplayName = busDetailsInformationValues.busDisplayName
        editingBusPassengerCapacity = "\(busDetailsInformationValues.busPassengerCapacity)"
        isEditingBusDetails = true
    }

    func saveBusDetailsEdits() {
        busDetailsInformationValues.busPlateNumber = editingBusPlateNumber
        busDetailsInformationValues.busDisplayName = editingBusDisplayName
        if let parsedCapacity = Int(editingBusPassengerCapacity) {
            busDetailsInformationValues.busPassengerCapacity = parsedCapacity
        }
        isEditingBusDetails = false
    }

    func cancelBusDetailsEdits() {
        isEditingBusDetails = false
    }

    func openPricingDetailsEditMode() {
        editingMorningOnlyFee = "\(pricingDetailsValues.morningOnlyMonthlyFee)"
        editingEveningOnlyFee = "\(pricingDetailsValues.eveningOnlyMonthlyFee)"
        editingBothSessionsFee = "\(pricingDetailsValues.bothSessionsMonthlyFee)"
        isEditingPricingDetails = true
    }

    func savePricingDetailsEdits() {
        if let parsedMorning = Int(editingMorningOnlyFee) { pricingDetailsValues.morningOnlyMonthlyFee = parsedMorning }
        if let parsedEvening = Int(editingEveningOnlyFee) { pricingDetailsValues.eveningOnlyMonthlyFee = parsedEvening }
        if let parsedBoth = Int(editingBothSessionsFee) { pricingDetailsValues.bothSessionsMonthlyFee = parsedBoth }
        isEditingPricingDetails = false
    }

    func cancelPricingDetailsEdits() {
        isEditingPricingDetails = false
    }

    func acceptPassengerJoinRequest(requestIdentifier: UUID) {
        passengerRequestsList.removeAll { $0.id == requestIdentifier }
    }

    func rejectPassengerJoinRequest(requestIdentifier: UUID) {
        passengerRequestsList.removeAll { $0.id == requestIdentifier }
    }

    func terminateActivePassenger(passengerIdentifier: UUID) {
        if let removedPassenger = activePassengersList.first(where: { $0.id == passengerIdentifier }) {
            activePassengersList.removeAll { $0.id == passengerIdentifier }
            let newInactiveEntry = InactivePassengerEntry(
                passengerFullName: removedPassenger.passengerFullName,
                inactiveReasonType: .removed
            )
            inactivePassengersList.append(newInactiveEntry)
        }
    }

    func signOut() {
        AuthManager.shared.signOut()
    }
}
