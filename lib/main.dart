import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const NadeGuideApp());
}

class NadeGuideApp extends StatelessWidget {
  const NadeGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'CS Nade Guide',
      theme: theme,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
