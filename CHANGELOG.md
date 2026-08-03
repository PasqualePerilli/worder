# Changelog

All notable changes to the WORDER project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.4] - 2026-08-03

### Changed
- **+ button behavior**: Now extends the game instead of restarting it
  - Previous: Pressing + kept the same grid but reset score to 0 and cleared found words
  - New: Pressing + keeps the grid, score, and all found words, adding 1 minute to continue
  - Previously found words remain found and cannot be re-scored
  - Allows players to continue searching for new words without losing progress
  
### Technical
- Modified `_addOneMinute()` in results_screen.dart:
  - Creates copy of game state with `isFinished: false` and `gameDurationMinutes + 1`
  - Saves extended game as current game
  - GameScreen resumes the extended game (not a new game)
- Added PersistenceService import to results_screen.dart

### Example
- Play 2-minute game, find 10 words worth 50 points
- Time expires → Results screen shows
- Press + button
- Game resumes with: same grid + 10 found words + 50 points + 1 minute added
- Can now find additional words for more points

## [1.3.3] - 2026-08-03

### Fixed
- **Text sizing for large grids**: Letter and value text now scale down for 7x7 and 8x8 grids
  - 7x7: Letter 16px (was 24px), Value 8px (was 10px)
  - 8x8: Letter 14px (was 24px), Value 7px (was 10px)
  - Previously, text was too large on 7x7/8x8 grids, making letter/value distinction difficult
  - Bonus tiles had especially poor visibility with oversized text and indicators
  - Text sizes now scale proportionally: larger for small grids, smaller for large grids

### Improved
- **Responsive text scaling**: TileWidget now adapts font sizes to grid size
  - 4x4: Letter 28px, Value 11px (slightly larger for maximum readability)
  - 5x5: Letter 24px, Value 10px (baseline)
  - 6x6: Letter 20px, Value 9px
  - 7x7: Letter 16px, Value 8px
  - 8x8: Letter 14px, Value 7px
  - Each grid size optimized for its available space

### Changed
- TileWidget: Added `gridSize` parameter
- GameScreen: Passes `gridSize` when creating TileWidget instances
- Font sizes: Computed dynamically using `_getLetterFontSize()` and `_getValueFontSize()`

## [1.3.2] - 2026-08-03

### Fixed
- **Diagonal selection accuracy**: Increased cell spacing from 4px to 8px
  - Prevents accidental selection of adjacent cells when dragging diagonally
  - Example: Selecting C→E diagonally no longer grabs F inadvertently
  - Makes diagonal word selection more reliable and forgiving

### Improved
- **Preview bar UX**: Word text now persists while showing success/error feedback
  - Text stays visible while bar is green (valid word) or red (invalid word)
  - Only clears when bar resets to orange (selecting state)
  - Previously cleared immediately on finger lift, making it difficult to see what was submitted
  - Users can now read the word they just attempted
  
- **Results screen sorting**: "Show All Words" now sorted by maximum possible score
  - Displays highest-value words first, regardless of whether found
  - "Found Words Only" still sorted by user's actual score
  - Previously both views sorted by user score, putting unfound words (0 points) at bottom

### Changed
- Grid cell spacing: `crossAxisSpacing` and `mainAxisSpacing` increased to 8 (was 4)
- Preview bar: `_currentWord` only cleared when transitioning to selecting state
- Results sorting: Uses `maxScore` for "Show All", `userScore` for "Found Only"

## [1.3.1] - 2026-08-03

### Fixed
- **CRITICAL**: Word submission on finger lift
  - Selection now clears immediately when finger lifts
  - Previously, valid words would remain selected/frozen after finger lift
  - Invalid words worked correctly, but valid words didn't
  - Fixed by copying path before clearing selection, then processing asynchronously
  - Added `onPanCancel` handler to catch cancelled gestures
  
- **Grid replay issue**: When finishing a game and pressing + to replay, a new grid would appear instead of the same grid
  - Now correctly reuses the same grid when replaying a finished game
  - Flow: Play Grid A → Finish → Press + → Get Grid A again (with reset state)
  - If settings change (language/size), generates new grid as expected

