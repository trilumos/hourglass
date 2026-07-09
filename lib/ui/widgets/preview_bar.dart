import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../app/theme_providers.dart';
import '../../app/tokens.dart';

/// While a locked theme is being previewed: a small floating pill (eye icon +
/// "Get" + ✕) overlaid on the screen. It takes NO layout space — the screen
/// underneath keeps its normal size — and it is draggable, so it can never
/// permanently cover a control. Defaults to top-centre, over the wordmark.
/// "Get" opens the Themes screen to buy / Get Pro; ✕ clears the preview (the
/// preview is in-memory only, so a relaunch also clears it). Renders nothing
/// when not previewing. Layer it as the LAST child of a Stack over the body.
class PreviewBar extends ConsumerStatefulWidget {
  /// Opens the place to buy the theme (the Themes screen). Provided by the
  /// screen, which holds the navigator.
  final VoidCallback onGetIt;
  const PreviewBar({super.key, required this.onGetIt});

  @override
  ConsumerState<PreviewBar> createState() => _PreviewBarState();
}

class _PreviewBarState extends ConsumerState<PreviewBar> {
  // Footprint used for drag clamping. The pill's text scale is clamped below,
  // so this generous estimate always covers the real intrinsic size — no
  // measuring pass needed. Height honours the ≥48dp hit-area rule.
  static const _pillW = 150.0;
  static const _pillH = HgSize.touchMin;

  /// Where the user last dragged the pill. Static so the position sticks for
  /// the whole preview session, across screens and rebuilds. Null = default
  /// (top-centre, over the wordmark — never over a control).
  static Offset? _dragged;

  @override
  Widget build(BuildContext context) {
    final previewId = ref.watch(previewThemeProvider);
    if (previewId == null) return const SizedBox.shrink();
    final name = HgThemes.byId(previewId).name;
    final hg = context.hg;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, box) {
          final maxX = (box.maxWidth - _pillW).clamp(0.0, double.infinity);
          final maxY = (box.maxHeight - _pillH).clamp(0.0, double.infinity);
          final pos = _dragged ?? Offset(maxX / 2, 0);
          final left = pos.dx.clamp(0.0, maxX);
          final top = pos.dy.clamp(0.0, maxY);
          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  onPanUpdate: (d) => setState(() {
                    _dragged = Offset(
                      (left + d.delta.dx).clamp(0.0, maxX),
                      (top + d.delta.dy).clamp(0.0, maxY),
                    );
                  }),
                  child: _pill(context, name, hg),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pill(BuildContext context, String name, HgTokens hg) {
    // A tap zone that spans the pill's full height (≥48dp target).
    Widget hit({
      required Widget child,
      required VoidCallback onTap,
      required String label,
    }) {
      return Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _pillH,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(child: child),
            ),
          ),
        ),
      );
    }

    return Material(
      color: hg.surfaceRaised,
      elevation: 6,
      shape: StadiumBorder(side: BorderSide(color: hg.hairline)),
      clipBehavior: Clip.antiAlias,
      // System-control sizing: cap the text scale so extra-large fonts can't
      // balloon the pill (it must stay notch-sized and off the content).
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: HgSpacing.md),
            Tooltip(
              message: 'Previewing $name',
              child: Icon(
                Icons.visibility_outlined,
                size: HgSize.iconSm,
                color: hg.accent,
              ),
            ),
            hit(
              label: 'Get $name',
              onTap: widget.onGetIt,
              child: Text(
                'Get',
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hg.accent,
                ),
              ),
            ),
            Container(width: 1, height: 20, color: hg.hairline),
            hit(
              label: 'Exit preview',
              onTap: () => ref.read(previewThemeProvider.notifier).clear(),
              child: Icon(
                Icons.close_rounded,
                size: HgSize.iconSm,
                color: hg.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
