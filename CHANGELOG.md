# Changelog

All notable changes to the WORDER project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-08-03

### Added
- Complete Flutter application structure with cross-platform support (Android, iOS, Linux, Windows, macOS)
- Offline word game mechanics inspired by Ruzzle
- Drag-to-select word input with adjacency validation
- Bilingual support (Italian as default, English)
- Configurable game settings:
  - Grid sizes: 4x4, 5x5, 6x6, 7x7, 8x8
  - Game durations: 2, 3, 4, 5 minutes, or infinite
  - Player name customization
- Bonus tile system:
  - 1 Triple Word (TW)
  - 2 Double Word (DW)
  - 2 Triple Letter (TL)
  - 1 Double Letter (DL)
  - Bonus tiles never placed at grid edges
- Game features:
  - Pause/resume functionality
  - Timer with +1 minute button (single tap)
  - Infinite time mode (double-tap +1 button)
  - Real-time word validation
  - Score calculation with bonus multipliers
  - Shake animation for invalid words (500ms)
  - Tile popup animation on selection (15% scale)
- Results screen with:
  - Word list showing user score vs maximum possible score
  - Mini-grid visualization showing word paths
  - Toggle to show all possible words vs found words only
  - Word comparison to see missed opportunities
- Conditional sharing system:
  - Native screenshot + share on Android 14+ and iOS
  - Manual screenshot screen on Android 10-13, Linux, Windows, macOS
  - Configurable share message in settings.yaml
- Game persistence:
  - JSON files for game history in documents directory
  - SharedPreferences for settings
  - Resume interrupted games
- YAML-based configuration system (settings.yaml):
  - Animation durations
  - Colors (bonus tiles, UI elements)
  - Default settings
  - Share configuration
- Letter distribution system based on language-specific frequencies
- Scrabble-style point values for letters
- Italian "Q" automatically becomes "QU"

### Technical
- Package ID: com.github.pasqualeperilli.worder
- Android compatibility: API 29+ (Android 10+)
- Android build configuration:
  - minSdk: 29 (Android 10)
  - compileSdk: 36
  - targetSdk: 34
- Dependencies:
  - flutter: SDK
  - shared_preferences: ^2.2.2
  - path_provider: ^2.1.6
  - screenshot: ^3.0.0
  - share_plus: ^10.0.0
  - yaml: ^3.1.2
- Platform-specific implementations for Android, iOS, Linux, Windows, macOS
- Material Design UI with light theme
- Git repository initialized with master branch

### Fixed
- Duplicate TilePosition class conflicts (removed from score_calculator_service.dart and results_screen.dart)
- Compilation errors related to missing imports
- Import conflicts between screens
- Screenshot package API compatibility (upgraded to 3.0.0)
- Android SDK compatibility issues for older devices
- Namespace configuration for Gradle build

### Notes
- Word dictionaries (assets/words/italian.txt and assets/words/english.txt) contain sample data (~100 words each)
- Comprehensive dictionaries should be provided before production use
- First build requires downloading Gradle dependencies and NDK (5-15 minutes)
- Subsequent builds take 30-60 seconds

---

## Version Number Format

- **Major** (X.0.0): Breaking changes, major feature additions
- **Minor** (0.X.0): New features, non-breaking changes
- **Patch** (0.0.X): Bug fixes, minor improvements

## Change Categories

- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements
- **Technical**: Internal/infrastructure changes
