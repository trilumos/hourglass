import 'package:flutter/material.dart';
import 'theme.dart';

class HourglassApp extends StatelessWidget {
  const HourglassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hourglass',
      debugShowCheckedModeBanner: false,
      theme: hourglassDarkTheme(),
      home: const Scaffold(
        body: Center(child: Text('Hourglass')),
      ),
    );
  }
}
