# Cai - macOS Smart Clipboard Actions

## What It Is
Native macOS menu bar app (SwiftUI) that detects clipboard content types and offers context-aware actions powered by local AI (LM Studio/Ollama). Privacy-first, no telemetry.

## Core Flow
1. **Option+C** anywhere → `HotKeyManager` fires
2. `ClipboardService` simulates **Cmd+C** via CGEvent (private event source to isolate modifier state)
3. `ContentDetector` analyzes clipboard → returns type + entities
4. `ActionGenerator` generates context-aware actions (always shows all actions regardless of LLM availability)
5. `WindowController` shows floating panel with fade animation → user picks action
6. Action executes (LLM call / system action) → result auto-copied with markdown rendering → user pastes with Cmd+V

## Project Structure
```
Cai/Cai/
├── CaiApp.swift              # @main entry, delegates to AppDelegate
├── AppDelegate.swift          # Menu bar (Cai logo), hotkey setup, permission flow, right-click menu, About window
├── ContentView.swift          # Placeholder (unused, menu bar app)
├── Info.plist                 # LSUIElement=true, accessibility descriptions
├── Cai.entitlements           # Empty (no sandbox - required for CGEvent)
├── Models/
│   ├── ActionItem.swift       # ActionItem, ActionType enum (with calendar description), LLMAction enum
│   └── CaiSettings.swift      # UserDefaults-backed: searchURL, translationLanguage, modelProvider (LM Studio/Ollama/Custom), mapsProvider (Apple/Google), launchAtLogin (default: true)
├── Services/
│   ├── HotKeyManager.swift    # Global Option+C via HotKey SPM (soffes/HotKey v0.2.0+)
│   ├── PermissionsManager.swift # AXIsProcessTrusted check + system prompt
│   ├── ClipboardService.swift  # CGEvent Cmd+C simulation + NSPasteboard read
│   ├── ContentDetector.swift   # 8-priority detection: URL > JSON > Address > Meeting > Venue > Word > Short > Long
│   ├── ClipboardHistory.swift  # Polls pasteboard 0.5s, last 9 unique entries, initialized at launch
│   ├── WindowController.swift  # CaiPanel (NSPanel subclass), keyboard routing, toast, position persistence, fade in/out animations
│   ├── LLMService.swift        # Actor, OpenAI-compatible /v1/chat/completions, 30s timeout, temp 0.3, improved error handling
│   ├── SystemActions.swift     # openURL, openInMaps (Apple/Google from settings), createCalendarEvent (ICS with location+description), searchWeb, copyToClipboard
│   └── ActionGenerator.swift   # Generates actions per content type, Custom Action always first for all types
└── Views/
    ├── CaiColors.swift         # Color theme (Background, Surface, Primary/indigo, Text, Selection, Divider)
    ├── VisualEffectBackground.swift # NSVisualEffectView (.hudWindow) wrapper
    ├── ActionRow.swift         # Icon + Title/Subtitle + Cmd+N badge + accessibility labels
    ├── ActionListWindow.swift  # Root view, routes between screens (actions/result/settings/history/customPrompt)
    ├── ResultView.swift        # Loading/Error/Success states, markdown rendering, auto-copy, settings hint on errors
    ├── SettingsView.swift      # Translation language, search URL, maps provider, model provider (dropdown), launch at login, version from Bundle
    ├── CaiLogo.swift           # SVG→SwiftUI Shape ("C" + "ai" ligature), used in menu bar + footer
    ├── ClipboardHistoryView.swift # Cmd+0 submenu, last 9 entries, accessibility labels
    ├── CustomPromptView.swift  # Two-phase: text input (Cmd+Enter submit) → LLM result
    ├── AboutView.swift         # About window: icon, name, version/build from Bundle, tagline, GitHub link
    └── ToastWindow.swift       # Pill notification ("Copied to Clipboard")
```

## Content Detection Priority
| Priority | Type | Detection Method | Confidence |
|----------|------|-----------------|------------|
| 1 | URL | Regex `https?://\|www\.` | 1.0 |
| 2 | JSON | Starts `{`/`[` + JSONSerialization | 1.0 |
| 3 | Address | International street regex + NSDataDetector | 0.8 |
| 4 | Meeting | NSDataDetector.date + preprocessing (14h→14:00) | 0.7-0.9 |
| 5 | Venue | Case-sensitive regex: `at/in` + uppercase place name | 0.6 |
| 6 | Word | ≤2 words, <30 chars | 1.0 |
| 7 | Short Text | <100 chars | 1.0 |
| 8 | Long Text | ≥100 chars | 1.0 |

