import AppKit
import SwiftUI

// MARK: - CaiPanel

/// Custom NSPanel subclass that can become key window.
/// Standard NSPanel with .nonactivatingPanel returns NO from canBecomeKeyWindow,
/// which prevents keyboard events from being received. This override fixes that.
class CaiPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - SelectionState

/// Observable state holder so SwiftUI views react to selection changes
/// without recreating the entire hosting view.
class SelectionState: ObservableObject {
    @Published var selectedIndex: Int = 0
}

/// Manages the floating action window. Creates a borderless, translucent NSWindow
/// that hosts the SwiftUI ActionListWindow view. Handles positioning, keyboard
/// events (arrow keys, Enter, ESC, Cmd+1-9), and dismiss-on-click-outside.
class WindowController: NSObject, ObservableObject {
    private var window: NSWindow?
    private var actions: [ActionItem] = []
    private var selectionState = SelectionState()
    private var localMonitor: Any?
    private var globalMonitor: Any?

    /// Layout constants
    private static let windowWidth: CGFloat = 500
    private static let headerHeight: CGFloat = 52
    private static let footerHeight: CGFloat = 36
    private static let dividerHeight: CGFloat = 1
    private static let rowHeight: CGFloat = 42  // 7 + 28 + 7 padding
    private static let listVerticalPadding: CGFloat = 12  // 6 top + 6 bottom
    private static let maxWindowHeight: CGFloat = 600
    private static let cornerRadius: CGFloat = 20

    /// Calculates dynamic window height based on action count.
    private func calculateWindowHeight(actionCount: Int) -> CGFloat {
        let contentHeight = CGFloat(actionCount) * Self.rowHeight + Self.listVerticalPadding
        let totalHeight = Self.headerHeight + Self.dividerHeight + contentHeight + Self.dividerHeight + Self.footerHeight
        return min(totalHeight, Self.maxWindowHeight)
    }

    /// Shows the action window centered on screen with actions for the given content.
    func showActionWindow(text: String, detection: ContentResult) {
        // If window is already visible, dismiss first
        hideWindow()

        let actions = ActionProvider.shared.actions(for: text, detection: detection)
        self.actions = actions

        // Reset selection state
        selectionState = SelectionState()

        // Calculate dynamic height
        let windowHeight = calculateWindowHeight(actionCount: actions.count)

        // Create dismiss/execute closures
        let dismissAction: () -> Void = { [weak self] in
            self?.hideWindow()
        }
        let executeAction: (ActionItem) -> Void = { [weak self] action in
            self?.executeSystemAction(action)
        }

        // Create the SwiftUI view with shared selection state
        let actionList = ActionListWindow(
            text: text,
            detection: detection,
            actions: actions,
            selectionState: selectionState,
            onDismiss: dismissAction,
            onExecute: executeAction
        )

        // Wrap in a hosting view that captures key events
        let hostingView = KeyEventHostingView(
            rootView: actionList
                .frame(width: Self.windowWidth, height: windowHeight),
            onKeyDown: { [weak self] event in
                self?.handleKeyEvent(event) ?? false
            }
        )
        hostingView.frame = NSRect(x: 0, y: 0, width: Self.windowWidth, height: windowHeight)
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = Self.cornerRadius
        hostingView.layer?.cornerCurve = .continuous
        hostingView.layer?.masksToBounds = true

        // Create borderless CaiPanel (custom subclass that returns YES from canBecomeKey)
        let panel = CaiPanel(
            contentRect: NSRect(x: 0, y: 0, width: Self.windowWidth, height: windowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false  // We draw our own shadow in SwiftUI
        panel.level = .floating
        panel.isMovableByWindowBackground = true  // Drag to reposition
        panel.contentView = hostingView

        // Allow the panel to become key so we receive keyboard events
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.hidesOnDeactivate = false

        // Restore last saved position, or center on screen
        if let savedOrigin = Self.loadWindowPosition() {
            panel.setFrameOrigin(savedOrigin)
        } else if let screen = NSScreen.main ?? NSScreen.screens.first {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - Self.windowWidth / 2
            let y = screenFrame.midY - windowHeight / 2 + 50
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.window = panel

        // Activate our app temporarily so the panel can become key
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        // Monitor for clicks outside the window to dismiss (LOCAL events — within our app)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let window = self.window else { return event }
            let windowFrame = window.frame

            // Convert to screen coordinates
            if let eventWindow = event.window {
                let screenPoint = eventWindow.convertPoint(toScreen: event.locationInWindow)
                if !windowFrame.contains(screenPoint) {
                    self.hideWindow()
                }
            } else {
                if !windowFrame.contains(event.locationInWindow) {
                    self.hideWindow()
                }
            }
            return event
        }

        // Monitor for clicks outside the window to dismiss (GLOBAL events — other apps)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            // Global events always mean clicks outside our app
            self?.hideWindow()
        }

        print("🪟 Action window shown with \(actions.count) actions (height: \(windowHeight))")
    }

    func hideWindow() {
        // Save window position before dismissing
        if let origin = window?.frame.origin {
            Self.saveWindowPosition(origin)
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        window?.orderOut(nil)
        window = nil
        actions = []
        print("🪟 Action window dismissed")
    }

    // MARK: - Position Persistence

    private static let positionXKey = "cai_windowPositionX"
    private static let positionYKey = "cai_windowPositionY"

    private static func saveWindowPosition(_ origin: NSPoint) {
        UserDefaults.standard.set(Double(origin.x), forKey: positionXKey)
        UserDefaults.standard.set(Double(origin.y), forKey: positionYKey)
    }

    private static func loadWindowPosition() -> NSPoint? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: positionXKey) != nil else { return nil }
        let x = defaults.double(forKey: positionXKey)
        let y = defaults.double(forKey: positionYKey)
        // Validate the position is still on a connected screen
        let point = NSPoint(x: x, y: y)
        let testRect = NSRect(origin: point, size: NSSize(width: windowWidth, height: 100))
        for screen in NSScreen.screens {
            if screen.visibleFrame.intersects(testRect) {
                return point
            }
        }
        return nil  // Saved position is off-screen, reset to center
    }

