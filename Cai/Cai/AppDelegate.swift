import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    private let hotKeyManager = HotKeyManager()
    private let clipboardService = ClipboardService.shared
    private let contentDetector = ContentDetector.shared
    private let windowController = WindowController()
    private let permissionsManager = PermissionsManager.shared
    private let clipboardHistory = ClipboardHistory.shared
    private var aboutWindow: NSWindow?

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

            print("Status bar item created with clipboard icon")
        } else {
            print("Failed to create status bar button")
        }

        // Create popover for left-click — shows settings
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 340, height: 440)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: SettingsView())

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

        // Setup global hotkey (Option+C)
        setupHotKey()

        // Listen for permission changes to re-register hotkey
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AccessibilityPermissionChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if self?.permissionsManager.hasAccessibilityPermission == true {
                print("Accessibility permission granted - re-registering hotkey")
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
            // Left-click: toggle settings popover
            togglePopover()
        }
    }

    func showMenu() {
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Open Cai", action: #selector(openCai), keyEquivalent: "")
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(openSettings), keyEquivalent: ","))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "About Cai", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit Cai", action: #selector(quitApp), keyEquivalent: "q"))

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

    @objc func openSettings() {
        togglePopover()
    }

    @objc func openCai() {
        handleHotKeyTrigger()
    }

    @objc func showAbout() {
        // If already open, bring to front
        if let existing = aboutWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let aboutView = AboutView()
        let hostingView = NSHostingView(rootView: aboutView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About Cai"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.center()

        self.aboutWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func setupHotKey() {
        // Register Option+C as the global hotkey
        hotKeyManager.register { [weak self] in
            self?.handleHotKeyTrigger()
        }
    }

    func handleHotKeyTrigger() {
        print("Hotkey triggered")

        // If the action window is already visible, dismiss it (toggle behavior)
        if windowController.isVisible {
            windowController.hideWindow()
            return
        }

        // First, copy any selected text (simulates Cmd+C)
        clipboardService.copySelectedText { [weak self] in
            guard let self = self else { return }

            // Read clipboard — works whether Cmd+C copied new text or clipboard already had content.
            // This means Option+C with no selection will re-use the last clipboard contents.
            if let content = self.clipboardService.readClipboard() {
                // Record to clipboard history
                self.clipboardHistory.recordCurrentClipboard()

                // Detect content type
                let detection = self.contentDetector.detect(content)
                print("Detected: \(detection.type.rawValue) (confidence: \(detection.confidence))")

                // Show the action window immediately — LLM errors handled at execution time
                self.windowController.showActionWindow(
                    text: content,
                    detection: detection
                )
            } else {
                print("Clipboard is empty")
                self.windowController.showToast(message: "Clipboard is empty")
            }
        }
    }
}
