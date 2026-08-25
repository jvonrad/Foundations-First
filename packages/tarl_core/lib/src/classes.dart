/// How a school's teachers are mapped onto the ladder.
///
/// The ladder has six teachable rungs but a school rarely has six teachers
/// free, so rungs are shared out as evenly as the count allows. With three
/// teachers that gives two rungs each — number recognition, the additive
/// operations, then the multiplicative ones — which is how the levels pair up
/// pedagogically as well as arithmetically.
///
/// Where the rungs do not divide evenly, the larger classes go at the top.
/// The delivery guide is explicit about the direction:
///
///   "Avoid mixing levels, and if you do, only do so for higher levels."
///   "Prioritize maintaining similarly levelled groups at lower levels."
///
/// So a child furthest behind always sits in a class at least as tightly
/// targeted as the ones above them.
library;

import 'levels.dart';

/// One class in this school's setup, taught by one teacher.
class TeachingClass {
  const TeachingClass({
    required this.index,
    required this.groups,
    required this.upperLimit,
  });

  /// Zero-based position on the ladder, lowest first.
  final int index;

  /// The ladder rungs this class covers. More than one means levels are
  /// mixed here.
  final List<TeachingGroup> groups;

  /// Largest number used in recognition, so labels can name the real range
  /// rather than a vague "10+".
  final int upperLimit;

  bool get isMixed => groups.length > 1;

  bool get _isBothRecognitionRungs =>
      groups.length == 2 &&
      groups.first == TeachingGroup.numberRecognition1To9 &&
      groups.last == TeachingGroup.numberRecognition10ToMax;

  String get label {
    if (groups.length == 1) return groups.single.labelWithLimit(upperLimit);
    if (_isBothRecognitionRungs) return 'Number recognition 1–$upperLimit';
    if (groups.length == 2) {
      return '${groups.first.shortLabel} & ${groups.last.shortLabel}';
    }
    return '${groups.first.shortLabel} to ${groups.last.shortLabel}';
  }

  String get teacherLabel => 'Teacher ${index + 1}';

  bool covers(TeachingGroup group) => groups.contains(group);

  @override
  String toString() => '$teacherLabel · $label';
}

/// The class structure for a given number of teachers.
class ClassPlan {
  ClassPlan._(this.teacherCount, this.classes);

  /// Fewer than two classes is not Teaching at the Right Level — it is just
  /// teaching, which is the situation the programme exists to change.
  static const int minTeachers = 2;

  /// There are only six teachable rungs, so six is the most classes that can
  /// differ from one another. Teachers beyond that share a class rather than
  /// creating a distinction the ladder cannot express.
  static int get maxDistinctClasses => TeachingGroup.values.length;

  factory ClassPlan.forTeachers(int teacherCount, {int upperLimit = 99}) {
    if (teacherCount < minTeachers) {
      throw ArgumentError.value(
        teacherCount,
        'teacherCount',
        'TaRL needs at least $minTeachers classes to group children into',
      );
    }

    final rungs = TeachingGroup.values;
    final classCount =
        teacherCount < maxDistinctClasses ? teacherCount : maxDistinctClasses;

    // Even split, with the remainder handed to the highest classes so the
    // lower ones stay at least as tightly targeted.
    final base = rungs.length ~/ classCount;
    final remainder = rungs.length % classCount;
    final firstEnlarged = classCount - remainder;

    final classes = <TeachingClass>[];
    var cursor = 0;
    for (var i = 0; i < classCount; i++) {
      final size = i >= firstEnlarged ? base + 1 : base;
      classes.add(TeachingClass(
        index: i,
        groups: rungs.sublist(cursor, cursor + size),
        upperLimit: upperLimit,
      ));
      cursor += size;
    }

    return ClassPlan._(teacherCount, classes);
  }

  final int teacherCount;
  final List<TeachingClass> classes;

  /// Teachers with no distinct rung of their own, who double up on a class.
  int get sharingTeachers =>
      teacherCount > classes.length ? teacherCount - classes.length : 0;

  TeachingClass classForGroup(TeachingGroup group) =>
      classes.firstWhere((c) => c.covers(group));

  TeachingClass classForLevel(NumeracyLevel level) =>
      classForGroup(level.teachingGroup);

  TeachingClass byIndex(int index) => classes[index];
}
