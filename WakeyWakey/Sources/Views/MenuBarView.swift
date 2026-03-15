import SwiftUI

/// The main menu bar view displayed when clicking the menubar icon.
struct MenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @State private var newConfigName = ""
    @State private var showingSaveField = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("WakeyWakey")
                .font(.headline)
            Text(viewModel.statusText)
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            // Capture action
            Button("Capture Current Layout") {
                showingSaveField = true
            }
            .disabled(!viewModel.isIdle)

            if showingSaveField {
                HStack {
                    TextField("Config name", text: $newConfigName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 160)
                    Button("Save") {
                        let name = newConfigName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        viewModel.captureAndSave(name: name)
                        newConfigName = ""
                        showingSaveField = false
                    }
                    .disabled(newConfigName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.vertical, 2)
            }

            Divider()

            // Saved configs
            if viewModel.savedConfigs.isEmpty {
                Text("No saved configs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Restore Layout")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ForEach(viewModel.savedConfigs) { config in
                    HStack {
                        Button(config.name) {
                            viewModel.restoreConfig(name: config.name)
                        }
                        .disabled(!viewModel.isIdle)
                        Spacer()
                        Button {
                            viewModel.revealScript(name: config.name)
                        } label: {
                            Image(systemName: "doc.text")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .help("Show script in Finder")
                        Button(role: .destructive) {
                            viewModel.deleteConfig(name: config.name)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            if let error = viewModel.lastError {
                Divider()
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(2)
            }

            Divider()

            Button("Open Scripts Folder") {
                viewModel.openConfigFolder()
            }

            Divider()

            if #available(macOS 14.0, *) {
                SettingsLink {
                    Text("Preferences...")
                }
            } else {
                Button("Preferences...") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(8)
        .frame(width: 240)
        .onAppear {
            viewModel.refreshConfigs()
        }
    }
}