### Changed
- `_onSelectionEnd()` signature changed from `void async` to `Future<void> async` (proper async method)
- Word validation and scoring now happens asynchronously after selection is cleared
- Finished games are saved as current game (not cleared) to enable grid reuse
- `_initializeGame()` now handles three cases:
  1. Finished game with matching settings → reuse grid, reset state
  2. Unfinished game → resume
  3. No game or settings mismatch → generate new grid

### Technical
- Removed duplicate `TilePosition` class from game_screen.dart (was causing type conflicts)
- `TilePosition` now only defined in found_word.dart
- Added debug logging for gesture events

## [1.3.0] - 2026-08-03

### Changed
- **MAJOR**: Complete rewrite of grid generation algorithm
  - Previous algorithm was fundamentally flawed (needed 200 retries per tile)
  - New approach: generate first, validate after (same as successful generation script)
  - Runtime generation now completes in <10ms (was >1000ms)
  - Algorithm tries 10 times to generate valid grid, usually succeeds on attempt 1-2
  
### Added
- Pre-generated grids as fallback (1000 grids per language/size combination)
  - 10 JSON files: italian/english × 4x4/5x5/6x6/7x7/8x8
  - Total: 10,000 pre-validated grids
  - Used only if runtime generation fails (extremely rare)
  - Adds ~3MB to APK size
- Generation script: `scripts/generate_grids.dart`

### Removed
- Complex per-tile constraint checking (root cause of slowness)
- ConfigService dependency from grid generator
- `_generateLetters()`, `_generateLettersRelaxed()`, `_wouldCreateConsecutive()` methods
- Retry logic (200 attempts per tile)

### Technical
- New `_generateSingleGrid()`: simple weighted random, entire grid at once
- New `_isValidGrid()`: validates complete grid, size-scaled limits
- Validation rules scale with grid size:
  - 4x4-5x5: max 2 uncommon, 4 common letters
  - 6x6: max 3 uncommon, 6 common
  - 7x7: max 4 uncommon, 8 common  
  - 8x8: max 5 uncommon, 10 common
- No more consecutive letter checking during generation (only in validation)
- Flow: runtime generation (10 tries) → pre-generated grids → unconstrained grid

## [1.2.2] - 2026-08-03

### Fixed
- **CRITICAL**: Infinite spinner issue - grid would never load
  - Root cause: Letter distribution constraints from v1.2.0 were too strict
  - Algorithm was trying 100 times to generate valid grids and failing every time
  - Fixed by optimizing the generation algorithm:
    * Increased per-tile retry attempts from 50 to 200 for small grids
    * Improved fallback logic to avoid consecutive letters intelligently
    * Reduced max grid retries from 100 to 10 (faster fallback to relaxed mode)
    * Removed unnecessary async from internal methods
  - Grid generation now completes in under 1 second

