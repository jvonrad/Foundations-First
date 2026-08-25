/// Core assessment logic for TaRL numeracy levelling.
///
/// Deliberately free of Flutter and of any I/O: placement decisions are pure
/// functions of a child's marks, so they can be tested exhaustively and
/// explained afterwards.
library;

export 'src/classes.dart';
export 'src/config.dart';
export 'src/generator.dart';
export 'src/items.dart';
export 'src/ladder.dart';
export 'src/levels.dart';
