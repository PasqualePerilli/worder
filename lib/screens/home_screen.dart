import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import '../services/config_service.dart';
import '../services/persistence_service.dart';
import '../services/dictionary_service.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GameSettings _settings;
  final PersistenceService _persistenceService = PersistenceService();
  final DictionaryService _dictionaryService = DictionaryService.getInstance();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final config = await ConfigService.getInstance();
    final savedSettings = await _persistenceService.loadSettings();

    setState(() {
      _settings = savedSettings ??
          GameSettings(
            language: config.defaultLanguage,
            gridSize: config.defaultGridSize,
            gameDurationMinutes: config.defaultGameDurationMinutes,
            playerName: config.defaultPlayerName,
          );
      _isLoading = false;
    });

    // Preload dictionary for selected language
    await _dictionaryService.loadLanguage(_settings.language);
  }

  Future<void> _saveSettings() async {
    await _persistenceService.saveSettings(_settings);
  }

  void _startGame() async {
    await _saveSettings();
    // Clear any saved game to ensure we start fresh with a new grid
    await _persistenceService.clearCurrentGame();
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(settings: _settings),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<ConfigService>(
      future: ConfigService.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final config = snapshot.data!;
        final backgroundColor = _parseColor(config.backgroundHomeColor);

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    const Text(
                      'WORDER',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Player Name
                    _buildInputField(
                      label: 'Player Name',
                      value: _settings.playerName,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(playerName: value);
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Language Picker
                    _buildDropdown<String>(
                      label: 'Language',
                      value: _settings.language,
                      items: const [
                        DropdownMenuItem(value: 'italian', child: Text('Italian')),
                        DropdownMenuItem(value: 'english', child: Text('English')),
                      ],
                      onChanged: (value) async {
                        if (value != null) {
                          setState(() {
                            _settings = _settings.copyWith(language: value);
                          });
                          await _dictionaryService.loadLanguage(value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Time Duration
                    _buildDropdown<int>(
                      label: 'Time for Round',
                      value: _settings.gameDurationMinutes,
                      items: const [
                        DropdownMenuItem(value: 2, child: Text('2 minutes')),
                        DropdownMenuItem(value: 3, child: Text('3 minutes')),
                        DropdownMenuItem(value: 4, child: Text('4 minutes')),
                        DropdownMenuItem(value: 5, child: Text('5 minutes')),
                        DropdownMenuItem(value: 0, child: Text('Infinite')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _settings =
                                _settings.copyWith(gameDurationMinutes: value);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Grid Size
                    _buildDropdown<int>(
                      label: 'Grid Size',
                      value: _settings.gridSize,
                      items: const [
                        DropdownMenuItem(value: 4, child: Text('4x4')),
                        DropdownMenuItem(value: 5, child: Text('5x5')),
                        DropdownMenuItem(value: 6, child: Text('6x6')),
                        DropdownMenuItem(value: 7, child: Text('7x7')),
                        DropdownMenuItem(value: 8, child: Text('8x8')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _settings = _settings.copyWith(gridSize: value);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 48),

                    // Play Button
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _parseColor(config.playButtonColor),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('PLAY'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: value.length),
            ),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}
