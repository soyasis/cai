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
    /// When true, text-input keys (Return, arrows) pass through to the focused text field
    /// instead of being consumed by the keyboard handler. Set by views with text input.
    static var passThrough = false
    private var window: NSWindow?
    private var toastWindow: NSWindow?
    private var actions: [ActionItem] = []
    private var selectionState = SelectionState()
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var keyMonitor: Any?
    private var toastObserver: NSObjectProtocol?

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

        // Monitor for key events — fires BEFORE the first responder chain,
        // so ESC works even when a TextField/TextEditor is focused.
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.window != nil else { return event }
            if self.handleKeyEvent(event) {
                return nil  // Consumed — suppress the event
            }
            return event  // Pass through to responder chain
        }

        // Listen for toast notifications from SwiftUI views
        toastObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CaiShowToast"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let message = notification.userInfo?["message"] as? String ?? "Copied to Clipboard"
            self?.showToast(message: message)
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
        if let keyMonitor = keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        if let toastObserver = toastObserver {
            NotificationCenter.default.removeObserver(toastObserver)
            self.toastObserver = nil
        }
        Self.passThrough = false
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

        // Cmd+Return — always captured (submit in custom prompt, or copy result)
        if event.keyCode == 36 && event.modifierFlags.contains(.command) {
            NotificationCenter.default.post(
                name: NSNotification.Name("CaiCmdEnterPressed"),
                object: nil
            )
            return true
        }

        // When a text editor is active, let plain Return and arrows pass through
        // (Return adds newlines, arrows move cursor)
        if Self.passThrough {
            if event.keyCode == 126 || event.keyCode == 125 || event.keyCode == 36 {
                return false
            }
        }

        // Arrow Up
        if event.keyCode == 126 {
            NotificationCenter.default.post(
                name: NSNotification.Name("CaiArrowUp"),
                object: nil
            )
            return true
        }

        // Arrow Down
        if event.keyCode == 125 {
            NotificationCenter.default.post(
                name: NSNotification.Name("CaiArrowDown"),
                object: nil
            )
            return true
        }

        // Return/Enter
        if event.keyCode == 36 {
            NotificationCenter.default.post(
                name: NSNotification.Name("CaiEnterPressed"),
                object: nil
            )
            return true
        }

        // Cmd+0 — open clipboard history
        if event.modifierFlags.contains(.command) && event.keyCode == 29 {  // 29 = '0'
            NotificationCenter.default.post(
                name: NSNotification.Name("CaiShowClipboardHistory"),
                object: nil
            )
            return true
        }

        // Cmd+1 through Cmd+9
        if event.modifierFlags.contains(.command) {
            let keyNumber = keyCodeToNumber(event.keyCode)
            if let number = keyNumber, number >= 1 && number <= 9 {
                // Post number for both action shortcuts and history shortcuts
                // The active view decides what to do
                NotificationCenter.default.post(
                    name: NSNotification.Name("CaiCmdNumber"),
                    object: nil,
                    userInfo: ["number": number]
                )
                return true
            }
        }

        return false
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

    // MARK: - Toast Notification

    /// Shows a pill-shaped toast notification that auto-dismisses after 1.5 seconds.
    func showToast(message: String) {
        hideToast()

        let toastView = ToastView(message: message)
        let hostingView = NSHostingView(rootView: toastView)
        hostingView.wantsLayer = true

        // Size the hosting view to fit content
        let fittingSize = hostingView.fittingSize
        let width = max(fittingSize.width, 200)
        let height = max(fittingSize.height, 36)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.isMovableByWindowBackground = false
        panel.contentView = hostingView
        panel.ignoresMouseEvents = true

        // Position at top-center of screen
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - width / 2
            let y = screenFrame.maxY - 80
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.toastWindow = panel
        panel.alphaValue = 0
        panel.orderFront(nil)

        // Fade in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            panel.animator().alphaValue = 1
        }

        // Auto-dismiss after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.hideToast()
        }
    }

    private func hideToast() {
        guard let toast = toastWindow else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            toast.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.toastWindow?.orderOut(nil)
            self?.toastWindow = nil
        })
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