**Filters**: Currency ($50), durations ("for 5 minutes"), pure numbers

## Actions Per Content Type
- **All types**: Custom Action (always first, regardless of LLM availability)
- **Word**: Define, Explain, Translate, Search
- **Short/Long Text**: Explain/Summarize, Translate, Search
- **Meeting**: Create Calendar Event (title: "Meeting", description: original text in quotes, includes location), Open in Maps (if location detected)
- **Address/Venue**: Open in Maps (Apple Maps or Google Maps per settings)
- **URL**: Open in Browser
- **JSON**: Pretty Print JSON

## Keyboard Shortcuts
| Key | Action |
|-----|--------|
| Option+C | Global trigger |
| ↑↓ | Navigate actions |
| Enter | Execute selected |
| Cmd+1-9 | Direct action shortcuts |
| Cmd+0 | Clipboard history |
| Cmd+Enter | Submit custom prompt / Copy result |
| ESC | Back / Dismiss |
| Cai logo click | Settings (in footer) |

## Menu Bar
- **Left-click**: Settings popover (340×440)
- **Right-click**: Menu (Open Cai → Preferences... → About Cai → Quit Cai)
- **Icon**: Cai logo rendered as template NSImage (adapts to light/dark)

## Settings (CaiSettings.swift)
- **Translation Language**: Picker from 15 common languages (default: English)
- **Search URL**: Custom base URL (default: Brave Search)
- **Maps Provider**: Apple Maps / Google Maps (default: Apple)
- **Model Provider**: LM Studio / Ollama / Custom (default: LM Studio)
- **Custom Model URL**: Only shown when provider is Custom
- **Launch at Login**: Toggle (default: true, uses SMAppService)

## Key Technical Decisions
- **No sandbox**: Required for CGEvent posting + global hotkey
- **CGEvent private source**: Prevents Option key leak from hotkey into simulated Cmd+C
- **CaiPanel (NSPanel subclass)**: Overrides `canBecomeKey` for keyboard events
- **PassThrough flag**: Lets TextEditor receive Enter/arrows during custom prompt input
- **ICS files for calendar**: No EventKit permissions needed, works with any calendar app
- **Notification-based keyboard routing**: WindowController posts, SwiftUI views subscribe
- **Actor-based LLMService**: Thread-safe async/await
- **Position persistence**: Saves window origin to UserDefaults, validates on-screen
- **Fade animations**: Window show (0.15s) / hide (0.12s) via NSAnimationContext
- **Markdown rendering**: ResultView uses AttributedString(markdown:) for rich text display
- **Actions always visible**: All actions shown regardless of LLM server status; errors handled at execution time

## Dependencies
- **HotKey** (SPM): soffes/HotKey v0.2.0+ — global keyboard shortcut
- **System**: AppKit, SwiftUI, Foundation, ApplicationServices, Carbon, ServiceManagement

## Tests
- `CaiTests/ContentDetectorTests.swift`: 60 tests covering all content types, edge cases, priority order, international addresses, meeting false positives, venue detection, currency/duration filters

## Project Status

### Completed (Phases 0-5)
- **Phase 0**: Global hotkey (Option+C) + accessibility permissions
- **Phase 1**: Clipboard read + Cmd+C simulation via CGEvent
- **Phase 2**: Content detection (7 types + venue) with 60 tests
- **Phase 3**: Floating action window + keyboard navigation
- **Phase 4**: Action generation, LLM integration, system actions (URL, Maps, Calendar ICS, Search)
- **Phase 5**: Polish & Preferences
  - Menu bar: Cai logo (template image, adapts to light/dark)
  - Settings: Maps provider (Apple/Google), Launch at Login (SMAppService, default on)
  - Right-click menu: Open Cai / Preferences / About / Quit
  - About window with version from Bundle
  - Improved LLM error messages (connection failed, timeout, invalid URL)
  - ResultView: Markdown rendering via AttributedString, settings hint on errors
  - Window: Fade in/out animations, dynamic height with min 3 rows
  - Accessibility labels on ActionRow, ClipboardHistoryView, ResultView, SettingsView
  - Removed: search URL help text, customActionPrompt setting

### Next Steps
- Distribution (GitHub Release ZIP, notarization)
- Onboarding flow for first-time users
- Additional LLM providers (API key-based services)

## Documentation
- `CAI_MACOS_IMPLEMENTATION_GUIDE.md` — 5-phase step-by-step build guide
- `CAI_MACOS_MLP_PROJECT_PLAN.md` — Architecture decisions + timeline
- `PHASE_4_ACTIONS_LLM.md` — Phase 4 specific guidance (action lists, ICS format, LLM prompts)
