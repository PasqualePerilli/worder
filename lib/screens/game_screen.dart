import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../models/letter_tile.dart';
import '../models/found_word.dart';
import '../services/config_service.dart';
import '../services/dictionary_service.dart';
import '../services/grid_generator_service.dart';
import '../services/score_calculator_service.dart';
import '../services/persistence_service.dart';
import '../widgets/tile_widget.dart';
import '../widgets/preview_bar.dart';
import 'results_screen.dart';

class GameScreen extends StatefulWidget {
  final GameSettings settings;

  const GameScreen({super.key, required this.settings});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late List<List<LetterTile>> _grid;
  late List<FoundWord> _foundWords;
  late int _currentScore;
  late DateTime _startTime;
  late int _elapsedSeconds;
  late int _gameDurationMinutes;
  late bool _isPaused;
  late bool _showAddedTime;

  final List<TilePosition> _currentPath = [];
  String _currentWord = '';
  PreviewBarState _previewState = PreviewBarState.selecting;
  Timer? _gameTimer;
  final Set<String> _foundWordStrings = {};

  final DictionaryService _dictionaryService = DictionaryService.getInstance();
  final GridGeneratorService _gridGenerator = GridGeneratorService();
  final ScoreCalculatorService _scoreCalculator = ScoreCalculatorService();
  final PersistenceService _persistenceService = PersistenceService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pauseGame();
    }
  }

  Future<void> _initializeGame() async {
    final savedGame = await _persistenceService.loadCurrentGame();

    if (savedGame != null &&
        !savedGame.isFinished &&
        savedGame.language == widget.settings.language &&
        savedGame.grid.length == widget.settings.gridSize) {
      // Resume saved game
      setState(() {
        _grid = savedGame.grid;
        _foundWords = savedGame.foundWords;
        _currentScore = savedGame.currentScore;
        _startTime = savedGame.startTime;
        _elapsedSeconds = savedGame.elapsedSeconds;
        _gameDurationMinutes = savedGame.gameDurationMinutes;
        _isPaused = savedGame.isPaused;
        _showAddedTime = false;

        _foundWordStrings
            .addAll(savedGame.foundWords.map((w) => w.word.toUpperCase()));
      });
    } else {
      // Start new game
      setState(() {
        _grid = _gridGenerator.generateGrid(
            widget.settings.gridSize, widget.settings.language);
        _foundWords = [];
        _currentScore = 0;
        _startTime = DateTime.now();
        _elapsedSeconds = 0;
        _gameDurationMinutes = widget.settings.gameDurationMinutes;
        _isPaused = false;
        _showAddedTime = false;
      });
    }

    _startTimer();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
        });

        _saveGameState();

        // Check if time is up (if not infinite)
        if (_gameDurationMinutes > 0) {
          final remainingSeconds = (_gameDurationMinutes * 60) - _elapsedSeconds;
          if (remainingSeconds <= 0) {
            _endGame();
          }
        }
      }
    });
  }

  void _pauseGame() {
    setState(() {
      _isPaused = true;
    });
    _saveGameState();
  }

  void _resumeGame() {
    setState(() {
      _isPaused = false;
    });
  }

  Future<void> _saveGameState() async {
    final gameState = GameState(
      grid: _grid,
      foundWords: _foundWords,
      currentScore: _currentScore,
      startTime: _startTime,
      elapsedSeconds: _elapsedSeconds,
      isPaused: _isPaused,
      isFinished: false,
      gameDurationMinutes: _gameDurationMinutes,
      language: widget.settings.language,
      playerName: widget.settings.playerName,
    );

    await _persistenceService.saveCurrentGame(gameState);
  }

  void _endGame() {
    _gameTimer?.cancel();
    
    final gameState = GameState(
      grid: _grid,
      foundWords: _foundWords,
      currentScore: _currentScore,
      startTime: _startTime,
      elapsedSeconds: _elapsedSeconds,
      isPaused: false,
      isFinished: true,
      gameDurationMinutes: _gameDurationMinutes,
      language: widget.settings.language,
      playerName: widget.settings.playerName,
    );

    _persistenceService.saveCompletedGame(gameState);
    _persistenceService.clearCurrentGame();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(gameState: gameState),
      ),
    );
  }

  void _addOneMinute() async {
    final config = await ConfigService.getInstance();
    
    setState(() {
      if (_gameDurationMinutes == 0) {
        // Already infinite, do nothing
        return;
      }
      
      _gameDurationMinutes += 1;
      _showAddedTime = true;
    });

    // Hide the added time overlay after configured duration
    Future.delayed(Duration(milliseconds: config.addedTimeOverlayDuration), () {
      if (mounted) {
        setState(() {
          _showAddedTime = false;
        });
      }
    });
  }

  void _setInfiniteTime() async {
    final config = await ConfigService.getInstance();
    
    setState(() {
      _gameDurationMinutes = 0;
      _showAddedTime = true;
    });

    Future.delayed(Duration(milliseconds: config.addedTimeOverlayDuration), () {
      if (mounted) {
        setState(() {
          _showAddedTime = false;
        });
      }
    });
  }

  void _onTileEnter(int row, int col) {
    if (_isPaused) return;

    final pos = TilePosition(row, col);

    // Check if already in path
    if (_currentPath.contains(pos)) return;

    // Check if adjacent to last tile
    if (_currentPath.isNotEmpty) {
      final last = _currentPath.last;
      final rowDiff = (last.row - row).abs();
      final colDiff = (last.col - col).abs();

      if (rowDiff > 1 || colDiff > 1) return; // Not adjacent
    }

    setState(() {
      _currentPath.add(pos);
      _currentWord += _grid[row][col].letter;
      _previewState = PreviewBarState.selecting;
    });
  }

  void _onSelectionEnd() async {
    if (_currentPath.isEmpty) return;

    final config = await ConfigService.getInstance();
    final word = _currentWord.toUpperCase();

    // Check minimum length
    if (word.length < config.minWordLength) {
      _resetSelection();
      return;
    }

    // Check if already found
    if (_foundWordStrings.contains(word)) {
      _resetSelection();
      return;
    }

    // Validate word
    final isValid =
        _dictionaryService.isValidWord(word, widget.settings.language);

    if (isValid) {
      // Calculate score
      final tiles = _currentPath.map((pos) => _grid[pos.row][pos.col]).toList();
      final score =
          _scoreCalculator.calculateWordScore(tiles, widget.settings.language);
      final maxScore = _scoreCalculator.calculateMaxPossibleScore(
          word, _grid, widget.settings.language);

      final foundWord = FoundWord(
        word: word,
        score: score,
        maxPossibleScore: maxScore,
        path: List.from(_currentPath),
        timestamp: DateTime.now(),
      );

      setState(() {
        _previewState = PreviewBarState.success;
        _foundWords.add(foundWord);
        _foundWordStrings.add(word);
        _currentScore += score;
      });

      // Wait a bit before clearing
      await Future.delayed(Duration(milliseconds: config.previewBarSuccessDuration));
      
      if (mounted) {
        _resetSelection();
      }
    } else {
      setState(() {
        _previewState = PreviewBarState.error;
      });

      // Wait for shake animation
      await Future.delayed(Duration(milliseconds: config.invalidWordShakeDuration));
      
      if (mounted) {
        _resetSelection();
      }
    }
  }

  void _resetSelection() {
    setState(() {
      _currentPath.clear();
      _currentWord = '';
      _previewState = PreviewBarState.selecting;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConfigService>(
      future: ConfigService.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final config = snapshot.data!;
        final backgroundColor = _parseColor(config.backgroundGameColor);

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTopBar(config),
                    PreviewBar(word: _currentWord, state: _previewState),
                    Expanded(
                      child: Center(
                        child: _buildGrid(),
                      ),
                    ),
                  ],
                ),
                if (_isPaused) _buildPauseOverlay(),
                if (_showAddedTime) _buildAddedTimeOverlay(config),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(ConfigService config) {
    final remainingSeconds = _gameDurationMinutes > 0
        ? (_gameDurationMinutes * 60) - _elapsedSeconds
        : 0;

    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final timeText = _gameDurationMinutes == 0
        ? '∞'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade900,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Timer
          Text(
            timeText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          // +1 Button
          GestureDetector(
            onTap: _addOneMinute,
            onDoubleTap: _setInfiniteTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '+',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Score
          Text(
            '$_currentScore',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Stop Button
          ElevatedButton(
            onPressed: _endGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'STOP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (details) {
            // Start selection on drag start
            final cellWidth = constraints.maxWidth / _grid.length;
            final cellHeight = constraints.maxHeight / _grid.length;
            final row = (details.localPosition.dy / cellHeight).floor();
            final col = (details.localPosition.dx / cellWidth).floor();

            if (row >= 0 && row < _grid.length && col >= 0 && col < _grid.length) {
              _onTileEnter(row, col);
            }
          },
          onPanUpdate: (details) {
            // Continue selection during drag
            final cellWidth = constraints.maxWidth / _grid.length;
            final cellHeight = constraints.maxHeight / _grid.length;
            final row = (details.localPosition.dy / cellHeight).floor();
            final col = (details.localPosition.dx / cellWidth).floor();

            if (row >= 0 && row < _grid.length && col >= 0 && col < _grid.length) {
              _onTileEnter(row, col);
            }
          },
          onPanEnd: (_) => _onSelectionEnd(),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _grid.length,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: _grid.length * _grid.length,
            itemBuilder: (context, index) {
              final row = index ~/ _grid.length;
              final col = index % _grid.length;
              final tile = _grid[row][col];
              final pos = TilePosition(row, col);
              final isSelected = _currentPath.contains(pos);

              return TileWidget(
                tile: tile,
                isSelected: isSelected,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Score: $_currentScore',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Time: ${_formatTime(_elapsedSeconds)}',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _resumeGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: const Icon(Icons.play_arrow, size: 48),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddedTimeOverlay(ConfigService config) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _gameDurationMinutes == 0 ? '∞ TIME' : '+1 MINUTE',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}

class TilePosition {
  final int row;
  final int col;

  const TilePosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TilePosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}
