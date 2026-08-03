import 'letter_tile.dart';
import 'found_word.dart';

class GameState {
  final List<List<LetterTile>> grid;
  final List<FoundWord> foundWords;
  final int currentScore;
  final DateTime startTime;
  final DateTime? pauseTime;
  final int elapsedSeconds;
  final bool isPaused;
  final bool isFinished;
  final int gameDurationMinutes; // 0 means infinite
  final String language;
  final String playerName;

  const GameState({
    required this.grid,
    required this.foundWords,
    required this.currentScore,
    required this.startTime,
    this.pauseTime,
    required this.elapsedSeconds,
    required this.isPaused,
    required this.isFinished,
    required this.gameDurationMinutes,
    required this.language,
    required this.playerName,
  });

  Map<String, dynamic> toJson() {
    return {
      'grid': grid
          .map((row) => row.map((tile) => tile.toJson()).toList())
          .toList(),
      'foundWords': foundWords.map((w) => w.toJson()).toList(),
      'currentScore': currentScore,
      'startTime': startTime.toIso8601String(),
      'pauseTime': pauseTime?.toIso8601String(),
      'elapsedSeconds': elapsedSeconds,
      'isPaused': isPaused,
      'isFinished': isFinished,
      'gameDurationMinutes': gameDurationMinutes,
      'language': language,
      'playerName': playerName,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      grid: (json['grid'] as List)
          .map((row) => (row as List)
              .map((tile) => LetterTile.fromJson(tile as Map<String, dynamic>))
              .toList())
          .toList(),
      foundWords: (json['foundWords'] as List)
          .map((w) => FoundWord.fromJson(w as Map<String, dynamic>))
          .toList(),
      currentScore: json['currentScore'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
      pauseTime: json['pauseTime'] != null
          ? DateTime.parse(json['pauseTime'] as String)
          : null,
      elapsedSeconds: json['elapsedSeconds'] as int,
      isPaused: json['isPaused'] as bool,
      isFinished: json['isFinished'] as bool,
      gameDurationMinutes: json['gameDurationMinutes'] as int,
      language: json['language'] as String,
      playerName: json['playerName'] as String,
    );
  }

  GameState copyWith({
    List<List<LetterTile>>? grid,
    List<FoundWord>? foundWords,
    int? currentScore,
    DateTime? startTime,
    DateTime? pauseTime,
    int? elapsedSeconds,
    bool? isPaused,
    bool? isFinished,
    int? gameDurationMinutes,
    String? language,
    String? playerName,
  }) {
    return GameState(
      grid: grid ?? this.grid,
      foundWords: foundWords ?? this.foundWords,
      currentScore: currentScore ?? this.currentScore,
      startTime: startTime ?? this.startTime,
      pauseTime: pauseTime ?? this.pauseTime,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isPaused: isPaused ?? this.isPaused,
      isFinished: isFinished ?? this.isFinished,
      gameDurationMinutes: gameDurationMinutes ?? this.gameDurationMinutes,
      language: language ?? this.language,
      playerName: playerName ?? this.playerName,
    );
  }
}
