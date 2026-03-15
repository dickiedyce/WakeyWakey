import SwiftUI

/// The Preferences window with toolbar-style tabs.
struct PreferencesView: View {
    enum Tab: String, CaseIterable {
        case general = "General"
        case automations = "Automations"
        case privacy = "Privacy"

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .automations: return "arrow.triangle.2.circlepath"
            case .privacy: return "lock.shield"
            }
        }
    }

    @ObservedObject var settings: AppSettings
    @State private var selectedTab: Tab = .general

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar-style tab header
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Divider()

            // Tab content
            Group {
                switch selectedTab {
                case .general:
                    GeneralTab(settings: settings)
                case .automations:
                    AutomationsTab(settings: settings)
                case .privacy:
                    PrivacyTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .frame(width: 500, height: 400)
    }

    @ViewBuilder
    private func tabButton(_ tab: Tab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.title2)
                Text(tab.rawValue)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General Tab

struct GeneralTab: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("Config directory:", text: $settings.configDirectory)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse...") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.canCreateDirectories = true
                        if panel.runModal() == .OK, let url = panel.url {
                            settings.configDirectory = url.path
                        }
                    }
                }

                Toggle("Run saved layout on startup", isOn: $settings.runOnStartup)
            }
        }
    }
}

// MARK: - Automations Tab

struct AutomationsTab: View {
    @ObservedObject var settings: AppSettings
    @State private var newExcludedApp = ""

    var body: some View {
        Form {
            Section("Capture Delay") {
                HStack {
                    Text("Delay between apps:")
                    TextField("", value: $settings.captureDelay, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("seconds")
                }
            }

            Section("Excluded Apps") {
                Text("These apps will be skipped when restoring layouts.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    TextField("App name", text: $newExcludedApp)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        let name = newExcludedApp.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty, !settings.excludedApps.contains(name) else { return }
                        settings.excludedApps.append(name)
                        newExcludedApp = ""
                    }
                    .disabled(newExcludedApp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                List {
                    ForEach(settings.excludedApps, id: \.self) { app in
                        HStack {
                            Text(app)
                            Spacer()
                            Button(role: .destructive) {
                                settings.excludedApps.removeAll { $0 == app }
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .frame(height: 120)
            }
        }
    }
}

// MARK: - Privacy Tab

struct PrivacyTab: View {
    @State private var accessibilityGranted = AXIsProcessTrusted()

    var body: some View {
        Form {
            Section("Permissions") {
                HStack {
                    Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(accessibilityGranted ? .green : .red)
                    Text("Accessibility")
                    Spacer()
                    if !accessibilityGranted {
                        Button("Request Access") {
                            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
                            _ = AXIsProcessTrustedWithOptions(options)
                            // Re-check after a moment
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                accessibilityGranted = AXIsProcessTrusted()
                            }
                        }
                    }
                }

                Button("Open Accessibility Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
                .font(.caption)
            }

            Section("Data Handling") {
                Text("WakeyWakey runs entirely on your Mac. Layout data is saved locally in the config directory you specify. No data is sent to any server.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
