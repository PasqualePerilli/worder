import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/game_state.dart';
import '../models/found_word.dart';
import '../models/game_settings.dart';
import '../services/dictionary_service.dart';
import '../services/score_calculator_service.dart';
import '../services/config_service.dart';
import 'home_screen.dart';
import 'game_screen.dart';

class ResultsScreen extends StatefulWidget {
  final GameState gameState;

  const ResultsScreen({super.key, required this.gameState});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _showAllWords = false;
  int? _selectedWordIndex;
  final ScreenshotController _screenshotController = ScreenshotController();
  final DictionaryService _dictionaryService = DictionaryService.getInstance();
  final ScoreCalculatorService _scoreCalculator = ScoreCalculatorService();
  List<WordDisplay> _displayWords = [];

  @override
  void initState() {
    super.initState();
    _prepareWordList();
  }

  void _prepareWordList() {
    final foundWordStrings =
        widget.gameState.foundWords.map((w) => w.word.toUpperCase()).toSet();
    final foundWordsMap = {
      for (var w in widget.gameState.foundWords) w.word.toUpperCase(): w
    };

    if (_showAllWords) {
      // Get all possible words from the grid
      final allWords = _dictionaryService.getAllWords(widget.gameState.language);
      final possibleWords = <String>{};

      for (final word in allWords) {
        if (_isWordPossible(word)) {
          possibleWords.add(word.toUpperCase());
        }
      }

      _displayWords = possibleWords.map((word) {
        if (foundWordStrings.contains(word)) {
          final foundWord = foundWordsMap[word]!;
          return WordDisplay(
            word: word,
            userScore: foundWord.score,
            maxScore: foundWord.maxPossibleScore,
            isFound: true,
            path: foundWord.path,
          );
        } else {
          final maxScore = _scoreCalculator.calculateMaxPossibleScore(
              word, widget.gameState.grid, widget.gameState.language);
          return WordDisplay(
            word: word,
            userScore: 0,
            maxScore: maxScore,
            isFound: false,
            path: const [],
          );
        }
      }).toList();
    } else {
      _displayWords = widget.gameState.foundWords.map((w) {
        return WordDisplay(
          word: w.word.toUpperCase(),
          userScore: w.score,
          maxScore: w.maxPossibleScore,
          isFound: true,
          path: w.path,
        );
      }).toList();
    }

    // Sort by user score (descending)
    _displayWords.sort((a, b) => b.userScore.compareTo(a.userScore));
  }

  bool _isWordPossible(String word) {
    // Simple check - this could be optimized
    return _scoreCalculator.calculateMaxPossibleScore(
            word, widget.gameState.grid, widget.gameState.language) >
        0;
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  void _addOneMinute() {
    // Return to game with +1 minute
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          settings: widget.gameState.toGameSettings().copyWith(
                gameDurationMinutes: 1,
              ),
        ),
      ),
    );
  }

  Future<void> _shareResults() async {
    final config = await ConfigService.getInstance();
    final topWords = _displayWords.take(config.topWordsCount).toList();

    // Take screenshot of results
    final image = await _screenshotController.capture();
    if (image == null) return;

    // Save to temp file
    final directory = await getTemporaryDirectory();
    final imagePath = '${directory.path}/worder_results.png';
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(image);

    // Share
    await Share.shareXFiles(
      [XFile(imagePath)],
      text: 'WORDER - Score: ${widget.gameState.currentScore}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: _goHome,
        ),
        title: Text(
          widget.gameState.language == 'italian' ? 'Risultati' : 'Results',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _addOneMinute,
            tooltip: '+1 minute',
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildWordList(),
                  ),
                  if (_selectedWordIndex != null)
                    Expanded(
                      flex: 1,
                      child: _buildMiniGrid(),
                    ),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final minutes = widget.gameState.elapsedSeconds ~/ 60;
    final seconds = widget.gameState.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Column(
        children: [
          Text(
            widget.gameState.playerName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Text('Score', style: TextStyle(fontSize: 16)),
                  Text(
                    '${widget.gameState.currentScore}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('Time', style: TextStyle(fontSize: 16)),
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWordList() {
    return ListView.builder(
      itemCount: _displayWords.length,
      itemBuilder: (context, index) {
        final word = _displayWords[index];
        final isSelected = _selectedWordIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedWordIndex = index;
            });
          },
          child: Container(
            color: isSelected ? Colors.blue.shade100 : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (isSelected)
                  const Icon(Icons.chevron_right, size: 20)
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    word.word,
                    style: TextStyle(
                      fontWeight: word.isFound ? FontWeight.bold : FontWeight.normal,
                      color: word.isFound ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${word.userScore}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: word.isFound ? FontWeight.bold : FontWeight.normal,
                      color: word.isFound ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${word.maxScore}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    word.word,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniGrid() {
    final selectedWord = _displayWords[_selectedWordIndex!];
    final gridSize = widget.gameState.grid.length;

    return Container(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: gridSize * gridSize,
        itemBuilder: (context, index) {
          final row = index ~/ gridSize;
          final col = index % gridSize;
          final tile = widget.gameState.grid[row][col];
          final isInPath = selectedWord.path
              .any((pos) => pos.row == row && pos.col == col);

          return Container(
            decoration: BoxDecoration(
              color: isInPath ? Colors.orange : Colors.white,
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: Text(
                tile.letter,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isInPath ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border(
          top: BorderSide(color: Colors.grey.shade400),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showAllWords = !_showAllWords;
                _prepareWordList();
              });
            },
            icon: Icon(_showAllWords ? Icons.visibility_off : Icons.visibility),
            label: Text(_showAllWords ? 'Hide All' : 'Show All'),
          ),
          ElevatedButton.icon(
            onPressed: _shareResults,
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }
}

class WordDisplay {
  final String word;
  final int userScore;
  final int maxScore;
  final bool isFound;
  final List<TilePosition> path;

  WordDisplay({
    required this.word,
    required this.userScore,
    required this.maxScore,
    required this.isFound,
    required this.path,
  });
}

extension GameStateExtension on GameState {
  GameSettings toGameSettings() {
    return GameSettings(
      language: language,
      gridSize: grid.length,
      gameDurationMinutes: gameDurationMinutes,
      playerName: playerName,
    );
  }
}
