import Cocoa
import ApplicationServices

class PermissionsManager: ObservableObject {
    @Published var hasAccessibilityPermission: Bool = false

    static let shared = PermissionsManager()

    private init() {
        checkAccessibilityPermission()
    }

    func checkAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options)

        if hasAccessibilityPermission {
            print("✅ Accessibility permission granted")
        } else {
            print("⚠️ Accessibility permission not granted")
        }
    }

    func requestAccessibilityPermission() {
        // This will trigger the system prompt and add Cai to System Settings
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options)

        // Make an actual accessibility API call to ensure the app appears in System Settings
        // This attempts to get the system-wide element, which requires accessibility permission
        let systemWideElement = AXUIElementCreateSystemWide()
        var value: CFTypeRef?
        _ = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &value)
        // We don't need the result - just making the call is enough to register with the system

        if hasAccessibilityPermission {
            print("✅ Accessibility permission granted after request")
        } else {
            print("⚠️ Accessibility permission prompt shown - waiting for user")
        }
    }

    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
        Cai needs accessibility permission for the ⌥C hotkey to work.

        Enable Cai in System Settings → Accessibility.
        """
        alert.alertStyle = .informational
        if let logo = NSImage(named: "CaiLogo") {
            alert.icon = logo
        }
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // Open System Settings
            openAccessibilityPreferences()
        }
    }

    func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func recheckPermissionWhenAppBecomesActive() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let hadPermission = self.hasAccessibilityPermission
            self.checkAccessibilityPermission()

            // If permission status changed, post notification
            if hadPermission != self.hasAccessibilityPermission {
                NotificationCenter.default.post(
                    name: NSNotification.Name("AccessibilityPermissionChanged"),
                    object: nil
                )
            }
        }
    }
}
