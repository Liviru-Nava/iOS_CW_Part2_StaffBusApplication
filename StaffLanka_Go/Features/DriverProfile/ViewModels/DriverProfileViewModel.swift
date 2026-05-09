//
//  DriverProfileViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import MapKit

@MainActor
final class DriverProfileViewModel: ObservableObject {

    enum PassengerFilterType: String, CaseIterable, Identifiable {
        case active   = "Active"
        case inactive = "Inactive"
        var id: String { rawValue }
    }

    // Date-based filter for the inactive passengers list
    enum InactiveDateRangeFilter: String, CaseIterable, Identifiable {
        case allTime    = "All Time"
        case today      = "Today"
        case thisWeek   = "This Week"
        case thisMonth  = "This Month"
        var id: String { rawValue }
    }

    enum PassengerSessionType: String {
        case morningOnly   = "Morning Only"
        case eveningOnly   = "Evening Only"
        case bothSessions  = "Both"
    }

    enum PassengerPaymentStatusType: String {
        case paid    = "Paid"
        case pending = "Pending"
    }

    enum PassengerInactiveReasonType: String {
        case notPaid     = "Not Paid"
        case removed     = "Removed"
        // The passenger cancelled their own enrollment — shown as "Self-Removed" to distinguish from driver-initiated removal
        case selfRemoved = "Self-Removed"
    }

    enum PassengerRequestSessionPreference: String {
        case morningOnly  = "Morning Only"
        case eveningOnly  = "Evening Only"
        case bothSessions = "Both"
    }

    enum BusVehicleType: String {
        case miniBus  = "Mini Bus"
        case van      = "Van"
        case largeBus = "Large Bus"
    }

    struct DriverProfileInformation {
        var driverFullName: String
        var driverPhoneNumber: String
        var driverLicenseNumber: String
        var driverEmailAddress: String
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
        let latitude: Double
        let longitude: Double
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
        let id: String
        let passengerFullName: String
        let passengerPhone: String
        let requestedPickupStopName: String
        let requestedDropOffLocationName: String
        let preferredSessionType: PassengerRequestSessionPreference
        let noteFromPassenger: String
    }

    struct ActivePassengerEntry: Identifiable {
        // docId from Firestore joinRequests so we can act on the correct document
        let id: String
        let passengerUserId: String
        let passengerFullName: String
        let passengerPhoneNumber: String
        let boardingStopName: String
        let dropOffStopName: String
        let enrolledSessionType: PassengerSessionType
        let currentPaymentStatus: PassengerPaymentStatusType
    }

    struct InactivePassengerEntry: Identifiable {
        let id: String
        let passengerFullName: String
        let inactiveReasonType: PassengerInactiveReasonType
        // The date when the passenger was removed or became inactive — used for date-range filtering
        let removedDate: Date
    }

    // Published properties for driver profile data

    @Published var driverProfileInformationValues = DriverProfileInformation(
        driverFullName:       "Loading...",
        driverPhoneNumber:    "Loading...",
        driverLicenseNumber:  "Loading...",
        driverEmailAddress:   ""
    )

    @Published var driverAvailabilityStatusIsOnline: Bool = true {
        didSet {
            if oldValue != driverAvailabilityStatusIsOnline { pushServiceStatusUpdate() }
        }
    }

    @Published var driverAcceptingRequestsState: Bool = true {
        didSet {
            if oldValue != driverAcceptingRequestsState { pushAcceptingRequestsUpdate() }
        }
    }

    @Published var busDetailsInformationValues = BusVehicleDetails(
        busPlateNumber: "Loading...",
        busDisplayName: "Loading...",
        busVehicleType: .miniBus,
        busPassengerCapacity: 0
    )

    @Published var routeInformationValues = RouteInformation(
        routeStartingPointName: "Loading...",
        routeEndingPointName:   "Loading...",
        orderedListOfRouteStops: []
    )

    @Published var scheduleDetailsValues = ScheduleDetailsInformation(
        morningTripSchedule: TripScheduleTime(departureTime: "Loading...", estimatedArrivalTime: "Loading..."),
        eveningTripSchedule: TripScheduleTime(departureTime: "Loading...", estimatedArrivalTime: "Loading...")
    )

    @Published var pricingDetailsValues = PricingDetailsInformation(
        morningOnlyMonthlyFee:  0,
        eveningOnlyMonthlyFee:  0,
        bothSessionsMonthlyFee: 0
    )

    @Published var driverProfilePhotoImageData: Data? = nil
    @Published var selectedProfilePhotoPicPickerItem: PhotosPickerItem? = nil

    @Published var passengerRequestsList:  [PassengerJoinRequest]  = []
    @Published var activePassengersList:   [ActivePassengerEntry]  = []
    @Published var inactivePassengersList: [InactivePassengerEntry] = []

    @Published var selectedPassengerFilterType: PassengerFilterType = .active
    // Currently selected date range filter for the inactive passengers list
    @Published var selectedInactiveDateRangeFilter: InactiveDateRangeFilter = .allTime

