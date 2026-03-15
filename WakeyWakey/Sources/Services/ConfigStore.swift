import Foundation

/// Manages saving, loading, and deleting AeroSpace layout configurations.
final class ConfigStore {
    private let directory: URL

    init(directory: URL) {
        self.directory = directory
    }

    /// Convenience initializer using a path string.
    convenience init(path: String) {
        self.init(directory: URL(fileURLWithPath: path))
    }

    /// Ensure the config directory exists.
    func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Save a config to disk as JSON.
    func save(_ config: SavedConfig) throws {
        try ensureDirectory()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        let fileURL = directory.appendingPathComponent("\(config.name).json")
        try data.write(to: fileURL, options: .atomic)
    }

    /// Save a shell script to disk.
    func saveScript(_ script: String, name: String) throws {
        try ensureDirectory()
        let fileURL = directory.appendingPathComponent("\(name).sh")
        try script.write(to: fileURL, atomically: true, encoding: .utf8)

        // Make executable
        var attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let currentPermissions = (attributes[.posixPermissions] as? Int) ?? 0o644
        try FileManager.default.setAttributes(
            [.posixPermissions: currentPermissions | 0o111],
            ofItemAtPath: fileURL.path
        )
    }

    /// Load a config from disk by name.
    func load(name: String) throws -> SavedConfig {
        let fileURL = directory.appendingPathComponent("\(name).json")
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SavedConfig.self, from: data)
    }

    /// List all saved configs.
    func listConfigs() throws -> [SavedConfig] {
        try ensureDirectory()
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return files.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let config = try? decoder.decode(SavedConfig.self, from: data) else {
                return nil
            }
            return config
        }
    }

    /// Delete a saved config by name.
    func delete(name: String) throws {
        let jsonURL = directory.appendingPathComponent("\(name).json")
        let shURL = directory.appendingPathComponent("\(name).sh")

        if FileManager.default.fileExists(atPath: jsonURL.path) {
            try FileManager.default.removeItem(at: jsonURL)
        }
        if FileManager.default.fileExists(atPath: shURL.path) {
            try FileManager.default.removeItem(at: shURL)
        }
    }
}
