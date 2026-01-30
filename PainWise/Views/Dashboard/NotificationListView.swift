import SwiftUI
import UserNotifications

struct NotificationListView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationService = NotificationService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if notificationService.pendingNotifications.isEmpty {
                        emptyState
                    } else {
                        ForEach(notificationService.pendingNotifications, id: \.identifier) { request in
                            NotificationItemRow(request: request)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .background(colorScheme == .dark ? Color.backgroundDark : Color.backgroundLight)
            .navigationTitle(L10n.notificationListTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                }
            }
            .task {
                await notificationService.fetchPendingNotifications()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color.textSecondary)

            Text(L10n.notificationListEmpty)
                .font(.headline)
                .foregroundStyle(Color.textSecondary)

            Text(L10n.notificationListEmptyHint)
                .font(.subheadline)
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 100)
    }
}

struct NotificationItemRow: View {
    @Environment(\.colorScheme) var colorScheme
    let request: UNNotificationRequest

    private var iconInfo: (String, Color) {
        switch request.identifier {
        case "morning_reminder":
            return ("sun.max.fill", .orange)
        case "evening_reminder":
            return ("moon.fill", .purple)
        case "tracking_reminder":
            return ("clock.arrow.circlepath", .blue)
        default:
            if request.identifier.contains("weather_alert") {
                return ("cloud.bolt.rain.fill", .cyan)
            }
            return ("bell.fill", .gray)
        }
    }

    private var triggerTime: String? {
        if let trigger = request.trigger as? UNCalendarNotificationTrigger {
            let components = trigger.dateComponents
            if let hour = components.hour, let minute = components.minute {
                return String(format: "%02d:%02d", hour, minute)
            }
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconInfo.1.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: iconInfo.0)
                    .font(.title2)
                    .foregroundStyle(iconInfo.1)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(request.content.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(request.content.body)
                    .font(.caption)
                    .foregroundStyle(Color.gray)
                    .lineLimit(2)
            }

            Spacer()

            if let time = triggerTime {
                Text(time)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? Color.surfaceDark : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NotificationListView()
        .preferredColorScheme(.dark)
}
