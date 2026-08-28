import AppKit
import CursorCompanionCore

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var scheduler: UsageScheduler?
    private var appState: AppState?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // App läuft als reines Menüleisten-Utility ohne Dock-Icon (LSUIElement)
        NSApp.setActivationPolicy(.accessory)

        let store = AccountStore()
        let state = AppState(store: store)
        self.appState = state

        let statusController = StatusBarController(appState: state)
        self.statusBarController = statusController

        let sched = UsageScheduler(appState: state)
        self.scheduler = sched
        sched.start(intervalMinutes: state.settings.refreshIntervalMinutes)

        Task {
            // Kaltstart: Gecachte Daten sofort laden (<1s)
            await state.loadCachedAccounts()
            
            // Erststart-Check: Öffnet den Onboarding-Assistenten beim allerersten Start
            if !state.settings.hasCompletedOnboarding {
                statusController.openOnboardingWindow()
            }

            // Im Hintergrund frische Daten von Cursor einholen
            await state.refreshAllAccounts()

            // Benachrichtigungen prüfen
            for account in state.accounts {
                NotificationService.shared.checkAndNotify(account: account, settings: state.settings)
            }
        }
    }

    public func applicationWillTerminate(_ notification: Notification) {
        scheduler?.stop()
    }
}
