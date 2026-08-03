import '../models/letter_tile.dart';
import '../models/found_word.dart';
import 'dictionary_service.dart';

class ScoreCalculatorService {
  final DictionaryService _dictionaryService = DictionaryService.getInstance();

  int calculateWordScore(
    List<LetterTile> tiles,
    String language,
  ) {
    int baseScore = 0;
    int wordMultiplier = 1;

    for (final tile in tiles) {
      int letterScore = tile.value;

      // Apply letter multipliers
      switch (tile.bonusType) {
        case BonusType.doubleLetter:
          letterScore *= 2;
          break;
        case BonusType.tripleLetter:
          letterScore *= 3;
          break;
        case BonusType.doubleWord:
          wordMultiplier *= 2;
          break;
        case BonusType.tripleWord:
          wordMultiplier *= 3;
          break;
        case BonusType.none:
          break;
      }

      baseScore += letterScore;
    }

    return baseScore * wordMultiplier;
  }

  int calculateMaxPossibleScore(
    String word,
    List<List<LetterTile>> grid,
    String language,
  ) {
    // Find all possible paths for this word and return the highest score
    final paths = _findAllPathsForWord(word, grid, language);
    
    if (paths.isEmpty) return 0;

    int maxScore = 0;
    for (final path in paths) {
      final tiles = path.map((pos) => grid[pos.row][pos.col]).toList();
      final score = calculateWordScore(tiles, language);
      if (score > maxScore) {
        maxScore = score;
      }
    }

    return maxScore;
  }

  /// Get the path that produces the maximum score for a word
  List<TilePosition> getBestPathForWord(
    String word,
    List<List<LetterTile>> grid,
    String language,
  ) {
    final paths = _findAllPathsForWord(word, grid, language);
    
    if (paths.isEmpty) return [];

    int maxScore = 0;
    List<TilePosition> bestPath = [];
    
    for (final path in paths) {
      final tiles = path.map((pos) => grid[pos.row][pos.col]).toList();
      final score = calculateWordScore(tiles, language);
      if (score > maxScore) {
        maxScore = score;
        bestPath = path;
      }
    }

    return bestPath;
  }

  List<List<TilePosition>> _findAllPathsForWord(
    String word,
    List<List<LetterTile>> grid,
    String language,
  ) {
    final List<List<TilePosition>> allPaths = [];
    final size = grid.length;
    word = word.toUpperCase();

    // Try starting from each position
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col].letter == word[0]) {
          final path = <TilePosition>[];
          final visited = <TilePosition>{};
          _dfsSearch(word, 0, row, col, grid, path, visited, allPaths);
        }
      }
    }

    return allPaths;
  }

  void _dfsSearch(
    String word,
    int index,
    int row,
    int col,
    List<List<LetterTile>> grid,
    List<TilePosition> currentPath,
    Set<TilePosition> visited,
    List<List<TilePosition>> allPaths,
  ) {
    final size = grid.length;
    final pos = TilePosition(row, col);

    if (row < 0 || row >= size || col < 0 || col >= size) return;
    if (visited.contains(pos)) return;
    if (grid[row][col].letter != word[index]) return;

    currentPath.add(pos);
    visited.add(pos);

    if (index == word.length - 1) {
      // Found complete word
      allPaths.add(List.from(currentPath));
    } else {
      // Continue searching adjacent tiles
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          _dfsSearch(
            word,
            index + 1,
            row + dr,
            col + dc,
            grid,
            currentPath,
            visited,
            allPaths,
          );
        }
      }
    }

    currentPath.removeLast();
    visited.remove(pos);
  }
}
