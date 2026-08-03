import 'package:flutter/material.dart';
import '../models/letter_tile.dart';
import '../services/config_service.dart';

class TileWidget extends StatelessWidget {
  final LetterTile tile;
  final bool isSelected;
  final bool isHighlighted;
  final int gridSize;

  const TileWidget({
    super.key,
    required this.tile,
    this.isSelected = false,
    this.isHighlighted = false,
    required this.gridSize,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConfigService>(
      future: ConfigService.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final config = snapshot.data!;
        final scale = isSelected ? config.tilePopupScale : 1.0;

        final borderWidth = tile.bonusType != BonusType.none
            ? 6.0  // Triple size for bonus tiles
            : (isSelected || isHighlighted ? 3.0 : 2.0);

        return Transform.scale(
          scale: scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(config),
                  border: Border.all(
                    color: _getBorderColor(config),
                    width: borderWidth,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    // Letter
                    Center(
                      child: Text(
                        tile.letter,
                        style: TextStyle(
                          fontSize: _getLetterFontSize(),
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // Letter value (bottom right)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Text(
                        '${tile.value}',
                        style: TextStyle(
                          fontSize: _getValueFontSize(),
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bonus indicator (extends outside tile)
              if (tile.bonusType != BonusType.none)
                Positioned(
                  top: -8,
                  right: -8,
                  child: _buildBonusIndicator(config),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(ConfigService config) {
    if (isSelected || isHighlighted) {
      return _parseColor(config.selectedTileColor);
    }

    // Always white background - only border is colored for bonus tiles
    return Colors.white;
  }

  Color _getBorderColor(ConfigService config) {
    if (isSelected || isHighlighted) {
      return _parseColor(config.selectedTileColor);
    }

    switch (tile.bonusType) {
      case BonusType.tripleWord:
        return _parseColor(config.tripleWordColor);
      case BonusType.doubleWord:
        return _parseColor(config.doubleWordColor);
      case BonusType.tripleLetter:
        return _parseColor(config.tripleLetterColor);
      case BonusType.doubleLetter:
        return _parseColor(config.doubleLetterColor);
      case BonusType.none:
        return Colors.grey;
    }
  }

  Widget _buildBonusIndicator(ConfigService config) {
    final isWordBonus = tile.bonusType == BonusType.tripleWord ||
        tile.bonusType == BonusType.doubleWord;
    final multiplier = tile.bonusType == BonusType.tripleWord ||
            tile.bonusType == BonusType.tripleLetter
        ? 3
        : 2;

    final indicatorSize = _getBonusIndicatorSize();
    final numberFontSize = _getBonusNumberFontSize();

    if (isWordBonus) {
      // Star for word bonuses with number inside
      return SizedBox(
        width: indicatorSize,
        height: indicatorSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.star,
              size: indicatorSize,
              color: _getBorderColor(config),
            ),
            Text(
              '$multiplier',
              style: TextStyle(
                fontSize: numberFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else {
      // Circle for letter bonuses with number inside
      return Container(
        width: indicatorSize,
        height: indicatorSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getBorderColor(config),
        ),
        child: Center(
          child: Text(
            '$multiplier',
            style: TextStyle(
              fontSize: numberFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }
  double _getLetterFontSize() {
    // Scale down letter size for larger grids
    switch (gridSize) {
      case 4:
        return 26.0;
      case 5:
        return 20.0;
      case 6:
        return 15.0;
      case 7:
        return 12.0;
      case 8:
        return 10.0;
      default:
        return 20.0;
    }
  }

  double _getValueFontSize() {
    // Scale down value size for larger grids
    switch (gridSize) {
      case 4:
        return 10.0;
      case 5:
        return 8.0;
      case 6:
        return 7.0;
      case 7:
        return 6.0;
      case 8:
        return 5.0;
      default:
        return 8.0;
    }
  }

  double _getBonusIndicatorSize() {
    // Scale down bonus indicator for larger grids
    switch (gridSize) {
      case 4:
        return 28.0;
      case 5:
        return 20.0;
      case 6:
        return 16.0;
      case 7:
        return 14.0;
      case 8:
        return 12.0;
      default:
        return 20.0;
    }
  }

  double _getBonusNumberFontSize() {
    // Scale down bonus number for larger grids
    switch (gridSize) {
      case 4:
        return 11.0;
      case 5:
        return 9.0;
      case 6:
        return 7.0;
      case 7:
        return 6.0;
      case 8:
        return 5.5;
      default:
        return 9.0;
    }
  }
  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}
