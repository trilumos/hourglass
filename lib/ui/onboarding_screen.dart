import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import '../data/image_storage_service.dart';
import '../hourglass/hourglass_view.dart';
import 'crop_avatar_screen.dart';
import 'home_screen.dart';
import 'widgets/primary_button.dart';
import 'widgets/screen_background.dart';

/// First-run onboarding: a persistent hourglass hero above a 5-page PageView
/// (4 teaching beats + a name/photo profile page). The hero drains 10% deeper
/// per page (10%→50%). Skippable; finishing saves the profile, drains the
/// hourglass fully, flips it upright (sand back on top), then lands on Home.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _TeachPage {
  final String headline;
  final String subcopy;
  const _TeachPage(this.headline, this.subcopy);
}

const _teach = <_TeachPage>[
  _TeachPage(
    'Train your focus like an athlete.',
    'Focus is a skill you can build — with real training, and real recovery.',
  ),
  _TeachPage(
    'Find your flow.',
    "In Flow, the first minutes feel hard — that's the struggle. Stay with it "
        'and focus takes over: effortless, absorbed.',
  ),
  _TeachPage(
    'Rest without your phone.',
    'Then a short, boring break lets focus recover — no scrolling. Struggle, '
        'flow, recover: one full block.',
  ),
  _TeachPage(
    'Watch your focus grow.',
    'Your Focus Score (0–100) tracks your focus ability as you train. Pomodoro '
        'and Custom are training wheels — Flow is the real method. The full '
        'guide is in Settings → How it works.',
  ),
];

