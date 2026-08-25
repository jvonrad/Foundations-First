import 'package:flutter/material.dart';
import 'package:tarl_core/tarl_core.dart';

import '../state/app_state.dart';
import '../theme.dart';

/// Asks how many teachers are delivering TaRL, before any child is registered.
///
/// This is not a preference — it determines how many classes exist, and
/// therefore how precisely children can be grouped. Asking it up front avoids
/// levelling a whole class and only then discovering the groups cannot be
/// staffed.
Future<void> showTeacherCountSheet(
  BuildContext context,
  AppState state, {
  required VoidCallback onConfirmed,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: state.isConfigured,
    enableDrag: state.isConfigured,
    builder: (_) => _TeacherCountSheet(state: state),
  );
  if (confirmed ?? false) onConfirmed();
}

class _TeacherCountSheet extends StatefulWidget {
  const _TeacherCountSheet({required this.state});

  final AppState state;

  @override
  State<_TeacherCountSheet> createState() => _TeacherCountSheetState();
}

class _TeacherCountSheetState extends State<_TeacherCountSheet> {
  /// Six is the last count that changes anything — beyond it the ladder has no
  /// further rungs to hand out, so the top option is open-ended rather than a
  /// list of numbers that all produce the same six classes.
  static final _options = [
    for (var n = ClassPlan.minTeachers; n <= ClassPlan.maxDistinctClasses; n++)
      n
  ];

  bool get _isMaxSelected => _count >= ClassPlan.maxDistinctClasses;

  late int _count = widget.state.isConfigured
      ? widget.state.teacherCount
      : 3;

  ClassPlan get _preview =>
      ClassPlan.forTeachers(_count, upperLimit: widget.state.config.upperLimit);

  @override
  Widget build(BuildContext context) {
    final plan = _preview;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How many teachers are delivering TaRL?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'One class per teacher. Children furthest behind get a class '
                'of their own; higher levels share.',
                style: TextStyle(fontSize: 15, color: Palette.inkMuted),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final n in _options)
                    SizedBox(
                      width: n == ClassPlan.maxDistinctClasses
                          ? kTouchTarget + 14
                          : kTouchTarget,
                      height: kTouchTarget,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _count = n),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor:
                              _count == n ? Palette.teal : Colors.white,
                          foregroundColor:
                              _count == n ? Colors.white : Palette.ink,
                          side: BorderSide(
                            color: _count == n ? Palette.teal : Palette.rule,
                            width: _count == n ? 2 : 1.5,
                          ),
                        ),
                        child: Text(
                          n == ClassPlan.maxDistinctClasses ? '$n+' : '$n',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'At least ${ClassPlan.minTeachers} — with one class there is '
                'no grouping to do.',
                style: TextStyle(
                    fontSize: 13,
                    color: Palette.inkMuted,
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 22),
              const Text('THESE CLASSES WILL BE CREATED',
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: Palette.inkMuted)),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    for (final (i, c) in plan.classes.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 76,
                              child: Text(
                                c.teacherLabel,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Palette.inkMuted,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                c.label,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (c.isMixed)
                              LevelChip('${c.groups.length} levels',
                                  background: Palette.ochreWash,
                                  foreground: Palette.ochre),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_isMaxSelected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Palette.ochreWash,
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: Palette.ochre.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'One class per level — the most targeted grouping the '
                    'ladder allows. With more than '
                    '${ClassPlan.maxDistinctClasses} teachers, the extras '
                    'share the largest class rather than splitting a level '
                    'that cannot be divided further.',
                    style: const TextStyle(
                        fontSize: 13.5, color: Palette.inkMuted),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () {
                  widget.state.setTeacherCount(_count);
                  Navigator.of(context).pop(true);
                },
                child: Text(
                  widget.state.isConfigured
                      ? 'Update classes'
                      : 'Create $_count classes',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
