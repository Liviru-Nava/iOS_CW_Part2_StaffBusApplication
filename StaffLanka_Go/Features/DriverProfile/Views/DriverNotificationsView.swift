//
//  DriverNotificationsView.swift
//  StaffLanka_Go
//
//  Created by Liviru Navaratna on 2026-04-23.
//

import SwiftUI
import CoreData
import FirebaseAuth

struct DriverNotificationsView: View {
    @Environment(\.managedObjectContext) private var coreDataViewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NotificationEntity.timestamp, ascending: false)],
        animation: .default)
    private var allStoredNotifications: FetchedResults<NotificationEntity>

    @State private var showingClearAllConfirmationDialog: Bool = false

    var notificationsForCurrentUser: [NotificationEntity] {
        let currentFirebaseUserId = Auth.auth().currentUser?.uid ?? ""
        return allStoredNotifications.filter { $0.userId == currentFirebaseUserId }
    }

    var hasAnyUnreadNotification: Bool {
        notificationsForCurrentUser.contains { !$0.isRead }
    }

    var body: some View {
        List {
            if notificationsForCurrentUser.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color.textTertiary)
                    Text("No notifications yet")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 60)
                .listRowBackground(Color.clear)
            } else {
                ForEach(notificationsForCurrentUser) { singleNotification in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(singleNotification.title ?? "No Title")
                                    .font(.system(size: 15, weight: singleNotification.isRead ? .medium : .bold))
                                    .foregroundColor(singleNotification.isRead ? Color.textSecondary : Color.textPrimary)

                                Text(singleNotification.body ?? "")
                                    .font(.system(size: 13))
                                    .foregroundColor(singleNotification.isRead ? Color.textTertiary : Color.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                if let notificationTimestamp = singleNotification.timestamp {
                                    Text(notificationTimestamp, style: .time)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.textTertiary)
                                        .padding(.top, 2)
                                }
                            }

                            Spacer()

                            if !singleNotification.isRead {
                                Circle()
                                    .fill(Color.brandAccent)
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.cardBackground)
                    .onTapGesture {
                        markSingleNotificationAsRead(singleNotification)
                    }
                }
                .onDelete(perform: deleteNotificationsByOffset)
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

    private func markSingleNotificationAsRead(_ notificationRecord: NotificationEntity) {
        notificationRecord.isRead = true
        try? coreDataViewContext.save()
    }

    private func markAllNotificationsAsRead() {
        notificationsForCurrentUser.forEach { notificationRecord in
            notificationRecord.isRead = true
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
