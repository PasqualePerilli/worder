import 'letter_tile.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
    };
  }

  factory TilePosition.fromJson(Map<String, dynamic> json) {
    return TilePosition(
      json['row'] as int,
      json['col'] as int,
    );
  }
}

class FoundWord {
  final String word;
  final int score;
  final int maxPossibleScore;
  final List<TilePosition> path;
  final DateTime timestamp;

  const FoundWord({
    required this.word,
    required this.score,
    required this.maxPossibleScore,
    required this.path,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'score': score,
      'maxPossibleScore': maxPossibleScore,
      'path': path.map((p) => p.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FoundWord.fromJson(Map<String, dynamic> json) {
    return FoundWord(
      word: json['word'] as String,
      score: json['score'] as int,
      maxPossibleScore: json['maxPossibleScore'] as int,
      path: (json['path'] as List)
          .map((p) => TilePosition.fromJson(p as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
