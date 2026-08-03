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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate font sizes based on actual tile dimensions
              // Use the smaller dimension to ensure text fits on all screen aspect ratios
              final tileSize = constraints.maxHeight > 0 && constraints.maxWidth > 0
                  ? (constraints.maxHeight < constraints.maxWidth 
                      ? constraints.maxHeight 
                      : constraints.maxWidth)
                  : (constraints.maxHeight > 0 ? constraints.maxHeight : constraints.maxWidth);
              
              final letterFontSize = tileSize * config.letterSizeRatio;
              final valueFontSize = tileSize * config.valueSizeRatio;
              final bonusIndicatorSize = tileSize * config.bonusIndicatorRatio;
              final bonusNumberFontSize = bonusIndicatorSize * config.bonusNumberRatio;

              return Stack(
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
                              fontSize: letterFontSize,
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
                              fontSize: valueFontSize,
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
                      child: _buildBonusIndicator(config, bonusIndicatorSize, bonusNumberFontSize),
                    ),
                ],
              );
            },
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

  Widget _buildBonusIndicator(ConfigService config, double indicatorSize, double numberFontSize) {
    final isWordBonus = tile.bonusType == BonusType.tripleWord ||
        tile.bonusType == BonusType.doubleWord;
    final multiplier = tile.bonusType == BonusType.tripleWord ||
            tile.bonusType == BonusType.tripleLetter
        ? 3
        : 2;

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

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}
