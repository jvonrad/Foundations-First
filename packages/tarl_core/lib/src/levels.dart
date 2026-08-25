/// The numeracy ladder.
///
/// A child is assessed at the *highest* thing they can do. The level they
/// reach determines the class they are taught in — and those are offset by
/// one, because TaRL teaches the next skill a child has *not* yet mastered.
/// See [NumeracyLevel.teachingGroup].
library;

/// What a child demonstrated they can do.
///
/// Declaration order is significant: it is the difficulty order of the
/// assessment, and [NumeracyLevel.values] is indexed against the item list
/// during levelling.
enum NumeracyLevel {
  /// Could not read single-digit numbers. Not an assessed item — the state a
  /// child is in when they fail the first one.
  beginner,

  /// Reads single-digit numbers (1–9).
  numberRecognition1To9,

  /// Reads multi-digit numbers (10 up to the configured upper limit).
  numberRecognition10ToMax,

  /// Adds two 2-digit numbers with carry-over.
  addition,

  /// Subtracts two 2-digit numbers with borrowing.
  subtraction,

  /// Multiplies a 2-digit number by a 1-digit number with carry-over.
  multiplication,

  /// Divides a 2-digit number by a 1-digit number, with a remainder.
  division;

  /// The class this child should be taught in.
  ///
  /// Offset by one: a child whose highest success was [addition] has *not*
  /// mastered subtraction, so they join the subtraction class. A child at
  /// [division] has completed the ladder and stays in the division class,
  /// working towards fluency.
  TeachingGroup get teachingGroup => switch (this) {
        NumeracyLevel.beginner => TeachingGroup.numberRecognition1To9,
        NumeracyLevel.numberRecognition1To9 =>
          TeachingGroup.numberRecognition10ToMax,
        NumeracyLevel.numberRecognition10ToMax => TeachingGroup.addition,
        NumeracyLevel.addition => TeachingGroup.subtraction,
        NumeracyLevel.subtraction => TeachingGroup.multiplication,
        NumeracyLevel.multiplication => TeachingGroup.division,
        NumeracyLevel.division => TeachingGroup.division,
      };

  /// Short code used on paper records and in exports.
  String get code => switch (this) {
        NumeracyLevel.beginner => 'B',
        NumeracyLevel.numberRecognition1To9 => 'N1',
        NumeracyLevel.numberRecognition10ToMax => 'N2',
        NumeracyLevel.addition => 'A',
        NumeracyLevel.subtraction => 'S',
        NumeracyLevel.multiplication => 'M',
        NumeracyLevel.division => 'D',
      };

  /// Levels that correspond to an assessed item, in the order they are
  /// presented. [beginner] is excluded — it is the fallback when a child
  /// fails the first item.
  static List<NumeracyLevel> get assessed =>
      values.where((l) => l != NumeracyLevel.beginner).toList();
}

/// The class a child is placed in. One per rung the ladder can teach.
enum TeachingGroup {
  numberRecognition1To9,
  numberRecognition10ToMax,
  addition,
  subtraction,
  multiplication,
  division;

  String get label => switch (this) {
        TeachingGroup.numberRecognition1To9 => 'Number recognition 1–9',
        TeachingGroup.numberRecognition10ToMax => 'Number recognition 10+',
        TeachingGroup.addition => 'Addition',
        TeachingGroup.subtraction => 'Subtraction',
        TeachingGroup.multiplication => 'Multiplication',
        TeachingGroup.division => 'Division',
      };

  /// Used when naming a class that spans several rungs, where the full label
  /// would be too long to read at a glance.
  String get shortLabel => switch (this) {
        TeachingGroup.numberRecognition1To9 => 'Numbers 1–9',
        TeachingGroup.numberRecognition10ToMax => 'Numbers 10+',
        TeachingGroup.addition => 'Addition',
        TeachingGroup.subtraction => 'Subtraction',
        TeachingGroup.multiplication => 'Multiplication',
        TeachingGroup.division => 'Division',
      };

  /// Names the real range rather than an open-ended "10+", so a teacher can
  /// see what the class actually covers.
  String labelWithLimit(int upperLimit) => switch (this) {
        TeachingGroup.numberRecognition10ToMax =>
          'Number recognition 10–$upperLimit',
        _ => label,
      };
}
