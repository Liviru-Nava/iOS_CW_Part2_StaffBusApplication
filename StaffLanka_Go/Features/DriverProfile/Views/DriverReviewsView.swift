//
//  DriverReviewsView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-10.
//

//import SwiftUI
//
//struct DriverReviewsView: View {
//
//    @ObservedObject var driverProfileViewModel: DriverProfileViewModel
//
//    var body: some View {
//        List {
//            ratingSummarySection
//            reviewsListSection
//        }
//        .listStyle(.insetGrouped)
//        .scrollContentBackground(.hidden)
//        .background(Color.appBackground)
//        .navigationTitle("Passenger Reviews")
//        .navigationBarTitleDisplayMode(.large)
//    }
//
//    private var ratingSummarySection: some View {
//        Section {
//            HStack(spacing: 24) {
//                VStack(spacing: 6) {
//                    Text(String(format: "%.1f", driverProfileViewModel.averageDriverRatingValue))
//                        .font(.system(size: 52, weight: .bold, design: .rounded))
//                        .foregroundColor(.textPrimary)
//                    HStack(spacing: 4) {
//                        ForEach(0 ..< 5) { starIndex in
//                            Image(systemName: Double(starIndex) < driverProfileViewModel.averageDriverRatingValue ? "star.fill" : "star")
//                                .font(.system(size: 14))
//                                .foregroundColor(.statusWarning)
//                        }
//                    }
//                    Text("\(driverProfileViewModel.driverReviewsList.count) reviews")
//                        .font(.system(size: 12))
//                        .foregroundColor(.textTertiary)
//                }
//
//                Divider()
//
//                VStack(alignment: .leading, spacing: 6) {
//                    ForEach([5, 4, 3, 2, 1], id: \.self) { starLevel in
//                        HStack(spacing: 8) {
//                            Text("\(starLevel)")
//                                .font(.system(size: 12))
//                                .foregroundColor(.textSecondary)
//                                .frame(width: 10, alignment: .trailing)
//                            Image(systemName: "star.fill")
//                                .font(.system(size: 10))
//                                .foregroundColor(.statusWarning)
//                            GeometryReader { geometry in
//                                ZStack(alignment: .leading) {
//                                    RoundedRectangle(cornerRadius: 3)
//                                        .fill(Color.divider)
//                                        .frame(height: 5)
//                                    RoundedRectangle(cornerRadius: 3)
//                                        .fill(Color.statusWarning)
//                                        .frame(width: geometry.size.width * ratingBarFraction(forStar: starLevel), height: 5)
//                                }
//                            }
//                            .frame(height: 5)
//                            Text("\(reviewCountForStarLevel(starLevel))")
//                                .font(.system(size: 11))
//                                .foregroundColor(.textTertiary)
//                                .frame(width: 16, alignment: .leading)
//                        }
//                    }
//                }
//                .frame(maxWidth: .infinity)
//            }
//            .padding(.vertical, 8)
//            .listRowBackground(Color.cardBackground)
//        }
//    }
//
//    private var reviewsListSection: some View {
//        Section {
//            if driverProfileViewModel.driverReviewsList.isEmpty {
//                VStack(spacing: 16) {
//                    Image(systemName: "star.slash")
//                        .font(.system(size: 40))
//                        .foregroundColor(.textTertiary)
//                    Text("No reviews yet")
//                        .font(.system(size: 16, weight: .semibold))
//                        .foregroundColor(.textPrimary)
//                    Text("Passenger reviews will appear here after completed trips.")
//                        .font(.system(size: 13))
//                        .foregroundColor(.textSecondary)
//                        .multilineTextAlignment(.center)
//                }
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 40)
//                .listRowBackground(Color.clear)
//            } else {
//                ForEach(driverProfileViewModel.driverReviewsList) { review in
//                    reviewCard(review: review)
//                        .listRowBackground(Color.cardBackground)
//                }
//            }
//        } header: {
//            Text("All Reviews")
//        }
//    }
//
//    private func reviewCard(review: DriverProfileViewModel.DriverReviewEntry) -> some View {
//        VStack(alignment: .leading, spacing: 10) {
//            HStack(spacing: 12) {
//                ZStack {
//                    Circle()
//                        .fill(LinearGradient.brandSubtle)
//                        .frame(width: 44, height: 44)
//                    Text(String(review.reviewerPassengerName.prefix(1)))
//                        .font(.system(size: 17, weight: .bold))
//                        .foregroundColor(.brandAccent)
//                }
//
//                VStack(alignment: .leading, spacing: 3) {
//                    Text(review.reviewerPassengerName)
//                        .font(.system(size: 15, weight: .semibold))
//                        .foregroundColor(.textPrimary)
//                    HStack(spacing: 3) {
//                        ForEach(0 ..< 5) { starIndex in
//                            Image(systemName: Double(starIndex) < review.reviewRatingOutOfFive ? "star.fill" : "star")
//                                .font(.system(size: 11))
//                                .foregroundColor(.statusWarning)
//                        }
//                        Text(String(format: "%.1f", review.reviewRatingOutOfFive))
//                            .font(.system(size: 12, weight: .semibold))
//                            .foregroundColor(.textSecondary)
//                            .padding(.leading, 3)
//                    }
//                }
//                Spacer()
//            }
//
//            Text(review.reviewCommentText)
//                .font(.system(size: 14))
//                .foregroundColor(.textSecondary)
//                .lineSpacing(4)
//        }
//        .padding(.vertical, 8)
//    }
//
//    private func reviewCountForStarLevel(_ starLevel: Int) -> Int {
//        driverProfileViewModel.driverReviewsList.filter { Int($0.reviewRatingOutOfFive.rounded()) == starLevel }.count
//    }
//
//    private func ratingBarFraction(forStar starLevel: Int) -> CGFloat {
//        guard !driverProfileViewModel.driverReviewsList.isEmpty else { return 0 }
//        let countForLevel = reviewCountForStarLevel(starLevel)
//        return CGFloat(countForLevel) / CGFloat(driverProfileViewModel.driverReviewsList.count)
//    }
//}
