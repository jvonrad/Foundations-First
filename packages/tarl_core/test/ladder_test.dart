import 'dart:math';

import 'package:tarl_core/tarl_core.dart';
import 'package:test/test.dart';

/// Builds results in ladder order from a pass/fail pattern.
List<ItemResult> marks(List<bool> pattern) {
  final form = ItemGenerator(random: Random(7)).generateForm();
  return [
    for (var i = 0; i < pattern.length; i++)
      ItemResult(item: form[i], correct: pattern[i]),
  ];
}

void main() {
  group('level assignment', () {
    test('failing the first item is beginner', () {
      final r = assignLevel(marks([false, false, false, false, false, false]));
      expect(r.level, NumeracyLevel.beginner);
    });

    test('a full run reaches division', () {
      final r = assignLevel(marks([true, true, true, true, true, true]));
      expect(r.level, NumeracyLevel.division);
    });

    test('stopping after addition gives the addition level', () {
      final r = assignLevel(marks([true, true, true, false, false, false]));
      expect(r.level, NumeracyLevel.addition);
    });

    test('reading single digits only gives the 1–9 level', () {
      final r = assignLevel(marks([true, false, false, false, false, false]));
      expect(r.level, NumeracyLevel.numberRecognition1To9);
    });
  });

  group('levelling rule', () {
    // A child marked ✓ ✓ ✓ ✗ ✓ ✗ — succeeded at multiplication but failed
    // subtraction. The delivery guide says "the last operation answered
    // correctly", which credits multiplication. Treating the ladder as
    // strictly ordinal credits addition instead. Different classes.
    final inconsistent = [true, true, true, false, true, false];

    test('lastCorrect credits the highest success', () {
      final r = assignLevel(marks(inconsistent));
      expect(r.level, NumeracyLevel.multiplication);
      expect(r.teachingGroup, TeachingGroup.division);
    });

    test('stopAtFirstFailure credits only the unbroken run', () {
      final r = assignLevel(
        marks(inconsistent),
        config: const AssessmentConfig(
          levellingRule: LevellingRule.stopAtFirstFailure,
        ),
      );
      expect(r.level, NumeracyLevel.addition);
      expect(r.teachingGroup, TeachingGroup.subtraction);
    });

    test('inconsistent patterns are flagged for the assessor', () {
      expect(assignLevel(marks(inconsistent)).isInconsistent, isTrue);
      expect(
        assignLevel(marks([true, true, false, false, false, false]))
            .isInconsistent,
        isFalse,
      );
    });
  });

  group('teaching group is offset by one level', () {
    test('you are taught the next thing you cannot do', () {
      expect(NumeracyLevel.beginner.teachingGroup,
          TeachingGroup.numberRecognition1To9);
      expect(NumeracyLevel.numberRecognition1To9.teachingGroup,
          TeachingGroup.numberRecognition10ToMax);
      expect(NumeracyLevel.numberRecognition10ToMax.teachingGroup,
          TeachingGroup.addition);
      expect(NumeracyLevel.addition.teachingGroup, TeachingGroup.subtraction);
      expect(
          NumeracyLevel.subtraction.teachingGroup, TeachingGroup.multiplication);
      expect(
          NumeracyLevel.multiplication.teachingGroup, TeachingGroup.division);
    });

    test('completing the ladder stays in the division class', () {
      expect(NumeracyLevel.division.teachingGroup, TeachingGroup.division);
    });

    test('every group is reachable', () {
      final reached =
          NumeracyLevel.values.map((l) => l.teachingGroup).toSet();
      expect(reached, containsAll(TeachingGroup.values));
    });
  });

  test('an empty result set is rejected rather than defaulted', () {
    expect(() => assignLevel([]), throwsArgumentError);
  });
}
