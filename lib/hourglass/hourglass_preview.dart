import 'package:flutter/material.dart';
import 'hourglass_view.dart';

/// A throwaway dev screen for evaluating the hourglass on a real device:
/// scrub the slider to see the sand drain from full (0%) to empty (100%).
/// Not part of the shipped app — run via lib/hourglass_preview_main.dart.
class HourglassPreview extends StatefulWidget {
  const HourglassPreview({super.key});

  @override
  State<HourglassPreview> createState() => _HourglassPreviewState();
}

class _HourglassPreviewState extends State<HourglassPreview> {
  double _progress = 0.35;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: HourglassView(progress: _progress),
                ),
              ),
            ),
            Text(
              'drain ${(_progress * 100).round()}%',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            Slider(
              value: _progress,
              onChanged: (v) => setState(() => _progress = v),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
