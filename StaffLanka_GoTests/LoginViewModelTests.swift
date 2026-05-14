//
//  LoginViewModelTests.swift
//  StaffLanka_GoTests
//
//  Created by Liviru Navaratna on 2026-05-14.
//

import XCTest
@testable import StaffLanka_Go

@MainActor
final class LoginViewModelTests: XCTestCase {

    private var subjectLoginViewModel: LoginViewModel!

    override func setUp() {
        super.setUp()
        subjectLoginViewModel = LoginViewModel()
    }

    override func tearDown() {
        subjectLoginViewModel = nil
        super.tearDown()
    }

    // Verifies that a 9-digit phone number passes the validation check.
    func testIsPhoneNumberValid_WithNineDigits_ReturnsTrue() {
        subjectLoginViewModel.phoneNumber = "771234567"

        XCTAssertTrue(
            subjectLoginViewModel.isPhoneNumberValid,
            "Expected a 9-digit phone number to be valid."
        )
    }

    // Verifies that a 10-digit phone number starting with zero is considered valid.
    func testIsPhoneNumberValid_WithTenDigitsIncludingLeadingZero_ReturnsTrue() {
        subjectLoginViewModel.phoneNumber = "0771234567"

        XCTAssertTrue(
            subjectLoginViewModel.isPhoneNumberValid,
            "Expected a 10-digit phone number to be valid."
        )
    }

    // Verifies that a phone number with fewer than 9 digits fails validation.
    func testIsPhoneNumberValid_WithTooFewDigits_ReturnsFalse() {
        subjectLoginViewModel.phoneNumber = "7712345"

        XCTAssertFalse(
            subjectLoginViewModel.isPhoneNumberValid,
            "Expected a 7-digit phone number to be invalid."
        )
    }

    // Verifies that an empty phone number string fails validation.
    func testIsPhoneNumberValid_WithEmptyString_ReturnsFalse() {
        subjectLoginViewModel.phoneNumber = ""

        XCTAssertFalse(
            subjectLoginViewModel.isPhoneNumberValid,
            "Expected an empty phone number to be invalid."
        )
    }

    // Verifies that spaces in the phone number are not counted as digits.
    func testIsPhoneNumberValid_WithSpacesOnly_ReturnsFalse() {
        subjectLoginViewModel.phoneNumber = "         "

        XCTAssertFalse(
            subjectLoginViewModel.isPhoneNumberValid,
            "Expected a phone number containing only spaces to be invalid."
        )
    }

    // Verifies that the full phone number combines the country code and local number
    // and strips all whitespace.
    func testFullPhoneNumber_CombinesCountryCodeAndStripsSpaces() {
        subjectLoginViewModel.phoneNumber = "077 123 4567"

        let computedFullPhoneNumber = subjectLoginViewModel.fullPhoneNumber

        XCTAssertEqual(
            computedFullPhoneNumber,
            "+940771234567",
            "Expected fullPhoneNumber to prepend +94 and remove all spaces."
        )
    }

    // Verifies that the selected country code is always the Sri Lanka code.
    func testSelectedCountryCode_AlwaysReturnsSriLankaCode() {
        XCTAssertEqual(
            subjectLoginViewModel.selectedCountryCode,
            "+94",
            "Expected the country code to be +94 for Sri Lanka."
        )
    }

    // Verifies that canSendOTP mirrors the phone number validity.
    func testCanSendOTP_WhenPhoneIsValid_ReturnsTrue() {
        subjectLoginViewModel.phoneNumber = "771234567"

        XCTAssertTrue(
            subjectLoginViewModel.canSendOTP,
            "Expected canSendOTP to be true when the phone number is valid."
        )
    }

    // Verifies that canSendOTP is false when the phone number is invalid.
    func testCanSendOTP_WhenPhoneIsInvalid_ReturnsFalse() {
        subjectLoginViewModel.phoneNumber = "123"

        XCTAssertFalse(
            subjectLoginViewModel.canSendOTP,
            "Expected canSendOTP to be false when the phone number is invalid."
        )
    }

    // Verifies that the initial login state is idle upon creation.
    func testInitialLoginState_IsIdle() {
        XCTAssertEqual(
            subjectLoginViewModel.loginState,
            .idle,
            "Expected the initial login state to be idle."
        )
    }

    // Verifies that a phone number containing non-digit characters strips them
    // correctly for the digit count used in validation.
    func testIsPhoneNumberValid_WithHyphensAndDigits_CountsOnlyDigits() {
        subjectLoginViewModel.phoneNumber = "077-123-4567"

        XCTAssertTrue(
            subjectLoginViewModel.isPhoneNumberValid,
            "Expected phone number with hyphens to strip non-digits and be valid."
        )
    }
}