    @Published var isEditingDriverProfile:  Bool = false
    @Published var isEditingBusDetails:     Bool = false
    @Published var isEditingPricingDetails: Bool = false
    @Published var isEditingRouteStops:     Bool = false
    @Published var isEditingSchedule:       Bool = false
    @Published var showSignOutConfirmationAlert: Bool = false

    @Published var showRemoveLocalDataConfirm: Bool = false
    @Published var localDataRemoved: Bool = false

    @Published var showDeleteAccountConfirm: Bool = false
    @Published var isDeletingAccount: Bool = false
    @Published var deleteAccountError: String? = nil
    @Published var showDeleteAccountError: Bool = false

    @Published var editingDriverFullName:      String = ""
    @Published var editingDriverPhoneNumber:   String = ""
    @Published var editingDriverLicenseNumber: String = ""
    @Published var editingDriverEmailAddress:  String = ""

    @Published var editingBusPlateNumber:       String = ""
    @Published var editingBusDisplayName:       String = ""
    @Published var editingBusPassengerCapacity: String = ""
    @Published var editingMorningOnlyFee:       String = ""
    @Published var editingEveningOnlyFee:       String = ""
    @Published var editingBothSessionsFee:      String = ""
    @Published var editingMorningDepartureTime: Date   = Date()
    @Published var editingEveningDepartureTime: Date   = Date()

    @Published var editingRouteStartLocation: RouteLocationData? = nil
    @Published var editingRouteEndLocation: RouteLocationData? = nil

    @Published var editingRouteStopsList: [RouteStopEntry] = []
    @Published var isDataLoading: Bool = false

    private var currentDriverModel: DriverModel?
    private var currentRouteModel:  RouteModel?

    nonisolated(unsafe) private var pendingRequestsListenerRegistration: ListenerRegistration?
    nonisolated(unsafe) private var acceptedPassengersListenerRegistration: ListenerRegistration?

    private let firestoreDatabase = Firestore.firestore()

    deinit {
        pendingRequestsListenerRegistration?.remove()
        acceptedPassengersListenerRegistration?.remove()
    }

    // Returns the inactive passengers list filtered by the selected date range
    var inactivePassengersFilteredByDateRange: [InactivePassengerEntry] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedInactiveDateRangeFilter {
        case .allTime:
            return inactivePassengersList

        case .today:
            return inactivePassengersList.filter { calendar.isDateInToday($0.removedDate) }

        case .thisWeek:
            guard let startOfCurrentWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
                return inactivePassengersList
            }
            return inactivePassengersList.filter { $0.removedDate >= startOfCurrentWeek }

