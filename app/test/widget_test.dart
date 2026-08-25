import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations_first/src/screens/home_screen.dart';
import 'package:foundations_first/src/state/app_state.dart';
import 'package:foundations_first/src/theme.dart';
import 'package:tarl_core/tarl_core.dart';

/// Walks the flow a teacher actually performs: set up classes, pick a child,
/// mark six items, land on a class.
void main() {
  /// The default 800×600 test surface puts the setup sheet's confirm button and
  /// the lower class options below the fold, where they are either unhittable
  /// or not built at all. A tall surface keeps the assertions about behaviour
  /// rather than about scrolling.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget app(AppState state) => MaterialApp(
        theme: buildTheme(),
        home: HomeScreen(state: state),
      );

  /// Marks a whole form. Recognition items take a count; operations take
  /// pass/fail.
  Future<void> markForm(
    WidgetTester tester, {
    required int recognitionCount,
    required List<bool> operations,
  }) async {
    for (var i = 0; i < 2; i++) {
      await tester.tap(
          find.widgetWithText(OutlinedButton, '$recognitionCount'));
      await tester.pumpAndSettle();
    }
    for (final correct in operations) {
      await tester.tap(find.text(correct ? 'Correct' : 'Incorrect'));
      await tester.pumpAndSettle();
    }
  }

  group('setup gate', () {
    testWidgets('an empty register asks for teachers before children',
        (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(app(AppState()));
      expect(find.text('No class register yet'), findsOne);

      await tester.tap(find.text('Load sample class'));
      await tester.pumpAndSettle();

      // The roster must not appear until classes exist.
      expect(find.text('How many teachers are delivering TaRL?'), findsOne);
      expect(find.text('Amina Wanjiru'), findsNothing);
    });

    testWidgets('choosing teachers then loads the register', (tester) async {
      useTallSurface(tester);
      final state = AppState();
      await tester.pumpWidget(app(state));

      await tester.tap(find.text('Load sample class'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, '4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create 4 classes'));
      await tester.pumpAndSettle();

      expect(state.teacherCount, 4);
      expect(state.plan!.classes, hasLength(4));
      expect(find.text('Amina Wanjiru'), findsOne);
    });

    testWidgets('three teachers preview as numbers, +/− and ×/÷',
        (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(app(AppState()));
      await tester.tap(find.text('Load sample class'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, '3'));
      await tester.pumpAndSettle();
      expect(find.text('Number recognition 1–99'), findsOne);
      expect(find.text('Addition & Subtraction'), findsOne);
      expect(find.text('Multiplication & Division'), findsOne);
    });

    testWidgets('the top option is open-ended and explains itself',
        (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(app(AppState()));
      await tester.tap(find.text('Load sample class'));
      await tester.pumpAndSettle();

      // Counts above six produce the same six classes, so the last option is
      // "6+" rather than a list of numbers that all behave identically.
      expect(find.widgetWithText(OutlinedButton, '6+'), findsOne);
      expect(find.widgetWithText(OutlinedButton, '7'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, '8'), findsNothing);

      await tester.tap(find.widgetWithText(OutlinedButton, '6+'));
      await tester.pumpAndSettle();
      expect(find.textContaining('share the largest class'), findsOne);
      expect(find.text('Create 6 classes'), findsOne);
    });
  });

  group('assessment', () {
    Future<AppState> configured(WidgetTester tester,
        {int teachers = 4, int seed = 1}) async {
      useTallSurface(tester);
      final state = AppState(random: Random(seed))
        ..setTeacherCount(teachers)
        ..loadSampleRoster();
      await tester.pumpWidget(app(state));
      return state;
    }

    testWidgets('all correct places the child in the highest class',
        (tester) async {
      final state = await configured(tester);
      await tester.tap(find.text('Amina Wanjiru'));
      await tester.pumpAndSettle();

      await markForm(tester,
          recognitionCount: 5, operations: [true, true, true, true]);

      final amina = state.students.first;
      expect(amina.level, NumeracyLevel.division);
      expect(amina.assignedClass(state.plan!)!.index, 3);
    });

    testWidgets('all wrong places the child in the lowest class',
        (tester) async {
      final state = await configured(tester, seed: 2);
      await tester.tap(find.text('Joseph Kamau'));
      await tester.pumpAndSettle();

      await markForm(tester,
          recognitionCount: 0, operations: [false, false, false, false]);

      final joseph =
          state.students.firstWhere((s) => s.firstName == 'Joseph');
      expect(joseph.level, NumeracyLevel.beginner);
      expect(joseph.assignedClass(state.plan!)!.index, 0);
    });

    testWidgets('an inconsistent pattern asks the assessor to confirm',
        (tester) async {
      final state = await configured(tester, seed: 3);
      await tester.tap(find.text('Mercy Achieng'));
      await tester.pumpAndSettle();

      // ✓ ✓ ✓ ✗ ✓ ✗ — passed multiplication, failed subtraction.
      await markForm(tester,
          recognitionCount: 5, operations: [true, false, true, false]);

      expect(find.text('Please confirm this placement'), findsOne);
      expect(
        state.students.firstWhere((s) => s.firstName == 'Mercy').result!
            .isInconsistent,
        isTrue,
      );
    });

    testWidgets('undo steps back an item', (tester) async {
      await configured(tester, seed: 4);
      await tester.tap(find.text('Amina Wanjiru'));
      await tester.pumpAndSettle();
      expect(find.text('Item 1 of 6'), findsOne);

      await tester.tap(find.widgetWithText(OutlinedButton, '5'));
      await tester.pumpAndSettle();
      expect(find.text('Item 2 of 6'), findsOne);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Item 1 of 6'), findsOne);
    });
  });

  group('moving a child between classes', () {
    testWidgets('the teacher picks a class, and the level is untouched',
        (tester) async {
      useTallSurface(tester);
      final state = AppState(random: Random(5))
        ..setTeacherCount(4)
        ..loadSampleRoster();
      await tester.pumpWidget(app(state));

      await tester.tap(find.text('Amina Wanjiru'));
      await tester.pumpAndSettle();
      await markForm(tester,
          recognitionCount: 5, operations: [true, true, true, true]);

      final amina = state.students.first;
      expect(amina.assignedClass(state.plan!)!.index, 3);

      // Move her down to the second class.
      await tester.tap(find.text('Number recognition 10–99'));
      await tester.pumpAndSettle();

      expect(amina.assignedClass(state.plan!)!.index, 1);
      expect(amina.isMoved(state.plan!), isTrue);
      // The measured level is a record of what she did — unchanged.
      expect(amina.level, NumeracyLevel.division);
      expect(find.text('moved by teacher'.toUpperCase()), findsOne);
    });

    testWidgets('re-picking the natural class clears the move',
        (tester) async {
      useTallSurface(tester);
      final state = AppState(random: Random(6))
        ..setTeacherCount(3)
        ..loadSampleRoster();
      await tester.pumpWidget(app(state));

      await tester.tap(find.text('Amina Wanjiru'));
      await tester.pumpAndSettle();
      await markForm(tester,
          recognitionCount: 5, operations: [true, true, true, true]);

      final amina = state.students.first;
      // Three teachers: numbers / +− / ×÷. She reached division, so her
      // natural class is the third.
      expect(amina.assignedClass(state.plan!)!.index, 2);

      await tester.tap(find.text('Number recognition 1–99'));
      await tester.pumpAndSettle();
      expect(amina.classOverride, 0);

      await tester.tap(find.text('Multiplication & Division'));
      await tester.pumpAndSettle();
      expect(amina.classOverride, isNull);
      expect(amina.isMoved(state.plan!), isFalse);
    });

    testWidgets('changing teacher count discards stale class moves',
        (tester) async {
      useTallSurface(tester);
      final state = AppState(random: Random(7))
        ..setTeacherCount(6)
        ..loadSampleRoster();
      await tester.pumpWidget(app(state));

      await tester.tap(find.text('Amina Wanjiru'));
      await tester.pumpAndSettle();
      await markForm(tester,
          recognitionCount: 5, operations: [true, true, true, true]);
      await tester.tap(find.text('Addition'));
      await tester.pumpAndSettle();
      expect(state.students.first.classOverride, 2);

      // Class index 5 does not exist under a two-class plan.
      state.setTeacherCount(2);
      expect(state.students.first.classOverride, isNull);
      expect(state.students.first.assignedClass(state.plan!)!.index, 1);
    });
  });
}
