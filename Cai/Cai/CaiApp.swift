import SwiftUI

@main
struct CaiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty scene - the app runs entirely from the menu bar
        Settings {
            EmptyView()
        }
    }
}
