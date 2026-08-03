import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/letter_tile.dart';
import 'dictionary_service.dart';

class GridGeneratorService {
  final Random _random = Random();
  final DictionaryService _dictionaryService = DictionaryService.getInstance();
  
  // Cache loaded grids to avoid reloading
  final Map<String, List<List<List<LetterTile>>>> _gridCache = {};

  Future<List<List<LetterTile>>> generateGrid(int size, String language) async {
    print('GridGenerator: Starting grid generation (size: $size, language: $language)');
    
    // Try runtime generation first (up to 10 attempts)
    for (int attempt = 0; attempt < 10; attempt++) {
      final grid = _generateSingleGrid(size, language);
      
      if (_isValidGrid(grid, size, language)) {
        print('GridGenerator: Successfully generated valid grid on attempt ${attempt + 1}');
        _addBonusTiles(grid, size);
        return grid;
      }
    }
    
    // Fallback to pre-generated grids
    print('GridGenerator: Runtime generation failed, loading pre-generated grid');
    try {
      final grids = await _loadPregeneratedGrids(size, language);
      
      if (grids.isNotEmpty) {
        final selectedGrid = grids[_random.nextInt(grids.length)];
        print('GridGenerator: Selected pre-generated grid from ${grids.length} available');
        _addBonusTiles(selectedGrid, size);
        return selectedGrid;
      }
    } catch (e) {
      print('GridGenerator: Error loading pre-generated grids: $e');
    }
    
    // Last resort: simple grid with no validation
    print('GridGenerator: All methods failed, generating simple unconstrained grid');
    final grid = _generateSingleGrid(size, language);
    _addBonusTiles(grid, size);
    return grid;
  }
  
  Future<List<List<List<LetterTile>>>> _loadPregeneratedGrids(int size, String language) async {
    final cacheKey = '${language}_${size}x$size';
    
    // Return from cache if already loaded
    if (_gridCache.containsKey(cacheKey)) {
      return _gridCache[cacheKey]!;
    }
    
    // Load from assets
    final path = 'assets/pregenerated_grids/${language}_${size}x$size.json';
    final jsonString = await rootBundle.loadString(path);
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final gridsJson = jsonData['grids'] as List;
    
    // Parse grids
    final grids = <List<List<LetterTile>>>[];
    for (final gridJson in gridsJson) {
      final grid = (gridJson as List).map((rowJson) {
        return (rowJson as List).map((tileJson) {
          final tile = tileJson as Map<String, dynamic>;
          return LetterTile(
            letter: tile['letter'] as String,
            value: tile['value'] as int,
            bonusType: BonusType.none,
            row: 0, // Will be set by index
            col: 0, // Will be set by index
          );
        }).toList();
      }).toList();
      
      // Set row/col indices
      for (int row = 0; row < grid.length; row++) {
        for (int col = 0; col < grid[row].length; col++) {
          grid[row][col] = grid[row][col].copyWith(row: row, col: col);
        }
      }
      
      grids.add(grid);
    }
    
    // Cache and return
    _gridCache[cacheKey] = grids;
    return grids;
  }
  
