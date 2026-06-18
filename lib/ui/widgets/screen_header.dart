import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/tokens.dart';

/// The calm back-arrow + title header shared by the secondary screens (mirrors
/// the original Settings header). Optional trailing [actions].
class ScreenHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  const ScreenHeader({super.key, required this.title, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          iconSize: HgSize.iconMd,
          color: hg.textSecondary,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: HgSpacing.xs),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: hg.textPrimary,
            ),
          ),
        ),
        ...actions,
      ],
    );
  }
}
