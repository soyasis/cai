<p align="center">
  <img src="assets/cai-logo.png" width="128" height="128" alt="Cai logo">
</p>

<h1 align="center">Cai</h1>

<h3 align="center">Select any text. Get smart actions.</h3>

<p align="center">
  A privacy-first clipboard assistant powered by local AI.<br>
  Your data never leaves your machine.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0%2B-blue" alt="macOS 13.0+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
</p>

<p align="center">
  <a href="https://getcai.app">getcai.app</a>
</p>

---

![Cai Demo](assets/cai-demo.gif)

Cai is a native macOS menu bar app that detects what's on your clipboard and offers smart, context-aware actions. Copy a meeting invite and it creates a calendar event. Copy an address and it opens Maps. Copy any text and ask your local AI to summarize, translate, or do anything you want — all without leaving your keyboard.

No cloud. No telemetry. No accounts.

## How It Works

1. **Select text** anywhere on your Mac
2. Press **⌥C** (Option+C)
3. Cai detects the content type and shows relevant actions
4. Pick an action with arrow keys or **⌘1–9**
5. Result is auto-copied to your clipboard — just **⌘V** to paste

**Examples:**
- Select `"serendipity"` → Define, Explain, Translate, Search
- Select `"Let's meet Tuesday at 3pm at Starbucks"` → Create calendar event, Open in Maps
- Select `"123 Main St, NYC 10001"` → Open in Maps
- Select `https://github.com/...` → Open in Browser
- Select `{"name": "John"}` → Pretty Print JSON

## Features

- **Smart detection** of 7 content types with context-aware actions
- **Local AI** integration — works with LM Studio, Ollama, or any OpenAI-compatible server
- **Custom AI action** (⌘1) — set your own prompt to do anything: improve writing, create email replies, translate, count words
- **Clipboard history** — access last 9 items with ⌘0
- **Keyboard-first** — navigate and execute everything without touching the mouse
- **Privacy-first** — no internet required, no data leaves your machine

## Content Types & Actions

| Content Type | Detection | Actions |
|---|---|---|
| **URL** | `https://...`, `www.` | Open in Browser |
| **JSON** | Valid JSON object/array | Pretty Print |
| **Meeting** | Date/time references | Create Calendar Event, Open in Maps |
| **Address** | Street patterns, "at [Place Name]" | Open in Maps |
| **Word** | 1–2 words | Define, Explain, Translate, Search |
| **Short Text** | < 100 characters | Explain, Translate, Search |
| **Long Text** | 100+ characters | Summarize, Translate, Search |

All text types also get **Custom Action** (⌘1) for free-form AI prompts.

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| **⌥C** | Trigger Cai (global hotkey) |
| **↑ ↓** | Navigate actions |
| **↵** | Execute selected action |
| **⌘1–9** | Jump to action by number |
| **⌘0** | Open clipboard history |
| **⌘↵** | Submit custom prompt / Copy result |
| **Esc** | Back / Dismiss |

## Installation

### Download

1. Download `Cai.zip` from the [latest release](../../releases/latest)
2. Unzip and drag **Cai.app** to your Applications folder
3. **Right-click → Open** on first launch (required for unsigned apps)
4. Grant Accessibility permission when prompted
5. Configure your LLM server in Preferences (left-click menu bar icon)

### Build from Source

```bash
git clone https://github.com/soyasis/cai.git
cd cai/Cai
open Cai.xcodeproj
```

In Xcode:
1. Select the **Cai** scheme and **My Mac** as destination
2. **Product → Run** (⌘R)

> **Note:** The app requires **Accessibility permission** and runs **without App Sandbox** (required for global hotkey and CGEvent posting).

## LLM Setup

Cai works with any OpenAI-compatible local server. AI is optional — system actions (Open URL, Maps, Calendar, Search, Pretty Print JSON) work without it.

| Provider | Default URL | Setup |
|---|---|---|
| **LM Studio** | `http://127.0.0.1:1234/v1` | [Download](https://lmstudio.ai) → Load model → Start server |
| **Ollama** | `http://127.0.0.1:11434/v1` | [Install](https://ollama.ai) → `ollama pull llama3.2` |
| **Jan AI** | `http://127.0.0.1:1337/v1` | [Download](https://jan.ai) → Load model → Start server |
| **LocalAI** | `http://127.0.0.1:8080/v1` | [Setup guide](https://localai.io) |
| **Open WebUI** | `http://127.0.0.1:8080/v1` | [Install](https://openwebui.com) → Enable OpenAI API |
| **GPT4All** | `http://127.0.0.1:4891/v1` | [Download](https://gpt4all.io) → Enable API server |
| **Custom** | User-defined | Any OpenAI-compatible server |

**To configure:** Open Cai Preferences (left-click menu bar icon) → select your Model Provider.

## Configuration

Left-click the Cai menu bar icon (or click the logo in the action window footer) to access Preferences:

| Setting | Description | Default |
|---|---|---|
| **Translation Language** | Target language for translations | English |
| **Search URL** | Base URL for web searches | Brave Search |
| **Maps Provider** | Apple Maps or Google Maps | Apple Maps |
| **Model Provider** | LM Studio, Ollama, or Custom | LM Studio |
| **Custom Action Prompt** | Your own AI instruction for ⌘1 | — |
| **Launch at Login** | Start Cai automatically | On |

## Requirements

- **macOS 13.0** (Ventura) or later
- **Accessibility permission** (for global hotkey ⌥C)
- **Local LLM server** (optional — for AI-powered actions only)

## Tech Stack

- **SwiftUI** + **AppKit** (native macOS, no Electron)
- **CGEvent** for Cmd+C simulation (private event source to isolate modifier state)
- **AXUIElement** for text selection detection
- **NSPanel** subclass for floating window that captures keyboard events
- **Actor-based** LLMService for thread-safe async/await
- **ICS file generation** for calendar events (no EventKit permissions needed)
- **SMAppService** for Launch at Login
- [HotKey](https://github.com/soffes/HotKey) (SPM) for global keyboard shortcut

## License

[MIT](LICENSE)
