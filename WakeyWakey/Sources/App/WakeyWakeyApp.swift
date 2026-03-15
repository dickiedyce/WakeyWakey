import SwiftUI

@main
struct WakeyWakeyApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var viewModel: MenuBarViewModel

    init() {
        let s = AppSettings()
        _settings = StateObject(wrappedValue: s)
        _viewModel = StateObject(wrappedValue: MenuBarViewModel(settings: s))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            Image(systemName: viewModel.isCapturing ? "arrow.triangle.2.circlepath.circle.fill" : "square.grid.2x2")
        }
        .menuBarExtraStyle(.window)

        Settings {
            PreferencesView(settings: settings)
        }
    }
}
