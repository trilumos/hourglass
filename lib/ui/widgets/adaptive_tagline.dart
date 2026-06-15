import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'typewriter_tagline.dart';

/// The positioning line, shown as a centered caption under the hourglass: a
/// typewriter that types "Train your focus …" and cycles the phrase. Always on
/// (it's a quiet branded caption now, not a top-of-screen re-pitch).
class AdaptiveTagline extends StatelessWidget {
  const AdaptiveTagline({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: ValueKey('tagline'),
      padding: EdgeInsets.only(top: HgSpacing.sm),
      child: TypewriterTagline(),
    );
  }
}
