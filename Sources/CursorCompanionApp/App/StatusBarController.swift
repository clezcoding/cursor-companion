import AppKit
import SwiftUI
import CursorCompanionCore

/// Steuert den NSStatusItem in der macOS-Menüleiste und das NSPopover
@MainActor
public final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private let appState: AppState
    private var settingsWindow: NSWindow?

    public init(appState: AppState) {
        self.appState = appState
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        super.init()

        setupStatusButton()
        setupPopover()
    }

    private func setupStatusButton() {
        guard let button = statusItem.button else { return }
        
        let hostingView = NSHostingView(rootView: MenuBarLabelView(appState: appState))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 4),
            hostingView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -4),
            hostingView.topAnchor.constraint(equalTo: button.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])

        button.target = self
        button.action = #selector(togglePopover)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func setupPopover() {
        popover.contentSize = NSSize(width: 270, height: 180)
        popover.behavior = .transient
        popover.animates = true

        let popoverContent = PopoverView(appState: appState) { [weak self] in
            self?.openSettingsWindow()
        }
        popover.contentViewController = NSHostingController(rootView: popoverContent)
    }

    @objc public func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    public func openSettingsWindow() {
        popover.performClose(nil)

        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 320),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "CursorCompanion Einstellungen"
            window.contentView = NSHostingView(rootView: SettingsView(appState: appState))
            window.isReleasedWhenClosed = false
            self.settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
