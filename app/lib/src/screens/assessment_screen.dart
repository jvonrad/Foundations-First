import 'package:flutter/material.dart';
import 'package:tarl_core/tarl_core.dart';

import '../models/student.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'result_screen.dart';

/// Levels one child through the ladder.
///
/// The child works the problem on paper, as they do today; the assessor marks
/// it here. The problem is shown large enough for the child to read from the
/// same screen, and the expected answer is shown to the assessor because the
/// numbers are randomised per child — they cannot mark from memory.
class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({
    super.key,
    required this.state,
    required this.student,
  });

  final AppState state;
  final Student student;

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  late final List<Item> _form = widget.state.newFormFor(widget.student);
  final List<ItemResult> _marks = [];

  Item get _current => _form[_marks.length];
  bool get _isComplete => _marks.length == _form.length;

  void _mark(bool correct) {
    setState(() => _marks.add(ItemResult(item: _current, correct: correct)));
    if (_isComplete) _finish();
  }

  void _markRecognition(int numbersCorrect) {
    final item = _current as NumberRecognitionItem;
    setState(() => _marks.add(
          ItemResult.recognition(item: item, numbersCorrect: numbersCorrect),
        ));
    if (_isComplete) _finish();
  }

  void _undo() {
    if (_marks.isEmpty) return;
    setState(() => _marks.removeLast());
  }

  void _finish() {
    widget.state.recordResult(widget.student, _marks);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultScreen(
        state: widget.state,
        student: widget.student,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplete) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.student.displayName,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            Text(
              'Item ${_marks.length + 1} of ${_form.length}',
              style:
                  const TextStyle(fontSize: 13, color: Palette.inkMuted),
            ),
          ],
        ),
        actions: [
          if (_marks.isNotEmpty)
            TextButton.icon(
              onPressed: _undo,
              icon: const Icon(Icons.undo, size: 20),
              label: const Text('Undo'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _LadderProgress(form: _form, marks: _marks),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: switch (_current) {
                  final NumberRecognitionItem item =>
                    _RecognitionPrompt(item: item),
                  final OperationItem item => _OperationPrompt(item: item),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: switch (_current) {
                final NumberRecognitionItem item => _RecognitionControls(
                    item: item,
                    onCount: _markRecognition,
                  ),
                OperationItem() => _PassFailControls(onMark: _mark),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows where the child is on the ladder, and how each item went.
class _LadderProgress extends StatelessWidget {
  const _LadderProgress({required this.form, required this.marks});

  final List<Item> form;
  final List<ItemResult> marks;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Palette.rule)),
        ),
        child: Row(
          children: [
            for (final (i, item) in form.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: i < marks.length
                            ? (marks[i].correct
                                ? Palette.teal
                                : Palette.rust)
                            : (i == marks.length
                                ? Palette.ink
                                : Palette.rule),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.level.code,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: i == marks.length
                            ? Palette.ink
                            : Palette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
}

class _OperationPrompt extends StatelessWidget {
  const _OperationPrompt({required this.item});

  final OperationItem item;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          LevelChip(_levelLabel(item.level), background: Palette.ink),
          const SizedBox(height: 28),
          // Shown large so the child can read it from the assessor's screen.
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 36),
              child: Column(
                children: [
                  Text(
                    '${item.left}',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                      height: 1.1,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.operation.symbol,
                        style: const TextStyle(
                            fontSize: 44, color: Palette.inkMuted),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${item.right}',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _AnswerKey(value: item.answerKey),
        ],
      );
}

class _RecognitionPrompt extends StatelessWidget {
  const _RecognitionPrompt({required this.item});

  final NumberRecognitionItem item;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          LevelChip(_levelLabel(item.level), background: Palette.ink),
          const SizedBox(height: 12),
          const Text(
            'Ask the child to read these aloud',
            style: TextStyle(fontSize: 15, color: Palette.inkMuted),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 20,
                children: [
                  for (final n in item.numbers)
                    Text(
                      '$n',
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Passes with ${item.passThreshold} of ${item.numbers.length} correct',
            style: const TextStyle(fontSize: 14, color: Palette.inkMuted),
          ),
        ],
      );
}

/// The expected answer, for the assessor only — randomised numbers mean they
/// cannot mark from memory.
class _AnswerKey extends StatelessWidget {
  const _AnswerKey({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Palette.tealWash,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Palette.teal.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.key_outlined, size: 18, color: Palette.tealDark),
            const SizedBox(width: 10),
            const Text('Answer',
                style: TextStyle(
                    fontSize: 13,
                    color: Palette.tealDark,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(width: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Palette.tealDark,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
}

class _PassFailControls extends StatelessWidget {
  const _PassFailControls({required this.onMark});

  final void Function(bool correct) onMark;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 72,
              child: FilledButton.icon(
                onPressed: () => onMark(false),
                icon: const Icon(Icons.close, size: 26),
                label: const Text('Incorrect'),
                style: FilledButton.styleFrom(
                  backgroundColor: Palette.rustWash,
                  foregroundColor: Palette.rust,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 72,
              child: FilledButton.icon(
                onPressed: () => onMark(true),
                icon: const Icon(Icons.check, size: 26),
                label: const Text('Correct'),
                style: FilledButton.styleFrom(
                  backgroundColor: Palette.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
}

/// Recognition is scored as a count, not pass/fail — the assessor records how
/// many numbers the child read, and the threshold decides the rest.
class _RecognitionControls extends StatelessWidget {
  const _RecognitionControls({required this.item, required this.onCount});

  final NumberRecognitionItem item;
  final void Function(int count) onCount;

  @override
  Widget build(BuildContext context) {
    final total = item.numbers.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How many did they read correctly?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var n = 0; n <= total; n++) ...[
              if (n > 0) const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: OutlinedButton(
                    onPressed: () => onCount(n),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: item.passedWith(n)
                          ? Palette.tealWash
                          : Palette.rustWash,
                      foregroundColor:
                          item.passedWith(n) ? Palette.tealDark : Palette.rust,
                      side: BorderSide(
                        color: item.passedWith(n)
                            ? Palette.teal.withValues(alpha: 0.4)
                            : Palette.rust.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text('$n',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

String _levelLabel(NumeracyLevel level) => switch (level) {
      NumeracyLevel.numberRecognition1To9 => 'Number recognition 1–9',
      NumeracyLevel.numberRecognition10ToMax => 'Number recognition 10+',
      NumeracyLevel.addition => 'Addition',
      NumeracyLevel.subtraction => 'Subtraction',
      NumeracyLevel.multiplication => 'Multiplication',
      NumeracyLevel.division => 'Division',
      NumeracyLevel.beginner => 'Beginner',
    };