const _profileIndex = 4; // 0..3 teach, 4 profile
const _pageCount = 5;

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  // Flips the hero upright on finish (rotateX π→0), same mechanic as a session
  // start. Rests at 1.0 (= upright) so onboarding pages aren't rotated.
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    value: 1.0,
  );
  int _index = 0;
  String? _pendingPath;
  File? _pendingFile;
  bool _saving = false;
  bool _finishing = false; // draining the hero to 100%
  bool _flipping = false; // hero snapped to full (0), flipping upright

  @override
  void initState() {
    super.initState();
    // Rebuild as the pages scroll so the hero drain + content fade track the
    // swipe in real time (buttery, not stepped only on settle).
    _pageCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pageCtrl.removeListener(_onScroll);
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _flip.dispose();
    super.dispose();
  }

  /// Live fractional page (tracks the swipe), falling back to the settled index.
  double get _page {
    try {
      if (_pageCtrl.hasClients) {
        final p = _pageCtrl.page;
        if (p != null) return p;
      }
    } catch (_) {}
    return _index.toDouble();
  }

  // Per page the drain deepens 10% (page 1 = 10% … profile page = 50%), tracking
  // the swipe live; the sand keeps falling the whole time (the stream animates
  // whenever 0 < drain < 1). On finish: drain fully (1.0), then snap to full
  // (0.0) hidden by the flip.
  double get _heroProgress {
    if (_flipping) return 0.0;
    if (_finishing) return 1.0;
    return (0.1 * (_page + 1)).clamp(0.1, 0.5);
  }

  static const _pageTurn = Duration(milliseconds: 500);

  void _onCta() {
    if (_index < _profileIndex) {
      _pageCtrl.nextPage(duration: _pageTurn, curve: HgMotion.calm);
    } else {
      _finish(save: true);
    }
  }

  void _onSkip() {
    if (_index < _profileIndex) {
      _pageCtrl.animateToPage(_profileIndex,
          duration: _pageTurn, curve: HgMotion.calm);
    } else {
      _finish(save: false);
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 2048);
    if (picked == null || !mounted) return;
    final bytes = await Navigator.of(context).push<Uint8List?>(
      MaterialPageRoute(
        builder: (_) => CropAvatarScreen(source: File(picked.path)),
      ),
    );
    if (bytes == null || !mounted) return;
    try {
      final storage = ref.read(imageStorageProvider);
      final rel = await storage.saveAvatarBytes(bytes);
      final file = await storage.resolve(rel);
      await FileImage(file).evict();
      if (!mounted) return;
      setState(() {
        _pendingPath = rel;
        _pendingFile = file;
      });
    } on ImageStorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _finish({required bool save}) async {
    if (_saving) return;
    // Begin draining the hero fully (50% → 100%).
    setState(() {
      _saving = true;
      _finishing = true;
    });
    // Persist while the sand drains.
    final name = _nameCtrl.text.trim();
    if (save && (name.isNotEmpty || _pendingPath != null)) {
      await ref.read(profileRepositoryProvider).update(
            name: name.isEmpty ? null : name,
            imagePath: _pendingPath,
          );
    }
    await ref
        .read(settingsRepositoryProvider)
        .setBool(SettingsKeys.onboardingComplete, true);
    // Let the sand fall to the bottom.
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;
    // Flip: snap to a full hourglass (hidden by the upside-down flip start),
    // then rotate it upright so the filled part lands on top — like Home.
    setState(() => _flipping = true);
    await _flip.forward(from: 0);
    if (!mounted) return;
    ref.invalidate(profileProvider);
    ref.invalidate(onboardingCompleteProvider);
    // Cross-fade to Home while the (now full, upright) hourglass Hero-flies to
    // its Home position — no cut, no fill pop.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: HgMotion.calm),
          child: child,
        ),
      ),
    );
  }

  /// Cross-fades + lifts page content as it scrolls past centre (buttery, vs a
  /// rigid horizontal slide).
  Widget _paged(int i, Widget child) {
    final d = (_page - i).abs().clamp(0.0, 1.0);
    return Opacity(
      opacity: 1 - d,
      child: Transform.translate(offset: Offset(0, d * 16), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: Column(
              children: [
                // Chrome: Skip top-right.
                SizedBox(
                  height: HgSize.touchMin,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _saving ? null : _onSkip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 14,
                          color: hg.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                // Persistent hero (does not page). Flips upright on finish.
                Expanded(
                  flex: 5,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _flip,
                      builder: (context, child) {
                        final t = Curves.easeOutCubic.transform(_flip.value);
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0012) // perspective
                            ..rotateX((1 - t) * math.pi),
                          child: child,
                        );
                      },
                      child: HourglassView(
                        progress: _heroProgress,
                        heroTag: kHourglassHeroTag,
                      ),
                    ),
                  ),
                ),
                // Paged content.
                Expanded(
                  flex: 6,
                  child: PageView(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _index = i),
                    children: [
                      for (var i = 0; i < _teach.length; i++)
                        _paged(i, _TeachView(page: _teach[i])),
                      _paged(
                        _profileIndex,
                        _ProfileView(
                          controller: _nameCtrl,
                          pendingFile: _pendingFile,
                          onPickPhoto: _saving ? null : _pickPhoto,
                        ),
                      ),
                    ],
                  ),
                ),
                // Dots.
                Semantics(
                  label: 'Step ${_index + 1} of $_pageCount',
                  child: _Dots(count: _pageCount, index: _index),
                ),
                const SizedBox(height: HgSpacing.lg),
                PrimaryButton(
                  label: _index < _profileIndex ? 'Continue' : 'Begin',
                  onPressed: _saving ? null : _onCta,
                ),
                const SizedBox(height: HgSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeachView extends StatelessWidget {
  final _TeachPage page;
  const _TeachView({required this.page});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          page.headline,
          style: TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 30,
            fontWeight: FontWeight.w500,
            height: 1.15,
            letterSpacing: -0.5,
            color: hg.textPrimary,
          ),
        ),
        const SizedBox(height: HgSpacing.md),
        Text(
          page.subcopy,
          style: TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 16,
            height: 1.5,
            color: hg.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ProfileView extends StatelessWidget {
  final TextEditingController controller;
  final File? pendingFile;
  final VoidCallback? onPickPhoto;
  const _ProfileView({
    required this.controller,
    required this.pendingFile,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: HgSpacing.md),
          Text(
            'What should we call you?',
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 30,
              fontWeight: FontWeight.w500,
              height: 1.15,
              letterSpacing: -0.5,
              color: hg.textPrimary,
            ),
          ),
          const SizedBox(height: HgSpacing.lg),
          GestureDetector(
            onTap: onPickPhoto,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                _AvatarRing(file: pendingFile),
                const SizedBox(width: HgSpacing.md),
                Text(
                  pendingFile == null ? 'Add a photo' : 'Change photo',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 15,
                    color: hg.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: HgSpacing.lg),
          TextField(
            controller: controller,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 16,
              color: hg.textPrimary,
            ),
            buildCounter: (_,
                    {required currentLength, required isFocused, maxLength}) =>
                null,
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(color: hg.textMuted),
              filled: true,
              fillColor: hg.surfaceRaised,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(HgRadius.sm),
                borderSide: BorderSide(color: hg.hairline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(HgRadius.sm),
                borderSide: BorderSide(color: hg.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(HgRadius.sm),
                borderSide: BorderSide(color: hg.accent),
              ),
            ),
          ),
          const SizedBox(height: HgSpacing.sm),
          Text(
            'Optional — you can add or change this later in your profile.',
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 13,
              height: 1.4,
              color: hg.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  final File? file;
  const _AvatarRing({required this.file});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    const size = 56.0;
    if (file == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: hg.surfaceRaised,
          shape: BoxShape.circle,
          border: Border.all(color: hg.hairline),
        ),
        child: Icon(Icons.add_a_photo_outlined,
            size: size * 0.42, color: hg.textMuted),
      );
    }
    return ClipOval(
      child: Image.file(file!,
          width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: HgMotion.fast,
            curve: HgMotion.calm,
            margin: const EdgeInsets.symmetric(horizontal: HgSpacing.xs),
            height: 6,
            width: i == index ? 20 : 6,
            decoration: BoxDecoration(
              color: i == index ? hg.accent : hg.hairline,
              borderRadius: BorderRadius.circular(HgRadius.pill),
            ),
          ),
      ],
    );
  }
}
