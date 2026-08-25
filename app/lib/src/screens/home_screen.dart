import 'package:flutter/material.dart';
import '../models/student.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'assessment_screen.dart';
import 'result_screen.dart';
import 'setup_sheet.dart';
import 'summary_screen.dart';

/// The class register, and the entry point to levelling a child.
///
/// Assessment is one child at a time, as it already is in the field, so the
/// register is the natural home screen: pick the next child, level them, come
/// back. Progress survives across children so a class can be levelled over
/// several sittings rather than one long block.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final students = state.students;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Numeracy levelling',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                Text(
                  state.isConfigured
                      ? '${state.className} · ${state.teacherCount} teachers · '
                          '${state.assessedCount} of ${students.length} assessed'
                      : state.className,
                  style: const TextStyle(
                      fontSize: 13, color: Palette.inkMuted),
                ),
              ],
            ),
            actions: [
              if (state.isConfigured)
                IconButton(
                  tooltip: 'Teachers and classes',
                  icon: const Icon(Icons.school_outlined),
                  onPressed: () => showTeacherCountSheet(
                    context,
                    state,
                    onConfirmed: () {},
                  ),
                ),
              if (state.assessedCount > 0)
                IconButton(
                  tooltip: 'Groups',
                  icon: const Icon(Icons.groups_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SummaryScreen(state: state),
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'sample') _loadSample(context, state);
                  if (v == 'clear') state.clearAllResults();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'sample', child: Text('Load sample class')),
                  const PopupMenuItem(
                      value: 'clear', child: Text('Clear all results')),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: students.isEmpty
                ? _EmptyRoster(state: state)
                : Column(
                    children: [
                      if (state.allAssessed) _AllDoneBanner(state: state),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                          itemCount: students.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) => _StudentRow(
                            state: state,
                            student: students[i],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          floatingActionButton: students.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _addChild(context, state),
                  backgroundColor: Palette.teal,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Add child'),
                ),
        );
      },
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.state, required this.student});

  final AppState state;
  final Student student;

  void _open(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => student.isAssessed
          ? ResultScreen(state: state, student: student)
          : AssessmentScreen(state: state, student: student),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final plan = state.plan;
    final assigned = plan == null ? null : student.assignedClass(plan);
    return Card(
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: student.isAssessed
                      ? Palette.tealWash
                      : const Color(0xFFF1F4F3),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Text(
                  student.initials,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: student.isAssessed
                        ? Palette.tealDark
                        : Palette.inkMuted,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${student.firstName} ${student.surname}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      assigned == null
                          ? 'Not yet assessed'
                          : '${assigned.label} · ${assigned.teacherLabel}',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: assigned == null
                            ? Palette.inkMuted
                            : Palette.tealDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (student.needsConfirmation)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.help_outline,
                      color: Palette.ochre, size: 20),
                ),
              if (plan != null && student.isAssessed && student.isMoved(plan))
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.swap_horiz,
                      color: Palette.ochre, size: 18),
                ),
              if (student.level != null)
                LevelChip(student.level!.code, background: Palette.teal)
              else
                const Icon(Icons.chevron_right, color: Palette.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllDoneBanner extends StatelessWidget {
  const _AllDoneBanner({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Palette.tealWash,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Palette.teal, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Palette.teal),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Whole class assessed — groups are ready.',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SummaryScreen(state: state),
              )),
              child: const Text('View'),
            ),
          ],
        ),
      );
}

class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.groups_outlined,
                    size: 56, color: Palette.inkMuted),
                const SizedBox(height: 20),
                const Text('No class register yet',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                  'Names are entered once from the school register, then '
                  'reused all term.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Palette.inkMuted),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => _loadSample(context, state),
                  child: const Text('Load sample class'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _addChild(context, state),
                  child: const Text('Add a child'),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Number of teachers has to be known before the register exists, because it
/// decides how many classes there are to group children into.
void _loadSample(BuildContext context, AppState state) {
  if (state.isConfigured) {
    state.loadSampleRoster();
    return;
  }
  showTeacherCountSheet(context, state,
      onConfirmed: state.loadSampleRoster);
}

void _addChild(BuildContext context, AppState state) {
  if (state.isConfigured) {
    _showAddStudent(context, state);
    return;
  }
  showTeacherCountSheet(
    context,
    state,
    onConfirmed: () => _showAddStudent(context, state),
  );
}

void _showAddStudent(BuildContext context, AppState state) {
  final first = TextEditingController();
  final last = TextEditingController();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add child to register',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: first,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'First name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: last,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Surname'),
            onSubmitted: (_) {
              state.addStudent(first.text, last.text);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              state.addStudent(first.text, last.text);
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
}
