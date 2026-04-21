//
//  TermsView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-12.
//
import SwiftUI

struct TermsView: View {

    @EnvironmentObject private var authManager: AuthManager
    @State private var hasScrolledToBottomOfTerms: Bool = false

    private let termsAndConditionsClauses: [(title: String, body: String)] = [
        (
            "1. Acceptance of Terms",
            "By using StaffLanka Go, you agree to be bound by these Terms & Conditions. If you do not agree, please do not use the application."
        ),
        (
            "2. Use of the Application",
            "StaffLanka Go is intended solely for staff bus commuters and drivers operating within registered transport services. You agree to use the app only for its intended purpose."
        ),
        (
            "3. Location Data",
            "The app collects real-time location data to provide ride detection, route tracking, and stop alerts. Location data is processed on-device and only shared with your registered transport provider."
        ),
        (
            "4. Attendance & Bookings",
            "Your attendance confirmations and booking records are stored to calculate subscription-based fares. These records may be visible to your bus driver and transport administrator."
        ),
        (
            "5. Privacy Policy",
            "We do not sell your personal data to third parties. Your phone number, location, and trip history are used exclusively to deliver and improve the service. Data is stored securely and accessible only to authorised parties."
        ),
        (
            "6. Notifications",
            "The app sends push notifications and vibration-based alerts for stop reminders and attendance prompts. You may adjust notification preferences in your device settings."
        ),
        (
            "7. Payments",
            "Subscription fees are calculated based on actual trip usage. Payments processed through the app are subject to the terms of the respective payment gateway provider."
        ),
        (
            "8. Modifications",
            "We reserve the right to modify these terms at any time. Continued use of the app after changes constitutes acceptance of the updated terms."
        )
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, 24)
                    .padding(.top, 56)
                    .padding(.bottom, 24)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(termsAndConditionsClauses, id: \.title) { clause in
                            termsClauseCard(title: clause.title, body: clause.body)
                        }

                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                hasScrolledToBottomOfTerms = true
                            }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }

                acceptButtonSection
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                    .background(
                        Color.appBackground
                            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: -4)
                    )
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.13))
                    .frame(width: 72, height: 72)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.brandAccent)
            }

            Text("Terms & Conditions")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)

            Text("Please read and accept our terms before continuing")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func termsClauseCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)
            Text(body)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var acceptButtonSection: some View {
        VStack(spacing: 12) {
            if !hasScrolledToBottomOfTerms {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                    Text("Scroll down to read all terms")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.textSecondary)
                }
            }

            Button {
                authManager.acceptTerms()
            } label: {
                Text("Accept & Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(LinearGradient.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Text("You must accept the terms to use StaffLanka Go")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
        }
    }
}
