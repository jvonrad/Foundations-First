import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:tarl_core/tarl_core.dart';

import '../models/student.dart';

/// In-memory store for the prototype.
///
/// Deliberately not persisted yet: how records are stored, merged across the
/// assessors' phones, and retained is an open decision, and guessing at it now
/// would bake in the wrong schema. Everything here is replaceable behind the
/// same interface.
class AppState extends ChangeNotifier {
  AppState({AssessmentConfig? config, Random? random})
      : config = config ?? const AssessmentConfig(),
        _generator = ItemGenerator(
          config: config ?? const AssessmentConfig(),
          random: random,
        );

  final AssessmentConfig config;
  final ItemGenerator _generator;

  final List<Student> _students = [];
  List<Student> get students => List.unmodifiable(_students);

  String className = 'Std 4B';

  /// Null until the school has told us how many teachers are delivering TaRL.
  /// The class structure depends on it, so it is asked before the first child
  /// goes on the register.
  ClassPlan? _plan;
  ClassPlan? get plan => _plan;
  bool get isConfigured => _plan != null;

  int get teacherCount => _plan?.teacherCount ?? 0;

  void setTeacherCount(int count) {
    _plan = ClassPlan.forTeachers(count, upperLimit: config.upperLimit);
    // Class indices are only meaningful against a given plan; a different
    // number of teachers invalidates them.
    for (final s in _students) {
      s.classOverride = null;
    }
    notifyListeners();
  }

  int get assessedCount => _students.where((s) => s.isAssessed).length;
  bool get allAssessed =>
      _students.isNotEmpty && assessedCount == _students.length;

  // ------------------------------------------------------------------ roster

  void addStudent(String firstName, String surname, {String? grade}) {
    final trimmedFirst = firstName.trim();
    if (trimmedFirst.isEmpty) return;
    _students.add(Student(
      id: 'stu-${DateTime.now().microsecondsSinceEpoch}',
      firstName: trimmedFirst,
      surname: surname.trim(),
      grade: grade ?? className,
    ));
    notifyListeners();
  }

  void removeStudent(Student student) {
    _students.remove(student);
    notifyListeners();
  }

  /// Seeds a class so the flow can be exercised without typing 45 names.
  void loadSampleRoster() {
    _students.clear();
    const names = [
      ['Amina', 'Wanjiru'],
      ['Joseph', 'Kamau'],
      ['Mercy', 'Achieng'],
      ['Daniel', 'Otieno'],
      ['Faith', 'Njeri'],
      ['Brian', 'Mutua'],
      ['Grace', 'Akinyi'],
      ['Samuel', 'Kipchoge'],
      ['Esther', 'Wambui'],
      ['Peter', 'Ochieng'],
      ['Halima', 'Abdi'],
      ['Kevin', 'Maina'],
    ];
    for (final (i, n) in names.indexed) {
      _students.add(Student(
        id: 'sample-$i',
        firstName: n[0],
        surname: n[1],
        grade: className,
      ));
    }
    notifyListeners();
  }

  void clearAllResults() {
    for (final s in _students) {
      s.result = null;
      s.classOverride = null;
    }
    notifyListeners();
  }

  // -------------------------------------------------------------- assessment

  /// A fresh form for one child. Numbers differ per child, which is why the
  /// assessor is always shown the answer key.
  List<Item> newFormFor(Student student) => _generator.generateForm();

  void recordResult(Student student, List<ItemResult> results) {
    student.result = assignLevel(results, config: config);
    student.classOverride = null;
    notifyListeners();
  }

  /// Moves a child to a different class. Passing the class their level already
  /// implies clears the override rather than recording a no-op.
  void moveToClass(Student student, int classIndex) {
    final natural = _plan!.classForLevel(student.level!).index;
    student.classOverride = classIndex == natural ? null : classIndex;
    notifyListeners();
  }

  // ----------------------------------------------------------------- classes

  /// Children bucketed by the class they will be taught in.
  ///
  /// Sizes are not balanced against the guide's 30–35 target yet; that needs
  /// the full grouping solver. This is the distribution it would start from.
  Map<TeachingClass, List<Student>> get classRoster {
    final plan = _plan;
    if (plan == null) return {};
    final byClass = <TeachingClass, List<Student>>{
      for (final c in plan.classes) c: [],
    };
    for (final s in _students) {
      final assigned = s.assignedClass(plan);
      if (assigned != null) byClass[assigned]!.add(s);
    }
    return byClass;
  }
}
