import AppKit
import Carbon

class ClipboardService {
    static let shared = ClipboardService()

    private init() {}

    /// Simulates Cmd+C by posting CGEvents directly to the frontmost application.
    ///
    /// This is the same technique used by Raycast, Rectangle, and other macOS utilities.
    /// Requirements:
    ///   - Accessibility permission granted (AXIsProcessTrusted)
    ///   - App Sandbox DISABLED
    ///   - Hardened Runtime enabled (fine — CGEvent posting is allowed)
    ///
    /// CRITICAL DETAIL: We use a CGEventSource with `.combinedSessionState` and
    /// explicitly set the flags to ONLY `.maskCommand`. This is essential because
    /// our hotkey is Option+C — when the handler fires, the Option key is still
    /// physically held down. Without an explicit event source and flag override,
    /// the OS would merge the physical Option key state into our synthetic event,
    /// sending Cmd+Option+C to the target app instead of Cmd+C.
    func copySelectedText(completion: @escaping () -> Void) {
        let pasteboard = NSPasteboard.general
        let changeCountBefore = pasteboard.changeCount

        // Create a private event source so our synthetic keystrokes have their
        // own modifier state, independent of physical keys currently held down.
        guard let eventSource = CGEventSource(stateID: .privateState) else {
            print("❌ Failed to create CGEventSource")
            completion()
            return
        }

        // The virtual keycode for 'C' is 8 (from Carbon's Events.h / kVK_ANSI_C)
        let keyCodeC: CGKeyCode = 8  // kVK_ANSI_C

        // Create key-down event for Cmd+C using our private event source
        guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCodeC, keyDown: true) else {
            print("❌ Failed to create CGEvent key-down")
            completion()
            return
        }

        // Create key-up event for Cmd+C using our private event source
        guard let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCodeC, keyDown: false) else {
            print("❌ Failed to create CGEvent key-up")
            completion()
            return
        }

        // Set flags to ONLY Command — this overrides any physical modifier state.
        // Without this, the Option key (still physically held from our hotkey)
        // would leak into the event, turning Cmd+C into Cmd+Option+C.
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        // Post at the CGAnnotatedSession tap level. This inserts the event into
        // the current login session's event stream and routes it to the focused app.
        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)

        print("⌨️ Posted Cmd+C via CGEvent (private source) to frontmost app")

        // Wait for the target app to process the copy command and update the
        // pasteboard. 200ms provides a reliable window for most apps.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if pasteboard.changeCount > changeCountBefore {
                print("✂️ Text copied to clipboard (pasteboard changed)")
            } else {
                print("⚠️ Pasteboard unchanged — no text was selected, or copy was too slow")
            }
            completion()
        }
    }

    /// Reads text content from the system clipboard
    /// - Returns: Trimmed text content, or nil if clipboard is empty or doesn't contain text
    func readClipboard() -> String? {
        let pasteboard = NSPasteboard.general

        guard let content = pasteboard.string(forType: .string) else {
            print("📋 Clipboard is empty or doesn't contain text")
            return nil
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            print("📋 Clipboard contains only whitespace")
            return nil
        }

        print("📋 Clipboard read: \(trimmed.prefix(50))\(trimmed.count > 50 ? "..." : "")")
        return trimmed
    }
}