### Technical
- Made `_generateLetters()` and `_generateLettersRelaxed()` synchronous (they don't await anything)
- Increased `maxAttempts` to 200 for grids ≤4x4 (was 50 for all sizes)
- Fallback now tries common letters that avoid consecutive patterns before random selection
- Reduced `max_generation_retries` from 100 to 10 in settings.yaml
- Added debug logging: "Starting grid generation", "Successfully generated valid grid on attempt X", "Using relaxed rules"

## [1.2.1] - 2026-08-03

### Fixed
- **CRITICAL**: Gray screen issue after pressing Play button
  - Problem: Grid generation became async in v1.2.0 but UI tried to render before grid was ready
  - Solution: Added loading state with CircularProgressIndicator
  - Made `_grid` nullable and added `_isLoading` flag
  - UI now waits for grid generation to complete before rendering
  - Prevents crash from accessing uninitialized grid

### Technical
- Changed `_grid` from `late List<List<LetterTile>>` to `List<List<LetterTile>>?`
- Added `bool _isLoading = true` state variable
- Show loading spinner while `_isLoading || _grid == null`
- Set `_isLoading = false` after grid generation completes (both new and resumed games)
- Use null assertion operator (`!`) when accessing grid after null check

## [1.2.0] - 2026-08-03

### Fixed
- **CRITICAL**: Drag selection ACTUALLY works now (root cause identified and fixed)
  - Removed GestureDetector from TileWidget that was consuming touch events
  - Removed onPanDown handler that blocked parent gesture detection
  - Parent GestureDetector now properly receives all pan gestures
  - **This was the actual problem** - child widgets were intercepting gestures

### Added
- Intelligent letter distribution system with configurable constraints:
  - Maximum occurrences for uncommon letters (< 3% frequency): 2 per grid
  - Maximum occurrences for common letters (≥ 3% frequency): 4 per grid
  - Prevents 3+ consecutive identical letters in any direction (horizontal, vertical, all diagonals)
  - Validates entire grid after generation with up to 100 retries
  - Falls back to relaxed rules only if unable to generate valid grid
- New settings in settings.yaml:
  - `letter_distribution.max_uncommon_letter_occurrences`: 2
  - `letter_distribution.max_common_letter_occurrences`: 4
  - `letter_distribution.uncommon_threshold`: 3.0%
  - `letter_distribution.min_distance_same_letter`: 1
  - `letter_distribution.max_generation_retries`: 100

### Changed
- Grid generation is now asynchronous to support validation and retry logic
- Letter rarity classification based on language frequency data
- Improved grid quality with balanced letter distribution

### Technical
- Added ConfigService getters for all distribution settings
- Completely rewrote GridGeneratorService:
  - `_generateLetters()`: Smart generation with constraint enforcement
  - `_generateLettersRelaxed()`: Fallback for edge cases
  - `_wouldCreateConsecutive()`: Checks for consecutive letter violations
  - `_validateGrid()`: Post-generation validation
- Updated GameScreen to await async grid generation

### Examples of Fixed Issues
- ✅ No more 4 "V" letters in a 4×4 grid
- ✅ No more 3 consecutive "R" letters in a column
- ✅ No more rows entirely composed of consonants
- ✅ No more 2 uncommon "U" vowels in small grids
- ✅ Balanced distribution prevents disappointing letter combinations

## [1.1.2] - 2026-08-03

### Fixed
- **CRITICAL**: Drag selection now actually works
  - Added `HitTestBehavior.opaque` to GestureDetector
  - Ensures touch events are properly captured and not consumed by child widgets
  - GridView no longer blocks gesture detection
- Results screen + button styling improved
  - Changed to fixed 44×44px size (standard touch target)
  - Increased font size to 24px for better visibility
  - Added more right padding (16px instead of 8px)
  - Button now has proper square proportions instead of tall/narrow

## [1.1.1] - 2026-08-03

### Fixed
- **CRITICAL**: Drag selection now works correctly
  - Fixed coordinate calculation to account for GridView padding
  - onPanStart and onPanUpdate now properly detect tile positions
  - Drag gesture consistently captures tile selections
- **CRITICAL**: Bonus tiles now always appear in every game
  - Triple Word (3★) always placed in exact center of grid
  - Double Word (2★) two tiles in center area (away from edges)
  - Triple Letter (3●) two tiles anywhere on grid
  - Double Letter (2●) one tile anywhere on grid
  - Simplified placement logic to guarantee all bonus types
- Bonus indicator stars now display multiplier number (2 or 3) inside
  - Stack widget overlays text on star icon
  - Circles already showed numbers correctly
- Results screen title now always shows "Results" (language-independent)
- Results screen title is now centered in AppBar
- Results screen + button now matches game screen styling
  - White container with + text instead of icon button
  - Visual consistency across screens

## [1.1.0] - 2026-08-03

### Changed
- Bonus tile appearance significantly improved:
  - Stars and circles increased to 32px (2x larger)
  - Bonus indicators now extend outside tiles into gaps between tiles
  - Tile borders colored instead of tile backgrounds for bonus tiles
  - Bonus tile borders increased to 6px (3x thicker)
  - Letter point values moved from top-right to bottom-right
  - Circle multiplier text increased to 14px for better readability
- Top bar UI redesigned:
  - Added dark blue container with border and drop shadow
  - Better visual separation from game background
  - Stop button now displays "STOP" text instead of icon
  - Improved spacing and visual hierarchy
- Letter selection mechanics refined:
  - Now purely drag-based (removed tap-to-select)
  - Selection starts on drag start (onPanStart)
  - Selection continues during drag (onPanUpdate)
  - Word submitted when finger lifts (onPanEnd)
  - More intuitive and consistent drag experience

### Technical
- Removed onTapDown callback from TileWidget
- Implemented LayoutBuilder in grid for proper drag coordinate calculation
- Updated TileWidget to use Stack with Clip.none for overflow indicators

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
