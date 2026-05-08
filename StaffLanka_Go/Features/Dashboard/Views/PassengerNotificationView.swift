//
//  PassengerNotificationView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-05-08.
//

import SwiftUI
import CoreData
import FirebaseAuth

struct PassengerNotificationsView: View {
    @Environment(\.managedObjectContext) private var coreDataViewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NotificationEntity.timestamp, ascending: false)],
        animation: .default
    )
    private var allStoredNotifications: FetchedResults<NotificationEntity>

    @State private var showingClearAllConfirmationDialog: Bool = false

    var notificationsForCurrentUser: [NotificationEntity] {
        let currentFirebaseUserId = Auth.auth().currentUser?.uid ?? ""
        return allStoredNotifications.filter { $0.userId == currentFirebaseUserId }
    }

    var unreadNotificationCount: Int {
        notificationsForCurrentUser.filter { !$0.isRead }.count
    }

    var hasAnyUnreadNotification: Bool {
        unreadNotificationCount > 0
    }

    var body: some View {
        List {
            if notificationsForCurrentUser.isEmpty {
                emptyNotificationsPlaceholder
            } else {
                notificationRowsSection
            }
        }
        .listStyle(.insetGrouped)
        .background(Color.appBackground)
        .scrollContentBackground(.hidden)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Clear All Notifications",
            isPresented: $showingClearAllConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                clearAllNotifications()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your notifications. This action cannot be undone.")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !notificationsForCurrentUser.isEmpty {
                    Menu {
                        if hasAnyUnreadNotification {
                            Button {
                                markAllNotificationsAsRead()
                            } label: {
                                Label("Mark All as Read", systemImage: "checkmark.circle")
                            }
                        }
                        Button(role: .destructive) {
                            showingClearAllConfirmationDialog = true
                        } label: {
                            Label("Clear All Notifications", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.brandAccent)
                    }
                }
            }
        }
    }

    private var emptyNotificationsPlaceholder: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.10))
                    .frame(width: 72, height: 72)
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.textTertiary)
            }
            VStack(spacing: 6) {
                Text("No Notifications Yet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("Alerts for your trips, bookings, and bus arrivals will appear here.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 60)
        .listRowBackground(Color.clear)
    }

    private var notificationRowsSection: some View {
        ForEach(notificationsForCurrentUser) { singleNotificationRecord in
            notificationRowView(notificationRecord: singleNotificationRecord)
                .listRowBackground(Color.cardBackground)
                .onTapGesture {
                    markSingleNotificationAsRead(notificationRecord: singleNotificationRecord)
                }
        }
        .onDelete(perform: deleteNotificationsByOffset)
    }

    private func notificationRowView(notificationRecord: NotificationEntity) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColorForActionType(notificationRecord.actionType))
                    .frame(width: 38, height: 38)
                Image(systemName: iconNameForActionType(notificationRecord.actionType))
                    .font(.system(size: 15))
                    .foregroundStyle(iconForegroundColorForActionType(notificationRecord.actionType))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notificationRecord.title ?? "Notification")
                        .font(.system(size: 14, weight: notificationRecord.isRead ? .medium : .bold))
                        .foregroundStyle(notificationRecord.isRead ? Color.textSecondary : Color.textPrimary)
                    Spacer()
                    if !notificationRecord.isRead {
                        Circle()
                            .fill(Color.brandAccent)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(notificationRecord.body ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(notificationRecord.isRead ? Color.textTertiary : Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)

                if let notificationTimestamp = notificationRecord.timestamp {
                    Text(formattedTimestampLabel(date: notificationTimestamp))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textTertiary)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func iconNameForActionType(_ actionType: String?) -> String {
        switch actionType {
        case "TRIP_START":            return "bus.fill"
        case "TRIP_END":              return "checkmark.seal.fill"
        case "BUS_APPROACHING_PICKUP":  return "location.fill"
        case "BUS_APPROACHING_DROPOFF": return "mappin.circle.fill"
        case "LOGIN_SUCCESS":         return "person.fill.checkmark"
        default:                      return "bell.fill"
        }
    }

    private func iconBackgroundColorForActionType(_ actionType: String?) -> Color {
        switch actionType {
        case "TRIP_START":                              return Color.brandAccent.opacity(0.12)
        case "TRIP_END":                                return Color.statusActive.opacity(0.12)
        case "BUS_APPROACHING_PICKUP", "BUS_APPROACHING_DROPOFF": return Color.statusWarning.opacity(0.12)
        case "LOGIN_SUCCESS":                           return Color.brandAccent.opacity(0.10)
        default:                                        return Color.brandAccent.opacity(0.10)
        }
    }

    private func iconForegroundColorForActionType(_ actionType: String?) -> Color {
        switch actionType {
        case "TRIP_START":                              return Color.brandAccent
        case "TRIP_END":                                return Color.statusActive
        case "BUS_APPROACHING_PICKUP", "BUS_APPROACHING_DROPOFF": return Color.statusWarning
        case "LOGIN_SUCCESS":                           return Color.brandAccent
        default:                                        return Color.brandAccent
        }
    }

    private func formattedTimestampLabel(date: Date) -> String {
        let secondsSinceNotification = Date().timeIntervalSince(date)
        if secondsSinceNotification < 60 {
            return "Just now"
        } else if secondsSinceNotification < 3600 {
            let minutesAgo = Int(secondsSinceNotification / 60)
            return "\(minutesAgo) min ago"
        } else if Calendar.current.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            return timeFormatter.string(from: date)
        } else if Calendar.current.isDateInYesterday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            return "Yesterday, \(timeFormatter.string(from: date))"
        } else {
            let dateTimeFormatter = DateFormatter()
            dateTimeFormatter.dateStyle = .short
            dateTimeFormatter.timeStyle = .short
            return dateTimeFormatter.string(from: date)
        }
    }

    private func markSingleNotificationAsRead(notificationRecord: NotificationEntity) {
        guard !notificationRecord.isRead else { return }
        notificationRecord.isRead = true
        try? coreDataViewContext.save()
    }

    private func markAllNotificationsAsRead() {
        notificationsForCurrentUser.forEach { singleRecord in
            singleRecord.isRead = true
        }
        try? coreDataViewContext.save()
    }

    private func clearAllNotifications() {
        withAnimation {
            notificationsForCurrentUser.forEach(coreDataViewContext.delete)
            try? coreDataViewContext.save()
        }
    }

    private func deleteNotificationsByOffset(offsets: IndexSet) {
        let recordsToDelete = offsets.map { notificationsForCurrentUser[$0] }
        withAnimation {
            recordsToDelete.forEach(coreDataViewContext.delete)
            try? coreDataViewContext.save()
        }
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        PassengerNotificationsView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    NavigationStack {
        PassengerNotificationsView()
    }
    .preferredColorScheme(.light)
}
