import 'package:tarl_core/tarl_core.dart';

/// A child on the class register.
///
/// Names come from the school register, entered once per term — never typed
/// by the child and never read by a model. Handwritten Kenyan proper names
/// are a hard recognition problem and a bad place to spend accuracy.
class Student {
  Student({
    required this.id,
    required this.firstName,
    required this.surname,
    required this.grade,
  });

  final String id;
  final String firstName;
  final String surname;

  /// Standard and stream as the school writes it, e.g. "4B".
  final String grade;

  /// Null until this child has been levelled.
  LevellingResult? result;

  /// Set when a teacher moves this child to a different class than their
  /// level implies. Stored as a class index and kept alongside [result]
  /// rather than replacing it, so the measured level and the human decision
  /// are both on the record.
  int? classOverride;

  /// The level the assessment measured. Never overridden — a teacher can move
  /// a child to a different class, but cannot rewrite what the child did.
  NumeracyLevel? get level => result?.level;

  TeachingGroup? get teachingGroup => level?.teachingGroup;

  /// The class this child sits in: the override if a teacher set one,
  /// otherwise the one their level maps to.
  TeachingClass? assignedClass(ClassPlan plan) {
    final measured = level;
    if (measured == null) return null;
    final index = classOverride;
    return index == null ? plan.classForLevel(measured) : plan.byIndex(index);
  }

  bool isMoved(ClassPlan plan) =>
      classOverride != null &&
      classOverride != plan.classForLevel(level!).index;

  bool get isAssessed => result != null;

  bool get needsConfirmation => result?.isInconsistent ?? false;

  String get displayName => '$firstName ${surname.isEmpty ? '' : surname[0]}.';

  String get initials =>
      '${firstName.isEmpty ? '?' : firstName[0]}${surname.isEmpty ? '' : surname[0]}';
}
