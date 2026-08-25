import 'package:flutter/material.dart';
import 'package:tarl_core/tarl_core.dart';

import '../models/student.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// The output the assessment exists to produce: which teacher takes which
/// children.
///
/// One class per teacher, so this screen is a staffing plan as much as a
/// result. Sizes are not yet balanced against the guide's 30–35 target —
/// that needs the full grouping solver.
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final plan = state.plan;
        if (plan == null) {
          return const Scaffold(
            body: Center(child: Text('No classes set up yet.')),
          );
        }

        final roster = state.classRoster;
        final unassessed =
            state.students.where((s) => !s.isAssessed).toList();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Classes',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(
                  '${plan.classes.length} classes · '
                  '${plan.teacherCount} teachers',
                  style: const TextStyle(
                      fontSize: 13, color: Palette.inkMuted),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Distribution(plan: plan, roster: roster),
                const SizedBox(height: 20),
                for (final c in plan.classes) ...[
                  _ClassCard(
                      teachingClass: c, members: roster[c]!, plan: plan),
                  const SizedBox(height: 10),
                ],
                if (plan.sharingTeachers > 0) ...[
                  const SizedBox(height: 4),
                  _Notice(
                    title: '${plan.sharingTeachers} '
                        '${plan.sharingTeachers == 1 ? "teacher" : "teachers"} '
                        'without their own level',
                    body: 'The ladder has ${ClassPlan.maxDistinctClasses} '
                        'teachable levels. Extra teachers should share the '
                        'largest class rather than split a level that cannot '
                        'be divided further.',
                  ),
                ],
                if (unassessed.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _Notice(
                    title: '${unassessed.length} not yet assessed',
                    body: '${unassessed.map((s) => s.displayName).join(', ')}'
                        '\n\nClasses are provisional until every child on the '
                        'register has been levelled.',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Class sizes at a glance — a bottom-heavy distribution is what a mentor is
/// looking for, and the guide's 30–35 target is what they balance to.
class _Distribution extends StatelessWidget {
  const _Distribution({required this.plan, required this.roster});

  final ClassPlan plan;
  final Map<TeachingClass, List<Student>> roster;

  @override
  Widget build(BuildContext context) {
    final counts = {for (final c in plan.classes) c: roster[c]!.length};
    final total = counts.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    final max = counts.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DISTRIBUTION · $total CHILDREN',
                style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: Palette.inkMuted)),
            const SizedBox(height: 16),
            SizedBox(
              height: 116,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (i, c) in plan.classes.indexed) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${counts[c]}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Container(
                            height: max == 0
                                ? 0
                                : 62 * (counts[c]! / max).clamp(0.0, 1.0) +
                                    (counts[c]! > 0 ? 4 : 0),
                            decoration: BoxDecoration(
                              color: counts[c]! > 0
                                  ? (c.isMixed
                                      ? Palette.tealDark
                                      : Palette.teal)
                                  : Palette.rule,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'T${c.index + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Palette.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.teachingClass,
    required this.members,
    required this.plan,
  });

  final TeachingClass teachingClass;
  final List<Student> members;
  final ClassPlan plan;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teachingClass.label,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Palette.tealDark),
                        ),
                        Text(
                          teachingClass.teacherLabel,
                          style: const TextStyle(
                              fontSize: 13, color: Palette.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  if (teachingClass.isMixed)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: LevelChip(
                          '${teachingClass.groups.length} levels',
                          background: Palette.ochreWash,
                          foreground: Palette.ochre),
                    ),
                  LevelChip('${members.length}', background: Palette.teal),
                ],
              ),
              const SizedBox(height: 12),
              if (members.isEmpty)
                const Text('No children at this level.',
                    style: TextStyle(
                        fontSize: 13.5,
                        color: Palette.inkMuted,
                        fontStyle: FontStyle.italic))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in members)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Palette.tealWash,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s.displayName,
                                style: const TextStyle(fontSize: 13.5)),
                            const SizedBox(width: 6),
                            Text(s.level!.code,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Palette.tealDark)),
                            if (s.isMoved(plan)) ...[
                              const SizedBox(width: 5),
                              const Icon(Icons.swap_horiz,
                                  size: 13, color: Palette.ochre),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Palette.ochreWash,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Palette.ochre.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Palette.ochre)),
            const SizedBox(height: 6),
            Text(body,
                style: const TextStyle(
                    fontSize: 13.5, color: Palette.inkMuted)),
          ],
        ),
      );
}
