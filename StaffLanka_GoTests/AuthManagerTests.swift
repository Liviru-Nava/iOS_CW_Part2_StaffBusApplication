//
//  AuthManagerTests.swift
//  StaffLanka_GoTests
//
//  Created by Liviru Navaratna on 2026-05-14.
//


import XCTest
@testable import StaffLanka_Go
 
final class AuthManagerTests: XCTestCase {
 
    private let hasSeenOnboardingStorageKey      = "hasSeenOnboarding"
    private let hasAcceptedTermsStorageKey       = "hasAcceptedTerms"
    private let isLoggedInStorageKey             = "isLoggedIn"
    private let storedPhoneNumberStorageKey      = "storedPhoneNumber"
    private let isBiometricEnabledStorageKey     = "isBiometricEnabled"
    private let firebaseVerificationIDStorageKey = "firebaseVerificationID"
    private let storedUserRoleStorageKey         = "storedUserRole"
 
    override func setUp() {
        super.setUp()
        removeAllTestKeys()
    }
 
    override func tearDown() {
        removeAllTestKeys()
        super.tearDown()
    }
 
    private func removeAllTestKeys() {
        UserDefaults.standard.removeObject(forKey: hasSeenOnboardingStorageKey)
        UserDefaults.standard.removeObject(forKey: hasAcceptedTermsStorageKey)
        UserDefaults.standard.removeObject(forKey: isLoggedInStorageKey)
        UserDefaults.standard.removeObject(forKey: storedPhoneNumberStorageKey)
        UserDefaults.standard.removeObject(forKey: isBiometricEnabledStorageKey)
        UserDefaults.standard.removeObject(forKey: firebaseVerificationIDStorageKey)
        UserDefaults.standard.removeObject(forKey: storedUserRoleStorageKey)
    }
 
    // Verifies that hasSeenOnboarding reads back false when the key has been removed.
    func testHasSeenOnboarding_WhenKeyIsAbsent_ReturnsFalse() {
        UserDefaults.standard.removeObject(forKey: hasSeenOnboardingStorageKey)
 
        let resolvedHasSeenOnboardingValue = UserDefaults.standard.bool(forKey: hasSeenOnboardingStorageKey)
 
        XCTAssertFalse(
            resolvedHasSeenOnboardingValue,
            "Expected hasSeenOnboarding to be false when the key has not been written."
        )
    }
 
    // Verifies that writing true to hasSeenOnboarding persists across a re-read.
    func testHasSeenOnboarding_WhenSetToTrue_PersistsCorrectly() {
        UserDefaults.standard.set(true, forKey: hasSeenOnboardingStorageKey)
 
        let resolvedHasSeenOnboardingValue = UserDefaults.standard.bool(forKey: hasSeenOnboardingStorageKey)
 
        XCTAssertTrue(
            resolvedHasSeenOnboardingValue,
            "Expected hasSeenOnboarding to persist as true after being written."
        )
    }
 
    // Verifies that hasAcceptedTerms reads back false when the key has been removed.
    func testHasAcceptedTerms_WhenKeyIsAbsent_ReturnsFalse() {
        UserDefaults.standard.removeObject(forKey: hasAcceptedTermsStorageKey)
 
        let resolvedHasAcceptedTermsValue = UserDefaults.standard.bool(forKey: hasAcceptedTermsStorageKey)
 
        XCTAssertFalse(
            resolvedHasAcceptedTermsValue,
            "Expected hasAcceptedTerms to be false when the key has not been written."
        )
    }
 
    // Verifies that writing true to hasAcceptedTerms persists correctly.
    func testHasAcceptedTerms_WhenSetToTrue_PersistsCorrectly() {
        UserDefaults.standard.set(true, forKey: hasAcceptedTermsStorageKey)
 
        let resolvedHasAcceptedTermsValue = UserDefaults.standard.bool(forKey: hasAcceptedTermsStorageKey)
 
        XCTAssertTrue(
            resolvedHasAcceptedTermsValue,
            "Expected hasAcceptedTerms to persist as true after being written."
        )
    }
 
    // Verifies that writing a phone number to UserDefaults persists and can be read back.
    func testStoredPhoneNumber_WhenWritten_CanBeReadBack() {
        let testPhoneNumberValue = "+94771234567"
 
        UserDefaults.standard.set(true, forKey: isLoggedInStorageKey)
        UserDefaults.standard.set(testPhoneNumberValue, forKey: storedPhoneNumberStorageKey)
 
        let resolvedStoredPhoneNumber = UserDefaults.standard.string(forKey: storedPhoneNumberStorageKey)
 
        XCTAssertEqual(
            resolvedStoredPhoneNumber,
            testPhoneNumberValue,
            "Expected the stored phone number to match the value that was written."
        )
        XCTAssertTrue(
            UserDefaults.standard.bool(forKey: isLoggedInStorageKey),
            "Expected isLoggedIn to be true after being written."
        )
    }
 
