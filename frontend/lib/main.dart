import 'package:core/gen/strings.g.dart' as core;
import 'package:flutter/material.dart';
import 'package:frontend/gen/strings.g.dart' as frontend;

void main() {
  runApp(
    core.TranslationProvider(
      child: frontend.TranslationProvider(child: const MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Hello'),
      ),
    );
  }
}
