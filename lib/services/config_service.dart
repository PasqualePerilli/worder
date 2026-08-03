import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class ConfigService {
  static ConfigService? _instance;
  late Map<String, dynamic> _config;

  ConfigService._();

  static Future<ConfigService> getInstance() async {
    if (_instance == null) {
      _instance = ConfigService._();
      await _instance!._loadConfig();
    }
    return _instance!;
  }

  Future<void> _loadConfig() async {
    final String yamlString =
        await rootBundle.loadString('assets/config/settings.yaml');
    final dynamic yamlData = loadYaml(yamlString);
    _config = json.decode(json.encode(yamlData)) as Map<String, dynamic>;
  }

  int get invalidWordShakeDuration =>
      (_config['animations']?['invalid_word_shake_duration'] as int?) ?? 500;

  double get tilePopupScale =>
      ((_config['animations']?['tile_popup_scale'] as num?) ?? 1.15).toDouble();

  int get previewBarSuccessDuration =>
      (_config['animations']?['preview_bar_success_duration'] as int?) ?? 800;

  int get previewBarErrorDuration =>
      (_config['animations']?['preview_bar_error_duration'] as int?) ?? 500;

  int get addedTimeOverlayDuration =>
      (_config['animations']?['added_time_overlay_duration'] as int?) ?? 1500;

  int get minWordLength => (_config['grid']?['min_word_length'] as int?) ?? 2;

  int get tripleWordCount =>
      (_config['grid']?['bonus_tiles']?['triple_word_count'] as int?) ?? 1;

  int get doubleWordCount =>
      (_config['grid']?['bonus_tiles']?['double_word_count'] as int?) ?? 2;

  int get tripleLetterCount =>
      (_config['grid']?['bonus_tiles']?['triple_letter_count'] as int?) ?? 2;

  int get doubleLetterCount =>
      (_config['grid']?['bonus_tiles']?['double_letter_count'] as int?) ?? 1;

  String get tripleWordColor =>
      (_config['colors']?['triple_word'] as String?) ?? '#FF0000';

  String get doubleWordColor =>
      (_config['colors']?['double_word'] as String?) ?? '#FFFF00';

  String get tripleLetterColor =>
      (_config['colors']?['triple_letter'] as String?) ?? '#0000FF';

  String get doubleLetterColor =>
      (_config['colors']?['double_letter'] as String?) ?? '#00FF00';

  String get selectedTileColor =>
      (_config['colors']?['selected_tile'] as String?) ?? '#FFA500';

  String get backgroundGameColor =>
      (_config['colors']?['background_game'] as String?) ?? '#ADD8E6';

  String get backgroundHomeColor =>
      (_config['colors']?['background_home'] as String?) ?? '#ADD8E6';

  String get playButtonColor =>
      (_config['colors']?['play_button'] as String?) ?? '#FFA500';

  String get previewBarSuccessColor =>
      (_config['colors']?['preview_bar_success'] as String?) ?? '#00FF00';

  String get previewBarErrorColor =>
      (_config['colors']?['preview_bar_error'] as String?) ?? '#FF0000';

  String get previewBarDefaultColor =>
      (_config['colors']?['preview_bar_default'] as String?) ?? '#FFA500';

  String get defaultLanguage =>
      (_config['defaults']?['language'] as String?) ?? 'italian';

  int get defaultGridSize => (_config['defaults']?['grid_size'] as int?) ?? 4;

  int get defaultGameDurationMinutes =>
      (_config['defaults']?['game_duration_minutes'] as int?) ?? 2;

  String get defaultPlayerName =>
      (_config['defaults']?['player_name'] as String?) ?? 'Player';

  int get topWordsCount => (_config['share']?['top_words_count'] as int?) ?? 10;
}
