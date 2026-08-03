import 'dart:math';
import '../models/letter_tile.dart';
import 'dictionary_service.dart';
import 'config_service.dart';

class GridGeneratorService {
  final Random _random = Random();
  final DictionaryService _dictionaryService = DictionaryService.getInstance();

  Future<List<List<LetterTile>>> generateGrid(int size, String language) async {
    final config = await ConfigService.getInstance();
    
    // Try to generate a valid grid with retries
    for (int attempt = 0; attempt < config.maxGenerationRetries; attempt++) {
      final grid = await _generateLetters(size, language, config);
      
      // Validate the grid
      if (_validateGrid(grid, config, language)) {
        // Add bonus tiles
        _addBonusTiles(grid, size);
        return grid;
      }
    }
    
    // Fallback: generate without strict rules if max retries exceeded
    print('Warning: Could not generate grid with strict rules. Using relaxed rules.');
    final grid = await _generateLettersRelaxed(size, language);
    _addBonusTiles(grid, size);
    return grid;
  }

  Future<List<List<LetterTile>>> _generateLetters(
      int size, String language, ConfigService config) async {
    final List<List<LetterTile>> grid = [];
    final frequencies = _dictionaryService.getLetterFrequencies(language);
    final letters = frequencies.keys.toList();
    final Map<String, int> letterCounts = {};

    // Classify letters as common or uncommon
    final commonLetters = <String>[];
    final uncommonLetters = <String>[];
    for (final letter in letters) {
      if (frequencies[letter]! >= config.uncommonThreshold) {
        commonLetters.add(letter);
      } else {
        uncommonLetters.add(letter);
      }
    }

    // Create cumulative frequency distribution
    final cumulativeFreq = <double>[];
    double sum = 0;
    for (final letter in letters) {
      sum += frequencies[letter]!;
      cumulativeFreq.add(sum);
    }

    // Generate grid with distribution constraints
    for (int row = 0; row < size; row++) {
      final List<LetterTile> rowList = [];
      for (int col = 0; col < size; col++) {
        String? selectedLetter;
        int attempts = 0;
        
        // Try to select a valid letter
        while (selectedLetter == null && attempts < 50) {
          attempts++;
          final candidate = _selectLetterByFrequency(
              letters, cumulativeFreq, sum, language);
          
          // Check occurrence limits
          final currentCount = letterCounts[candidate] ?? 0;
          final isUncommon = uncommonLetters.contains(candidate);
          final maxOccurrences = isUncommon
              ? config.maxUncommonLetterOccurrences
              : config.maxCommonLetterOccurrences;
          
          if (currentCount >= maxOccurrences) {
            continue; // Try another letter
          }
          
          // Check for consecutive identical letters
          if (_wouldCreateConsecutive(grid, row, col, candidate, config.minDistanceSameLetter)) {
            continue; // Try another letter
          }
          
          selectedLetter = candidate;
        }
        
        // Fallback: if we couldn't find a valid letter, use a common one
        if (selectedLetter == null) {
          selectedLetter = commonLetters[_random.nextInt(commonLetters.length)];
        }
        
        // Update count
        letterCounts[selectedLetter] = (letterCounts[selectedLetter] ?? 0) + 1;
        
        final value = _dictionaryService.getLetterValue(selectedLetter, language);
        rowList.add(LetterTile(
          letter: selectedLetter,
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

  Future<List<List<LetterTile>>> _generateLettersRelaxed(int size, String language) async {
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

    // Generate grid with weighted random selection (original logic)
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

  bool _wouldCreateConsecutive(List<List<LetterTile>> grid, int row, int col,
      String letter, int minDistance) {
    // Check horizontal (left neighbor)
    if (col > 0 && grid[row][col - 1].letter == letter) {
      // Check if this would create 3+ consecutive
      if (col > 1 && grid[row][col - 2].letter == letter) {
        return true; // Would create 3 consecutive horizontally
      }
    }

    // Check vertical (top neighbor)
    if (row > 0 && grid[row - 1][col].letter == letter) {
      // Check if this would create 3+ consecutive
      if (row > 1 && grid[row - 2][col].letter == letter) {
        return true; // Would create 3 consecutive vertically
      }
    }

    // Check diagonal top-left
    if (row > 0 && col > 0 && grid[row - 1][col - 1].letter == letter) {
      if (row > 1 && col > 1 && grid[row - 2][col - 2].letter == letter) {
        return true; // Would create 3 consecutive diagonally
      }
    }

    // Check diagonal top-right
    if (row > 0 && col < grid[row - 1].length - 1 && grid[row - 1][col + 1].letter == letter) {
      if (row > 1 && col < grid[row - 2].length - 2 && grid[row - 2][col + 2].letter == letter) {
        return true; // Would create 3 consecutive diagonally
      }
    }

    return false;
  }

  bool _validateGrid(List<List<LetterTile>> grid, ConfigService config, String language) {
    final frequencies = _dictionaryService.getLetterFrequencies(language);
    final Map<String, int> letterCounts = {};

    // Count all letters
    for (final row in grid) {
      for (final tile in row) {
        letterCounts[tile.letter] = (letterCounts[tile.letter] ?? 0) + 1;
      }
    }

    // Check occurrence limits
    for (final entry in letterCounts.entries) {
      final letter = entry.key;
      final count = entry.value;
      final frequency = frequencies[letter] ?? 0;
      final isUncommon = frequency < config.uncommonThreshold;
      final maxOccurrences = isUncommon
          ? config.maxUncommonLetterOccurrences
          : config.maxCommonLetterOccurrences;

      if (count > maxOccurrences) {
        return false; // Too many occurrences
      }
    }

    // Check for 3+ consecutive identical letters
    for (int row = 0; row < grid.length; row++) {
      for (int col = 0; col < grid[row].length; col++) {
        // Check horizontal
        if (col <= grid[row].length - 3) {
          if (grid[row][col].letter == grid[row][col + 1].letter &&
              grid[row][col].letter == grid[row][col + 2].letter) {
            return false;
          }
        }
        // Check vertical
        if (row <= grid.length - 3) {
          if (grid[row][col].letter == grid[row + 1][col].letter &&
              grid[row][col].letter == grid[row + 2][col].letter) {
            return false;
          }
        }
        // Check diagonal (top-left to bottom-right)
        if (row <= grid.length - 3 && col <= grid[row].length - 3) {
          if (grid[row][col].letter == grid[row + 1][col + 1].letter &&
              grid[row][col].letter == grid[row + 2][col + 2].letter) {
            return false;
          }
        }
        // Check diagonal (top-right to bottom-left)
        if (row <= grid.length - 3 && col >= 2) {
          if (grid[row][col].letter == grid[row + 1][col - 1].letter &&
              grid[row][col].letter == grid[row + 2][col - 2].letter) {
            return false;
          }
        }
      }
    }

    return true;
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
