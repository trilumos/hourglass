import 'dart:io';
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
/// (4 teaching beats + a name/photo profile page). Skippable; finishing saves
/// the profile, marks onboarding done, and flies the hero into Home.
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

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  int _index = 0;
  String? _pendingPath;
  File? _pendingFile;
  bool _saving = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // Drain deepens 10% per page (page 1 = 10% … profile page = 50%); the sand
  // keeps falling the whole time (the stream animates whenever 0 < drain < 1).
  // Home then shows its own filled, no-fall hourglass.
  double get _heroProgress => 0.1 * (_index + 1);

  void _onCta() {
    if (_index < _profileIndex) {
      _pageCtrl.nextPage(duration: HgMotion.medium, curve: HgMotion.calm);
    } else {
      _finish(save: true);
    }
  }

  void _onSkip() {
    if (_index < _profileIndex) {
      _pageCtrl.animateToPage(_profileIndex,
          duration: HgMotion.medium, curve: HgMotion.calm);
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
    setState(() => _saving = true);
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
    ref.invalidate(profileProvider);
    ref.invalidate(onboardingCompleteProvider);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
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
                // Persistent hero (does not page).
                Expanded(
                  flex: 5,
                  child: Center(
                    child: HourglassView(
                      progress: _heroProgress,
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
                      for (final p in _teach) _TeachView(page: p),
                      _ProfileView(
                        controller: _nameCtrl,
                        pendingFile: _pendingFile,
                        onPickPhoto: _saving ? null : _pickPhoto,
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
