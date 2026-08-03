class GameSettings {
  final String language;
  final int gridSize;
  final int gameDurationMinutes; // 0 means infinite
  final String playerName;

  const GameSettings({
    required this.language,
    required this.gridSize,
    required this.gameDurationMinutes,
    required this.playerName,
  });

  factory GameSettings.defaultSettings() {
    return const GameSettings(
      language: 'italian',
      gridSize: 4,
      gameDurationMinutes: 2,
      playerName: 'Player',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'gridSize': gridSize,
      'gameDurationMinutes': gameDurationMinutes,
      'playerName': playerName,
    };
  }

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      language: json['language'] as String,
      gridSize: json['gridSize'] as int,
      gameDurationMinutes: json['gameDurationMinutes'] as int,
      playerName: json['playerName'] as String,
    );
  }

  GameSettings copyWith({
    String? language,
    int? gridSize,
    int? gameDurationMinutes,
    String? playerName,
  }) {
    return GameSettings(
      language: language ?? this.language,
      gridSize: gridSize ?? this.gridSize,
      gameDurationMinutes: gameDurationMinutes ?? this.gameDurationMinutes,
      playerName: playerName ?? this.playerName,
    );
  }
}
