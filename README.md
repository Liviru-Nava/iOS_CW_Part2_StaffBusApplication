# StaffLanka Go

**Student:** L.M. Navaratna
**Index Number:** COBSCCOMP242P-002
**Module:** iOS Application Development — BSc (Hons) Computing Year 04

---

## Table of Contents

1. [App Overview](#1-app-overview)
2. [Problem Statement](#2-problem-statement)
3. [MVP Features Implemented](#3-mvp-features-implemented)
4. [Advanced iOS Features](#4-advanced-ios-features)
5. [Tech Stack and Dependencies](#5-tech-stack-and-dependencies)
6. [Architecture](#6-architecture)
7. [Project Structure](#7-project-structure)
8. [Feature Documentation](#8-feature-documentation)
9. [Data Models](#9-data-models)
10. [Backend Services](#10-backend-services)
11. [Unit Tests](#11-unit-tests)
12. [Accessibility](#12-accessibility)
13. [Setting Up and Running the Project](#13-setting-up-and-running-the-project)
14. [Firebase Configuration](#14-firebase-configuration)
15. [Known Limitations](#15-known-limitations)
16. [Future Development Plans](#16-future-development-plans)
17. [Development Process and Challenges](#17-development-process-and-challenges)
18. [Reflection on Learning Outcomes](#18-reflection-on-learning-outcomes)

---

## 1. App Overview

**StaffLanka Go** is a smart iOS application built to digitise and streamline the staff bus commuting system in Sri Lanka. The app serves two distinct user roles — **Passengers** and **Drivers** — and provides each with a purpose-built experience tailored to their responsibilities.

Passengers can search for registered bus routes, submit ride requests, track their bus in real time on a live map, and receive proximity-based alerts that ensure they never miss their stop — even if they fall asleep during the commute. Drivers can manage their enrolled passenger list, view attendance confirmations, simulate a trip along a road-accurate route, and track their earnings.

The application is built entirely in **Swift and SwiftUI**, uses **Firebase** as its cloud backend, and integrates a range of advanced iOS frameworks including **ActivityKit**, **EventKit**, **Core Data**, **MapKit**, **CoreLocation**, and **LocalAuthentication**.

**Platform:** iOS
**Language:** Swift 5.0
**UI Framework:** SwiftUI
**Minimum Deployment Target:** iOS 17.0
**Version:** 1.0
**Bundle Identifier:** `com.002.app.StaffLanka-Go`
**Total Swift Source Files:** 95 (65 feature, 20 backend, 6 test, 2 widget, 2 app root)
**Total Lines of Code:** ~23,000

---

## 2. Problem Statement

The current staff bus commuting system in Sri Lanka suffers from several significant inefficiencies:

- Passengers rely on static, text-based websites for route information with no interactive maps or real-time data.
- Bookings and communications are handled informally via phone calls and messaging platforms, with no structured record-keeping.
- Passengers who fall asleep on the bus have no reliable mechanism to be alerted before reaching their stop.
- Drivers must manually track which passengers boarded, often leading to inaccuracies in attendance.
- There is no automated notification system for trip events such as departures, arrivals, or cancellations.
- Route information is not updated dynamically based on which passengers are travelling on a given day.

**StaffLanka Go** addresses all of these problems through a structured digital platform with real-time synchronisation, smart location-aware notifications, calendar integration, and a role-based dual-interface design.

---

## 3. MVP Features Implemented

All eight approved MVP features have been fully implemented.

| # | Feature | Status | Key Files |
|---|---|---|---|
| 1 | Authentication (Phone + OTP) and Face ID / Touch ID | Complete | `AuthManager.swift`, `BiometricService.swift`, `LoginViewModel.swift`, `OTPVerificationViewModel.swift` |
| 2 | Push Notifications and Core Data | Complete | `NotificationManager.swift`, `CoreDataManager.swift`, `PersistenceController.swift` |
| 3 | Profile and Settings | Complete | `PassengerProfileView.swift`, `DriverProfileView.swift`, `PassengerNotificationSettingView.swift`, `DriverNotificationSettingsView.swift` |
| 4 | Dashboard and Landing Page / User Onboarding | Complete | `OnboardingView.swift`, `TermsView.swift`, `PassengerDashboard.swift`, `DriverDashboardView.swift` |
| 5 | Staff Service Trip Finding Flow | Complete | `RouteSearchView.swift`, `RouteDetailView.swift`, `JoinRequestView.swift` |
| 6 | Trip History | Complete | `PassengerTripHistoryView.swift`, `DriverTripHistoryView.swift` |
| 7 | Driver View | Complete | `DriverDashboardView.swift`, `DriverTripSimulationView.swift`, `DriverPassengerManagementView.swift` |
| 8 | Cost History and Earnings | Complete | `PassengerCostTrackingView.swift`, `DriverEarningsView.swift` |

---

## 4. Advanced iOS Features

### Advanced Feature 1 — MapKit and Core Location

MapKit is used throughout the app for interactive map rendering, route visualisation, and stop selection. Core Location is used to retrieve the passenger's current location for pickup selection and to power the driver's simulated trip coordinate updates.

Key integrations:
- `RouteSearchView` — `Map` with location-picker sheet; current location used as default pickup via `CLLocationManager`
- `RouteDetailView` — `Map` displaying route start, intermediate stops, and end location as `MapAnnotation` markers
- `PassengerTripTrackingView` — Full-screen `Map` with a live bus position annotation updated from Firestore in real time; `MapCameraPosition` recentres on each coordinate update
- `DriverTripSimulationView` — `Map` with a `MapPolyline` drawn from `MKDirections` road data; bus annotation interpolates along the real road path each timer tick

The `MKDirections` API is used in `DriverTripSimulationViewModel` to build a road-accurate polyline between each stop pair. Results from consecutive leg requests are stitched together into a single continuous coordinate path.

### Advanced Feature 2 — Live Activities and EventKit

**Live Activities (ActivityKit)**

When a passenger opens the trip tracking screen, a Live Activity is started via `PassengerLiveActivityManager`. It displays the trip's progress on the iOS Lock Screen and in the Dynamic Island, updating in real time as the bus advances through stops.

The `StaffLankaGoTripActivityAttributes` struct defines static attributes (route name, passenger name) and a dynamic `ContentState` holding the current stop name, stops remaining, estimated minutes, and whether the passenger has been picked up. Every Firestore trip update triggers `PassengerLiveActivityManager.updateLiveActivityWithCurrentBusProgress()`, which pushes a new `ContentState` to the activity.

The widget extension (`StaffLankaGoWidgetExtension`) implements the Lock Screen banner with a header row, a stop-progress row, and a stops-remaining label, as well as all four Dynamic Island regions: expanded leading/trailing/bottom, compact, and minimal.

**EventKit**

When a driver accepts a passenger's join request, `EventKitManager.schedulePassengerEventsOnAcceptance()` creates recurring weekly calendar events in the passenger's iOS Calendar for every operating day of the route until the end of the current calendar month. Events include the route name, pickup stop location, and a 30-minute pre-departure alarm.

On iOS 17 and later, write-only calendar access is requested via `EKEventStore.requestWriteOnlyAccessToEvents()`. On earlier versions, full access is requested via the legacy API.

At app launch, `refreshExpiredCalendarEventsIfNeeded()` in `StaffLanka_GoApp` checks the stored expiry date for each enrolled route. If the month has ended, the old events are removed and new ones are created for the current month.

---

## 5. Tech Stack and Dependencies

| Component | Technology |
|---|---|
| Language | Swift 5.0 |
| UI Framework | SwiftUI |
| App Architecture | MVVM (Model-View-ViewModel) |
| Authentication | Firebase Authentication (Phone + OTP) |
| Database | Firebase Firestore (real-time NoSQL) |
| Local Storage | Core Data (NSPersistentContainer) |
| Maps | MapKit, MKDirections |
| Location | CoreLocation (CLLocationManager) |
| Biometrics | LocalAuthentication (LAContext) |
| Notifications | UserNotifications (UNUserNotificationCenter) |
| Live Activities | ActivityKit (Activity, WidgetKit) |
| Calendar | EventKit (EKEventStore) |
| Dependency Manager | Swift Package Manager |

**Swift Package Dependencies:**

| Package | Source | Purpose |
|---|---|---|
| `firebase-ios-sdk` | https://github.com/firebase/firebase-ios-sdk | Authentication, Firestore, Core |

All other frameworks used are Apple system frameworks included with the iOS SDK.

---

## 6. Architecture

The application follows the **MVVM (Model-View-ViewModel)** architecture pattern throughout every feature module.

```
View  ──observes──▶  ViewModel  ──calls──▶  Service / Manager
                        │
                        └──reads/writes──▶  Data Model
```

**View** — SwiftUI views are responsible only for rendering state and forwarding user actions to the ViewModel. They hold no business logic. Views observe the ViewModel's `@Published` properties and update automatically when they change.

**ViewModel** — Marked `@MainActor` and conforming to `ObservableObject`. Each ViewModel owns the business logic for one feature. It calls service classes for network and data operations, transforms results into view-ready state, and publishes changes. ViewModels are never shared between features.

**Service Layer** — Singleton service classes (`TripService`, `RouteService`, `AttendanceService`, etc.) are responsible for all Firestore read/write operations and real-time listeners. They have no knowledge of the UI.

**Manager Layer** — Singleton manager classes (`AuthManager`, `NotificationManager`, `PassengerLiveActivityManager`, `EventKitManager`, `CoreDataManager`) encapsulate cross-cutting concerns that span multiple features. These are injected into the SwiftUI environment where appropriate.

**App-Level Routing** — `RootView` switches between top-level screens based on a single `@Published var authenticationState` in `AuthManager`. No manual navigation is performed anywhere in the app; all transitions are reactive responses to state changes.

---

## 7. Project Structure

```
StaffLanka_Go/
├── App/
│   ├── StaffLanka_GoApp.swift       # App entry point, Firebase init, EventKit refresh
│   ├── ContentView.swift            # Root content view
│   ├── RootView.swift               # State-driven navigation router
│   ├── AuthManager.swift            # Authentication state machine
│   └── BiometricService.swift       # LocalAuthentication wrapper
│
├── Backend/
│   ├── Data/
│   │   ├── CoreDataManager.swift    # CRUD operations for all Core Data entities
│   │   └── PersistanceController.swift  # NSPersistentContainer setup
│   ├── Models/
│   │   ├── UserModel.swift
│   │   ├── RouteModel.swift
│   │   ├── TripModel.swift
│   │   ├── JoinRequestModel.swift
│   │   ├── AttendanceModel.swift
│   │   ├── DriverModel.swift
│   │   └── PassengerRouteResult.swift
│   └── Services/
│       ├── UserService.swift
│       ├── RouteService.swift
│       ├── TripService.swift
│       ├── JoinRequestService.swift
│       ├── AttendanceService.swift
│       ├── DriverService.swift
│       ├── PaymentService.swift
│       ├── TripHistoryStore.swift
│       ├── NotificationManager.swift
│       ├── EventKitManager.swift
│       └── AccountDeletionService.swift
│
├── Features/
│   ├── Authentication/
│   │   ├── Views/   OnboardingView, TermsView, LoginView, OTPVerificationView
│   │   └── ViewModels/   LoginViewModel, OTPVerificationViewModel
│   ├── Dashboard/
│   │   ├── Views/   PassengerDashboard, PassengerNotificationView
│   │   └── ViewModels/   PassengerDashboardViewModel
│   ├── DriverDashboard/
│   │   ├── Views/   DriverDashboardView, DriverTripSimulationView
│   │   └── ViewModels/   DriverDashboardViewModel, DriverTripSimulationViewModel
│   ├── DriverEarnings/
│   ├── DriverHistory/
│   ├── DriverOnboarding/
│   ├── DriverProfile/
│   ├── Navigation/
│   │   ├── PassengerMainView.swift  # Passenger tab bar
│   │   └── DriverMainView.swift     # Driver tab bar
│   ├── PassengerCostTracking/
│   ├── PassengerProfile/
│   ├── TripFindingFlow/
│   │   ├── Views/   RouteSearchView, RouteDetailView, JoinRequestView, PassengerTripTrackingView
│   │   └── ViewModels/   RouteSearchViewModel, RouteDetailViewModel, JoinRequestViewModel, TripTrackingViewModel
│   └── TripHistoryPassenger/
│
├── LiveActivity/
│   ├── StaffLankaBusLiveActivityAttributes.swift  # ActivityKit attributes and ContentState
│   └── PassengerLiveActivityManager.swift         # Start, update, end Live Activity
│
├── Data Models/
│   └── LocalDataModel.xcdatamodeld               # Core Data schema
│
└── Resources/
    └── Theme.swift                                # Centralised design tokens (colours, gradients)

StaffLankaGoWidgetExtension/
├── StaffLankaBusLiveActivityWidget.swift          # Lock Screen + Dynamic Island UI
└── StaffLankaGoWidgetExtensionBundle.swift        # Widget bundle entry point

StaffLanka_GoTests/
├── AuthManagerTests.swift
├── LoginViewModelTests.swift
├── OTPVerificationViewModelTests.swift
├── DataModelTests.swift
└── PassengerRouteResultTests.swift
```

---

## 8. Feature Documentation

### 8.1 App Launch and Navigation Routing

The app entry point (`StaffLanka_GoApp`) initialises Firebase, sets `AppDelegate` as the `UIApplicationDelegateAdaptor` (required for Firebase phone auth URL handling and APNs token registration), injects `AuthManager` and the Core Data context into the SwiftUI environment, and runs the EventKit monthly refresh task.

`RootView` observes `AuthManager.authenticationState` and renders the correct top-level view for each of the five states: `onboarding`, `terms`, `unauthenticated`, `authenticated`, `driverAuthenticated`. All transitions are animated with a 0.3-second ease-in-out fade.

### 8.2 Onboarding and Terms

`OnboardingView` presents a three-page `TabView` with `.tabViewStyle(.page)`. Pages are defined as a local `OnboardingPageContent` value type array. Tapping "Skip" or "Get Started" calls `authManager.markOnboardingComplete()`, which writes `hasSeenOnboarding = true` to `UserDefaults` and triggers a `checkSession()` transition to the terms state. This screen is shown exactly once per device installation.

### 8.3 Authentication

**Phone + OTP:** `LoginViewModel` validates the Sri Lankan phone number format (9–10 digits), constructs the full E.164 number (`+94XXXXXXXXX`), and calls Firebase's `PhoneAuthProvider.provider().verifyPhoneNumber()`. The returned verification ID is stored in `AuthManager` via `UserDefaults`. `OTPVerificationViewModel` distributes six digits into an array, auto-submits when complete, and creates a Firebase credential from the verification ID and entered OTP. On success, it calls `Auth.auth().signIn(with: credential)` and `authManager.completeSignIn()`, which fetches the user's role from Firestore and transitions to the appropriate dashboard.

**Face ID / Touch ID:** `BiometricService` wraps `LAContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)`. After a successful OTP login, the user is offered biometric enrolment. On subsequent launches, `RootView.attemptBiometricAutoLoginOnLaunch()` immediately prompts Face ID if biometric is enabled, bypassing the phone number screen entirely.

**Session persistence:** Login state, phone number, user role, and biometric preference are stored as primitive values in `UserDefaults`. Sensitive authentication tokens are managed by the Firebase SDK.

### 8.4 Passenger Dashboard

`PassengerDashboardViewModel.startListening()` attaches a Firestore snapshot listener to the `joinRequests` collection filtered by the passenger's UID. Accepted requests are built into `EnrolledService` structs by fetching the corresponding `RouteModel` and `DriverModel` from Firestore. A second listener attaches to the `trips` collection for each enrolled driver, watching for trip status and stop index changes.

When the trip's `currentStopIndex` changes, `evaluateProximityAlertForSession()` calculates the passenger's stop distance and fires a `UNNotificationRequest` via `NotificationManager` when within threshold. One-shot boolean flags prevent repeat firing for the same stop.

The notification bell badge count is driven by a SwiftUI `@FetchRequest` on `NotificationEntity`, filtered by the current user's UID and `isRead == false`.

### 8.5 Smart Proximity Notification System

This is the primary differentiating feature of the application. The system solves the problem of passengers missing their stop when asleep.

When enrollment is processed, the route's full ordered stop array is pre-fetched and cached in the ViewModel. For morning sessions, stops run from start to end. For evening sessions, the array is reversed.

On each `currentStopIndex` Firestore update:
1. The current stop index is compared against the passenger's pickup stop index to determine whether they have been picked up.
2. The number of stops remaining until the relevant stop (pickup or drop-off) is calculated.
3. This count is converted to estimated minutes using the simulation's configured total duration divided by total stop count.
4. If the estimate is at or below the configured threshold (5 minutes) and the one-shot flag has not fired, a notification is scheduled immediately via `UNUserNotificationCenter`.

The notification is delivered as a system banner with sound, alerting the passenger regardless of whether the app is foregrounded or backgrounded.

### 8.6 Trip Finding Flow

`RouteSearchViewModel` manages pickup and destination location selection, including "Use Current Location" support via `CLLocationManager`. Once both are set, `RouteService.shared.fetchRoutes(from:to:)` queries Firestore for matching routes. Results are presented as cards with price and schedule information.

`RouteDetailView` renders a `Map` with `MapAnnotation` markers for each stop. A join request form allows the passenger to select a session (Morning, Evening, or Both) and confirm their pickup and drop-off stops. `JoinRequestService.shared.createJoinRequest()` writes the request to Firestore with `status = "pending"`.

### 8.7 Driver Dashboard and Trip Simulation

`DriverDashboardViewModel` fetches the driver's profile, route, and enrolled passenger list with their attendance statuses on appear. The morning/evening segmented picker filters the passenger list for the selected session.

`DriverTripSimulationViewModel.startSimulation()` builds the ordered stop list from the `RouteModel`, calls `MKDirections.calculate()` for each consecutive stop pair to obtain road-accurate polyline coordinates, and concatenates the results into a single path. A `Timer` fires every 0.4 seconds, interpolating the bus position along the road path and calling `TripService.shared.updateDriverLocation(tripId:location:currentStopIndex:)` to write the coordinate and stop index to Firestore. This is the data source that drives the passenger's live map, Live Activity, and proximity notifications in real time.

### 8.8 Live Activity

`PassengerLiveActivityManager` starts a `Activity<StaffLankaGoTripActivityAttributes>` when the passenger opens the trip tracking screen. The `ActivityContent` is updated on every Firestore trip change via `await activeActivity.update()`. The `staleDate` is set 4 hours in the future on every update to prevent the activity from going stale.

The `StaffLankaGoWidgetExtension` target implements the full Live Activity presentation:
- **Lock Screen banner** — Route header, ETA, current stop, relevant stop (pickup or drop-off), and stops-remaining count.
- **Dynamic Island expanded** — Leading region (app name + route), trailing region (ETA), bottom region (stop progress).
- **Dynamic Island compact** — Bus icon (leading), ETA in minutes (trailing).
- **Dynamic Island minimal** — Bus icon only.

### 8.9 EventKit Calendar Integration

`EventKitManager.schedulePassengerEventsOnAcceptance()` creates `EKEvent` objects with weekly recurrence rules (`EKRecurrenceRule`) ending on the last second of the current calendar month. Each event carries a 30-minute pre-departure `EKAlarm`. Identifiers are stored in `UserDefaults` keyed by route ID and session to support later deletion.

`rescheduleEventsIfMonthExpired()` is called at app launch for every enrolled route. It reads the stored expiry date and, if it has passed, removes the previous month's events and creates new ones for the current month.

### 8.10 Core Data

Four entities are defined in `LocalDataModel.xcdatamodeld`:

- `PassengerProfileEntity` — Caches the passenger's profile for offline display.
- `DriverProfileEntity` — Caches the driver's profile for offline display.
- `CachedTripEntity` — Stores completed trip records locally for offline history browsing.
- `NotificationEntity` — Persists every in-app notification with read/unread state, forming the in-app notification inbox.

`CoreDataManager` uses a fetch-or-create pattern for upserts, ensuring no duplicate records. `deleteAllLocalData(userId:)` is called on sign-out to wipe all user-specific cached data.

---

## 9. Data Models

### UserModel
Stored in Firestore collection `users`. Fields: `userId`, `fullName`, `phoneNumber`, `emailAddress`, `userRole` ("passenger" or "driver"), `createdAt`.

### RouteModel
Stored in Firestore collection `routes`. Fields: `ownerDriverId`, `startLocation` (RouteLocationData), `endLocation` (RouteLocationData), `routeStops` ([RouteStopData]), `scheduleEntries` ([RouteScheduleEntry]), `morningPrice`, `eveningPrice`, `bothTripsPrice`, `startName`, `endName`, `isActive`, `createdAt`.

### TripModel
Stored in Firestore collection `trips`. Fields: `routeId`, `driverId`, `session`, `tripDate`, `status` ("active" or "completed"), `startedAt`, `endedAt`, `driverLatitude`, `driverLongitude`, `locationUpdatedAt`, `currentStopIndex`.

### JoinRequestModel
Stored in Firestore collection `joinRequests`. Fields: `passengerId`, `driverId`, `routeId`, `session`, `pickupStop`, `dropoffStop`, `status` ("pending", "accepted", or "rejected"), `createdAt`.

### AttendanceModel
Stored in Firestore collection `attendance`. Document ID is deterministic: `{passengerId}_{routeId}_{session}_{epochDay}`. Fields: `passengerId`, `routeId`, `requestId`, `session`, `tripDate`, `status` ("attending" or "absent"), `markedAt`, `updatedAt`.

### DriverModel
Stored in Firestore collection `drivers`. Fields: `userId`, `fullName`, `phoneNumber`, `emailAddress`, `licenseNumber`, `busInformation` (BusInformation), `routeId`, `createdAt`.

---

## 10. Backend Services

| Service | Responsibility |
|---|---|
| `UserService` | Fetch and update user documents in Firestore |
| `RouteService` | Create, fetch, update, and query route documents |
| `TripService` | Start and finish trips, update driver location, listen for active trips |
| `JoinRequestService` | Create join requests, accept/reject, listen for passenger requests |
| `AttendanceService` | Mark attendance, fetch attendance, real-time attendance listener |
| `DriverService` | Fetch and update driver profile documents |
| `PaymentService` | Fare calculation and payment record management |
| `TripHistoryStore` | Build trip history records from completed trip data |
| `NotificationManager` | Schedule local notifications, persist to Core Data, manage mute preferences |
| `EventKitManager` | Create, update, and remove calendar events via EventKit |
| `AccountDeletionService` | Cascade delete all user data from Firestore, Core Data, EventKit, and Firebase Auth |

---

## 11. Unit Tests

The test suite is located in `StaffLanka_GoTests/` and contains **56 test functions** across five test files.

### AuthManagerTests (10 tests)
Tests `UserDefaults` persistence of session flags: `hasSeenOnboarding`, `hasAcceptedTerms`, phone number storage and retrieval, sign-out key cleanup (verifies all session keys are removed), biometric enabled/disabled flag persistence, Firebase verification ID storage and removal, and user role (driver and passenger) persistence. Includes a test verifying all five `AuthenticationState` enum cases are distinct.

Each test uses `setUp()` to clear relevant keys before running and `tearDown()` to clean up after, ensuring tests are fully isolated.

### LoginViewModelTests (11 tests)
Tests `isPhoneNumberValid` with: a valid 9-digit number, a valid 10-digit number with leading zero, a too-short number, an empty string, and a string of spaces only. Tests `fullPhoneNumber` correctly prepends `+94` and strips whitespace. Tests `canSendOTP` mirrors validity. Tests `selectedCountryCode` is always `+94`. Tests the initial `loginState` is `.idle`. Tests that hyphenated phone numbers with valid digit counts pass validation.

### OTPVerificationViewModelTests (tests)
Tests that the ViewModel is initialised with the correct phone number, that `otpDigits` contains exactly six empty strings on init, that `enteredOTPString` joins all digit slots correctly, and that `isOTPComplete` returns `true` only when all six slots are filled.

### DataModelTests (tests)
Tests that `RouteLocationData` stores `locationName`, `latitude`, and `longitude` without mutation. Tests that `RouteStopData` retains `stopOrder` and `stopName`. Tests that `RouteModel` constructed with all required fields retains every value correctly.

### PassengerRouteResultTests (tests)
Tests that `timeString(from:)` formats midnight as "12:00 AM" and noon as "12:00 PM" using the Asia/Colombo timezone. Tests that `morningScheduleLabel` combines departure and arrival times with an en-dash separator.

### Why These Layers Were Tested
Service classes such as `NotificationManager`, `RouteService`, and `TripService` depend on Firebase Authentication, Firestore, and the system notification framework. Unit testing these classes in isolation would require mocking the entire Firebase SDK, which is a significant infrastructure investment beyond the scope of this coursework. The test suite focuses on pure-logic layers — model structs, ViewModel validation computed properties, and `UserDefaults` session state — which can be tested deterministically without any external dependencies or network access.

---

## 12. Accessibility

The application is designed with accessibility as a first-class concern:

- **Dynamic Type:** All text in the application uses `.font(.system(...))` with `design: .rounded` or `design: .monospaced` as appropriate, and SwiftUI's text rendering scales with the user's system font size setting.
- **Dark Mode:** All colours are defined as adaptive `UIColor` instances in `Theme.swift`, providing distinct light and dark appearances for every semantic colour token (`brandPrimary`, `cardBackground`, `textPrimary`, `textSecondary`, etc.).
- **Contrast:** Status colours (`statusActive`, `statusDanger`, `statusWarning`) are chosen to meet minimum contrast ratios against both the dark navy background and the light grouped background.
- **Button Hit Areas:** All interactive elements use `.frame(width:height:)` with a minimum of 44×44 points to meet Apple's Human Interface Guidelines for touch targets.
- **One-Handed Usability:** Primary actions (Send OTP, Verify, Track Live, Mark Attendance) are positioned in the lower portion of the screen within comfortable thumb reach. The OTP input uses a single hidden `TextField` rather than six separate fields, so the system keyboard appears once and does not require the user to switch focus.
- **Sleep-Safe Notifications:** The proximity alert system is specifically designed to assist users who may be unable to actively monitor the screen. System banner notifications are delivered with sound regardless of app foreground state, and the Live Activity displays essential trip progress on the Lock Screen without requiring the user to unlock their device.

---

## 13. Setting Up and Running the Project

### Prerequisites

- Xcode 16 or later
- iOS 17.0 simulator or physical device
- An active internet connection (required for Firebase)
- The `GoogleService-Info.plist` file (included in the submission zip — do not rename or move this file)

### Steps

1. Unzip the submission archive and open `StaffLanka_Go.xcodeproj` in Xcode.
2. Wait for Swift Package Manager to resolve and download the Firebase iOS SDK dependency. This requires an internet connection and may take 1–2 minutes on first open.
3. Verify that `GoogleService-Info.plist` is present at the project root and listed under the `StaffLanka_Go` target in the Xcode file navigator.
4. Select a simulator or connected device running iOS 17.0 or later.
5. Press **Run** (⌘R).

> **Note on Live Activities:** The Live Activity widget renders on the Lock Screen and Dynamic Island. This feature requires a physical iPhone running iOS 16.2 or later with Live Activities enabled in Settings → StaffLanka Go. It will not render in the iOS Simulator.

> **Note on Face ID:** Face ID requires a physical device. The Simulator supports Touch ID simulation via Hardware → Touch ID menu, but Face ID simulation is not available.

> **Note on OTP:** Firebase Phone Authentication is configured with `isAppVerificationDisabledForTesting = true` in the `AppDelegate`, which disables reCAPTCHA verification and allows OTP to work in the Simulator. In a production build this flag must be removed.

---

## 14. Firebase Configuration

The app uses three Firebase services:

| Service | Purpose |
|---|---|
| Firebase Authentication | Phone number + OTP sign-in, session management, APNs token registration |
| Cloud Firestore | Real-time NoSQL database for users, routes, trips, join requests, and attendance |
| Firebase Core | SDK initialisation |

The Firestore database uses the following top-level collections:

```
/users/{userId}
/routes/{routeId}
/trips/{tripId}
/joinRequests/{requestId}
/attendance/{attendanceId}
/drivers/{driverId}
```

Real-time listeners are attached to `joinRequests` (filtered by `passengerId`), `trips` (filtered by `driverId`), and `attendance` (single document by deterministic ID). All listeners are removed in `deinit` via `ListenerRegistration.remove()` to prevent memory leaks and orphaned listeners.

---

## 15. Known Limitations

- **Local notifications only:** The app uses `UNUserNotificationCenter` with immediate triggers for all notifications. Full remote APNs push delivery (for background-killed app state) would require a paid Apple Developer Program membership and a configured APNs certificate, which is outside the scope of a coursework submission. All notification behaviour is fully functional when the app is foregrounded or backgrounded.

- **Simulated trip location:** The driver trip uses a `Timer`-based simulation rather than a live `CLLocationManager` feed. This was a deliberate design decision to allow reliable demoing without requiring the driver and passenger to be at different physical locations. The simulation writes real Firestore updates that drive all downstream passenger features identically to how a live GPS feed would.

- **Single active trip per driver per session:** The system assumes one active trip per driver per session per day. The `listenForActiveTrip` query filters by `driverId` and matches the most recent active trip for the relevant session. Multiple simultaneous trips for the same driver are not supported in this MVP.

- **Attendance deterministic document ID:** The `attendance` collection uses a deterministic document ID (`passengerId_routeId_session_epochDay`). This means a passenger can only mark attendance once per session per day, which is the intended behaviour for a daily commute system.

---

## 16. Future Development Plans

The following enhancements are planned for post-MVP development:

### Short Term
- **Live GPS for drivers:** Replace the simulation timer with a real `CLLocationManager` background location session on the driver's device, writing coordinates to Firestore at a configurable interval (e.g., every 5 seconds). This would make the proximity alert ETA calculation accurate to real road conditions.
- **Remote APNs push notifications:** Integrate a server-side component (Firebase Cloud Functions) to deliver push notifications to passengers whose apps are fully terminated, ensuring sleep-safe alerts work even when the app has been removed from memory.
- **Passenger ratings for drivers:** Allow passengers to submit a rating at trip completion, enabling a quality feedback loop for the transport system.

### Medium Term
- **Multi-stop pickup optimisation:** Use the Google Maps Directions API or Apple's on-device routing to dynamically reorder stops based on confirmed attendance, minimising total travel time for the driver.
- **Monthly fare payment tracking:** Integrate with a payment gateway to allow passengers to pay their monthly route fees in-app, with automated receipts and payment history.
- **Driver earnings dashboard with charts:** Use Swift Charts to visualise earnings trends over time, broken down by route, session, and month.

### Long Term
- **iPad support:** The current interface targets iPhone. A future version would implement an adaptive layout that provides a side-by-side master-detail view on iPad, particularly useful for drivers managing passenger lists on a larger screen.
- **Web admin portal:** A companion web dashboard for transport administrators to add and manage routes, view system-wide attendance reports, and configure fare structures.
- **SiriKit integration:** Allow passengers to ask Siri "When is my bus?" and receive the scheduled departure time and current tracking status without opening the app.
- **Offline-first architecture:** Expand Core Data usage to cache full route data and pending attendance changes locally, syncing to Firestore when connectivity is restored. This would make the app fully functional in low-connectivity environments.

---

## 17. Development Process and Challenges

The development followed a branch-based Git workflow with feature branches merged into a `development` branch via pull requests before final merges to `main`. Each MVP feature was developed in its own branch:

```
feature/passengerDashboard
feature/trip_finding_flow
feature/driver_dashboard
feature/driver_onboarding
feature/driver_profile_view
feature/driver_earnings
feature/driver_trip_history
feature/passenger_profile
feature/passenger_cost_tracking_payment
feature/trip_history
backend/authentication
backend/driver_backend
backend/Coredata
backend/face-ID
backend/live-activity
backend/event-kit
test/unit-testing
```

### Key Challenges

**Real-time passenger-to-driver synchronisation:** The most architecturally complex aspect was ensuring that the driver's simulated stop index changes propagated immediately to all enrolled passengers. The solution uses Firestore snapshot listeners on the `trips` collection, which provide sub-second update latency. Each passenger's ViewModel independently calculates proximity from the shared `currentStopIndex` field, rather than the server calculating and pushing proximity state, which keeps the system scalable.

**Live Activity and widget extension coordination:** The widget extension runs in a separate process with no access to the main app's memory or network stack. All data displayed by the widget must be explicitly pushed via `ActivityContent` updates. Handling app restarts during an active trip required implementing `resumeExistingLiveActivityIfPresent()`, which reads `Activity.activities` to recover the running activity reference.

**EventKit monthly expiry:** Apple's `EKRecurrenceEnd(end:)` creates events that appear in the user's calendar only up to the specified end date. Using a far-future or indefinite end date would fill the calendar with years of events. The solution stores the expiry date per route in `UserDefaults` and reschedules on launch whenever the stored expiry has passed.

**OTP input UX:** Standard multi-`TextField` approaches for OTP inputs suffer from focus management issues — tapping between boxes, handling backspace, and auto-advancing. The solution uses a single hidden `TextField` for input, distributing characters into a display array. The visible boxes are purely decorative `Text` views that reflect the array contents.

---

## 18. Reflection on Learning Outcomes

**Critically evaluate the platform components and their uses across multiple devices and formats:**
Building the Live Activity widget extension required understanding how ActivityKit separates concerns between the main app process (which drives state updates) and the widget extension process (which renders UI from that state). The mandatory separation forced a clean one-way data flow and highlighted the constraints that shape iOS's multi-process architecture.

**Design and evaluate software suitable for mobile architectures:**
Adopting MVVM throughout the project made the codebase significantly more maintainable as features grew in complexity. The `PassengerDashboardViewModel`, for example, manages five concurrent Firestore listeners, proximity calculations, and Core Data interactions — none of which appear in the View layer. This separation would have been difficult to maintain with a more tightly coupled architecture.

**Develop and evaluate apps that can interact with external APIs and devices:**
Firebase Firestore's real-time listener API (`addSnapshotListener`) shaped many of the key design decisions in the app. Understanding that listeners must be explicitly removed on `deinit`, that Firestore compound queries require composite indexes, and that listener callbacks arrive on a background thread (requiring `@MainActor` dispatch) were all practical lessons learned during development.

**Develop and evaluate apps that can communicate with sensors built into the phone hardware:**
Integrating `CLLocationManager` for current-location pickup, `LAContext` for biometric authentication, and `MKDirections` for road-accurate routing demonstrated how iOS hardware sensor APIs are layered — `CoreLocation` provides raw sensor data, `MapKit` interprets it in a geographic context, and `LocalAuthentication` abstracts the biometric hardware behind a capability-checking interface.