    var isVisible: Bool {
        window?.isVisible ?? false
    }

    // MARK: - Keyboard Handling

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        // ESC — post a "back" notification; the SwiftUI view decides
        // whether to go back to action list or dismiss entirely.
        if event.keyCode == 53 {
            NotificationCenter.default.post(
                name: NSNotification.Name("CaiEscPressed"),
                object: nil
            )
            return true
        }

        // Arrow Up — wraps from first to last
        if event.keyCode == 126 {
            let current = selectionState.selectedIndex
            if current > 0 {
                selectionState.selectedIndex = current - 1
            } else {
                selectionState.selectedIndex = actions.count - 1
            }
            return true
        }

        // Arrow Down — wraps from last to first
        if event.keyCode == 125 {
            let current = selectionState.selectedIndex
            if current < actions.count - 1 {
                selectionState.selectedIndex = current + 1
            } else {
                selectionState.selectedIndex = 0
            }
            return true
        }

        // Return/Enter
        if event.keyCode == 36 {
            let index = selectionState.selectedIndex
            guard index < actions.count else { return true }
            executeOrDelegateAction(actions[index])
            return true
        }

        // Cmd+1 through Cmd+9
        if event.modifierFlags.contains(.command) {
            let keyNumber = keyCodeToNumber(event.keyCode)
            if let number = keyNumber, number >= 1 && number <= 9 {
                // Find the action with this shortcut number
                if let action = actions.first(where: { $0.shortcut == number }) {
                    // Update selection to that action
                    if let index = actions.firstIndex(where: { $0.id == action.id }) {
                        selectionState.selectedIndex = index
                    }
                    executeOrDelegateAction(action)
                    return true
                }
            }
        }

        return false
    }

    /// Execute an action — either handle system actions here, or let SwiftUI handle inline actions.
    private func executeOrDelegateAction(_ action: ActionItem) {
        switch action.type {
        case .llmAction, .jsonPrettyPrint, .copyText:
            // These are handled inline in SwiftUI via the onExecute/ActionListWindow
            // Post a notification so the SwiftUI view can pick it up
            NotificationCenter.default.post(
                name: NSNotification.Name("CaiExecuteAction"),
                object: nil,
                userInfo: ["actionId": action.id]
            )
        default:
            // System actions handled by WindowController
            executeSystemAction(action)
        }
    }

    private func keyCodeToNumber(_ keyCode: UInt16) -> Int? {
        switch keyCode {
        case 18: return 1  // 1
        case 19: return 2  // 2
        case 20: return 3  // 3
        case 21: return 4  // 4
        case 23: return 5  // 5
        case 22: return 6  // 6
        case 26: return 7  // 7
        case 28: return 8  // 8
        case 25: return 9  // 9
        default: return nil
        }
    }

    // MARK: - System Actions

    private func executeSystemAction(_ action: ActionItem) {
        switch action.type {
        case .openURL(let url):
            NSWorkspace.shared.open(url)
            hideWindow()

        case .openMaps(let address):
            let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
            if let url = URL(string: "maps://?q=\(encoded)") {
                NSWorkspace.shared.open(url)
            }
            hideWindow()

        case .search(let query):
            if let url = CaiSettings.shared.searchEngine.searchURL(for: query) {
                NSWorkspace.shared.open(url)
            }
            hideWindow()

        case .createCalendar(let title, let date, let location):
            createCalendarEvent(title: title, date: date, location: location)
            hideWindow()

        case .customPrompt:
            // For now, placeholder — will open a text input in a future phase
            print("📝 Custom prompt requested")
            hideWindow()

        case .translateCustom:
            print("🌐 Custom translation requested")
            hideWindow()

        default:
            hideWindow()
        }
    }

    private func createCalendarEvent(title: String, date: Date, location: String?) {
        // Open Calendar app with the date — simplified for now
        // Full EventKit integration would be a separate phase
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: date)
        if let url = URL(string: "calshow:\(date.timeIntervalSinceReferenceDate)") {
            NSWorkspace.shared.open(url)
        }
        print("📅 Creating calendar event: \(title) at \(dateString)")
    }
}

// MARK: - KeyEventHostingView

/// Custom NSHostingView subclass that intercepts key events before they
/// reach the SwiftUI responder chain. This allows us to handle arrow keys,
/// ESC, and Cmd+number shortcuts at the NSView level.
class KeyEventHostingView<Content: View>: NSHostingView<Content> {
    var onKeyDown: ((NSEvent) -> Bool)?

    convenience init(rootView: Content, onKeyDown: @escaping (NSEvent) -> Bool) {
        self.init(rootView: rootView)
        self.onKeyDown = onKeyDown
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if let handler = onKeyDown, handler(event) {
            return  // Event was handled
        }
        super.keyDown(with: event)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Ensure we become first responder to capture key events
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeFirstResponder(self)
        }
    }
}
