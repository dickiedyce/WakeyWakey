# WakeyWakey

A native macOS SwiftUI menu bar app that captures and restores [AeroSpace](https://github.com/nikitabobko/AeroSpace) tiling window manager layouts.

## Features

- **Capture layouts** -- Record which apps are in which AeroSpace workspaces
- **Save as configs** -- Store layouts as JSON configs and executable shell scripts
- **Restore layouts** -- Restore a saved layout with one click from the menu bar
- **Exclude apps** -- Skip specific apps when restoring
- **Preferences** -- Native macOS toolbar-style settings with General, Automations, and Privacy tabs

## Requirements

- macOS 13.0+
- [AeroSpace](https://github.com/nikitabobko/AeroSpace) installed with `aerospace` CLI in PATH
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) 2.38.0+

## Setup

```bash
# Generate the Xcode project
xcodegen generate

# Build (Debug, no signing)
xcodebuild -scheme WakeyWakey -configuration Debug build

# Run tests
xcodebuild -scheme WakeyWakeyTests -configuration Debug test
```

### Signing (for Release)

```bash
cp WakeyWakey/Config/Signing.xcconfig.example WakeyWakey/Config/Signing.xcconfig
# Edit Signing.xcconfig with your DEVELOPMENT_TEAM and CODE_SIGN_IDENTITY
xcodebuild -scheme WakeyWakey -configuration Release build
```

## Project Structure

```
WakeyWakey/
  Sources/
    App/          -- App entry point
    Models/       -- Data models (AppSettings, AeroSpaceModels, ShortcutNames)
    Services/     -- AeroSpaceService, ConfigStore
    Views/        -- MenuBarView, PreferencesView, MenuBarViewModel
  Resources/      -- Entitlements
  Config/         -- Signing config (gitignored)
WakeyWakeyTests/  -- Unit tests
project.yml       -- XcodeGen project definition
```

## Usage

1. Launch WakeyWakey -- it appears as a menu bar icon (airplane ticket)
2. Click the icon and choose **Capture Current Layout**
3. Name your config and save
4. Restore any saved config from the menu at any time
5. Configs are also saved as shell scripts you can run independently

## License

Copyright © 2026 WakeyWakey. All rights reserved.
