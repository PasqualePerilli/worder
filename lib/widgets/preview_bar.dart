import 'package:flutter/material.dart';
import '../services/config_service.dart';

enum PreviewBarState {
  selecting,
  success,
  error,
}

class PreviewBar extends StatefulWidget {
  final String word;
  final PreviewBarState state;
  final int? score;

  const PreviewBar({
    super.key,
    required this.word,
    required this.state,
    this.score,
  });

  @override
  State<PreviewBar> createState() => _PreviewBarState();
}

class _PreviewBarState extends State<PreviewBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );
  }

  @override
  void didUpdateWidget(PreviewBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == PreviewBarState.error &&
        oldWidget.state != PreviewBarState.error) {
      _shakeController.reset();
      _shakeController.forward();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConfigService>(
      future: ConfigService.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final config = snapshot.data!;

        return AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset = widget.state == PreviewBarState.error
                ? _shakeAnimation.value
                : 0.0;

            return Transform.translate(
              offset: Offset(offset, 0),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(config),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getBorderColor(config),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getDisplayText(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getDisplayText() {
    if (widget.word.isEmpty) return ' ';
    
    // Show "+N" for valid words with score
    if (widget.state == PreviewBarState.success && widget.score != null) {
      return '${widget.word} +${widget.score}';
    }
    
    return widget.word;
  }

  Color _getBackgroundColor(ConfigService config) {
    switch (widget.state) {
      case PreviewBarState.selecting:
        return _parseColor(config.previewBarDefaultColor);
      case PreviewBarState.success:
        return _parseColor(config.previewBarSuccessColor);
      case PreviewBarState.error:
        return _parseColor(config.previewBarErrorColor);
    }
  }

  Color _getBorderColor(ConfigService config) {
    return _getBackgroundColor(config).withOpacity(1.0);
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}
