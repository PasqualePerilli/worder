import 'package:flutter/material.dart';
import '../models/letter_tile.dart';
import '../services/config_service.dart';

class TileWidget extends StatelessWidget {
  final LetterTile tile;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback? onTapDown;

  const TileWidget({
    super.key,
    required this.tile,
    this.isSelected = false,
    this.isHighlighted = false,
    this.onTapDown,
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
              GestureDetector(
                onPanDown: (_) => onTapDown?.call(),
                child: Container(
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
                          style: const TextStyle(
                            fontSize: 24,
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
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
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

    if (isWordBonus) {
      // Star for word bonuses - bigger size
      return Icon(
        Icons.star,
        size: 32,
        color: _getBorderColor(config),
      );
    } else {
      // Circle for letter bonuses - bigger size
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getBorderColor(config),
        ),
        child: Center(
          child: Text(
            '$multiplier',
            style: const TextStyle(
              fontSize: 14,
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
