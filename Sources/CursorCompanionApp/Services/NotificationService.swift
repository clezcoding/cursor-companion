import Foundation
import UserNotifications
import CursorCompanionCore

/// Sendet lokale macOS-Benachrichtigungen bei hohem Kontingent-Verbrauch
public final class NotificationService: @unchecked Sendable {
    public static let shared = NotificationService()
    private var notifiedThresholds: [String: Set<Int>] = [:] // accountID -> Set of thresholds already notified (e.g. 85, 95)

    private init() {}

    /// Fragt Benachrichtigungsberechtigungen bei macOS an
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    /// Prüft den Snapshot und sendet Warnmeldungen bei Überschreitung des Schwellenwerts
    public func checkAndNotify(account: CursorAccount, settings: UserSettings) {
        guard settings.notifyHighUsage, let snapshot = account.snapshot else { return }

        let threshold = Int(settings.highUsageThresholdPercent)
        var thresholds = notifiedThresholds[account.id] ?? []

        // Cursor Models
        if let cursorPct = snapshot.cursorModelsPercent, Int(cursorPct) >= threshold {
            if !thresholds.contains(threshold) {
                sendNotification(
                    title: "Cursor Models fast erschöpft (\(account.label))",
                    body: String(format: "Du hast bereits %.0f%% deines Kontingents verbraucht.", cursorPct)
                )
                thresholds.insert(threshold)
            }
        }

        // Other Models
        if let otherPct = snapshot.otherModelsPercent, Int(otherPct) >= threshold {
            let key = threshold + 1000 // Differenzierter Key
            if !thresholds.contains(key) {
                sendNotification(
                    title: "Other Models fast erschöpft (\(account.label))",
                    body: String(format: "Du hast bereits %.0f%% deines Kontingents verbraucht.", otherPct)
                )
                thresholds.insert(key)
            }
        }

        notifiedThresholds[account.id] = thresholds
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Sofort anzeigen
        )

        UNUserNotificationCenter.current().add(request)
    }
}
