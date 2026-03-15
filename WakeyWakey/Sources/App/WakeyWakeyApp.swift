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
            Image(systemName: viewModel.isCapturing ? "clock.badge.airplane" : "airplane.ticket")
        }
        .menuBarExtraStyle(.window)

        Settings {
            PreferencesView(settings: settings)
        }
    }
}
