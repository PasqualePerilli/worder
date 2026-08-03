# WORDER - Project Overview

## Project Structure

```
worder/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── models/                            # Data models
│   │   ├── game_settings.dart            # User settings model
│   │   ├── game_state.dart               # Game state model
│   │   ├── letter_tile.dart              # Tile and bonus type models
│   │   └── found_word.dart               # Found word with score/path
│   ├── services/                          # Business logic layer
│   │   ├── config_service.dart           # YAML config loader
│   │   ├── dictionary_service.dart       # Word list management
│   │   ├── grid_generator_service.dart   # Grid generation with bonus tiles
│   │   ├── score_calculator_service.dart # Score calculation logic
│   │   └── persistence_service.dart      # Save/load game state
│   ├── screens/                           # Main UI screens
│   │   ├── home_screen.dart              # Settings and game start
│   │   ├── game_screen.dart              # Main gameplay
│   │   └── results_screen.dart           # Results with sharing
│   └── widgets/                           # Reusable UI components
│       ├── tile_widget.dart              # Letter tile display
│       └── preview_bar.dart              # Word preview with animations
├── assets/
│   ├── config/
│   │   └── settings.yaml                 # Configurable app settings
│   ├── words/
│   │   ├── italian.txt                   # Italian word list (sample)
│   │   └── english.txt                   # English word list (sample)
│   ├── letter_values/
│   │   ├── italian.txt                   # Italian letter point values
│   │   └── english.txt                   # English letter point values
│   └── letter_frequencies/
│       ├── italian.txt                   # Italian letter distribution
│       └── english.txt                   # English letter distribution
├── pubspec.yaml                           # Flutter dependencies
├── analysis_options.yaml                  # Dart linter rules
├── .gitignore                             # Git ignore patterns
└── README.md                              # Project readme

```

## Next Steps

### 1. Install Flutter (if not already installed)
```bash
# Visit https://flutter.dev/docs/get-started/install
# Follow instructions for your operating system
```

### 2. Install Dependencies
```bash
cd worder
flutter pub get
```

### 3. Run on Different Platforms

**Desktop (Linux):**
```bash
flutter run -d linux
```

**Desktop (Windows):**
```bash
flutter run -d windows
```

**Desktop (macOS):**
```bash
flutter run -d macos
```

**Mobile (Android):**
```bash
flutter run -d android
```

**Mobile (iOS):**
```bash
flutter run -d ios
```

**List available devices:**
```bash
flutter devices
```

### 4. Build Release Versions

**Android APK:**
```bash
flutter build apk
```

**iOS:**
```bash
flutter build ios
```

**Linux:**
```bash
flutter build linux
```

**Windows:**
```bash
flutter build windows
```

**macOS:**
```bash
flutter build macos
```

## Key Features Implemented

✅ **Bilingual Support**: Italian and English with separate word lists
✅ **Multiple Grid Sizes**: 4x4, 5x5, 6x6, 7x7, 8x8
✅ **Time Options**: 2', 3', 4', 5', or infinite
✅ **Bonus Tiles**: 1 TW, 2 DW, 2 TL, 1 DL with smart positioning
✅ **Word Selection**: Drag across tiles (horizontal, vertical, diagonal)
✅ **Preview Bar**: Orange → Green (valid) or Red (invalid) with shake animation
✅ **Timer Controls**: +1 minute button, double-tap for infinite
✅ **Pause/Resume**: Auto-pause on app background
✅ **Results Screen**: Compare found words vs max possible scores
✅ **Mini Grid**: Shows word paths in results
✅ **Show All Words**: Toggle to see all possible words
✅ **Share Feature**: Screenshot and share top 10 words
✅ **Game Persistence**: Saves current game and completed games
✅ **Configurable**: YAML file for animation timings and colors
✅ **Material Design**: Clean, modern UI with light theme

## Configuration

Edit `assets/config/settings.yaml` to customize:
- Animation durations (shake, popup, etc.)
- Colors (bonus tiles, selected tiles, backgrounds)
- Default settings (language, grid size, duration)
- Share settings (number of top words)

## Word Lists

The sample word lists in `assets/words/` contain basic vocabulary.

**To add your own words:**
1. Open `assets/words/italian.txt` or `english.txt`
2. Add one word per line
3. Words should be lowercase
4. No special characters or spaces
5. Save the file

**Recommended word list sizes:**
- Minimum: 1,000 words
- Good: 10,000+ words
- Excellent: 50,000+ words (comprehensive dictionary)

## Letter Values & Frequencies

You can customize letter values and frequencies by editing:
- `assets/letter_values/[language].txt` - Point values for each letter
- `assets/letter_frequencies/[language].txt` - Distribution percentages

Format: `LETTER=VALUE` (one per line)

## Git Workflow

The project is initialized with Git on the `master` branch.

**To create a feature branch:**
```bash
git checkout -b feature/my-feature-name
# Make changes
git add .
git commit -m "Description of changes"
```

**To merge back to master:**
```bash
git checkout master
git merge feature/my-feature-name
```

## Known Limitations

1. **Word Lists**: Sample word lists are minimal - you'll need to provide comprehensive dictionaries
2. **Platform-Specific Code**: Android/iOS/Desktop platform folders are not included - Flutter will generate them on first run
3. **No Remote Multiplayer**: As requested, this is 100% offline
4. **Share Feature**: Requires platform-specific permissions (will be configured on first build)

## Troubleshooting

**"Package not found" errors:**
```bash
flutter pub get
flutter pub upgrade
```

**Platform-specific issues:**
```bash
flutter clean
flutter pub get
flutter run
```

**Missing platform folder (android, ios, etc.):**
```bash
flutter create --platforms=android,ios,linux,windows,macos .
```

## Future Enhancements (Not Implemented)

These features could be added in future versions:
- Statistics tracking (best scores, word counts, etc.)
- Dark mode support
- Sound effects
- Haptic feedback
- Achievements system
- Multiple player profiles
- Game replay viewer (JSON structure is ready)
- Tutorial/help screen
- Different grid shapes (hexagonal, etc.)

## Contact & Support

For issues or questions, refer to the Flutter documentation:
- https://flutter.dev/docs
- https://api.flutter.dev/

Enjoy playing WORDER!
