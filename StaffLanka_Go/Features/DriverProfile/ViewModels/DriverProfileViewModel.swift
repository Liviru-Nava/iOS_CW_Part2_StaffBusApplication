//
//  DriverProfileViewModel.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//

import SwiftUI
import Combine
import FirebaseAuth
import PhotosUI
import MapKit
 
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
        case miniBus  = "Mini Bus"
        case van      = "Van"
        case largeBus = "Large Bus"
    }
 
    enum DeadlineStatusType {
        case paid, gracePeriodActive, overdue
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
        driverFullName:       "Loading...",
        driverPhoneNumber:    "Loading...",
        driverLicenseNumber:  "Loading...",
        driverEmailAddress:   ""       // PHASE 1.2: New field with safe default
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
    @Published var driverReviewsList:      [DriverReviewEntry]      = []
  
    @Published var selectedPassengerFilterType: PassengerFilterType = .active
    @Published var isEditingDriverProfile:  Bool = false
    @Published var isEditingBusDetails:     Bool = false
    @Published var isEditingPricingDetails: Bool = false
    @Published var isEditingRouteStops:     Bool = false
    @Published var isEditingSchedule:       Bool = false
    @Published var showSignOutConfirmationAlert: Bool = false
  
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
 
    func fetchDriverProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isDataLoading = true
        Task {
            do {
                let driver = try await DriverService.shared.fetchDriver(driverId: userId)
                let user   = try await UserService.shared.fetchUser(userId: userId)
                self.currentDriverModel = driver

                self.driverProfileInformationValues = DriverProfileInformation(
                    driverFullName:      driver.fullName,
                    driverPhoneNumber:   user?.phoneNumber ?? "No Phone Number",
                    driverLicenseNumber: driver.licenseNumber,
                    driverEmailAddress:  user?.emailAddress ?? ""   // PHASE 1.2
                )
 
                self.busDetailsInformationValues = BusVehicleDetails(
                    busPlateNumber:      driver.busInformation.plateNumber,
                    busDisplayName:      driver.busInformation.busName,
                    busVehicleType:      BusVehicleType(rawValue: driver.busInformation.busType) ?? .van,
                    busPassengerCapacity: driver.busInformation.passengerCapacity
                )
 
                self.driverAvailabilityStatusIsOnline = (driver.serviceStatus ?? "active") == "active"
                self.driverAcceptingRequestsState     = driver.isAcceptingRequests ?? true

                if let base64String = driver.profilePhotoBase64,
                   !base64String.isEmpty,
                   let imageData = Data(base64Encoded: base64String) {
                    self.driverProfilePhotoImageData = imageData   // PHASE 1.3
                }
 
                do {
                    let route = try await RouteService.shared.fetchRoute(routeId: driver.assignedRouteId)
                    self.currentRouteModel = route
 
                    let stopsData = route.routeStops.sorted { $0.stopOrder < $1.stopOrder }.map { stop in
                        RouteStopEntry(
                            stopPositionIndex: stop.stopOrder,
                            stopDisplayName:   stop.stopName,
                            latitude:          stop.latitude,
                            longitude:         stop.longitude
                        )
                    }
 
                    self.routeInformationValues = RouteInformation(
                        routeStartingPointName:   route.startLocation.locationName,
                        routeEndingPointName:     route.endLocation.locationName,
                        orderedListOfRouteStops:  stopsData
                    )
 
                    let timeFormatter      = DateFormatter()
                    timeFormatter.timeStyle = .short
 
                    var morningDept = "N/A"; var morningArr = "N/A"
                    var eveningDept = "N/A"; var eveningArr = "N/A"
 
                    if route.scheduleEntries.count > 0 {
                        let m = route.scheduleEntries[0]
                        morningDept = timeFormatter.string(from: m.scheduledDepartureTime)
                        if let a = m.scheduledArrivalTime { morningArr = timeFormatter.string(from: a) }
                    }
                    if route.scheduleEntries.count > 1 {
                        let e = route.scheduleEntries[1]
                        eveningDept = timeFormatter.string(from: e.scheduledDepartureTime)
                        if let a = e.scheduledArrivalTime { eveningArr = timeFormatter.string(from: a) }
                    }
 
                    self.scheduleDetailsValues = ScheduleDetailsInformation(
                        morningTripSchedule: TripScheduleTime(departureTime: morningDept, estimatedArrivalTime: morningArr),
                        eveningTripSchedule: TripScheduleTime(departureTime: eveningDept, estimatedArrivalTime: eveningArr)
                    )
 
                    self.pricingDetailsValues = PricingDetailsInformation(
                        morningOnlyMonthlyFee:  Int(route.morningPrice  ?? 0),
                        eveningOnlyMonthlyFee:  Int(route.eveningPrice  ?? 0),
                        bothSessionsMonthlyFee: Int(route.bothTripsPrice ?? 0)
                    )
                } catch {
                    print("Error fetching route for profile: \(error)")
                }
 
                self.isDataLoading = false
            } catch {
                self.driverProfileInformationValues.driverFullName = "Error Loading"
                self.isDataLoading = false
            }
        }
    }
 
    var driverProfileInitialsText: String {
        let parts = driverProfileInformationValues.driverFullName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(driverProfileInformationValues.driverFullName.prefix(2)).uppercased()
    }
 
    var averageDriverRatingValue: Double {
        guard !driverReviewsList.isEmpty else { return 0 }
        return driverReviewsList.reduce(0.0) { $0 + $1.reviewRatingOutOfFive } / Double(driverReviewsList.count)
    }
 
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
        driverProfileInformationValues.driverEmailAddress = editingDriverEmailAddress
 
        if var driverModel = currentDriverModel {
            driverModel.fullName      = driverProfileInformationValues.driverFullName
            driverModel.licenseNumber = driverProfileInformationValues.driverLicenseNumber
 
            Task {
                do {
                    if let userId = driverModel.id ?? Auth.auth().currentUser?.uid {
                        try await DriverService.shared.updateDriver(driverId: userId, updatedRecord: driverModel)
                        try await UserService.shared.updateUserRoleAndName(userId: userId, updatedRole: "driver", fullName: driverModel.fullName)
 
                        // PHASE 1.2: Also update the email address in the users document
                        try await UserService.shared.updateUserEmailAddress(
                            userId:       userId,
                            updatedEmailAddress: editingDriverEmailAddress
                        )
                    }
                } catch {
                    print("Could not update profile: \(error)")
                }
            }
            self.currentDriverModel = driverModel
        }
        isEditingDriverProfile = false
    }
 
    func cancelDriverProfileEdits() {
        isEditingDriverProfile = false
    }
    
    func processAndUploadSelectedProfilePhoto(selectedPhotoPickerItem item: PhotosPickerItem) {
        Task {
            // Load raw data from the picker item
            guard let rawData = try? await item.loadTransferable(type: Data.self) else { return }
            guard let uiImage = UIImage(data: rawData) else { return }
            let compressed = uiImage.jpegData(compressionQuality: 0.25) ?? rawData
 
            guard compressed.count < 900_000 else {
                print("Profile photo is too large after compression.")
                return
            }
 
            let base64String = compressed.base64EncodedString()
 
            // Update local display immediately so the UI reflects the change
            self.driverProfilePhotoImageData = compressed  // PHASE 1.3
 
            // Persist to Firestore via DriverService
            if var driverModel = self.currentDriverModel,
               let userId = driverModel.id ?? Auth.auth().currentUser?.uid {
                driverModel.profilePhotoBase64 = base64String  // PHASE 1.3
                do {
                    try await DriverService.shared.updateDriver(driverId: userId, updatedRecord: driverModel)
                    self.currentDriverModel = driverModel
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
                let user = try await UserService.shared.fetchUser(userId: userId)
                self.driverProfileInformationValues.driverPhoneNumber = user?.phoneNumber ?? ""
            } catch {
                print("Failed to refresh phone number: \(error)")
            }
        }
    }
 
    func openBusDetailsEditMode() {
        editingBusPlateNumber       = busDetailsInformationValues.busPlateNumber
        editingBusDisplayName       = busDetailsInformationValues.busDisplayName
        editingBusPassengerCapacity = "\(busDetailsInformationValues.busPassengerCapacity)"
        isEditingBusDetails = true
    }
 
    func saveBusDetailsEdits() {
        busDetailsInformationValues.busPlateNumber  = editingBusPlateNumber
        busDetailsInformationValues.busDisplayName  = editingBusDisplayName
        if let parsed = Int(editingBusPassengerCapacity) {
            busDetailsInformationValues.busPassengerCapacity = parsed
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
        if let m = Int(editingMorningOnlyFee.trimmingCharacters(in: .whitespaces))  { pricingDetailsValues.morningOnlyMonthlyFee  = m }
        if let e = Int(editingEveningOnlyFee.trimmingCharacters(in: .whitespaces))  { pricingDetailsValues.eveningOnlyMonthlyFee  = e }
        if let b = Int(editingBothSessionsFee.trimmingCharacters(in: .whitespaces)) { pricingDetailsValues.bothSessionsMonthlyFee = b }
 
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
        
        let startLoc = editingRouteStartLocation ?? routeModel.startLocation
        let endLoc = editingRouteEndLocation ?? routeModel.endLocation
        
        let req = MKDirections.Request()
        req.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: startLoc.latitude, longitude: startLoc.longitude)))
        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: endLoc.latitude, longitude: endLoc.longitude)))
        req.transportType = .automobile
        
        Task {
            var travelMinutes = (routeInformationValues.orderedListOfRouteStops.count + 1) * 8
            do {
                let directions = MKDirections(request: req)
                let response = try await directions.calculate()
                if let route = response.routes.first {
                    let travelTimeSeconds = route.expectedTravelTime
                    let stopDelaySeconds = Double(routeInformationValues.orderedListOfRouteStops.count * 3 * 60)
                    travelMinutes = Int((travelTimeSeconds + stopDelaySeconds) / 60)
                }
            } catch {
                print("Could not calculate exact ETA, falling back: \(error)")
            }
            
            let newMorningArrival = Calendar.current.date(byAdding: .minute, value: travelMinutes, to: self.editingMorningDepartureTime) ?? self.editingMorningDepartureTime
            let newEveningArrival = Calendar.current.date(byAdding: .minute, value: travelMinutes, to: self.editingEveningDepartureTime) ?? self.editingEveningDepartureTime
            
            routeModel.scheduleEntries[0].scheduledDepartureTime = self.editingMorningDepartureTime
            routeModel.scheduleEntries[0].scheduledArrivalTime   = newMorningArrival
            routeModel.scheduleEntries[1].scheduledDepartureTime = self.editingEveningDepartureTime
            routeModel.scheduleEntries[1].scheduledArrivalTime   = newEveningArrival
            
            do {
                if let routeId = self.currentDriverModel?.assignedRouteId {
                    try await RouteService.shared.updateRoute(routeId: routeId, updatedRecord: routeModel)
                }
            } catch { print("Update schedule error: \(error)") }
            
            self.currentRouteModel = routeModel
            
            let f = DateFormatter(); f.timeStyle = .short
            self.scheduleDetailsValues = ScheduleDetailsInformation(
                morningTripSchedule: TripScheduleTime(departureTime: f.string(from: self.editingMorningDepartureTime), estimatedArrivalTime: f.string(from: newMorningArrival)),
                eveningTripSchedule: TripScheduleTime(departureTime: f.string(from: self.editingEveningDepartureTime), estimatedArrivalTime: f.string(from: newEveningArrival))
            )
            self.isEditingSchedule = false
        }
    }
 
    func cancelScheduleEdits() {
        isEditingSchedule = false
    }
 
    func openRouteEditMode() {
        if let route = currentRouteModel {
            editingRouteStartLocation = route.startLocation
            editingRouteEndLocation = route.endLocation
        }
        editingRouteStopsList = routeInformationValues.orderedListOfRouteStops
        isEditingRouteStops = true
    }
 
    func saveRouteEdits() {
        routeInformationValues.orderedListOfRouteStops = editingRouteStopsList
        
        if let start = editingRouteStartLocation {
            routeInformationValues.routeStartingPointName = start.locationName
        }
        if let end = editingRouteEndLocation {
            routeInformationValues.routeEndingPointName = end.locationName
        }
 
        if var routeModel = currentRouteModel {
            let newStops = editingRouteStopsList.enumerated().map { (index, stopEntry) in
                RouteStopData(
                    stopName:  stopEntry.stopDisplayName,
                    latitude:  stopEntry.latitude,
                    longitude: stopEntry.longitude,
                    stopOrder: index
                )
            }
            routeModel.routeStops = newStops
            
            if let start = editingRouteStartLocation { routeModel.startLocation = start }
            if let end = editingRouteEndLocation { routeModel.endLocation = end }
 
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
        for index in editingRouteStopsList.indices {
            let old = editingRouteStopsList[index]
            editingRouteStopsList[index] = RouteStopEntry(
                stopPositionIndex: index,
                stopDisplayName:   old.stopDisplayName,
                latitude:          old.latitude,
                longitude:         old.longitude
            )
        }
    }
 
    func moveStop(from source: IndexSet, to destination: Int) {
        editingRouteStopsList.move(fromOffsets: source, toOffset: destination)
        for index in editingRouteStopsList.indices {
            let old = editingRouteStopsList[index]
            editingRouteStopsList[index] = RouteStopEntry(
                stopPositionIndex: index,
                stopDisplayName:   old.stopDisplayName,
                latitude:          old.latitude,
                longitude:         old.longitude
            )
        }
    }
    
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
 
    func acceptPassengerJoinRequest(requestIdentifier: UUID) {
        passengerRequestsList.removeAll { $0.id == requestIdentifier }
    }
 
    func rejectPassengerJoinRequest(requestIdentifier: UUID) {
        passengerRequestsList.removeAll { $0.id == requestIdentifier }
    }
 
    func terminateActivePassenger(passengerIdentifier: UUID) {
        if let removed = activePassengersList.first(where: { $0.id == passengerIdentifier }) {
            activePassengersList.removeAll { $0.id == passengerIdentifier }
            inactivePassengersList.append(
                InactivePassengerEntry(passengerFullName: removed.passengerFullName, inactiveReasonType: .removed)
            )
        }
    }
    
    func signOut() { AuthManager.shared.signOut() }
}
