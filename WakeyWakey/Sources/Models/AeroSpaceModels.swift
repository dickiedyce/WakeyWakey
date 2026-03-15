import Foundation

/// Represents a single window in an AeroSpace workspace.
struct WorkspaceWindow: Codable, Equatable, Identifiable {
    var id: String { "\(workspace)-\(appName)-\(windowTitle)" }
    let workspace: String
    let appName: String
    let windowTitle: String
}

/// Represents a complete AeroSpace layout snapshot.
struct AeroSpaceSnapshot: Codable, Equatable {
    let timestamp: Date
    let windows: [WorkspaceWindow]

    /// Unique workspaces that have windows in this snapshot.
    var workspaces: [String] {
        Array(Set(windows.map(\.workspace))).sorted()
    }

    /// Windows grouped by workspace.
    var windowsByWorkspace: [String: [WorkspaceWindow]] {
        Dictionary(grouping: windows, by: \.workspace)
    }
}

/// A named saved configuration that can be restored.
struct SavedConfig: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let snapshot: AeroSpaceSnapshot
    let createdAt: Date

    init(id: UUID = UUID(), name: String, snapshot: AeroSpaceSnapshot, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.snapshot = snapshot
        self.createdAt = createdAt
    }
}
