import 'levels.dart';

/// One thing put in front of a child during levelling.
sealed class Item {
  const Item({required this.level});

  /// The level this item tests. A child who passes it has reached [level].
  final NumeracyLevel level;

  /// What the assessor sees, so they can mark without doing the sum
  /// themselves. Randomised items mean the assessor cannot rely on knowing
  /// the answers.
  String get answerKey;
}

/// A set of numbers for the child to read aloud.
final class NumberRecognitionItem extends Item {
  const NumberRecognitionItem({
    required super.level,
    required this.numbers,
    required this.passThreshold,
  });

  final List<int> numbers;

  /// How many of [numbers] must be read correctly to pass this item.
  final int passThreshold;

  bool passedWith(int correctCount) => correctCount >= passThreshold;

  @override
  String get answerKey => numbers.join('  ');

  @override
  String toString() => 'Read: ${numbers.join(', ')}';
}

enum Operation {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷');

  const Operation(this.symbol);
  final String symbol;
}

/// A single arithmetic problem the child works on paper.
final class OperationItem extends Item {
  const OperationItem({
    required super.level,
    required this.operation,
    required this.left,
    required this.right,
  });

  final Operation operation;
  final int left;
  final int right;

  /// The expected result. For [Operation.divide] this is the whole-number
  /// quotient; see [remainder].
  int get answer => switch (operation) {
        Operation.add => left + right,
        Operation.subtract => left - right,
        Operation.multiply => left * right,
        Operation.divide => left ~/ right,
      };

  /// Non-null only for division, which the TaRL spec always sets up to leave
  /// a remainder.
  int? get remainder =>
      operation == Operation.divide ? left % right : null;

  @override
  String get answerKey {
    final r = remainder;
    return r == null ? '$answer' : '$answer r$r';
  }

  @override
  String toString() => '$left ${operation.symbol} $right';
}