        case .thisMonth:
            guard let startOfCurrentMonth = calendar.dateInterval(of: .month, for: now)?.start else {
                return inactivePassengersList
            }
            return inactivePassengersList.filter { $0.removedDate >= startOfCurrentMonth }
        }
    }

    // Groups the date-filtered inactive passengers by a human-readable date label
    // Used by the manage passengers view to show date section headers in the inactive list
    var inactivePassengersGroupedByDate: [(String, [InactivePassengerEntry])] {
        let abbreviatedDateFormatter = DateFormatter()
        abbreviatedDateFormatter.dateStyle = .medium

        var groupDictionary: [String: [InactivePassengerEntry]] = [:]

        for inactivePassenger in inactivePassengersFilteredByDateRange {
            let groupKey: String
            if Calendar.current.isDateInToday(inactivePassenger.removedDate) {
                groupKey = "Today"
            } else if Calendar.current.isDateInYesterday(inactivePassenger.removedDate) {
                groupKey = "Yesterday"
            } else {
                groupKey = abbreviatedDateFormatter.string(from: inactivePassenger.removedDate)
            }
            groupDictionary[groupKey, default: []].append(inactivePassenger)
        }

        // Sort groups descending so the most recently removed passengers appear first
        return groupDictionary.sorted { firstGroup, secondGroup in
            guard let firstDate = firstGroup.value.first?.removedDate,
                  let secondDate = secondGroup.value.first?.removedDate else { return false }
            return firstDate > secondDate
        }
    }

    // Core Data — Load cached profile from Core Data before Firestore fetch completes

    func loadFromCoreData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard let cachedDriverProfile = CoreDataManager.shared.fetchDriverProfile(userId: userId) else { return }

        driverProfileInformationValues = DriverProfileInformation(
            driverFullName:      cachedDriverProfile.fullName      ?? "",
            driverPhoneNumber:   cachedDriverProfile.phoneNumber   ?? "",
            driverLicenseNumber: cachedDriverProfile.licenseNumber ?? "",
            driverEmailAddress:  cachedDriverProfile.emailAddress  ?? ""
        )
        busDetailsInformationValues = BusVehicleDetails(
            busPlateNumber:       cachedDriverProfile.plateNumber ?? "",
            busDisplayName:       cachedDriverProfile.busName     ?? "",
            busVehicleType:       .van,
            busPassengerCapacity: 0
        )

        print("[CoreData] Loaded from cache — name: \(driverProfileInformationValues.driverFullName)")
    }

    private func cacheProfileLocally() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        CoreDataManager.shared.saveDriverProfile(
            userId:           userId,
            fullName:         driverProfileInformationValues.driverFullName,
            phoneNumber:      driverProfileInformationValues.driverPhoneNumber,
            emailAddress:     driverProfileInformationValues.driverEmailAddress,
            licenseNumber:    driverProfileInformationValues.driverLicenseNumber,
            busName:          busDetailsInformationValues.busDisplayName,
            plateNumber:      busDetailsInformationValues.busPlateNumber,
            profilePhotoData: driverProfilePhotoImageData
        )

        print("[CoreData] Cached driver profile for userId: \(userId)")
    }

    func removeLocalData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        CoreDataManager.shared.deleteAllLocalData(userId: userId)
        driverProfileInformationValues = DriverProfileInformation(
            driverFullName: "", driverPhoneNumber: "",
            driverLicenseNumber: "", driverEmailAddress: ""
        )
        driverProfilePhotoImageData = nil
        localDataRemoved = true
    }

    // Firestore Fetch — loads driver profile, route, and schedule data

    func fetchDriverProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isDataLoading = true
        Task {
            do {
                let driverRecord = try await DriverService.shared.fetchDriver(driverId: userId)
                let userRecord   = try await UserService.shared.fetchUser(userId: userId)
                self.currentDriverModel = driverRecord

                self.driverProfileInformationValues = DriverProfileInformation(
                    driverFullName:      driverRecord.fullName,
                    driverPhoneNumber:   userRecord?.phoneNumber ?? "No Phone Number",
                    driverLicenseNumber: driverRecord.licenseNumber,
                    driverEmailAddress:  userRecord?.emailAddress ?? ""
                )

                self.busDetailsInformationValues = BusVehicleDetails(
                    busPlateNumber:      driverRecord.busInformation.plateNumber,
                    busDisplayName:      driverRecord.busInformation.busName,
                    busVehicleType:      BusVehicleType(rawValue: driverRecord.busInformation.busType) ?? .van,
                    busPassengerCapacity: driverRecord.busInformation.passengerCapacity
                )

                self.driverAvailabilityStatusIsOnline = (driverRecord.serviceStatus ?? "active") == "active"
                self.driverAcceptingRequestsState     = driverRecord.isAcceptingRequests ?? true

                if let base64PhotoString = driverRecord.profilePhotoBase64,
                   !base64PhotoString.isEmpty,
                   let decodedPhotoData = Data(base64Encoded: base64PhotoString) {
                    self.driverProfilePhotoImageData = decodedPhotoData
                }

                do {
                    let routeRecord = try await RouteService.shared.fetchRoute(routeId: driverRecord.assignedRouteId)
                    self.currentRouteModel = routeRecord

                    let sortedRouteStopEntries = routeRecord.routeStops.sorted { $0.stopOrder < $1.stopOrder }.map { routeStop in
                        RouteStopEntry(
                            stopPositionIndex: routeStop.stopOrder,
                            stopDisplayName:   routeStop.stopName,
                            latitude:          routeStop.latitude,
                            longitude:         routeStop.longitude
                        )
                    }

                    self.routeInformationValues = RouteInformation(
                        routeStartingPointName:  routeRecord.startLocation.locationName,
                        routeEndingPointName:    routeRecord.endLocation.locationName,
                        orderedListOfRouteStops: sortedRouteStopEntries
                    )

                    let timeFormatter       = DateFormatter()
                    timeFormatter.timeStyle = .short

                    var morningDepartureDisplay = "N/A"; var morningArrivalDisplay = "N/A"
                    var eveningDepartureDisplay = "N/A"; var eveningArrivalDisplay = "N/A"

                    if routeRecord.scheduleEntries.count > 0 {
                        let morningScheduleEntry = routeRecord.scheduleEntries[0]
                        morningDepartureDisplay = timeFormatter.string(from: morningScheduleEntry.scheduledDepartureTime)
                        if let morningArrival = morningScheduleEntry.scheduledArrivalTime {
                            morningArrivalDisplay = timeFormatter.string(from: morningArrival)
                        }
                    }
                    if routeRecord.scheduleEntries.count > 1 {
                        let eveningScheduleEntry = routeRecord.scheduleEntries[1]
                        eveningDepartureDisplay = timeFormatter.string(from: eveningScheduleEntry.scheduledDepartureTime)
                        if let eveningArrival = eveningScheduleEntry.scheduledArrivalTime {
                            eveningArrivalDisplay = timeFormatter.string(from: eveningArrival)
                        }
                    }

                    self.scheduleDetailsValues = ScheduleDetailsInformation(
                        morningTripSchedule: TripScheduleTime(departureTime: morningDepartureDisplay, estimatedArrivalTime: morningArrivalDisplay),
                        eveningTripSchedule: TripScheduleTime(departureTime: eveningDepartureDisplay, estimatedArrivalTime: eveningArrivalDisplay)
                    )

                    self.pricingDetailsValues = PricingDetailsInformation(
                        morningOnlyMonthlyFee:  Int(routeRecord.morningPrice  ?? 0),
                        eveningOnlyMonthlyFee:  Int(routeRecord.eveningPrice  ?? 0),
                        bothSessionsMonthlyFee: Int(routeRecord.bothTripsPrice ?? 0)
                    )
                } catch {
                    print("Error fetching route for profile: \(error)")
                }

                self.isDataLoading = false
                self.cacheProfileLocally()
                self.listenForJoinRequests(driverId: userId)
                self.listenForAcceptedPassengers(driverId: userId)
            } catch {
                self.driverProfileInformationValues.driverFullName = "Error Loading"
                self.isDataLoading = false
            }
        }
    }

    // Computed Properties

    var driverProfileInitialsText: String {
        let nameParts = driverProfileInformationValues.driverFullName.split(separator: " ")
        if nameParts.count >= 2 {
            return "\(nameParts[0].prefix(1))\(nameParts[1].prefix(1))".uppercased()
        }
        return String(driverProfileInformationValues.driverFullName.prefix(2)).uppercased()
    }

    // Profile Editing

    func openDriverProfileEditMode() {
        editingDriverFullName      = driverProfileInformationValues.driverFullName
        editingDriverPhoneNumber   = driverProfileInformationValues.driverPhoneNumber
        editingDriverLicenseNumber = driverProfileInformationValues.driverLicenseNumber
        editingDriverEmailAddress  = driverProfileInformationValues.driverEmailAddress
        isEditingDriverProfile = true
    }

    func saveDriverProfileEdits() {
        if !editingDriverFullName.trimmingCharacters(in: .whitespaces).isEmpty {
            driverProfileInformationValues.driverFullName = editingDriverFullName
        }
        driverProfileInformationValues.driverLicenseNumber = editingDriverLicenseNumber
        driverProfileInformationValues.driverEmailAddress  = editingDriverEmailAddress

        if var driverModel = currentDriverModel {
            driverModel.fullName      = driverProfileInformationValues.driverFullName
            driverModel.licenseNumber = driverProfileInformationValues.driverLicenseNumber

            Task {
                do {
                    if let userId = driverModel.id ?? Auth.auth().currentUser?.uid {
                        try await DriverService.shared.updateDriver(driverId: userId, updatedRecord: driverModel)
                        try await UserService.shared.updateUserRoleAndName(userId: userId, updatedRole: "driver", fullName: driverModel.fullName)
                        try await UserService.shared.updateUserEmailAddress(userId: userId, updatedEmailAddress: editingDriverEmailAddress)
                    }
                } catch {
                    print("Could not update profile: \(error)")
                }
            }
            self.currentDriverModel = driverModel
        }

        cacheProfileLocally()
        isEditingDriverProfile = false
    }

    func cancelDriverProfileEdits() {
        isEditingDriverProfile = false
    }

    func processAndUploadSelectedProfilePhoto(selectedPhotoPickerItem item: PhotosPickerItem) {
        Task {
            guard let rawPhotoData = try? await item.loadTransferable(type: Data.self) else { return }
            guard let selectedUIImage = UIImage(data: rawPhotoData) else { return }
            let compressedPhotoData = selectedUIImage.jpegData(compressionQuality: 0.25) ?? rawPhotoData

            guard compressedPhotoData.count < 900_000 else {
                print("Profile photo is too large after compression.")
                return
            }

            let base64EncodedPhotoString = compressedPhotoData.base64EncodedString()
            self.driverProfilePhotoImageData = compressedPhotoData

            if var driverModel = self.currentDriverModel,
               let userId = driverModel.id ?? Auth.auth().currentUser?.uid {
                driverModel.profilePhotoBase64 = base64EncodedPhotoString
                do {
                    try await DriverService.shared.updateDriver(driverId: userId, updatedRecord: driverModel)
                    self.currentDriverModel = driverModel
                    self.cacheProfileLocally()
                } catch {
                    print("Failed to save profile photo to Firestore: \(error)")
                }
            }
        }
    }

    func refreshDisplayedPhoneNumber() {
        Task {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            do {
                let userRecord = try await UserService.shared.fetchUser(userId: userId)
                self.driverProfileInformationValues.driverPhoneNumber = userRecord?.phoneNumber ?? ""
            } catch {
                print("Failed to refresh phone number: \(error)")
            }
        }
    }

    // Bus Details Editing

    func openBusDetailsEditMode() {
        editingBusPlateNumber       = busDetailsInformationValues.busPlateNumber
        editingBusDisplayName       = busDetailsInformationValues.busDisplayName
        editingBusPassengerCapacity = "\(busDetailsInformationValues.busPassengerCapacity)"
        isEditingBusDetails = true
    }

    func saveBusDetailsEdits() {
        busDetailsInformationValues.busPlateNumber = editingBusPlateNumber
        busDetailsInformationValues.busDisplayName = editingBusDisplayName
        if let parsedCapacity = Int(editingBusPassengerCapacity) {
            busDetailsInformationValues.busPassengerCapacity = parsedCapacity
        }

        if var driverModel = currentDriverModel {
            driverModel.busInformation.plateNumber       = busDetailsInformationValues.busPlateNumber
            driverModel.busInformation.busName           = busDetailsInformationValues.busDisplayName
            driverModel.busInformation.passengerCapacity = busDetailsInformationValues.busPassengerCapacity

            Task {
                do {
                    if let userId = driverModel.id ?? Auth.auth().currentUser?.uid {
                        try await DriverService.shared.updateDriver(driverId: userId, updatedRecord: driverModel)
                    }
                } catch { print("Could not update bus info: \(error)") }
            }
            self.currentDriverModel = driverModel
        }

        cacheProfileLocally()
        isEditingBusDetails = false
    }

    func cancelBusDetailsEdits() {
        isEditingBusDetails = false
    }

    // Pricing Editing

    func openPricingDetailsEditMode() {
        editingMorningOnlyFee  = "\(pricingDetailsValues.morningOnlyMonthlyFee)"
        editingEveningOnlyFee  = "\(pricingDetailsValues.eveningOnlyMonthlyFee)"
        editingBothSessionsFee = "\(pricingDetailsValues.bothSessionsMonthlyFee)"
        isEditingPricingDetails = true
    }

    func savePricingDetailsEdits() {
        if let morningFee = Int(editingMorningOnlyFee.trimmingCharacters(in: .whitespaces))  { pricingDetailsValues.morningOnlyMonthlyFee  = morningFee }
        if let eveningFee = Int(editingEveningOnlyFee.trimmingCharacters(in: .whitespaces))  { pricingDetailsValues.eveningOnlyMonthlyFee  = eveningFee }
        if let bothFee = Int(editingBothSessionsFee.trimmingCharacters(in: .whitespaces)) { pricingDetailsValues.bothSessionsMonthlyFee = bothFee }

        if var routeModel = currentRouteModel {
            routeModel.morningPrice   = Double(pricingDetailsValues.morningOnlyMonthlyFee)
            routeModel.eveningPrice   = Double(pricingDetailsValues.eveningOnlyMonthlyFee)
            routeModel.bothTripsPrice = Double(pricingDetailsValues.bothSessionsMonthlyFee)

            Task {
                do {
                    if let routeId = currentDriverModel?.assignedRouteId {
                        try await RouteService.shared.updateRoute(routeId: routeId, updatedRecord: routeModel)
                    }
                } catch { print("Could not update pricing: \(error)") }
            }
            self.currentRouteModel = routeModel
        }
        isEditingPricingDetails = false
    }

    func cancelPricingDetailsEdits() {
        isEditingPricingDetails = false
    }

    // Schedule Editing

    func openScheduleEditMode() {
        if let routeModel = currentRouteModel, routeModel.scheduleEntries.count > 1 {
            editingMorningDepartureTime = routeModel.scheduleEntries[0].scheduledDepartureTime
            editingEveningDepartureTime = routeModel.scheduleEntries[1].scheduledDepartureTime
        }
        isEditingSchedule = true
    }

    func saveScheduleEdits() {
        guard var routeModel = currentRouteModel, routeModel.scheduleEntries.count > 1 else {
            isEditingSchedule = false
            return
        }

        let startLocationData = editingRouteStartLocation ?? routeModel.startLocation
        let endLocationData   = editingRouteEndLocation   ?? routeModel.endLocation

        let directionsRequest = MKDirections.Request()
        directionsRequest.source      = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: startLocationData.latitude, longitude: startLocationData.longitude)))
        directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: endLocationData.latitude, longitude: endLocationData.longitude)))
        directionsRequest.transportType = .automobile

        Task {
            var estimatedTravelMinutes = (routeInformationValues.orderedListOfRouteStops.count + 1) * 8
            do {
                let directionsCalculator = MKDirections(request: directionsRequest)
                let directionsResponse   = try await directionsCalculator.calculate()
                if let bestRoute = directionsResponse.routes.first {
                    let travelTimeInSeconds = bestRoute.expectedTravelTime
                    let stopDelayInSeconds  = Double(routeInformationValues.orderedListOfRouteStops.count * 3 * 60)
                    estimatedTravelMinutes = Int((travelTimeInSeconds + stopDelayInSeconds) / 60)
                }
            } catch {
                print("Could not calculate exact ETA, falling back: \(error)")
            }

            let calculatedMorningArrival = Calendar.current.date(byAdding: .minute, value: estimatedTravelMinutes, to: self.editingMorningDepartureTime) ?? self.editingMorningDepartureTime
            let calculatedEveningArrival = Calendar.current.date(byAdding: .minute, value: estimatedTravelMinutes, to: self.editingEveningDepartureTime) ?? self.editingEveningDepartureTime

            routeModel.scheduleEntries[0].scheduledDepartureTime = self.editingMorningDepartureTime
            routeModel.scheduleEntries[0].scheduledArrivalTime   = calculatedMorningArrival
            routeModel.scheduleEntries[1].scheduledDepartureTime = self.editingEveningDepartureTime
            routeModel.scheduleEntries[1].scheduledArrivalTime   = calculatedEveningArrival

            do {
                if let routeId = self.currentDriverModel?.assignedRouteId {
                    try await RouteService.shared.updateRoute(routeId: routeId, updatedRecord: routeModel)
                }
            } catch { print("Update schedule error: \(error)") }

            self.currentRouteModel = routeModel

            let timeDisplayFormatter = DateFormatter(); timeDisplayFormatter.timeStyle = .short
            self.scheduleDetailsValues = ScheduleDetailsInformation(
                morningTripSchedule: TripScheduleTime(departureTime: timeDisplayFormatter.string(from: self.editingMorningDepartureTime), estimatedArrivalTime: timeDisplayFormatter.string(from: calculatedMorningArrival)),
                eveningTripSchedule: TripScheduleTime(departureTime: timeDisplayFormatter.string(from: self.editingEveningDepartureTime), estimatedArrivalTime: timeDisplayFormatter.string(from: calculatedEveningArrival))
            )
            self.isEditingSchedule = false
        }
    }

    func cancelScheduleEdits() { isEditingSchedule = false }

    // Route Stop Editing

    func openRouteEditMode() {
        if let routeModel = currentRouteModel {
            editingRouteStartLocation = routeModel.startLocation
            editingRouteEndLocation   = routeModel.endLocation
        }
        editingRouteStopsList = routeInformationValues.orderedListOfRouteStops
        isEditingRouteStops = true
    }

    func saveRouteEdits() {
        routeInformationValues.orderedListOfRouteStops = editingRouteStopsList

        if let updatedStartLocation = editingRouteStartLocation { routeInformationValues.routeStartingPointName = updatedStartLocation.locationName }
        if let updatedEndLocation   = editingRouteEndLocation   { routeInformationValues.routeEndingPointName   = updatedEndLocation.locationName   }

        if var routeModel = currentRouteModel {
            let updatedRouteStops = editingRouteStopsList.enumerated().map { (stopIndex, stopEntry) in
                RouteStopData(
                    stopName:  stopEntry.stopDisplayName,
                    latitude:  stopEntry.latitude,
                    longitude: stopEntry.longitude,
                    stopOrder: stopIndex
                )
            }
            routeModel.routeStops = updatedRouteStops
            if let updatedStart = editingRouteStartLocation { routeModel.startLocation = updatedStart }
            if let updatedEnd   = editingRouteEndLocation   { routeModel.endLocation   = updatedEnd   }

            Task {
                do {
                    if let routeId = currentDriverModel?.assignedRouteId {
                        try await RouteService.shared.updateRoute(routeId: routeId, updatedRecord: routeModel)
                    }
                } catch { print("Update route error: \(error)") }
            }
            self.currentRouteModel = routeModel
        }
        isEditingRouteStops = false
    }

    func cancelRouteEdits() { isEditingRouteStops = false }

    func deleteStop(at offsets: IndexSet) {
        editingRouteStopsList.remove(atOffsets: offsets)
        for stopIndex in editingRouteStopsList.indices {
            let existingStop = editingRouteStopsList[stopIndex]
            editingRouteStopsList[stopIndex] = RouteStopEntry(
                stopPositionIndex: stopIndex,
                stopDisplayName:   existingStop.stopDisplayName,
                latitude:          existingStop.latitude,
                longitude:         existingStop.longitude
            )
        }
    }

    func moveStop(from sourceOffsets: IndexSet, to destinationOffset: Int) {
        editingRouteStopsList.move(fromOffsets: sourceOffsets, toOffset: destinationOffset)
        for stopIndex in editingRouteStopsList.indices {
            let existingStop = editingRouteStopsList[stopIndex]
            editingRouteStopsList[stopIndex] = RouteStopEntry(
                stopPositionIndex: stopIndex,
                stopDisplayName:   existingStop.stopDisplayName,
                latitude:          existingStop.latitude,
                longitude:         existingStop.longitude
            )
        }
    }

    // Status Pushes to Firestore

    func pushServiceStatusUpdate() {
        if var driverModel = currentDriverModel, !isDataLoading {
            driverModel.serviceStatus = driverAvailabilityStatusIsOnline ? "active" : "offline"
            Task {
                do {
                    if let userId = driverModel.id ?? Auth.auth().currentUser?.uid {
                        try await DriverService.shared.updateDriver(driverId: userId, updatedRecord: driverModel)
                    }
                } catch { print("Update service status error: \(error)") }
            }
            self.currentDriverModel = driverModel
        }
    }

    func pushAcceptingRequestsUpdate() {
        if var driverModel = currentDriverModel, !isDataLoading {
            driverModel.isAcceptingRequests = driverAcceptingRequestsState
            Task {
                do {
                    if let userId = driverModel.id ?? Auth.auth().currentUser?.uid {
                        try await DriverService.shared.updateDriver(driverId: userId, updatedRecord: driverModel)
                    }
                } catch { print("Update accepting requests error: \(error)") }
            }
            self.currentDriverModel = driverModel
        }
    }

    // Join Request Listener

    private func listenForJoinRequests(driverId: String) {
        pendingRequestsListenerRegistration?.remove()
        pendingRequestsListenerRegistration = JoinRequestService.shared.listenForPendingRequests(driverId: driverId) { [weak self] receivedRequestModels in
            guard let self else { return }
            Task { @MainActor in
                let previousRequestCount = self.passengerRequestsList.count
                self.passengerRequestsList = receivedRequestModels.compactMap { requestModel in
                    guard let documentId = requestModel.id else { return nil }
                    let mappedSessionPreference: PassengerRequestSessionPreference
                    switch requestModel.session {
                    case "Morning": mappedSessionPreference = .morningOnly
                    case "Evening": mappedSessionPreference = .eveningOnly
                    default:        mappedSessionPreference = .bothSessions
                    }
                    return PassengerJoinRequest(
                        id: documentId,
                        passengerFullName:            requestModel.passengerName,
                        passengerPhone:               requestModel.passengerPhone,
                        requestedPickupStopName:      requestModel.pickupStop,
                        requestedDropOffLocationName: requestModel.dropoffStop,
                        preferredSessionType:         mappedSessionPreference,
                        noteFromPassenger:            requestModel.note
                    )
                }
                if receivedRequestModels.count > previousRequestCount {
                    NotificationManager.shared.scheduleNotification(
                        title: "New Join Request",
                        body: "A passenger has requested to join your route.",
                        isTripAlert: false
                    )
                }
            }
        }
    }

    // Accepted Passengers Listener
    // Listens for both "accepted" and "cancelled" documents so the driver can see
    // whether a departure was passenger-initiated ("self-removed") or driver-initiated ("removed")

    private func listenForAcceptedPassengers(driverId: String) {
        acceptedPassengersListenerRegistration?.remove()
        acceptedPassengersListenerRegistration = firestoreDatabase
            .collection("joinRequests")
            .whereField("driverId", isEqualTo: driverId)
            .whereField("status", in: ["accepted", "cancelled"])
            .addSnapshotListener { [weak self] snapshot, listenerError in
                guard let self else { return }
                if let listenerError {
                    print("[DriverProfileVM] Accepted passengers listener error: \(listenerError.localizedDescription)")
                    return
                }
                guard let snapshotDocuments = snapshot?.documents else { return }

                Task { @MainActor in
                    var mappedActivePassengers: [ActivePassengerEntry] = []
                    var mappedInactiveFromSnapshot: [InactivePassengerEntry] = []

                    for document in snapshotDocuments {
                        let documentData      = document.data()
                        let requestDocumentId = document.documentID
                        let statusString      = documentData["status"]        as? String ?? "pending"
                        let passengerUserId   = documentData["passengerId"]   as? String ?? ""
                        let passengerName     = documentData["passengerName"] as? String ?? "Unknown Passenger"
                        let passengerPickup   = documentData["pickupStop"]    as? String ?? ""
                        let sessionString     = documentData["session"]       as? String ?? "Both"
                        let paymentString     = documentData["paymentStatus"] as? String ?? "pending"
                        // cancelledBy distinguishes "driver" removal from "passenger" self-removal
                        let cancelledByValue  = documentData["cancelledBy"]   as? String ?? ""

                        if statusString == "accepted" {
                            let mappedSessionType: PassengerSessionType
                            switch sessionString {
                            case "Morning": mappedSessionType = .morningOnly
                            case "Evening": mappedSessionType = .eveningOnly
                            default:        mappedSessionType = .bothSessions
                            }

                            let mappedPaymentStatus: PassengerPaymentStatusType = paymentString == "paid" ? .paid : .pending
                            let passengerPhone   = documentData["passengerPhone"] as? String ?? ""
                            let dropOffStop      = documentData["dropoffStop"]    as? String ?? ""

                            mappedActivePassengers.append(ActivePassengerEntry(
                                id:                   requestDocumentId,
                                passengerUserId:      passengerUserId,
                                passengerFullName:    passengerName,
                                passengerPhoneNumber: passengerPhone,
                                boardingStopName:     passengerPickup,
                                dropOffStopName:      dropOffStop,
                                enrolledSessionType:  mappedSessionType,
                                currentPaymentStatus: mappedPaymentStatus
                            ))

                        } else if statusString == "cancelled" {
                            // Determine reason from cancelledBy field
                            // "passenger" = they cancelled themselves → show "Self-Removed"
                            // "driver" or anything else = driver removed them → show "Removed"
                            let inactiveReasonType: PassengerInactiveReasonType = cancelledByValue == "passenger"
                                ? .selfRemoved
                                : .removed

                            // Use the Firestore cancelledAt timestamp if available, otherwise fall back to now
                            let removalDate: Date
                            if let firestoreTimestamp = documentData["cancelledAt"] as? Timestamp {
                                removalDate = firestoreTimestamp.dateValue()
                            } else {
                                removalDate = Date()
                            }

                            mappedInactiveFromSnapshot.append(InactivePassengerEntry(
                                id:                 requestDocumentId,
                                passengerFullName:  passengerName,
                                inactiveReasonType: inactiveReasonType,
                                removedDate:        removalDate
                            ))
                        }
                    }

                    // Merge same-passenger separate morning + evening entries into one combined entry
                    // so that the driver sees one row per person rather than two separate rows
                    self.activePassengersList = Self.mergeSeperateSessionsForSamePassenger(mappedActivePassengers)

                    // Merge snapshot-sourced inactive entries, updating existing ones if the reason changed
                    for updatedEntry in mappedInactiveFromSnapshot {
                        if let existingIndex = self.inactivePassengersList.firstIndex(where: { $0.id == updatedEntry.id }) {
                            self.inactivePassengersList[existingIndex] = updatedEntry
                        } else {
                            self.inactivePassengersList.append(updatedEntry)
                        }
                    }
                }
            }
    }

    // Passenger Join Request Actions

    func acceptPassengerJoinRequest(requestIdentifier: String) {
        Task {
            do {
                try await JoinRequestService.shared.updateStatus(requestId: requestIdentifier, status: "accepted")
            } catch {
                print("[DriverProfileVM] Accept request failed: \(error.localizedDescription)")
            }
        }
    }

    func rejectPassengerJoinRequest(requestIdentifier: String) {
        Task {
            do {
                try await JoinRequestService.shared.updateStatus(requestId: requestIdentifier, status: "rejected")
            } catch {
                print("[DriverProfileVM] Reject request failed: \(error.localizedDescription)")
            }
        }
    }

    // Removes an active passenger from the route — called from the driver's manage passengers screen
    // Uses cancelEnrollmentByDriver which writes cancelledBy = "driver" to Firestore
    // so the listener can show "Removed" (driver action) rather than "Self-Removed" (passenger action)
    func terminateActivePassenger(passengerDocumentId: String) {
        guard let removedPassenger = activePassengersList.first(where: { $0.id == passengerDocumentId }) else { return }

        activePassengersList.removeAll { $0.id == passengerDocumentId }

        // Optimistically add to inactive list as driver-initiated removal
        let optimisticInactiveEntry = InactivePassengerEntry(
            id: removedPassenger.id,
            passengerFullName: removedPassenger.passengerFullName,
            inactiveReasonType: .removed,
            removedDate: Date()
        )
        if !inactivePassengersList.contains(where: { $0.id == passengerDocumentId }) {
            inactivePassengersList.append(optimisticInactiveEntry)
        }

        Task {
            do {
                // cancelEnrollmentByDriver writes cancelledBy = "driver" to Firestore
                try await JoinRequestService.shared.cancelEnrollmentByDriver(requestId: passengerDocumentId)
                print("[DriverProfileVM] Passenger \(passengerDocumentId) removed by driver")
            } catch {
                print("[DriverProfileVM] Failed to update status for removed passenger: \(error.localizedDescription)")
            }
        }
    }


    // Merges separate morning and evening entries belonging to the same passenger (same passengerUserId)
    // into a single entry showing "Both" session type
    // This handles the case where a passenger submitted two separate requests instead of selecting Both
    static func mergeSeperateSessionsForSamePassenger(_ entries: [ActivePassengerEntry]) -> [ActivePassengerEntry] {
        var mergedEntries: [ActivePassengerEntry] = []
        var processedUserIds: Set<String> = []

        for entry in entries {
            let passengerId = entry.passengerUserId

            if processedUserIds.contains(passengerId) { continue }

            // Find all entries for this passenger
            let allEntriesForThisPassenger = entries.filter { $0.passengerUserId == passengerId }

            if allEntriesForThisPassenger.count == 1 {
                mergedEntries.append(entry)
            } else {
                // Multiple entries for the same passenger — combine sessions into "Both"
                // Use the morning entry as the base (or the first one found)
                let morningEntry = allEntriesForThisPassenger.first { $0.enrolledSessionType == .morningOnly }
                let eveningEntry = allEntriesForThisPassenger.first { $0.enrolledSessionType == .eveningOnly }
                let baseEntry = morningEntry ?? allEntriesForThisPassenger[0]

                // If either session is paid, show paid — if both are paid, show paid
                let combinedPaymentStatus: PassengerPaymentStatusType =
                    allEntriesForThisPassenger.allSatisfy { $0.currentPaymentStatus == .paid } ? .paid : .pending

                let mergedEntry = ActivePassengerEntry(
                    id:                   baseEntry.id,
                    passengerUserId:      passengerId,
                    passengerFullName:    baseEntry.passengerFullName,
                    passengerPhoneNumber: baseEntry.passengerPhoneNumber,
                    boardingStopName:     morningEntry?.boardingStopName ?? baseEntry.boardingStopName,
                    dropOffStopName:      eveningEntry?.dropOffStopName ?? baseEntry.dropOffStopName,
                    enrolledSessionType:  .bothSessions,
                    currentPaymentStatus: combinedPaymentStatus
                )
                mergedEntries.append(mergedEntry)
            }
            processedUserIds.insert(passengerId)
        }
        return mergedEntries
    }

    // Sign Out

    func signOut() {
        if let userId = Auth.auth().currentUser?.uid {
            CoreDataManager.shared.deleteAllLocalData(userId: userId)
        }
        AuthManager.shared.signOut()
    }

    // Delete Account

    func deleteAccount() {
        isDeletingAccount = true
        Task {
            do {
                try await AccountDeletionService.shared.deleteCurrentUserAccount(role: "driver")
                AuthManager.shared.signOut()
            } catch {
                isDeletingAccount      = false
                deleteAccountError     = error.localizedDescription
                showDeleteAccountError = true
                print("[DriverProfileViewModel] Account deletion failed: \(error.localizedDescription)")
            }
        }
    }
}
