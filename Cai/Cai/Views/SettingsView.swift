import SwiftUI

/// Settings panel — used both inline in the action window (via Cai logo)
/// and in the menu bar popover. Adapts to parent's size constraints.
struct SettingsView: View {
    @ObservedObject var settings = CaiSettings.shared

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.caiPrimary)
                Text("Settings")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.caiTextPrimary)
                Spacer()
                Text("v\(appVersion)")
                    .font(.system(size: 11))
                    .foregroundColor(.caiTextSecondary.opacity(0.4))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Translation Language
                    settingsSection(title: "Translation Language", icon: "globe") {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("", selection: $settings.translationLanguage) {
                                ForEach(CaiSettings.commonLanguages, id: \.self) { lang in
                                    Text(lang).tag(lang)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .accessibilityLabel("Translation language")

                            Text("Default language for the Translate action")
                                .font(.system(size: 11))
                                .foregroundColor(.caiTextSecondary)
                        }
                    }

                    // Search URL
                    settingsSection(title: "Search URL", icon: "magnifyingglass") {
                        TextField("https://search.brave.com/search?q=", text: $settings.searchURL)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                            .accessibilityLabel("Search engine base URL")
                    }

                    // Maps Provider
                    settingsSection(title: "Maps", icon: "map") {
                        Picker("", selection: $settings.mapsProvider) {
                            ForEach(CaiSettings.MapsProvider.allCases) { provider in
                                Text(provider.rawValue).tag(provider)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .accessibilityLabel("Maps provider")
                    }

                    // Model Provider
                    settingsSection(title: "Model Provider", icon: "cpu") {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("", selection: $settings.modelProvider) {
                                ForEach(CaiSettings.ModelProvider.allCases) { provider in
                                    Text(provider.rawValue).tag(provider)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .accessibilityLabel("LLM model provider")

                            if settings.modelProvider == .custom {
                                TextField("http://127.0.0.1:8080", text: $settings.customModelURL)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12, design: .monospaced))
                                    .accessibilityLabel("Custom model URL")
                            }

                            Text("OpenAI-compatible API endpoint (\(settings.modelURL))")
                                .font(.system(size: 11))
                                .foregroundColor(.caiTextSecondary)
                        }
                    }

                    // General
                    settingsSection(title: "General", icon: "gearshape") {
                        Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                            .font(.system(size: 12))
                            .foregroundColor(.caiTextPrimary)
                            .accessibilityLabel("Launch Cai at login")
                    }

                    // Hotkey reminder
                    HStack(spacing: 6) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.caiTextSecondary.opacity(0.5))
                        Text("Press \u{2325}C to trigger Cai anywhere")
                            .font(.system(size: 11))
                            .foregroundColor(.caiTextSecondary.opacity(0.5))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }

    // MARK: - Settings Section

    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.caiPrimary)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.caiTextPrimary)
            }
            content()
        }
    }
}
