import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/game_settings.dart';
import '../models/game_state.dart';

class PersistenceService {
  static const String _settingsKey = 'game_settings';
  static const String _currentGameKey = 'current_game';
  static const String _gameHistoryDir = 'game_history';

  Future<void> saveSettings(GameSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(settings.toJson()));
  }

  Future<GameSettings?> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsJson = prefs.getString(_settingsKey);

    if (settingsJson == null) return null;

    try {
      final Map<String, dynamic> data = json.decode(settingsJson);
      return GameSettings.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveCurrentGame(GameState gameState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentGameKey, json.encode(gameState.toJson()));
  }

  Future<GameState?> loadCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gameJson = prefs.getString(_currentGameKey);

    if (gameJson == null) return null;

    try {
      final Map<String, dynamic> data = json.decode(gameJson);
      return GameState.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentGameKey);
  }

  Future<void> saveCompletedGame(GameState gameState) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final gameHistoryPath = '${directory.path}/$_gameHistoryDir';
      final gameHistoryDir = Directory(gameHistoryPath);

      if (!await gameHistoryDir.exists()) {
        await gameHistoryDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'game_$timestamp.json';
      final file = File('$gameHistoryPath/$filename');

      await file.writeAsString(json.encode(gameState.toJson()));
    } catch (e) {
      // Handle error silently or log it
    }
  }

  Future<List<GameState>> loadGameHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final gameHistoryPath = '${directory.path}/$_gameHistoryDir';
      final gameHistoryDir = Directory(gameHistoryPath);

      if (!await gameHistoryDir.exists()) {
        return [];
      }

      final files = gameHistoryDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      final List<GameState> games = [];
      for (final file in files) {
        try {
          final content = await file.readAsString();
          final data = json.decode(content) as Map<String, dynamic>;
          games.add(GameState.fromJson(data));
        } catch (e) {
          // Skip invalid files
        }
      }

      // Sort by start time, most recent first
      games.sort((a, b) => b.startTime.compareTo(a.startTime));

      return games;
    } catch (e) {
      return [];
    }
  }
}
