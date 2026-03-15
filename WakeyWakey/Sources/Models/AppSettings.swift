import Foundation

/// Persistent app settings stored in UserDefaults.
final class AppSettings: ObservableObject {
    private let defaults: UserDefaults

    @Published var configDirectory: String {
        didSet { defaults.set(configDirectory, forKey: Keys.configDirectory) }
    }

    @Published var runOnStartup: Bool {
        didSet { defaults.set(runOnStartup, forKey: Keys.runOnStartup) }
    }

    @Published var excludedApps: [String] {
        didSet { defaults.set(excludedApps, forKey: Keys.excludedApps) }
    }

    @Published var captureDelay: Double {
        didSet { defaults.set(captureDelay, forKey: Keys.captureDelay) }
    }

    @Published var startupLayoutName: String? {
        didSet { defaults.set(startupLayoutName, forKey: Keys.startupLayoutName) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.configDirectory = defaults.string(forKey: Keys.configDirectory)
            ?? NSString("~/Documents/WakeyWakey").expandingTildeInPath
        self.runOnStartup = defaults.bool(forKey: Keys.runOnStartup)
        self.excludedApps = defaults.stringArray(forKey: Keys.excludedApps) ?? []
        self.captureDelay = defaults.double(forKey: Keys.captureDelay).nonZero ?? 1.5
        self.startupLayoutName = defaults.string(forKey: Keys.startupLayoutName)
    }

    func reset() {
        configDirectory = NSString("~/Documents/WakeyWakey").expandingTildeInPath
        runOnStartup = false
        excludedApps = []
        captureDelay = 1.5
        startupLayoutName = nil
    }

    private enum Keys {
        static let configDirectory = "configDirectory"
        static let runOnStartup = "runOnStartup"
        static let excludedApps = "excludedApps"
        static let captureDelay = "captureDelay"
        static let startupLayoutName = "startupLayoutName"
    }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
