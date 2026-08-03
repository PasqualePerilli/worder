import 'dart:math';
import '../models/letter_tile.dart';
import 'dictionary_service.dart';

class GridGeneratorService {
  final Random _random = Random();
  final DictionaryService _dictionaryService = DictionaryService.getInstance();

  List<List<LetterTile>> generateGrid(int size, String language) {
    // Generate letter grid with proper distribution
    final List<List<LetterTile>> grid = _generateLetters(size, language);

    // Add bonus tiles
    _addBonusTiles(grid, size);

    return grid;
  }

  List<List<LetterTile>> _generateLetters(int size, String language) {
    final List<List<LetterTile>> grid = [];
    final frequencies = _dictionaryService.getLetterFrequencies(language);
    final letters = frequencies.keys.toList();

    // Create cumulative frequency distribution
    final cumulativeFreq = <double>[];
    double sum = 0;
    for (final letter in letters) {
      sum += frequencies[letter]!;
      cumulativeFreq.add(sum);
    }

    // Generate grid with weighted random selection
    for (int row = 0; row < size; row++) {
      final List<LetterTile> rowList = [];
      for (int col = 0; col < size; col++) {
        final letter = _selectLetterByFrequency(
            letters, cumulativeFreq, sum, language);
        final value = _dictionaryService.getLetterValue(letter, language);

        rowList.add(LetterTile(
          letter: letter,
          value: value,
          bonusType: BonusType.none,
          row: row,
          col: col,
        ));
      }
      grid.add(rowList);
    }

    return grid;
  }

  String _selectLetterByFrequency(List<String> letters,
      List<double> cumulativeFreq, double total, String language) {
    final random = _random.nextDouble() * total;

    for (int i = 0; i < cumulativeFreq.length; i++) {
      if (random <= cumulativeFreq[i]) {
        return letters[i];
      }
    }

    return letters.last;
  }

  void _addBonusTiles(List<List<LetterTile>> grid, int size) {
    // Create list of all positions (for triple/double letters - can be anywhere)
    final allPositions = <List<int>>[];
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        allPositions.add([row, col]);
      }
    }

    // Create list of center positions (not edges) for word bonuses
    final centerPositions = <List<int>>[];
    for (int row = 1; row < size - 1; row++) {
      for (int col = 1; col < size - 1; col++) {
        centerPositions.add([row, col]);
      }
    }

    // Shuffle both lists
    allPositions.shuffle(_random);
    centerPositions.shuffle(_random);

    // 1. Add triple word (3*) - ALWAYS in center
    final centerRow = size ~/ 2;
    final centerCol = size ~/ 2;
    grid[centerRow][centerCol] = grid[centerRow][centerCol].copyWith(
      bonusType: BonusType.tripleWord,
    );

    // Remove center position from available positions
    centerPositions.removeWhere((pos) => pos[0] == centerRow && pos[1] == centerCol);
    allPositions.removeWhere((pos) => pos[0] == centerRow && pos[1] == centerCol);

    // 2. Add double words (2*) - two in center area (away from edges)
    for (int i = 0; i < 2 && i < centerPositions.length; i++) {
      final pos = centerPositions[i];
      grid[pos[0]][pos[1]] = grid[pos[0]][pos[1]].copyWith(
        bonusType: BonusType.doubleWord,
      );
      allPositions.removeWhere((p) => p[0] == pos[0] && p[1] == pos[1]);
    }

    // 3. Add triple letters (3 circle) - two anywhere
    for (int i = 0; i < 2 && i < allPositions.length; i++) {
      final pos = allPositions[i];
      grid[pos[0]][pos[1]] = grid[pos[0]][pos[1]].copyWith(
        bonusType: BonusType.tripleLetter,
      );
    }

    // 4. Add double letter (2 circle) - one anywhere
    if (allPositions.length > 2) {
      final pos = allPositions[2];
      grid[pos[0]][pos[1]] = grid[pos[0]][pos[1]].copyWith(
        bonusType: BonusType.doubleLetter,
      );
    }
  }
}
