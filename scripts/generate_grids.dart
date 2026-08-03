import 'dart:io';
import 'dart:convert';
import 'dart:math';

/// Script to pre-generate 1000 valid grids for each language and size
/// Run with: dart scripts/generate_grids.dart
void main() async {
  final generator = GridPreGenerator();
  
  final languages = ['italian', 'english'];
  final sizes = [4, 5, 6, 7, 8];
  
  for (final language in languages) {
    print('\n=== Generating grids for $language ===');
    
    // Load letter frequencies
    final frequencies = await _loadLetterFrequencies(language);
    
    for (final size in sizes) {
      print('Generating ${size}x$size grids...');
      final grids = generator.generateValidGrids(size, language, frequencies, 1000);
      
      // Save to JSON file
      final outputPath = 'assets/pregenerated_grids/${language}_${size}x$size.json';
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      
      final jsonData = {
        'language': language,
        'size': size,
        'count': grids.length,
        'grids': grids.map((g) => _gridToJson(g)).toList(),
      };
      
      await file.writeAsString(JsonEncoder.withIndent('  ').convert(jsonData));
      print('  ✓ Saved ${grids.length} grids to $outputPath');
    }
  }
  
  print('\n✓ All grids generated successfully!');
}

Future<Map<String, double>> _loadLetterFrequencies(String language) async {
  final file = File('assets/letter_frequencies/$language.txt');
  final lines = await file.readAsLines();
  final frequencies = <String, double>{};
  
  for (final line in lines) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length == 2) {
      frequencies[parts[0].trim()] = double.parse(parts[1].trim());
    }
  }
  
  return frequencies;
}

int _getLetterValue(String letter, String language, Map<String, double> frequencies) {
  final frequency = frequencies[letter] ?? 0.0;
  
  // Score based on rarity (inverse of frequency)
  if (frequency >= 10.0) return 1;
  if (frequency >= 7.0) return 2;
  if (frequency >= 5.0) return 3;
  if (frequency >= 3.0) return 4;
  if (frequency >= 2.0) return 5;
  if (frequency >= 1.0) return 7;
  return 10;
}

List<List<Map<String, dynamic>>> _gridToJson(List<List<GridTile>> grid) {
  return grid.map((row) => 
    row.map((tile) => {
      'letter': tile.letter,
      'value': tile.value,
    }).toList()
  ).toList();
}

class GridTile {
  final String letter;
  final int value;
  
  GridTile(this.letter, this.value);
}

class GridPreGenerator {
  final Random _random = Random();
  
  List<List<List<GridTile>>> generateValidGrids(
    int size, 
    String language, 
    Map<String, double> frequencies,
    int count,
  ) {
    final validGrids = <List<List<GridTile>>>[];
    int attempts = 0;
    final maxAttempts = count * 10; // Try up to 10x the target
    
    while (validGrids.length < count && attempts < maxAttempts) {
      attempts++;
      final grid = _generateSingleGrid(size, language, frequencies);
      
      if (_isValidGrid(grid, frequencies, language)) {
        validGrids.add(grid);
        if (validGrids.length % 100 == 0) {
          print('  Generated ${validGrids.length}/$count...');
        }
      }
    }
    
    if (validGrids.length < count) {
      print('  Warning: Only generated ${validGrids.length}/$count valid grids');
    }
    
    return validGrids;
  }
  
  List<List<GridTile>> _generateSingleGrid(
    int size, 
    String language, 
    Map<String, double> frequencies,
  ) {
    final letters = frequencies.keys.toList();
    
    // Create cumulative frequency distribution
    final cumulativeFreq = <double>[];
    double sum = 0;
    for (final letter in letters) {
      sum += frequencies[letter]!;
      cumulativeFreq.add(sum);
    }
    
    // Generate grid with weighted random selection
    final grid = <List<GridTile>>[];
    for (int row = 0; row < size; row++) {
      final rowList = <GridTile>[];
      for (int col = 0; col < size; col++) {
        final letter = _selectLetterByFrequency(letters, cumulativeFreq, sum);
        final value = _getLetterValue(letter, language, frequencies);
        rowList.add(GridTile(letter, value));
      }
      grid.add(rowList);
    }
    
    return grid;
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
  
  bool _isValidGrid(List<List<GridTile>> grid, Map<String, double> frequencies, String language) {
    final letterCounts = <String, int>{};
    final gridSize = grid.length;
    
    // Count all letters
    for (final row in grid) {
      for (final tile in row) {
        letterCounts[tile.letter] = (letterCounts[tile.letter] ?? 0) + 1;
      }
    }
    
    // Scale max occurrences for larger grids
    final maxUncommonForSize = gridSize <= 5 ? 2 : (gridSize == 6 ? 3 : (gridSize == 7 ? 4 : 5));
    final maxCommonForSize = gridSize <= 5 ? 4 : (gridSize == 6 ? 6 : (gridSize == 7 ? 8 : 10));
    
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
      [0, gridSize - 1],          // Top-right
      [gridSize - 1, 0],          // Bottom-left
      [gridSize - 1, gridSize - 1], // Bottom-right
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
        if (row < gridSize - 1) adjacentPositions.add([row + 1, col]); // Down
        if (col > 0) adjacentPositions.add([row, col - 1]);           // Left
        if (col < gridSize - 1) adjacentPositions.add([row, col + 1]); // Right
        if (row > 0 && col > 0) adjacentPositions.add([row - 1, col - 1]);         // Up-left
        if (row > 0 && col < gridSize - 1) adjacentPositions.add([row - 1, col + 1]); // Up-right
        if (row < gridSize - 1 && col > 0) adjacentPositions.add([row + 1, col - 1]); // Down-left
        if (row < gridSize - 1 && col < gridSize - 1) adjacentPositions.add([row + 1, col + 1]); // Down-right
        
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
}
