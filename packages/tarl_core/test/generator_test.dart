import 'dart:math';

import 'package:tarl_core/tarl_core.dart';
import 'package:test/test.dart';

void main() {
  final gen = ItemGenerator(random: Random(20260728));

  group('addition items', () {
    test('match the TaRL spec on every generated item', () {
      for (var i = 0; i < 500; i++) {
        final item =
            gen.generateItemFor(NumeracyLevel.addition) as OperationItem;
        expect(item.operation, Operation.add);
        expect(item.left, inInclusiveRange(10, 99), reason: '$item');
        expect(item.right, inInclusiveRange(10, 99), reason: '$item');
        expect(item.left % 10 + item.right % 10, greaterThanOrEqualTo(10),
            reason: 'must carry: $item');
        expect(item.answer, lessThanOrEqualTo(99),
            reason: 'answer stays 2-digit: $item');
      }
    });

    test('reproduces the guide example 47 + 15', () {
      const item = OperationItem(
        level: NumeracyLevel.addition,
        operation: Operation.add,
        left: 47,
        right: 15,
      );
      expect(item.answer, 62);
      expect(item.answerKey, '62');
    });
  });

  group('subtraction items', () {
    test('always require a borrow and leave a 2-digit result', () {
      for (var i = 0; i < 500; i++) {
        final item =
            gen.generateItemFor(NumeracyLevel.subtraction) as OperationItem;
        expect(item.left % 10, lessThan(item.right % 10),
            reason: 'must borrow: $item');
        expect(item.answer, greaterThanOrEqualTo(10), reason: '$item');
      }
    });

    test('reproduces the guide example 56 − 19', () {
      const item = OperationItem(
        level: NumeracyLevel.subtraction,
        operation: Operation.subtract,
        left: 56,
        right: 19,
      );
      expect(item.answer, 37);
    });
  });

  group('multiplication items', () {
    test('always carry, never use a trivial multiplier', () {
      for (var i = 0; i < 500; i++) {
        final item = gen.generateItemFor(NumeracyLevel.multiplication)
            as OperationItem;
        expect(item.right, inInclusiveRange(2, 9), reason: '$item');
        expect((item.left % 10) * item.right, greaterThanOrEqualTo(10),
            reason: 'must carry: $item');
      }
    });

    test('reproduces the guide example 27 × 3', () {
      const item = OperationItem(
        level: NumeracyLevel.multiplication,
        operation: Operation.multiply,
        left: 27,
        right: 3,
      );
      expect(item.answer, 81);
    });
  });

  group('division items', () {
    test('always leave a remainder', () {
      for (var i = 0; i < 500; i++) {
        final item =
            gen.generateItemFor(NumeracyLevel.division) as OperationItem;
        expect(item.right, inInclusiveRange(2, 9), reason: '$item');
        expect(item.remainder, isNot(0), reason: 'must have remainder: $item');
        expect(item.answer, greaterThanOrEqualTo(2), reason: '$item');
      }
    });

    test('reproduces the guide example 88 ÷ 6 = 14 r4', () {
      const item = OperationItem(
        level: NumeracyLevel.division,
        operation: Operation.divide,
        left: 88,
        right: 6,
      );
      expect(item.answer, 14);
      expect(item.remainder, 4);
      expect(item.answerKey, '14 r4');
    });
  });

  group('number recognition items', () {
    test('draw from the right range and do not repeat within an item', () {
      for (var i = 0; i < 200; i++) {
        final low = gen.generateItemFor(NumeracyLevel.numberRecognition1To9)
            as NumberRecognitionItem;
        expect(low.numbers, everyElement(inInclusiveRange(1, 9)));
        expect(low.numbers.toSet(), hasLength(low.numbers.length));

        final high =
            gen.generateItemFor(NumeracyLevel.numberRecognition10ToMax)
                as NumberRecognitionItem;
        expect(high.numbers, everyElement(inInclusiveRange(10, 99)));
        expect(high.numbers.toSet(), hasLength(high.numbers.length));
      }
    });

    test('respect a configured upper limit', () {
      final threeDigit = ItemGenerator(
        config: const AssessmentConfig(upperLimit: 999),
        random: Random(1),
      );
      final item =
          threeDigit.generateItemFor(NumeracyLevel.numberRecognition10ToMax)
              as NumberRecognitionItem;
      expect(item.numbers, everyElement(inInclusiveRange(10, 999)));
    });

    test('pass threshold is applied, not the raw count', () {
      const item = NumberRecognitionItem(
        level: NumeracyLevel.numberRecognition1To9,
        numbers: [3, 7, 1, 9, 4],
        passThreshold: 4,
      );
      expect(item.passedWith(4), isTrue);
      expect(item.passedWith(3), isFalse);
    });
  });

  group('candidate pools', () {
    // Sampling generated items only tests the constraints on what happens to
    // come out. These assert over the entire space.
    test('every addition candidate carries and stays 2-digit', () {
      final pool = gen.candidatesFor(NumeracyLevel.addition);
      expect(pool, isNotEmpty);
      expect(
        pool.every((i) =>
            i.left % 10 + i.right % 10 >= 10 &&
            i.answer <= 99 &&
            i.left >= 10 &&
            i.right >= 10),
        isTrue,
      );
    });

    test('every subtraction candidate borrows', () {
      final pool = gen.candidatesFor(NumeracyLevel.subtraction);
      expect(pool, isNotEmpty);
      expect(
        pool.every((i) => i.left % 10 < i.right % 10 && i.answer >= 10),
        isTrue,
      );
    });

    test('every multiplication candidate carries', () {
      final pool = gen.candidatesFor(NumeracyLevel.multiplication);
      expect(pool, isNotEmpty);
      expect(pool.every((i) => (i.left % 10) * i.right >= 10), isTrue);
    });

    test('every division candidate leaves a remainder', () {
      final pool = gen.candidatesFor(NumeracyLevel.division);
      expect(pool, isNotEmpty);
      expect(pool.every((i) => i.remainder != 0 && i.answer >= 2), isTrue);
    });

    // Regression: an "exclude repdigits" constraint once made 88 ÷ 6 —
    // the delivery guide's own example — impossible to generate. Any
    // constraint that rules out a published item is wrong by definition.
    test('the delivery guide examples are all reachable', () {
      bool reachable(NumeracyLevel level, int left, int right) => gen
          .candidatesFor(level)
          .any((i) => i.left == left && i.right == right);

      expect(reachable(NumeracyLevel.addition, 47, 15), isTrue,
          reason: '47 + 15');
      expect(reachable(NumeracyLevel.subtraction, 56, 19), isTrue,
          reason: '56 − 19');
      expect(reachable(NumeracyLevel.multiplication, 27, 3), isTrue,
          reason: '27 × 3');
      expect(reachable(NumeracyLevel.division, 88, 6), isTrue,
          reason: '88 ÷ 6');
    });

    test('pools are large enough for repeated parallel forms', () {
      for (final level in [
        NumeracyLevel.addition,
        NumeracyLevel.subtraction,
        NumeracyLevel.multiplication,
        NumeracyLevel.division,
      ]) {
        expect(gen.candidatesFor(level).length, greaterThan(100),
            reason: '$level needs enough items for baseline/midline/endline');
      }
    });
  });

  test('a form has one item per assessed level, in ladder order', () {
    final form = gen.generateForm();
    expect(form.map((i) => i.level), NumeracyLevel.assessed);
    expect(form, hasLength(6));
  });

  test('beginner has no item of its own', () {
    expect(
      () => gen.generateItemFor(NumeracyLevel.beginner),
      throwsArgumentError,
    );
  });
}
