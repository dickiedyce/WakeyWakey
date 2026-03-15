import XCTest
@testable import WakeyWakey

final class ConfigStoreTests: XCTestCase {
    private var tempDir: URL!
    private var store: ConfigStore!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        store = ConfigStore(directory: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func makeSampleConfig(name: String = "test") -> SavedConfig {
        let snapshot = AeroSpaceSnapshot(timestamp: Date(), windows: [
            WorkspaceWindow(workspace: "1", appName: "Chrome", windowTitle: "Home"),
            WorkspaceWindow(workspace: "2", appName: "Code", windowTitle: "main.swift"),
        ])
        return SavedConfig(name: name, snapshot: snapshot)
    }

    func testSaveAndLoadConfig() throws {
        let config = makeSampleConfig()
        try store.save(config)

        let loaded = try store.load(name: "test")
        XCTAssertEqual(loaded.name, "test")
        XCTAssertEqual(loaded.snapshot.windows.count, 2)
        XCTAssertEqual(loaded.id, config.id)
    }

    func testListConfigs() throws {
        try store.save(makeSampleConfig(name: "alpha"))
        try store.save(makeSampleConfig(name: "beta"))

        let configs = try store.listConfigs()
        XCTAssertEqual(configs.count, 2)
        XCTAssertEqual(configs.map(\.name).sorted(), ["alpha", "beta"])
    }

    func testDeleteConfig() throws {
        try store.save(makeSampleConfig(name: "deleteme"))
        try store.saveScript("#!/bin/bash\necho hi", name: "deleteme")

        try store.delete(name: "deleteme")

        let configs = try store.listConfigs()
        XCTAssertEqual(configs.count, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("deleteme.sh").path))
    }

    func testSaveScript() throws {
        let script = "#!/bin/bash\necho hello"
        try store.saveScript(script, name: "setup")

        let fileURL = tempDir.appendingPathComponent("setup.sh")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertEqual(content, script)

        // Check executable permission
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let permissions = attributes[.posixPermissions] as? Int ?? 0
        XCTAssertTrue(permissions & 0o111 != 0, "Script should be executable")
    }

    func testLoadNonexistentConfigThrows() {
        XCTAssertThrowsError(try store.load(name: "nope"))
    }

    func testListConfigsEmptyDirectory() throws {
        let configs = try store.listConfigs()
        XCTAssertEqual(configs.count, 0)
    }
}
