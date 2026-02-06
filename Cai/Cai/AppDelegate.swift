import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    private let hotKeyManager = HotKeyManager()
    private let clipboardService = ClipboardService.shared
    private let permissionsManager = PermissionsManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // Use SF Symbol for clipboard
            let image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Cai")
            image?.isTemplate = true
            button.image = image
            button.action = #selector(handleStatusItemClick(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])

            print("✅ Status bar item created with clipboard icon")
        } else {
            print("❌ Failed to create status bar button")
        }

        // Create popover for left-click
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 300)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: ContentView())

        // Check accessibility permission
        permissionsManager.checkAccessibilityPermission()
        permissionsManager.recheckPermissionWhenAppBecomesActive()

        // Trigger the system prompt to add Cai to System Settings
        if !permissionsManager.hasAccessibilityPermission {
            permissionsManager.requestAccessibilityPermission()

            // Show our alert after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.permissionsManager.showPermissionAlert()
            }
        }

        // Setup global hotkey (⌥C - Option+C)
        setupHotKey()

        // Listen for permission changes to re-register hotkey
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AccessibilityPermissionChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if self?.permissionsManager.hasAccessibilityPermission == true {
                print("🔄 Accessibility permission granted - re-registering hotkey")
                self?.setupHotKey()
            }
        }
    }

    @objc func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // Right-click: show menu
            showMenu()
        } else {
            // Left-click: toggle popover
            togglePopover()
        }
    }

    func showMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Cai", action: #selector(openCai), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc func togglePopover() {
        if let button = statusItem?.button {
            if let popover = popover {
                if popover.isShown {
                    popover.performClose(nil)
                } else {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
            }
        }
    }

    @objc func openCai() {
        togglePopover()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func setupHotKey() {
        // Register Option+C (⌥C) as the global hotkey
        hotKeyManager.register { [weak self] in
            self?.handleHotKeyTrigger()
        }
    }

    func handleHotKeyTrigger() {
        print("🔥 Hotkey triggered!")

        // First, copy any selected text (simulates Cmd+C)
        clipboardService.copySelectedText { [weak self] in
            // Then read the clipboard content after copy completes
            if let content = self?.clipboardService.readClipboard() {
                print("📋 Clipboard content: \(content)")
                // For now, just log to console - Phase 3 will add UI
            } else {
                print("⚠️ Clipboard is empty")
            }
        }
    }
}
