import 'package:flutter/material.dart';
import 'package:tarl_core/tarl_core.dart';

import '../models/student.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// What the child scored, why, and the class it puts them in.
///
/// The marks that produced the level are shown alongside it. A placement has
/// to be explainable to a mentor and eventually to a ministry, so the
/// evidence travels with the verdict rather than being discarded.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.state,
    required this.student,
  });

  final AppState state;
  final Student student;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final result = student.result!;
        final plan = state.plan!;
        final level = student.level!;
        final assigned = student.assignedClass(plan)!;

        return Scaffold(
          appBar: AppBar(
            title: Text(student.displayName),
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Verdict(
                  level: level,
                  assigned: assigned,
                  isMoved: student.isMoved(plan),
                ),
                if (result.isInconsistent) ...[
                  const SizedBox(height: 16),
                  const _ConfirmNotice(),
                ],
                const SizedBox(height: 24),
                const _SectionLabel('How they were marked'),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      for (final (i, r) in result.results.indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        _MarkRow(result: r),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionLabel('Move to another class'),
                const SizedBox(height: 6),
                const Text(
                  'The measured level does not change — only which class this '
                  'child joins.',
                  style: TextStyle(fontSize: 14, color: Palette.inkMuted),
                ),
                const SizedBox(height: 12),
                _ClassPicker(state: state, student: student, plan: plan),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({
    required this.level,
    required this.assigned,
    required this.isMoved,
  });

  final NumeracyLevel level;
  final TeachingClass assigned;
  final bool isMoved;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Palette.tealWash,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Palette.teal, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('REACHED LEVEL',
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: Palette.tealDark)),
            const SizedBox(height: 6),
            Text(
              _levelName(level),
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink),
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('JOINS CLASS',
                    style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: Palette.tealDark)),
                if (isMoved) ...[
                  const SizedBox(width: 8),
                  const LevelChip('moved by teacher',
                      background: Palette.ochre),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              assigned.label,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Palette.tealDark),
            ),
            const SizedBox(height: 4),
            Text(
              assigned.teacherLabel,
              style: const TextStyle(fontSize: 15, color: Palette.inkMuted),
            ),
            const SizedBox(height: 8),
            Text(
              isMoved
                  ? 'Moved from the class this level would normally give.'
                  : level == NumeracyLevel.division
                      ? 'Completed the ladder — continues towards fluency.'
                      : 'Targets the next skill they have not yet mastered.',
              style: const TextStyle(fontSize: 14, color: Palette.inkMuted),
            ),
          ],
        ),
      );
}

/// Shown when a child succeeded above something they failed. The app does not
/// quietly pick a side.
class _ConfirmNotice extends StatelessWidget {
  const _ConfirmNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Palette.ochreWash,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Palette.ochre.withValues(alpha: 0.5)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.help_outline, color: Palette.ochre, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Please confirm this placement',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Palette.ochre)),
                  SizedBox(height: 4),
                  Text(
                    'This child passed an item above one they failed. Check '
                    'the marks below, and override if the level looks wrong.',
                    style: TextStyle(fontSize: 14, color: Palette.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _MarkRow extends StatelessWidget {
  const _MarkRow({required this.result});

  final ItemResult result;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: LevelChip(result.item.level.code,
                  background: Palette.inkMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                result.item.toString(),
                style: const TextStyle(
                    fontSize: 15,
                    fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ),
            Text(
              result.item.answerKey,
              style: const TextStyle(
                  fontSize: 14,
                  color: Palette.inkMuted,
                  fontFeatures: [FontFeature.tabularFigures()]),
            ),
            const SizedBox(width: 14),
            Icon(
              result.correct ? Icons.check : Icons.close,
              color: result.correct ? Palette.teal : Palette.rust,
              size: 22,
            ),
          ],
        ),
      );
}

/// One row per class, so the teacher picks a destination by name rather than
/// by a level code they would have to translate.
class _ClassPicker extends StatelessWidget {
  const _ClassPicker({
    required this.state,
    required this.student,
    required this.plan,
  });

  final AppState state;
  final Student student;
  final ClassPlan plan;

  @override
  Widget build(BuildContext context) {
    final natural = plan.classForLevel(student.level!).index;
    final current = student.assignedClass(plan)!.index;

    return Card(
      child: Column(
        children: [
          for (final (i, c) in plan.classes.indexed) ...[
            if (i > 0) const Divider(height: 1),
            InkWell(
              onTap: () => state.moveToClass(student, c.index),
              child: Container(
                constraints: const BoxConstraints(minHeight: kTouchTarget),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: c.index == current ? Palette.tealWash : null,
                child: Row(
                  children: [
                    Icon(
                      c.index == current
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 22,
                      color: c.index == current
                          ? Palette.teal
                          : Palette.inkMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: c.index == current
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          Text(
                            c.teacherLabel,
                            style: const TextStyle(
                                fontSize: 12.5, color: Palette.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    if (c.index == natural)
                      const LevelChip('from level',
                          background: Palette.inkMuted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
          color: Palette.inkMuted,
        ),
      );
}

String _levelName(NumeracyLevel level) => switch (level) {
      NumeracyLevel.beginner => 'Beginner',
      NumeracyLevel.numberRecognition1To9 => 'Number recognition 1–9',
      NumeracyLevel.numberRecognition10ToMax => 'Number recognition 10+',
      NumeracyLevel.addition => 'Addition',
      NumeracyLevel.subtraction => 'Subtraction',
      NumeracyLevel.multiplication => 'Multiplication',
      NumeracyLevel.division => 'Division',
    };
