import Cocoa
import SwiftUI
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var clipboardManager: ClipboardManager?
    var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize clipboard manager
        clipboardManager = ClipboardManager()

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
        popover?.contentSize = NSSize(width: 400, height: 500)
        popover?.behavior = .transient
        if let manager = clipboardManager {
            popover?.contentViewController = NSHostingController(rootView: ContentView(clipboardManager: manager))
        }

        // Setup global hotkey (Cmd+Shift+V)
        setupHotKey()
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
        // Register Cmd+Shift+V as the global hotkey
        hotKey = HotKey(key: .v, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = { [weak self] in
            self?.togglePopover()
        }
        print("⌨️ Global hotkey registered: Cmd+Shift+V")
    }
}
