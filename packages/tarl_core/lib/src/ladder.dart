import 'config.dart';
import 'items.dart';
import 'levels.dart';

/// How one item went for one child.
class ItemResult {
  const ItemResult({required this.item, required this.correct});

  /// Convenience for a recognition item, where the assessor records how many
  /// of the shown numbers were read rather than a single pass/fail.
  factory ItemResult.recognition({
    required NumberRecognitionItem item,
    required int numbersCorrect,
  }) =>
      ItemResult(item: item, correct: item.passedWith(numbersCorrect));

  final Item item;
  final bool correct;
}

/// A child's levelling outcome, with enough detail to explain itself.
///
/// Placement decisions have to be defensible to a teacher, a mentor and
/// eventually a ministry, so the result carries the raw marks that produced
/// it rather than just the verdict.
class LevellingResult {
  const LevellingResult({
    required this.level,
    required this.results,
    required this.rule,
  });

  final NumeracyLevel level;
  final List<ItemResult> results;
  final LevellingRule rule;

  TeachingGroup get teachingGroup => level.teachingGroup;

  /// True when the child succeeded at some item *above* one they failed.
  ///
  /// Under [LevellingRule.lastCorrect] this child is credited with the
  /// higher level, which may not be what the assessor intended — worth
  /// surfacing for confirmation rather than silently deciding.
  bool get isInconsistent {
    final firstFailure = results.indexWhere((r) => !r.correct);
    if (firstFailure == -1) return false;
    return results.skip(firstFailure).any((r) => r.correct);
  }

  @override
  String toString() => '${level.code} → ${teachingGroup.label}';
}

/// Assigns a level from a child's marks.
///
/// [results] must be in ladder order — the order [ItemGenerator.generateForm]
/// produces. A child who fails the first item is [NumeracyLevel.beginner].
LevellingResult assignLevel(
  List<ItemResult> results, {
  AssessmentConfig config = const AssessmentConfig(),
}) {
  if (results.isEmpty) {
    throw ArgumentError('cannot level a child with no results');
  }

  final level = switch (config.levellingRule) {
    LevellingRule.lastCorrect => _lastCorrect(results),
    LevellingRule.stopAtFirstFailure => _stopAtFirstFailure(results),
  };

  return LevellingResult(
    level: level,
    results: results,
    rule: config.levellingRule,
  );
}

NumeracyLevel _lastCorrect(List<ItemResult> results) {
  for (var i = results.length - 1; i >= 0; i--) {
    if (results[i].correct) return results[i].item.level;
  }
  return NumeracyLevel.beginner;
}

NumeracyLevel _stopAtFirstFailure(List<ItemResult> results) {
  var level = NumeracyLevel.beginner;
  for (final r in results) {
    if (!r.correct) break;
    level = r.item.level;
  }
  return level;
}
