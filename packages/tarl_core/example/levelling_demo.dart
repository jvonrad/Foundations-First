import 'dart:math';

import 'package:tarl_core/tarl_core.dart';

/// Prints a sample levelling form and the placement it produces for a few
/// mark patterns. Run with: dart run example/levelling_demo.dart
void main() {
  final gen = ItemGenerator(random: Random(42));
  final form = gen.generateForm();

  print('Sample levelling form\n');
  for (final item in form) {
    print('  ${item.level.code.padRight(3)} '
        '${item.toString().padRight(30)} → ${item.answerKey}');
  }

  print('\nPlacement by mark pattern\n');
  const patterns = [
    [false, false, false, false, false, false],
    [true, true, false, false, false, false],
    [true, true, true, true, false, false],
    [true, true, true, false, true, false],
    [true, true, true, true, true, true],
  ];

  for (final pattern in patterns) {
    final result = assignLevel([
      for (var i = 0; i < form.length; i++)
        ItemResult(item: form[i], correct: pattern[i]),
    ]);
    final marks = pattern.map((ok) => ok ? '✓' : '✗').join(' ');
    final flag = result.isInconsistent ? '   ⚠ confirm with assessor' : '';
    print('  $marks   ${result.level.code.padRight(3)} '
        '→ ${result.teachingGroup.label}$flag');
  }
}
