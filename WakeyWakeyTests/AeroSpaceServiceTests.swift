import XCTest
@testable import WakeyWakey

/// Mock command runner for testing AeroSpaceService without running real commands.
final class MockCommandRunner: CommandRunner {
    var stubbedResults: [String: String] = [:]
    var stubbedErrors: [String: Error] = [:]
    var executedCommands: [(command: String, arguments: [String])] = []

    func run(_ command: String, arguments: [String]) throws -> String {
        executedCommands.append((command, arguments))
        let key = arguments.first ?? command
        if let error = stubbedErrors[key] {
            throw error
        }
        return stubbedResults[key] ?? ""
    }
}

final class AeroSpaceServiceTests: XCTestCase {
    private var runner: MockCommandRunner!
    private var service: AeroSpaceService!

    override func setUp() {
        super.setUp()
        runner = MockCommandRunner()
        service = AeroSpaceService(runner: runner)
    }

    // MARK: - parseWindowList

    func testParseWindowListValidOutput() throws {
        let output = """
        1|Google Chrome|GitHub - Home
        2|Code|main.swift — MyProject
        3|Terminal|~
        """
        let windows = try service.parseWindowList(output)
        XCTAssertEqual(windows.count, 3)

        XCTAssertEqual(windows[0].workspace, "1")
        XCTAssertEqual(windows[0].appName, "Google Chrome")
        XCTAssertEqual(windows[0].windowTitle, "GitHub - Home")

        XCTAssertEqual(windows[1].workspace, "2")
        XCTAssertEqual(windows[1].appName, "Code")
        XCTAssertEqual(windows[1].windowTitle, "main.swift — MyProject")

        XCTAssertEqual(windows[2].workspace, "3")
        XCTAssertEqual(windows[2].appName, "Terminal")
        XCTAssertEqual(windows[2].windowTitle, "~")
    }

    func testParseWindowListEmptyOutput() throws {
        let windows = try service.parseWindowList("")
        XCTAssertEqual(windows.count, 0)
    }

    func testParseWindowListWithPipeInTitle() throws {
        let output = "1|TextBuddy|file.txt | grep foo"
        let windows = try service.parseWindowList(output)
        XCTAssertEqual(windows.count, 1)
        XCTAssertEqual(windows[0].windowTitle, "file.txt | grep foo")
    }

    func testParseWindowListInvalidFormat() {
        let output = "bad data without pipes"
        XCTAssertThrowsError(try service.parseWindowList(output))
    }

    // MARK: - captureSnapshot

    func testCaptureSnapshotCallsCLI() throws {
        runner.stubbedResults["list-windows"] = "1|Chrome|Home\n2|Code|main.swift"
        let snapshot = try service.captureSnapshot()
        XCTAssertEqual(snapshot.windows.count, 2)
        XCTAssertEqual(snapshot.workspaces.sorted(), ["1", "2"])

        XCTAssertEqual(runner.executedCommands.count, 1)
        XCTAssertTrue(runner.executedCommands[0].arguments.contains("list-windows"))
    }

    // MARK: - generateScript

    func testGenerateScriptContainsApps() {
        let snapshot = AeroSpaceSnapshot(timestamp: Date(), windows: [
            WorkspaceWindow(workspace: "1", appName: "Chrome", windowTitle: "Home"),
            WorkspaceWindow(workspace: "2", appName: "Code", windowTitle: "main.swift"),
        ])

        let script = service.generateScript(from: snapshot)

        XCTAssertTrue(script.contains("#!/bin/bash"))
        XCTAssertTrue(script.contains("open_and_assign \"Chrome\" 1"))
        XCTAssertTrue(script.contains("open_and_assign \"Code\" 2"))
    }

    func testGenerateScriptExcludesApps() {
        let snapshot = AeroSpaceSnapshot(timestamp: Date(), windows: [
            WorkspaceWindow(workspace: "1", appName: "Chrome", windowTitle: "Home"),
            WorkspaceWindow(workspace: "2", appName: "Finder", windowTitle: "Desktop"),
        ])

        let script = service.generateScript(from: snapshot, excludedApps: ["Finder"])

        XCTAssertTrue(script.contains("open_and_assign \"Chrome\" 1"))
        XCTAssertFalse(script.contains("Finder"))
    }

    func testGenerateScriptDeduplicatesAppsPerWorkspace() {
        let snapshot = AeroSpaceSnapshot(timestamp: Date(), windows: [
            WorkspaceWindow(workspace: "1", appName: "Chrome", windowTitle: "Tab 1"),
            WorkspaceWindow(workspace: "1", appName: "Chrome", windowTitle: "Tab 2"),
        ])

        let script = service.generateScript(from: snapshot)
        let occurrences = script.components(separatedBy: "open_and_assign \"Chrome\" 1").count - 1
        XCTAssertEqual(occurrences, 1, "Should only appear once per workspace")
    }

    // MARK: - AeroSpaceSnapshot

    func testSnapshotWindowsByWorkspace() {
        let snapshot = AeroSpaceSnapshot(timestamp: Date(), windows: [
            WorkspaceWindow(workspace: "1", appName: "A", windowTitle: ""),
            WorkspaceWindow(workspace: "1", appName: "B", windowTitle: ""),
            WorkspaceWindow(workspace: "2", appName: "C", windowTitle: ""),
        ])

        let grouped = snapshot.windowsByWorkspace
        XCTAssertEqual(grouped["1"]?.count, 2)
        XCTAssertEqual(grouped["2"]?.count, 1)
    }
}
