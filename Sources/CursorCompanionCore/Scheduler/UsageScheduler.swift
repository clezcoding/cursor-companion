import Foundation
import AppKit

/// Periodischer Scheduler zur automatischen Hintergrund-Aktualisierung und Wake-Erkennung
public final class UsageScheduler: @unchecked Sendable {
    private var timerTask: Task<Void, Never>?
    private var wakeObserver: NSObjectProtocol?
    private weak var appState: AppState?

    public init(appState: AppState) {
        self.appState = appState
        setupWakeNotification()
    }

    deinit {
        stop()
    }

    /// Startet das periodische Polling
    public func start(intervalMinutes: Int = 5) {
        stop()
        let intervalSeconds = UInt64(max(1, intervalMinutes) * 60) * 1_000_000_000

        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: intervalSeconds)
                guard !Task.isCancelled else { break }
                await self?.appState?.refreshAllAccounts()
            }
        }
    }

    /// Stoppt das Polling
    public func stop() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func setupWakeNotification() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.appState?.refreshAllAccounts()
            }
        }
    }
}
