import 'package:tarl_core/tarl_core.dart';
import 'package:test/test.dart';

void main() {
  group('teacher count', () {
    test('fewer than two teachers is rejected', () {
      expect(() => ClassPlan.forTeachers(1), throwsArgumentError);
      expect(() => ClassPlan.forTeachers(0), throwsArgumentError);
      expect(() => ClassPlan.forTeachers(-3), throwsArgumentError);
    });

    test('two teachers give two classes', () {
      expect(ClassPlan.forTeachers(2).classes, hasLength(2));
    });

    test('six teachers give one class per rung', () {
      final plan = ClassPlan.forTeachers(6);
      expect(plan.classes, hasLength(6));
      expect(plan.classes.every((c) => !c.isMixed), isTrue);
    });

    test('more than six teachers share rather than over-splitting', () {
      final plan = ClassPlan.forTeachers(9);
      expect(plan.classes, hasLength(6));
      expect(plan.sharingTeachers, 3);
      expect(ClassPlan.forTeachers(6).sharingTeachers, 0);
    });
  });

  group('rungs are split evenly', () {
    test('three teachers pair the rungs: numbers, +/−, ×/÷', () {
      final plan = ClassPlan.forTeachers(3);
      expect(plan.classes[0].groups, [
        TeachingGroup.numberRecognition1To9,
        TeachingGroup.numberRecognition10ToMax,
      ]);
      expect(plan.classes[1].groups, [
        TeachingGroup.addition,
        TeachingGroup.subtraction,
      ]);
      expect(plan.classes[2].groups, [
        TeachingGroup.multiplication,
        TeachingGroup.division,
      ]);
    });

    test('four teachers keep the two lowest rungs pure', () {
      final sizes =
          ClassPlan.forTeachers(4).classes.map((c) => c.groups.length);
      expect(sizes, [1, 1, 2, 2]);
    });

    test('five teachers merge only the top pair', () {
      final sizes =
          ClassPlan.forTeachers(5).classes.map((c) => c.groups.length);
      expect(sizes, [1, 1, 1, 1, 2]);
    });

    test('two teachers split three and three', () {
      final sizes =
          ClassPlan.forTeachers(2).classes.map((c) => c.groups.length);
      expect(sizes, [3, 3]);
    });

    // The delivery guide: "Avoid mixing levels, and if you do, only do so for
    // higher levels." A child furthest behind must never sit in a class that
    // is more broadly mixed than the ones above them.
    test('class sizes never shrink as you go up the ladder', () {
      for (var n = ClassPlan.minTeachers; n <= 8; n++) {
        final sizes = ClassPlan.forTeachers(n)
            .classes
            .map((c) => c.groups.length)
            .toList();
        for (var i = 1; i < sizes.length; i++) {
          expect(sizes[i], greaterThanOrEqualTo(sizes[i - 1]),
              reason: '$n teachers: sizes $sizes must be non-decreasing');
        }
      }
    });

    test('every rung lands in exactly one class', () {
      for (var n = ClassPlan.minTeachers; n <= 8; n++) {
        final plan = ClassPlan.forTeachers(n);
        for (final group in TeachingGroup.values) {
          final matches =
              plan.classes.where((c) => c.covers(group)).toList();
          expect(matches, hasLength(1),
              reason: '$n teachers: $group should appear once');
        }
      }
    });

    test('no rungs are dropped or duplicated', () {
      for (var n = ClassPlan.minTeachers; n <= 8; n++) {
        final covered =
            ClassPlan.forTeachers(n).classes.expand((c) => c.groups).toList();
        expect(covered, TeachingGroup.values, reason: '$n teachers');
      }
    });
  });

  group('placement', () {
    test('every level resolves to a class, beginner included', () {
      final plan = ClassPlan.forTeachers(4);
      for (final level in NumeracyLevel.values) {
        expect(() => plan.classForLevel(level), returnsNormally);
      }
    });

    test('a beginner lands in the lowest class', () {
      final plan = ClassPlan.forTeachers(5);
      expect(plan.classForLevel(NumeracyLevel.beginner).index, 0);
    });

    test('completing the ladder lands in the highest class', () {
      final plan = ClassPlan.forTeachers(5);
      expect(plan.classForLevel(NumeracyLevel.division).index,
          plan.classes.length - 1);
    });

    test('with three teachers a subtraction child joins the +/− class', () {
      final plan = ClassPlan.forTeachers(3);
      // Reached subtraction, so is taught multiplication — the ×/÷ class.
      expect(plan.classForLevel(NumeracyLevel.subtraction).index, 2);
      // Reached number recognition 10+, so is taught addition — the +/− class.
      expect(
          plan.classForLevel(NumeracyLevel.numberRecognition10ToMax).index, 1);
      expect(plan.classForLevel(NumeracyLevel.beginner).index, 0);
    });
  });

  group('labels', () {
    test('a single-rung class is named after its rung', () {
      expect(ClassPlan.forTeachers(6).classes[2].label, 'Addition');
    });

    test('both recognition rungs read as one range', () {
      expect(ClassPlan.forTeachers(3).classes[0].label,
          'Number recognition 1–99');
    });

    test('the range follows the configured upper limit', () {
      final plan = ClassPlan.forTeachers(3, upperLimit: 999);
      expect(plan.classes[0].label, 'Number recognition 1–999');
      expect(ClassPlan.forTeachers(6, upperLimit: 999).classes[1].label,
          'Number recognition 10–999');
    });

    test('a pair of operations reads as both', () {
      final plan = ClassPlan.forTeachers(3);
      expect(plan.classes[1].label, 'Addition & Subtraction');
      expect(plan.classes[2].label, 'Multiplication & Division');
    });

    test('three or more rungs read as a span', () {
      expect(ClassPlan.forTeachers(2).classes[1].label,
          'Subtraction to Division');
    });

    test('teachers are numbered from one', () {
      expect(ClassPlan.forTeachers(2).classes[0].teacherLabel, 'Teacher 1');
      expect(ClassPlan.forTeachers(2).classes[1].teacherLabel, 'Teacher 2');
    });
  });
}
