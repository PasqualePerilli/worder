import 'package:flutter/services.dart';

class DictionaryService {
  static DictionaryService? _instance;
  final Map<String, Set<String>> _dictionaries = {};
  final Map<String, Map<String, int>> _letterValues = {};
  final Map<String, Map<String, double>> _letterFrequencies = {};

  DictionaryService._();

  static DictionaryService getInstance() {
    _instance ??= DictionaryService._();
    return _instance!;
  }

  Future<void> loadLanguage(String language) async {
    if (!_dictionaries.containsKey(language)) {
      await _loadDictionary(language);
      await _loadLetterValues(language);
      await _loadLetterFrequencies(language);
    }
  }

  Future<void> _loadDictionary(String language) async {
    final String content =
        await rootBundle.loadString('assets/words/$language.txt');
    final List<String> words =
        content.split('\n').where((w) => w.trim().isNotEmpty).toList();
    _dictionaries[language] =
        words.map((w) => w.trim().toUpperCase()).toSet();
  }

  Future<void> _loadLetterValues(String language) async {
    final String content =
        await rootBundle.loadString('assets/letter_values/$language.txt');
    final Map<String, int> values = {};

    for (String line in content.split('\n')) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final parts = line.split('=');
      if (parts.length == 2) {
        values[parts[0].trim()] = int.parse(parts[1].trim());
      }
    }

    _letterValues[language] = values;
  }

  Future<void> _loadLetterFrequencies(String language) async {
    final String content =
        await rootBundle.loadString('assets/letter_frequencies/$language.txt');
    final Map<String, double> frequencies = {};

    for (String line in content.split('\n')) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final parts = line.split('=');
      if (parts.length == 2) {
        frequencies[parts[0].trim()] = double.parse(parts[1].trim());
      }
    }

    _letterFrequencies[language] = frequencies;
  }

  bool isValidWord(String word, String language) {
    return _dictionaries[language]?.contains(word.toUpperCase()) ?? false;
  }

  int getLetterValue(String letter, String language) {
    return _letterValues[language]?[letter] ?? 1;
  }

  Map<String, double> getLetterFrequencies(String language) {
    return _letterFrequencies[language] ?? {};
  }

  Set<String> getAllWords(String language) {
    return _dictionaries[language] ?? {};
  }

  List<String> getAvailableLetters(String language) {
    return (_letterValues[language]?.keys.toList() ?? [])..sort();
  }
}
