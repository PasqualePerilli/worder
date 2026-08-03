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
    // Calculate center region (avoid edges)
    final centerStart = (size * 0.25).floor();
    final centerEnd = (size * 0.75).ceil();

    // Create list of valid positions (not edges)
    final validPositions = <List<int>>[];
    for (int row = 1; row < size - 1; row++) {
      for (int col = 1; col < size - 1; col++) {
        validPositions.add([row, col]);
      }
    }

    // Shuffle positions
    validPositions.shuffle(_random);

    int index = 0;

    // Add triple word (always center for small grids)
    if (size >= 4) {
      final centerRow = size ~/ 2;
      final centerCol = size ~/ 2;
      final tile = grid[centerRow][centerCol];
      grid[centerRow][centerCol] = tile.copyWith(bonusType: BonusType.tripleWord);
    } else if (validPositions.isNotEmpty) {
      final pos = validPositions[index++];
      final tile = grid[pos[0]][pos[1]];
      grid[pos[0]][pos[1]] = tile.copyWith(bonusType: BonusType.tripleWord);
    }

    // Add double words (2)
    for (int i = 0; i < 2 && index < validPositions.length; i++) {
      final pos = validPositions[index++];
      final tile = grid[pos[0]][pos[1]];
      grid[pos[0]][pos[1]] = tile.copyWith(bonusType: BonusType.doubleWord);
    }

    // Add triple letters (2)
    for (int i = 0; i < 2 && index < validPositions.length; i++) {
      final pos = validPositions[index++];
      final tile = grid[pos[0]][pos[1]];
      grid[pos[0]][pos[1]] = tile.copyWith(bonusType: BonusType.tripleLetter);
    }

    // Add double letter (1)
    if (index < validPositions.length) {
      final pos = validPositions[index];
      final tile = grid[pos[0]][pos[1]];
      grid[pos[0]][pos[1]] = tile.copyWith(bonusType: BonusType.doubleLetter);
    }
  }
}
