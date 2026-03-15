import XCTest
@testable import WakeyWakey

final class AppSettingsTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "com.wakeywakey.tests.\(UUID().uuidString)")!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: defaults.description)
        defaults = nil
        super.tearDown()
    }

    func testDefaultValues() {
        let settings = AppSettings(defaults: defaults)
        XCTAssertTrue(settings.configDirectory.hasSuffix("/Documents/WakeyWakey"))
        XCTAssertFalse(settings.runOnStartup)
        XCTAssertEqual(settings.excludedApps, [])
        XCTAssertEqual(settings.captureDelay, 1.5)
    }

    func testPersistsConfigDirectory() {
        let settings = AppSettings(defaults: defaults)
        settings.configDirectory = "/tmp/test"
        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.configDirectory, "/tmp/test")
    }

    func testPersistsRunOnStartup() {
        let settings = AppSettings(defaults: defaults)
        settings.runOnStartup = true
        let reloaded = AppSettings(defaults: defaults)
        XCTAssertTrue(reloaded.runOnStartup)
    }

    func testPersistsExcludedApps() {
        let settings = AppSettings(defaults: defaults)
        settings.excludedApps = ["Finder", "Safari"]
        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.excludedApps, ["Finder", "Safari"])
    }

    func testPersistsCaptureDelay() {
        let settings = AppSettings(defaults: defaults)
        settings.captureDelay = 3.0
        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.captureDelay, 3.0)
    }

    func testReset() {
        let settings = AppSettings(defaults: defaults)
        settings.configDirectory = "/custom/path"
        settings.runOnStartup = true
        settings.excludedApps = ["App"]
        settings.captureDelay = 5.0

        settings.reset()

        XCTAssertTrue(settings.configDirectory.hasSuffix("/Documents/WakeyWakey"))
        XCTAssertFalse(settings.runOnStartup)
        XCTAssertEqual(settings.excludedApps, [])
        XCTAssertEqual(settings.captureDelay, 1.5)
    }
}
