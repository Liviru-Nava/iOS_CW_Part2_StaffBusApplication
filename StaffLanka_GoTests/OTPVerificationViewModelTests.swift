//
//  OTPVerificationViewModelTests.swift
//  StaffLanka_GoTests
//
//  Created by Liviru Navaratna on 2026-05-14.
//
import XCTest
@testable import StaffLanka_Go

@MainActor
final class OTPVerificationViewModelTests: XCTestCase {

    private var subjectOTPVerificationViewModel: OTPVerificationViewModel!
    private let testPhoneNumberValue = "+94771234567"

    override func setUp() {
        super.setUp()
        subjectOTPVerificationViewModel = OTPVerificationViewModel(phoneNumber: testPhoneNumberValue)
    }

    override func tearDown() {
        subjectOTPVerificationViewModel = nil
        super.tearDown()
    }

    // Verifies that the phone number passed at initialisation is stored correctly.
    func testInit_StoresPhoneNumber() {
        XCTAssertEqual(
            subjectOTPVerificationViewModel.phoneNumber,
            testPhoneNumberValue,
            "Expected the view model to store the phone number supplied at init."
        )
    }

    // Verifies that the OTP digits array is initialised to six empty strings.
    func testInit_OTPDigitsAreInitialisedToSixEmptyStrings() {
        XCTAssertEqual(
            subjectOTPVerificationViewModel.otpDigits.count,
            6,
            "Expected otpDigits to contain exactly 6 elements on init."
        )
        XCTAssertTrue(
            subjectOTPVerificationViewModel.otpDigits.allSatisfy { $0.isEmpty },
            "Expected all initial OTP digit slots to be empty strings."
        )
    }

    // Verifies that enteredOTPString joins all digits into a single string.
    func testEnteredOTPString_JoinsAllDigitSlots() {
        subjectOTPVerificationViewModel.otpDigits = ["1", "2", "3", "4", "5", "6"]

        XCTAssertEqual(
            subjectOTPVerificationViewModel.enteredOTPString,
            "123456",
            "Expected enteredOTPString to concatenate all OTP digit slots."
        )
    }

    // Verifies that isOTPComplete returns true only when all six slots are filled.
    func testIsOTPComplete_WhenAllSixSlotsAreFilled_ReturnsTrue() {
        subjectOTPVerificationViewModel.otpDigits = ["9", "8", "7", "6", "5", "4"]

        XCTAssertTrue(
            subjectOTPVerificationViewModel.isOTPComplete,
            "Expected isOTPComplete to be true when all six digit slots contain values."
        )
    }

    // Verifies that isOTPComplete returns false when at least one slot is empty.
    func testIsOTPComplete_WhenOneSlotIsEmpty_ReturnsFalse() {
        subjectOTPVerificationViewModel.otpDigits = ["1", "2", "3", "4", "5", ""]

        XCTAssertFalse(
            subjectOTPVerificationViewModel.isOTPComplete,
            "Expected isOTPComplete to be false when one digit slot is empty."
        )
    }

    // Verifies that canResendOTP is false when the countdown has not yet reached zero.
    func testCanResendOTP_WhenCountdownIsNonZero_ReturnsFalse() {
        subjectOTPVerificationViewModel.secondsRemainingForResend = 15

        XCTAssertFalse(
            subjectOTPVerificationViewModel.canResendOTP,
            "Expected canResendOTP to be false while the countdown is still running."
        )
    }

    // Verifies that canResendOTP becomes true exactly when the countdown reaches zero.
    func testCanResendOTP_WhenCountdownReachesZero_ReturnsTrue() {
        subjectOTPVerificationViewModel.secondsRemainingForResend = 0

        XCTAssertTrue(
            subjectOTPVerificationViewModel.canResendOTP,
            "Expected canResendOTP to be true when secondsRemainingForResend is 0."
        )
    }

    // Verifies that the initial verification state is idle.
    func testInitialVerificationState_IsIdle() {
        XCTAssertEqual(
            subjectOTPVerificationViewModel.verificationState,
            .idle,
            "Expected the initial verificationState to be idle."
        )
    }

    // Verifies that the initial resend countdown is set to 30 seconds.
    func testInitialResendCountdown_IsThirtySeconds() {
        XCTAssertEqual(
            subjectOTPVerificationViewModel.secondsRemainingForResend,
            30,
            "Expected the initial resend countdown to be 30 seconds."
        )
    }

    // Verifies that calling resendOTP resets the digit slots to empty strings.
    func testResendOTP_ClearsAllOTPDigitSlots() {
        subjectOTPVerificationViewModel.otpDigits = ["1", "2", "3", "4", "5", "6"]
        subjectOTPVerificationViewModel.secondsRemainingForResend = 0

        subjectOTPVerificationViewModel.resendOTP()

        XCTAssertTrue(
            subjectOTPVerificationViewModel.otpDigits.allSatisfy { $0.isEmpty },
            "Expected all OTP digit slots to be cleared after calling resendOTP."
        )
    }

    // Verifies that resendOTP resets the verification state to idle.
    func testResendOTP_ResetsVerificationStateToIdle() {
        subjectOTPVerificationViewModel.verificationState = .error("Some previous error")
        subjectOTPVerificationViewModel.secondsRemainingForResend = 0

        subjectOTPVerificationViewModel.resendOTP()

        XCTAssertEqual(
            subjectOTPVerificationViewModel.verificationState,
            .idle,
            "Expected verificationState to reset to idle after calling resendOTP."
        )
    }

    // Verifies that the biometric enrollment prompt is not shown at initialisation.
    func testInitialBiometricEnrollmentPrompt_IsFalse() {
        XCTAssertFalse(
            subjectOTPVerificationViewModel.shouldPromptBiometricEnrollment,
            "Expected shouldPromptBiometricEnrollment to be false at initialisation."
        )
    }

    // Verifies that dismissBiometricEnrollmentPrompt sets the prompt flag to false.
    func testDismissBiometricEnrollmentPrompt_SetsFlagToFalse() {
        subjectOTPVerificationViewModel.shouldPromptBiometricEnrollment = true

        subjectOTPVerificationViewModel.dismissBiometricEnrollmentPrompt()

        XCTAssertFalse(
            subjectOTPVerificationViewModel.shouldPromptBiometricEnrollment,
            "Expected shouldPromptBiometricEnrollment to be false after dismissal."
        )
    }
}