  // Generate a single grid using simple weighted random selection
  List<List<LetterTile>> _generateSingleGrid(int size, String language) {
    final frequencies = _dictionaryService.getLetterFrequencies(language);
    final letters = frequencies.keys.toList();
    
    // Create cumulative frequency distribution
    final cumulativeFreq = <double>[];
    double sum = 0;
    for (final letter in letters) {
      sum += frequencies[letter]!;
      cumulativeFreq.add(sum);
    }
    
    // Generate grid with weighted random selection (no constraints during generation)
    final grid = <List<LetterTile>>[];
    for (int row = 0; row < size; row++) {
      final rowList = <LetterTile>[];
      for (int col = 0; col < size; col++) {
        final letter = _selectLetterByFrequency(letters, cumulativeFreq, sum);
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
  
  // Validate a generated grid
  bool _isValidGrid(List<List<LetterTile>> grid, int size, String language) {
    final frequencies = _dictionaryService.getLetterFrequencies(language);
    final letterCounts = <String, int>{};
    
    // Count all letters
    for (final row in grid) {
      for (final tile in row) {
        letterCounts[tile.letter] = (letterCounts[tile.letter] ?? 0) + 1;
      }
    }
    
    // Scale max occurrences for larger grids
    final maxUncommonForSize = size <= 5 ? 2 : (size == 6 ? 3 : (size == 7 ? 4 : 5));
    final maxCommonForSize = size <= 5 ? 4 : (size == 6 ? 6 : (size == 7 ? 8 : 10));
    
    // Check occurrence limits
    for (final entry in letterCounts.entries) {
      final letter = entry.key;
      final count = entry.value;
      final frequency = frequencies[letter] ?? 0;
      final isUncommon = frequency < 3.0;
      final maxOccurrences = isUncommon ? maxUncommonForSize : maxCommonForSize;
      
      if (count > maxOccurrences) {
        return false;
      }
    }
    
    // Check for 3+ consecutive identical letters in all directions
    for (int row = 0; row < grid.length; row++) {
      for (int col = 0; col < grid[row].length; col++) {
        // Horizontal
        if (col <= grid[row].length - 3) {
          if (grid[row][col].letter == grid[row][col + 1].letter &&
              grid[row][col].letter == grid[row][col + 2].letter) {
            return false;
          }
        }
        // Vertical
        if (row <= grid.length - 3) {
          if (grid[row][col].letter == grid[row + 1][col].letter &&
              grid[row][col].letter == grid[row + 2][col].letter) {
            return false;
          }
        }
        // Diagonal (top-left to bottom-right)
        if (row <= grid.length - 3 && col <= grid[row].length - 3) {
          if (grid[row][col].letter == grid[row + 1][col + 1].letter &&
              grid[row][col].letter == grid[row + 2][col + 2].letter) {
            return false;
          }
        }
        // Diagonal (top-right to bottom-left)
        if (row <= grid.length - 3 && col >= 2) {
          if (grid[row][col].letter == grid[row + 1][col - 1].letter &&
              grid[row][col].letter == grid[row + 2][col - 2].letter) {
            return false;
          }
        }
      }
    }
    
    // Check corner letters: if corner is consonant, at least one adjacent should be vowel
    final vowels = language == 'italian' 
        ? {'A', 'E', 'I', 'O', 'U'} 
        : {'A', 'E', 'I', 'O', 'U', 'Y'};
    
    final corners = [
      [0, 0],                     // Top-left
      [0, size - 1],              // Top-right
      [size - 1, 0],              // Bottom-left
      [size - 1, size - 1],       // Bottom-right
    ];
    
    for (final corner in corners) {
      final row = corner[0];
      final col = corner[1];
      final cornerLetter = grid[row][col].letter;
      
      // If corner is consonant, check adjacent tiles
      if (!vowels.contains(cornerLetter)) {
        final adjacentPositions = <List<int>>[];
        
        // Add all adjacent positions for this corner
        if (row > 0) adjacentPositions.add([row - 1, col]);           // Up
        if (row < size - 1) adjacentPositions.add([row + 1, col]);    // Down
        if (col > 0) adjacentPositions.add([row, col - 1]);           // Left
        if (col < size - 1) adjacentPositions.add([row, col + 1]);    // Right
        if (row > 0 && col > 0) adjacentPositions.add([row - 1, col - 1]);         // Up-left
        if (row > 0 && col < size - 1) adjacentPositions.add([row - 1, col + 1]);  // Up-right
        if (row < size - 1 && col > 0) adjacentPositions.add([row + 1, col - 1]);  // Down-left
        if (row < size - 1 && col < size - 1) adjacentPositions.add([row + 1, col + 1]); // Down-right
        
        // Check if at least one adjacent is a vowel
        bool hasAdjacentVowel = false;
        for (final pos in adjacentPositions) {
          if (vowels.contains(grid[pos[0]][pos[1]].letter)) {
            hasAdjacentVowel = true;
            break;
          }
        }
        
        if (!hasAdjacentVowel) {
          return false; // Corner consonant has no adjacent vowel
        }
      }
    }
    
    return true;
  }
  
  String _selectLetterByFrequency(List<String> letters, List<double> cumulativeFreq, double total) {
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
