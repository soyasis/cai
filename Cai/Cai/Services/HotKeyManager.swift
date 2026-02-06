import Foundation
import HotKey

class HotKeyManager {
    private var hotKey: HotKey?
    private var handler: (() -> Void)?

    func register(handler: @escaping () -> Void) {
        // Only register if we don't already have a hotkey
        guard hotKey == nil else {
            print("⚠️ HotKey already registered")
            return
        }

        // Check if accessibility permission is granted
        guard PermissionsManager.shared.hasAccessibilityPermission else {
            print("❌ Cannot register hotkey: Accessibility permission not granted")
            return
        }

        // Register Option+C (⌥C)
        hotKey = HotKey(key: .c, modifiers: [.option])
        self.handler = handler

        hotKey?.keyDownHandler = { [weak self] in
            print("⌨️ Hotkey triggered: Option+C")
            self?.handler?()
        }

        print("✅ Global hotkey registered: ⌥C (Option+C)")
    }

    func unregister() {
        hotKey = nil
        handler = nil
        print("🔕 Global hotkey unregistered")
    }

    func isRegistered() -> Bool {
        return hotKey != nil
    }
}
