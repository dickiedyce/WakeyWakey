import Foundation

/// Errors from AeroSpace operations.
enum AeroSpaceError: LocalizedError {
    case cliNotFound
    case captureFailure(String)
    case restoreFailure(String)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return "AeroSpace CLI not found. Install AeroSpace and ensure 'aerospace' is in PATH."
        case .captureFailure(let detail):
            return "Failed to capture layout: \(detail)"
        case .restoreFailure(let detail):
            return "Failed to restore layout: \(detail)"
        case .parseError(let detail):
            return "Failed to parse AeroSpace output: \(detail)"
        }
    }
}

/// Protocol for running shell commands, enabling test injection.
protocol CommandRunner {
    func run(_ command: String, arguments: [String]) throws -> String
}

/// Runs commands via Process.
struct SystemCommandRunner: CommandRunner {
    func run(_ command: String, arguments: [String]) throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw AeroSpaceError.captureFailure(output)
        }

        return output
    }
}

/// Service for interacting with the AeroSpace tiling window manager.
final class AeroSpaceService {
    private let runner: CommandRunner
    private let aerospacePath: String

    init(runner: CommandRunner = SystemCommandRunner(), aerospacePath: String = "/opt/homebrew/bin/aerospace") {
        self.runner = runner
        self.aerospacePath = aerospacePath
    }

    /// Capture the current AeroSpace layout as a snapshot.
    func captureSnapshot() throws -> AeroSpaceSnapshot {
        let output = try runner.run(aerospacePath, arguments: [
            "list-windows", "--all",
            "--format", "%{workspace}|%{app-name}|%{window-title}"
        ])

        let windows = try parseWindowList(output)
        return AeroSpaceSnapshot(timestamp: Date(), windows: windows)
    }

    /// Restore a snapshot by moving apps to their recorded workspaces.
    func restore(_ snapshot: AeroSpaceSnapshot, excludedApps: [String] = []) throws {
        let excluded = Set(excludedApps.map { $0.lowercased() })

        for window in snapshot.windows {
            guard !excluded.contains(window.appName.lowercased()) else { continue }

            // Focus the window's app, then move to workspace
            do {
                _ = try runner.run("/usr/bin/open", arguments: ["-a", window.appName])
            } catch {
                // App may not be installed; skip silently
                continue
            }

            // Small delay for app to come to foreground
            Thread.sleep(forTimeInterval: 0.5)

            do {
                _ = try runner.run(aerospacePath, arguments: [
                    "move-node-to-workspace", window.workspace
                ])
            } catch {
                // Best effort; continue with remaining windows
            }
        }
    }

    /// Generate a shell script that recreates the given snapshot.
    func generateScript(from snapshot: AeroSpaceSnapshot, excludedApps: [String] = []) -> String {
        let excluded = Set(excludedApps.map { $0.lowercased() })
        var lines: [String] = [
            "#!/bin/bash",
            "# WakeyWakey layout restore script",
            "# Generated: \(ISO8601DateFormatter().string(from: snapshot.timestamp))",
            "",
            "open_and_assign() {",
            "    local app=\"$1\"",
            "    local workspace=\"$2\"",
            "    open -a \"$app\"",
            "    sleep 1.5",
            "    aerospace move-node-to-workspace \"$workspace\"",
            "}",
        ]

        // Group by workspace, deduplicate apps within each
        let sortedWorkspaces = snapshot.workspaces
        for workspace in sortedWorkspaces {
            let windows = snapshot.windowsByWorkspace[workspace] ?? []
            var seen = Set<String>()
            var apps: [String] = []
            for window in windows {
                guard !excluded.contains(window.appName.lowercased()) else { continue }
                if seen.insert(window.appName).inserted {
                    apps.append(window.appName)
                }
            }
            guard !apps.isEmpty else { continue }

            lines.append("")
            lines.append("# Workspace \(workspace)")
            lines.append("aerospace summon-workspace \(workspace)")
            for app in apps {
                lines.append("open_and_assign \"\(app)\" \(workspace)")
            }
        }

        lines.append("")
        lines.append("echo \"Layout restored.\"")
        return lines.joined(separator: "\n")
    }

    // MARK: - Parsing

    func parseWindowList(_ output: String) throws -> [WorkspaceWindow] {
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return try lines.map { line in
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 3 else {
                throw AeroSpaceError.parseError("Unexpected format: \(line)")
            }
            return WorkspaceWindow(
                workspace: parts[0].trimmingCharacters(in: .whitespaces),
                appName: parts[1].trimmingCharacters(in: .whitespaces),
                windowTitle: parts[2...].joined(separator: "|").trimmingCharacters(in: .whitespaces)
            )
        }
    }
}
