import Foundation
import SwiftUI

/// View model for the menu bar, managing capture/restore state.
@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published var statusText = "Idle"
    @Published var isCapturing = false
    @Published var savedConfigs: [SavedConfig] = []
    @Published var lastError: String?

    let settings: AppSettings
    private let aeroSpace: AeroSpaceService
    private var configStore: ConfigStore

    var isIdle: Bool { !isCapturing }

    init(settings: AppSettings, aeroSpace: AeroSpaceService = AeroSpaceService(), configStore: ConfigStore? = nil) {
        self.settings = settings
        self.aeroSpace = aeroSpace
        self.configStore = configStore ?? ConfigStore(path: settings.configDirectory)
    }

    func refreshConfigs() {
        configStore = ConfigStore(path: settings.configDirectory)
        do {
            savedConfigs = try configStore.listConfigs()
        } catch {
            savedConfigs = []
        }
    }

    func captureAndSave(name: String) {
        guard !isCapturing else { return }
        isCapturing = true
        statusText = "Capturing..."
        lastError = nil

        Task {
            do {
                let snapshot = try aeroSpace.captureSnapshot()
                let config = SavedConfig(name: name, snapshot: snapshot)
                try configStore.save(config)

                let script = aeroSpace.generateScript(from: snapshot, excludedApps: settings.excludedApps)
                try configStore.saveScript(script, name: name)

                statusText = "Saved: \(name)"
                refreshConfigs()
            } catch {
                statusText = "Error"
                lastError = error.localizedDescription
            }
            isCapturing = false
        }
    }

    func restoreConfig(name: String) {
        guard !isCapturing else { return }
        isCapturing = true
        statusText = "Restoring..."
        lastError = nil

        Task {
            do {
                let config = try configStore.load(name: name)
                try aeroSpace.restore(config.snapshot, excludedApps: settings.excludedApps)
                statusText = "Restored: \(name)"
            } catch {
                statusText = "Error"
                lastError = error.localizedDescription
            }
            isCapturing = false
        }
    }

    func scriptURL(for name: String) -> URL {
        URL(fileURLWithPath: settings.configDirectory).appendingPathComponent("\(name).sh")
    }

    func revealScript(name: String) {
        let url = scriptURL(for: name)
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    func openConfigFolder() {
        let url = URL(fileURLWithPath: settings.configDirectory)
        NSWorkspace.shared.open(url)
    }

    func deleteConfig(name: String) {
        do {
            try configStore.delete(name: name)
            refreshConfigs()
            statusText = "Deleted: \(name)"
        } catch {
            lastError = error.localizedDescription
        }
    }
}
