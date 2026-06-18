import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import '../data/image_storage_service.dart';
import 'widgets/primary_button.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';

/// Edit the profile name (required) and photo (optional). Save is disabled until
/// the name is non-empty, so a blank profile can't be saved.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _controller = TextEditingController();
  String? _pendingPath;
  File? _pendingFile;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _load();
  }

  void _onChanged() => setState(() {});

  Future<void> _load() async {
    final profile = await ref.read(profileProvider.future);
    if (!mounted) return;
    _controller.text = profile.name;
    _pendingPath = profile.imagePath;
    if (profile.imagePath != null) {
      _pendingFile =
          await ref.read(imageStorageProvider).resolve(profile.imagePath!);
    }
    if (mounted) setState(() => _loaded = true);
  }

  bool get _canSave => _controller.text.trim().isNotEmpty && !_saving;

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (picked == null) return; // cancelled
    try {
      final storage = ref.read(imageStorageProvider);
      final rel = await storage.saveAvatar(File(picked.path));
      final file = await storage.resolve(rel);
      await FileImage(file).evict(); // bust the cache (fixed filename)
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

  Future<void> _removePhoto() async {
    final path = _pendingPath;
    if (path != null) await ref.read(imageStorageProvider).deleteAvatar(path);
    if (!mounted) return;
    setState(() {
      _pendingPath = null;
      _pendingFile = null;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(profileRepositoryProvider).update(
          name: _controller.text.trim(),
          imagePath: _pendingPath,
          clearImage: _pendingPath == null,
        );
    ref.invalidate(profileProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: !_loaded
                ? const SizedBox.shrink()
                : ListView(
                    children: [
                      const SizedBox(height: HgSpacing.sm),
                      const ScreenHeader(title: 'Edit profile'),
                      const SizedBox(height: HgSpacing.xl),
                      Center(child: _avatar(hg)),
                      const SizedBox(height: HgSpacing.md),
                      Center(
                        child: Wrap(
                          spacing: HgSpacing.md,
                          children: [
                            TextButton(
                              onPressed: _pickPhoto,
                              child: Text(_pendingFile == null
                                  ? 'Add photo'
                                  : 'Change photo'),
                            ),
                            if (_pendingFile != null)
                              TextButton(
                                onPressed: _removePhoto,
                                child: const Text('Remove'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: HgSpacing.lg),
                      _NameLabel(),
                      const SizedBox(height: HgSpacing.sm),
                      TextField(
                        controller: _controller,
                        maxLength: 40,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 16,
                          color: hg.textPrimary,
                        ),
                        buildCounter: (_,
                                {required currentLength,
                                required isFocused,
                                maxLength}) =>
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
                      const SizedBox(height: HgSpacing.xl),
                      PrimaryButton(
                        label: 'Save',
                        onPressed: _canSave ? _save : null,
                      ),
                      const SizedBox(height: HgSpacing.xl),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _avatar(HgTokens hg) {
    const size = 112.0;
    if (_pendingFile == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: hg.surfaceRaised,
          shape: BoxShape.circle,
          border: Border.all(color: hg.hairline),
        ),
        child: Icon(Icons.person_outline_rounded,
            size: size * 0.5, color: hg.textMuted),
      );
    }
    return ClipOval(
      child: Image.file(
        _pendingFile!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }
}

class _NameLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Text(
      'NAME',
      style: TextStyle(
        fontFamily: HgFont.sans,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
        color: hg.textMuted,
      ),
    );
  }
}