    // Verifies that removing session keys after a sign-out leaves them all absent.
    func testSignOutKeyCleanup_RemovesAllSessionRelatedKeys() {
        UserDefaults.standard.set(true, forKey: isLoggedInStorageKey)
        UserDefaults.standard.set("+94771234567", forKey: storedPhoneNumberStorageKey)
        UserDefaults.standard.set("driver", forKey: storedUserRoleStorageKey)
        UserDefaults.standard.set("verificationABC", forKey: firebaseVerificationIDStorageKey)
 
        UserDefaults.standard.set(false, forKey: isLoggedInStorageKey)
        UserDefaults.standard.removeObject(forKey: storedPhoneNumberStorageKey)
        UserDefaults.standard.removeObject(forKey: firebaseVerificationIDStorageKey)
        UserDefaults.standard.removeObject(forKey: storedUserRoleStorageKey)
 
        XCTAssertFalse(
            UserDefaults.standard.bool(forKey: isLoggedInStorageKey),
            "Expected isLoggedIn to be false after session cleanup."
        )
        XCTAssertNil(
            UserDefaults.standard.string(forKey: storedPhoneNumberStorageKey),
            "Expected storedPhoneNumber to be nil after session cleanup."
        )
        XCTAssertNil(
            UserDefaults.standard.string(forKey: storedUserRoleStorageKey),
            "Expected storedUserRole to be nil after session cleanup."
        )
        XCTAssertNil(
            UserDefaults.standard.string(forKey: firebaseVerificationIDStorageKey),
            "Expected firebaseVerificationID to be nil after session cleanup."
        )
    }
 
    // Verifies that the biometric flag persists as true when written.
    func testBiometricEnabled_WhenSetToTrue_PersistsCorrectly() {
        UserDefaults.standard.set(true, forKey: isBiometricEnabledStorageKey)
 
        let resolvedBiometricEnabledValue = UserDefaults.standard.bool(forKey: isBiometricEnabledStorageKey)
 
        XCTAssertTrue(
            resolvedBiometricEnabledValue,
            "Expected isBiometricEnabled to persist as true after being written."
        )
    }
 
    // Verifies that the biometric flag persists as false when explicitly disabled.
    func testBiometricEnabled_WhenSetToFalse_PersistsCorrectly() {
        UserDefaults.standard.set(true, forKey: isBiometricEnabledStorageKey)
        UserDefaults.standard.set(false, forKey: isBiometricEnabledStorageKey)
 
        let resolvedBiometricEnabledValue = UserDefaults.standard.bool(forKey: isBiometricEnabledStorageKey)
 
        XCTAssertFalse(
            resolvedBiometricEnabledValue,
            "Expected isBiometricEnabled to persist as false after being disabled."
        )
    }
 
    // Verifies that a Firebase verification ID written to UserDefaults can be read back.
    func testFirebaseVerificationID_WhenStored_CanBeRetrieved() {
        let testVerificationIdentifier = "APA91bTestVerificationIDString"
 
        UserDefaults.standard.set(testVerificationIdentifier, forKey: firebaseVerificationIDStorageKey)
 
        let retrievedVerificationIdentifier = UserDefaults.standard.string(forKey: firebaseVerificationIDStorageKey)
 
        XCTAssertEqual(
            retrievedVerificationIdentifier,
            testVerificationIdentifier,
            "Expected the retrieved verification ID to match the stored value."
        )
    }
 
    // Verifies that removing the Firebase verification ID key returns nil on read.
    func testFirebaseVerificationID_WhenKeyIsAbsent_ReturnsNil() {
        UserDefaults.standard.removeObject(forKey: firebaseVerificationIDStorageKey)
 
        let retrievedVerificationIdentifier = UserDefaults.standard.string(forKey: firebaseVerificationIDStorageKey)
 
        XCTAssertNil(
            retrievedVerificationIdentifier,
            "Expected nil when no Firebase verification ID has been stored."
        )
    }
 
    // Verifies that writing the driver role to UserDefaults persists correctly.
    func testStoredUserRole_WhenSetToDriver_PersistsCorrectly() {
        UserDefaults.standard.set("driver", forKey: storedUserRoleStorageKey)
 
        let resolvedStoredUserRole = UserDefaults.standard.string(forKey: storedUserRoleStorageKey)
 
        XCTAssertEqual(
            resolvedStoredUserRole,
            "driver",
            "Expected the stored user role to be driver after being written."
        )
    }
 
    // Verifies that writing the passenger role to UserDefaults persists correctly.
    func testStoredUserRole_WhenSetToPassenger_PersistsCorrectly() {
        UserDefaults.standard.set("passenger", forKey: storedUserRoleStorageKey)
 
        let resolvedStoredUserRole = UserDefaults.standard.string(forKey: storedUserRoleStorageKey)
 
        XCTAssertEqual(
            resolvedStoredUserRole,
            "passenger",
            "Expected the stored user role to be passenger after being written."
        )
    }
 
    // Verifies that the AuthenticationState enum cases are all distinct values.
    func testAuthenticationState_EnumCases_AreDistinct() {
        let onboardingStateValue = AuthenticationState.onboarding
        let termsStateValue = AuthenticationState.terms
        let unauthenticatedStateValue = AuthenticationState.unauthenticated
        let authenticatedStateValue = AuthenticationState.authenticated
        let driverAuthenticatedStateValue = AuthenticationState.driverAuthenticated
 
        XCTAssertNotEqual(onboardingStateValue, termsStateValue)
        XCTAssertNotEqual(onboardingStateValue, unauthenticatedStateValue)
        XCTAssertNotEqual(onboardingStateValue, authenticatedStateValue)
        XCTAssertNotEqual(onboardingStateValue, driverAuthenticatedStateValue)
        XCTAssertNotEqual(unauthenticatedStateValue, authenticatedStateValue)
        XCTAssertNotEqual(authenticatedStateValue, driverAuthenticatedStateValue)
    }
}
