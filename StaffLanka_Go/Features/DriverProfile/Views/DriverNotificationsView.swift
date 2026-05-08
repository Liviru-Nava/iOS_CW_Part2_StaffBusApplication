import SwiftUI
import CoreData
import FirebaseAuth

struct DriverNotificationsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NotificationEntity.timestamp, ascending: false)],
        animation: .default)
    private var notifications: FetchedResults<NotificationEntity>
    
    // Filter locally to avoid breaking Core Data predicates with optionals
    var userNotifications: [NotificationEntity] {
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        return notifications.filter { $0.userId == currentUserId }
    }
    
    var body: some View {
        List {
            if userNotifications.isEmpty {
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
                ForEach(userNotifications) { notification in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notification.title ?? "No Title")
                                    .font(.system(size: 15, weight: notification.isRead ? .medium : .bold))
                                    .foregroundColor(notification.isRead ? Color.textSecondary : Color.textPrimary)
                                
                                Text(notification.body ?? "")
                                    .font(.system(size: 13))
                                    .foregroundColor(notification.isRead ? Color.textTertiary : Color.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                if let date = notification.timestamp {
                                    Text(date, style: .time)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.textTertiary)
                                        .padding(.top, 2)
                                }
                            }
                            
                            Spacer()
                            
                            if !notification.isRead {
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
                        markAsRead(notification)
                    }
                }
                .onDelete(perform: deleteNotifications)
            }
        }
        .listStyle(.insetGrouped)
        .background(Color.appBackground)
        .scrollContentBackground(.hidden)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func markAsRead(_ notification: NotificationEntity) {
        notification.isRead = true
        try? viewContext.save()
    }
    
    private func deleteNotifications(offsets: IndexSet) {
        let itemsToDelete = offsets.map { userNotifications[$0] }
        withAnimation {
            itemsToDelete.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}
