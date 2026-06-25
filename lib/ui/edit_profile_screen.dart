import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import '../data/image_storage_service.dart';
import 'crop_avatar_screen.dart';
import 'photo_viewer_screen.dart';
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
  String? _onDiskPath; // the avatar file currently written to disk (if any)
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
    _onDiskPath = profile.imagePath;
    if (profile.imagePath != null) {
      _pendingFile =
          await ref.read(imageStorageProvider).resolve(profile.imagePath!);
    }
    if (mounted) setState(() => _loaded = true);
  }

  // Save when there's a name OR a photo — matches onboarding (a name is
  // optional, a photo alone is a valid profile). Requiring a name here meant a
  // name-less user could pick a photo but never save it.
  bool get _canSave =>
      !_saving &&
      (_controller.text.trim().isNotEmpty || _pendingFile != null);

  /// Pick a new photo from the gallery, then crop. No storage/media permission
  /// is needed — image_picker uses the system Photo Picker.
  Future<void> _changePhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 2048);
    if (picked == null || !mounted) return; // cancelled
    await _cropAndSave(File(picked.path));
  }

  /// Re-crop the photo already on the profile (zoom / reframe), WhatsApp-style.
  Future<void> _editCurrentPhoto() async {
    final current = _pendingFile;
    if (current == null) return;
    await _cropAndSave(current);
  }

  /// Shared: run the native cropper on [source], then persist the result.
  Future<void> _cropAndSave(File source) async {
    final bytes = await cropAvatar(context, source.path);
    if (bytes == null || !mounted) return; // crop cancelled
    try {
      final storage = ref.read(imageStorageProvider);
      final rel = await storage.saveAvatarBytes(bytes);
      final file = await storage.resolve(rel);
      await FileImage(file).evict(); // bust the cache (fixed filename)
      if (!mounted) return;
      setState(() {
        _pendingPath = rel;
        _pendingFile = file;
        _onDiskPath = rel;
      });
    } on ImageStorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _viewPhoto() {
    final path = _pendingPath;
    if (path == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PhotoViewerScreen(imagePath: path)),
    );
  }

  /// The WhatsApp-style photo menu: view, edit (re-crop current), change
  /// (pick another), or remove. Shown by tapping the avatar or its pencil badge.
  void _showPhotoOptions() {
    final hg = context.hg;
    final hasPhoto = _pendingFile != null;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        Widget option(IconData icon, String label, VoidCallback onTap,
            {bool danger = false}) {
          return ListTile(
            leading: Icon(icon,
                color: danger ? hg.danger : hg.accent, size: HgSize.iconMd),
            title: Text(label,
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 16,
                  color: danger ? hg.danger : hg.textPrimary,
                )),
            onTap: () {
              Navigator.of(sheetContext).pop();
              onTap();
            },
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: hg.surface,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(HgRadius.lg)),
            border: Border.all(color: hg.hairline),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: HgSpacing.md),
                  decoration: BoxDecoration(
                    color: hg.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (hasPhoto)
                  option(Icons.visibility_outlined, 'View photo', _viewPhoto),
                if (hasPhoto)
                  option(Icons.crop_rotate_rounded, 'Edit photo',
                      _editCurrentPhoto),
                option(Icons.photo_library_outlined,
                    hasPhoto ? 'Change photo' : 'Add photo', _changePhoto),
                if (hasPhoto)
                  option(Icons.delete_outline_rounded, 'Remove photo',
                      _removePhoto,
                      danger: true),
                const SizedBox(height: HgSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removePhoto() {
    // Defer the disk delete to Save, so cancelling leaves the saved photo intact.
    setState(() {
      _pendingPath = null;
      _pendingFile = null;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final clearImage = _pendingPath == null;
    try {
      await ref.read(profileRepositoryProvider).update(
            name: _controller.text.trim(),
            imagePath: _pendingPath,
            clearImage: clearImage,
          );
      // Photo removed → delete the now-orphaned file on disk.
      if (clearImage && _onDiskPath != null) {
        await ref.read(imageStorageProvider).deleteAvatar(_onDiskPath!);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    ref.invalidate(profileProvider);
    Navigator.of(context).pop();
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
                      const SizedBox(height: HgSpacing.sm),
                      Center(
                        child: Text(
                          _pendingFile == null
                              ? 'Tap to add a photo'
                              : 'Tap photo to view, edit, or change',
                          style: TextStyle(
                            fontFamily: HgFont.sans,
                            fontSize: 13,
                            color: hg.textMuted,
                          ),
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
    final Widget face = _pendingFile == null
        ? Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: hg.surfaceRaised,
              shape: BoxShape.circle,
              border: Border.all(color: hg.hairline),
            ),
            child: Icon(Icons.person_outline_rounded,
                size: size * 0.5, color: hg.textMuted),
          )
        : ClipOval(
            child: Image.file(
              _pendingFile!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // Decode to the on-screen size (not the full 512²) — low-RAM win.
              cacheWidth:
                  (size * MediaQuery.of(context).devicePixelRatio).ceil(),
              cacheHeight:
                  (size * MediaQuery.of(context).devicePixelRatio).ceil(),
              gaplessPlayback: true,
            ),
          );

    return GestureDetector(
      onTap: _showPhotoOptions,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size + 8,
        height: size + 8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            face,
            // Pencil badge, bottom-right, like WhatsApp's edit affordance.
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: hg.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: hg.background, width: 2.5),
                ),
                child: Icon(Icons.edit_rounded, size: 16, color: hg.onAccent),
              ),
            ),
          ],
        ),
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
