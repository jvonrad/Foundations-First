import 'package:flutter/material.dart';

import 'src/screens/home_screen.dart';
import 'src/state/app_state.dart';
import 'src/theme.dart';

void main() => runApp(const FoundationsFirstApp());

class FoundationsFirstApp extends StatefulWidget {
  const FoundationsFirstApp({super.key});

  @override
  State<FoundationsFirstApp> createState() => _FoundationsFirstAppState();
}

class _FoundationsFirstAppState extends State<FoundationsFirstApp> {
  final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Foundations First',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: HomeScreen(state: _state),
      );
}
