//
//  OnboardingView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-12.
//

import SwiftUI

struct OnboardingView: View {

    @EnvironmentObject private var authManager: AuthManager
    @State private var currentPageIndex: Int = 0

    private let onboardingPages: [OnboardingPageContent] = [
        OnboardingPageContent(
            systemIconName: "bus.fill",
            headline: "Welcome to StaffLanka Go",
            description: "Your smart daily commute companion, built exclusively for company staff travelling on registered bus routes.",
            accentColor: .brandAccent
        ),
        OnboardingPageContent(
            systemIconName: "map.fill",
            headline: "Track Your Route Live",
            description: "Get real-time updates on your bus location, upcoming stops, and estimated arrival times — all in one place.",
            accentColor: .statusActive
        ),
        OnboardingPageContent(
            systemIconName: "steeringwheel",
            headline: "Drive & Earn Easily",
            description: "Accept rides, track your earnings in real time, and get paid reliably — all in one place.",
            accentColor: .statusWarning
        )
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPageIndex) {
                    ForEach(onboardingPages.indices, id: \.self) { pageIndex in
                        onboardingPageView(page: onboardingPages[pageIndex])
                            .tag(pageIndex)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPageIndex)

                bottomControlsSection
                    .padding(.horizontal, 28)
                    .padding(.bottom, 52)
            }
        }
    }

    private func onboardingPageView(page: OnboardingPageContent) -> some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.accentColor.opacity(0.13))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(page.accentColor.opacity(0.08))
                    .frame(width: 110, height: 110)
                Image(systemName: page.systemIconName)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundColor(page.accentColor)
            }

            VStack(spacing: 16) {
                Text(page.headline)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var bottomControlsSection: some View {
        VStack(spacing: 28) {
            pageIndicatorDots

            if currentPageIndex < onboardingPages.count - 1 {
                HStack {
                    Button {
                        authManager.markOnboardingComplete()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeInOut) {
                            currentPageIndex += 1
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Next")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 28)
                        .frame(height: 50)
                        .background(Color.brandSecondary)
                        .clipShape(Capsule())
                    }
                }
            } else {
                Button {
                    authManager.markOnboardingComplete()
                } label: {
                    Text("Get Started")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(LinearGradient.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private var pageIndicatorDots: some View {
        HStack(spacing: 8) {
            ForEach(onboardingPages.indices, id: \.self) { dotIndex in
                Capsule()
                    .fill(dotIndex == currentPageIndex ? Color.brandAccent : Color.divider)
                    .frame(width: dotIndex == currentPageIndex ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPageIndex)
            }
        }
    }
}

private struct OnboardingPageContent {
    let systemIconName: String
    let headline: String
    let description: String
    let accentColor: Color
}
