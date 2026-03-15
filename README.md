# WakeyWakey

A native macOS SwiftUI menu bar app that captures and restores [AeroSpace](https://github.com/nikitabobko/AeroSpace) tiling window manager layouts.

## Features

- **Capture layouts** -- Record which apps are in which AeroSpace workspaces
- **Save as configs** -- Store layouts as JSON configs and executable shell scripts
- **Restore layouts** -- Restore a saved layout with one click from the menu bar
- **View scripts** -- Reveal generated shell scripts in Finder or open the scripts folder
- **Exclude apps** -- Skip specific apps when restoring
- **Preferences** -- Native macOS toolbar-style settings with General, Automations, and Privacy tabs

## Requirements

- macOS 13.0+
- [AeroSpace](https://github.com/nikitabobko/AeroSpace) installed with `aerospace` CLI in PATH
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) 2.38.0+

## Quick Start

```bash
# Clone the repo
git clone https://github.com/dd/WakeyWakey.git
cd WakeyWakey

# Generate the Xcode project
xcodegen generate

# Build (Debug, no signing)
xcodebuild -project WakeyWakey.xcodeproj -scheme WakeyWakey -configuration Debug build

# Run tests
xcodebuild -project WakeyWakey.xcodeproj -scheme WakeyWakeyTests -configuration Debug test
```

### Signing and Installation

```bash
# Set up local signing
cp WakeyWakey/Config/Signing.xcconfig.example WakeyWakey/Config/Signing.xcconfig
# Edit Signing.xcconfig with your DEVELOPMENT_TEAM and CODE_SIGN_IDENTITY

# Build, sign, and install to /Applications
xcodebuild -project WakeyWakey.xcodeproj -scheme WakeyWakey -configuration Release build
```

The Release build automatically re-signs with entitlements and copies to `/Applications`.

> **Note:** `Signing.xcconfig` is gitignored and never committed. Only the
> example template is tracked.

## Project Structure

```
WakeyWakey/
  Sources/
    App/          -- App entry point (WakeyWakeyApp)
    Models/       -- AppSettings, AeroSpaceModels, ShortcutNames
    Services/     -- AeroSpaceService, ConfigStore
    Views/        -- MenuBarView, MenuBarViewModel, PreferencesView
  Resources/      -- Entitlements, asset catalog
  Config/         -- Signing config (gitignored)
WakeyWakeyTests/  -- Unit tests
project.yml       -- XcodeGen project definition
scripts/          -- Icon generation script
```

## Usage

1. Launch WakeyWakey -- it appears as an airplane icon in the menu bar
2. Click the icon and choose **Capture Current Layout**
3. Name your config and save
4. Restore any saved config from the menu at any time
5. Click the document icon next to a config to reveal its shell script in Finder
6. Use **Open Scripts Folder** to browse all saved configs and scripts

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests first (TDD)
4. Submit a pull request

## License

MIT License -- see [LICENSE](LICENSE) for details.
