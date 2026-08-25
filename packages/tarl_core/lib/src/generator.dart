import 'dart:math';

import 'config.dart';
import 'items.dart';
import 'levels.dart';

/// Builds levelling forms whose items provably satisfy the TaRL spec.
///
/// The spec for each operation is a checkable predicate, which is what makes
/// generation safe here (and unsafe for reading passages, where "words
/// familiar to a grade 1 child" cannot be derived):
///
///   Addition       two 2-digit numbers, using carry-over
///   Subtraction    two 2-digit numbers, using borrowing
///   Multiplication 2-digit by 1-digit, with carry-over
///   Division       2-digit by 1-digit, with remainder
///
/// The extra constraints beyond the spec exist to keep parallel forms equal
/// in difficulty. A child must be able to sit baseline, midline and endline
/// on different numbers without the forms drifting — otherwise you measure
/// a change that is not there.
class ItemGenerator {
  ItemGenerator({AssessmentConfig? config, Random? random})
      : config = config ?? const AssessmentConfig(),
        _random = random ?? Random();

  final AssessmentConfig config;
  final Random _random;

  /// One complete levelling form: an item per assessed level, in ladder
  /// order. This is what a single child is given.
  List<Item> generateForm() =>
      NumeracyLevel.assessed.map(generateItemFor).toList();

  Item generateItemFor(NumeracyLevel level) => switch (level) {
        NumeracyLevel.numberRecognition1To9 =>
          _recognitionItem(level, min: 1, max: 9),
        NumeracyLevel.numberRecognition10ToMax =>
          _recognitionItem(level, min: 10, max: config.upperLimit),
        _ => _pick(level),
      };

  /// Every operation item satisfying the spec for [level].
  ///
  /// Enumerated rather than rejection-sampled, so the constraints are
  /// testable as a whole — `candidatesFor(x).every(spec)` is a real
  /// assertion over the entire space, and a constraint that accidentally
  /// excludes valid items shows up as a missing candidate rather than as a
  /// rare surprise in the field.
  List<OperationItem> candidatesFor(NumeracyLevel level) => switch (level) {
        NumeracyLevel.addition => _additionCandidates(),
        NumeracyLevel.subtraction => _subtractionCandidates(),
        NumeracyLevel.multiplication => _multiplicationCandidates(),
        NumeracyLevel.division => _divisionCandidates(),
        NumeracyLevel.beginner => throw ArgumentError(
            'beginner is the fallback when the first item fails; '
            'it has no item of its own',
          ),
        _ => throw ArgumentError('$level is not an operation level'),
      };

  NumberRecognitionItem _recognitionItem(
    NumeracyLevel level, {
    required int min,
    required int max,
  }) {
    final pool = [for (var n = min; n <= max; n++) n]..shuffle(_random);
    final numbers = pool.take(config.numbersPerRecognitionItem).toList();
    return NumberRecognitionItem(
      level: level,
      numbers: numbers,
      passThreshold: config.recognitionPassThreshold,
    );
  }

  OperationItem _pick(NumeracyLevel level) {
    final pool = candidatesFor(level);
    if (pool.isEmpty) {
      throw StateError('no items satisfy the constraints for $level');
    }
    return pool[_random.nextInt(pool.length)];
  }

  /// Two 2-digit numbers, carry required in the units column.
  ///
  /// Sum is held below 100 so the answer stays 2-digit — 91+89 crosses into
  /// hundreds and is meaningfully harder than 47+15.
  ///
  /// Round operands need no separate exclusion: a number ending in 0 cannot
  /// contribute a carry, so the carry predicate already rejects it.
  List<OperationItem> _additionCandidates() => [
        for (var a = 10; a <= 99; a++)
          for (var b = 10; b <= 99; b++)
            if (a % 10 + b % 10 >= 10 && a + b <= 99)
              OperationItem(
                level: NumeracyLevel.addition,
                operation: Operation.add,
                left: a,
                right: b,
              ),
      ];

  /// Two 2-digit numbers, borrow required, 2-digit positive result.
  List<OperationItem> _subtractionCandidates() => [
        for (var a = 10; a <= 99; a++)
          for (var b = 10; b < a; b++)
            if (a % 10 < b % 10 && a - b >= 10)
              OperationItem(
                level: NumeracyLevel.subtraction,
                operation: Operation.subtract,
                left: a,
                right: b,
              ),
      ];

  /// 2-digit by 1-digit, carry required in the units column.
  ///
  /// Multipliers 0, 1 and 10 are excluded by the range: children special-case
  /// them and they test nothing.
  List<OperationItem> _multiplicationCandidates() => [
        for (var a = 10; a <= 99; a++)
          for (var b = 2; b <= 9; b++)
            if ((a % 10) * b >= 10)
              OperationItem(
                level: NumeracyLevel.multiplication,
                operation: Operation.multiply,
                left: a,
                right: b,
              ),
      ];

  /// 2-digit by 1-digit, non-zero remainder, quotient of at least 2.
  List<OperationItem> _divisionCandidates() => [
        for (var a = 10; a <= 99; a++)
          for (var b = 2; b <= 9; b++)
            if (a % b != 0 && a ~/ b >= 2)
              OperationItem(
                level: NumeracyLevel.division,
                operation: Operation.divide,
                left: a,
                right: b,
              ),
      ];
}
