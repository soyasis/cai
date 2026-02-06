# Cai - macOS Menu Bar App

A macOS menu bar application built with SwiftUI.

## Project Structure

```
Cai/
├── Cai.xcodeproj/          # Xcode project file
└── Cai/                    # Source code directory
    ├── CaiApp.swift        # Main app entry point
    ├── AppDelegate.swift   # Menu bar management
    ├── ContentView.swift   # Main UI view
    ├── Info.plist          # App configuration
    ├── Cai.entitlements    # App sandbox entitlements
    └── Assets.xcassets/    # Asset catalog
```

## Features

- Menu bar only app (no Dock icon)
- Clipboard icon in menu bar
- Right-click menu with "Open Cai" and "Quit" options
- Left-click shows popover window
- Placeholder UI showing "Cai is running"

## Requirements

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

## Dependencies

The project uses Swift Package Manager (SPM) for dependencies:

- **[HotKey](https://github.com/soffes/HotKey)** (v0.2.0+) - Global keyboard shortcut handling for Phase 1 implementation

Dependencies will be automatically resolved when you open the project in Xcode.

## Setup

1. Open `Cai.xcodeproj` in Xcode
2. Xcode will automatically resolve and download SPM dependencies (HotKey package)
3. Update the Bundle Identifier in project settings if needed (currently: `com.yourname.cai`)
4. Select your development team in Signing & Capabilities
5. Build and run (⌘R)

## Configuration

The app is configured as a menu bar app via:
- `LSUIElement = true` in [Info.plist](Cai/Info.plist) (hides Dock icon)
- Menu bar icon uses SF Symbol "clipboard"
- Window is hidden by default and shown via popover

## Development

To modify the app:
- [CaiApp.swift](Cai/CaiApp.swift) - Main app lifecycle
- [AppDelegate.swift](Cai/AppDelegate.swift) - Menu bar setup and interactions
- [ContentView.swift](Cai/ContentView.swift) - Main UI content

## Build Settings

- Deployment Target: macOS 13.0
- Bundle ID: com.yourname.cai
- App Sandbox: Enabled
- Hardened Runtime: Enabled
