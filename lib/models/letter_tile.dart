enum BonusType {
  none,
  doubleLetter,
  tripleLetter,
  doubleWord,
  tripleWord,
}

class LetterTile {
  final String letter;
  final int value;
  final BonusType bonusType;
  final int row;
  final int col;

  const LetterTile({
    required this.letter,
    required this.value,
    required this.bonusType,
    required this.row,
    required this.col,
  });

  Map<String, dynamic> toJson() {
    return {
      'letter': letter,
      'value': value,
      'bonusType': bonusType.index,
      'row': row,
      'col': col,
    };
  }

  factory LetterTile.fromJson(Map<String, dynamic> json) {
    return LetterTile(
      letter: json['letter'] as String,
      value: json['value'] as int,
      bonusType: BonusType.values[json['bonusType'] as int],
      row: json['row'] as int,
      col: json['col'] as int,
    );
  }

  LetterTile copyWith({
    String? letter,
    int? value,
    BonusType? bonusType,
    int? row,
    int? col,
  }) {
    return LetterTile(
      letter: letter ?? this.letter,
      value: value ?? this.value,
      bonusType: bonusType ?? this.bonusType,
      row: row ?? this.row,
      col: col ?? this.col,
    );
  }
}
