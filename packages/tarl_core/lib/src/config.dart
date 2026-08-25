/// Everything an implementer is allowed to vary.
///
/// The TaRL assessment tools are explicit that these differ by context:
/// "Implementers decide on the appropriate upper-limit, depending on the
/// goals set for the intervention." Keep them here rather than scattered
/// through the code, so a change for Kenya is a config edit and not a
/// rewrite.
library;

/// How a level is decided when a child's results are not a clean run of
/// successes followed by failures — e.g. ✓ ✗ ✓ ✗.
enum LevellingRule {
  /// The level of the *highest* item answered correctly, regardless of
  /// failures below it. This is the Botswana delivery guide read literally:
  /// "organize response papers into piles based on the last operation each
  /// student answered correctly."
  lastCorrect,

  /// The level of the last item before the *first* failure. Treats the
  /// ladder as strictly ordinal — a child who cannot subtract is not
  /// credited with multiplication.
  stopAtFirstFailure,
}

class AssessmentConfig {
  const AssessmentConfig({
    this.upperLimit = 99,
    this.numbersPerRecognitionItem = 5,
    this.recognitionPassThreshold = 4,
    this.levellingRule = LevellingRule.lastCorrect,
  })  : assert(upperLimit >= 10, 'upperLimit must allow multi-digit numbers'),
        assert(
          recognitionPassThreshold <= numbersPerRecognitionItem,
          'cannot require more correct than are shown',
        );

  /// Largest number a child is asked to read in the multi-digit recognition
  /// item. 99 for two-digit, 999 for three-digit.
  ///
  /// Note this bounds *number recognition only*. Operation items stay at the
  /// 2-digit form the levelling tool specifies; 3-digit operands appear as
  /// lesson objectives, not as levelling items.
  final int upperLimit;

  /// How many numbers are shown in one recognition item.
  final int numbersPerRecognitionItem;

  /// How many of those must be read correctly to pass.
  final int recognitionPassThreshold;

  final LevellingRule levellingRule;
}
