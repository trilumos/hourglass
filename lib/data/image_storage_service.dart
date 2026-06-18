import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Saves the user's avatar into app-private storage as a 512² JPEG and returns a
/// **relative** path (e.g. `profile/avatar.jpg`) to store in the profile row.
class ImageStorageService {
  final Future<Directory> Function() _baseDir;
  ImageStorageService({Future<Directory> Function()? baseDirOverride})
      : _baseDir = baseDirOverride ?? getApplicationDocumentsDirectory;

  static const _relDir = 'profile';
  static const _avatarName = 'avatar.jpg';
  static const _size = 512;

  /// Saves a picked image, center-cropped to a square. (Fallback path.)
  Future<String> saveAvatar(File picked) async {
    return _persist(_centerSquare(_decode(await picked.readAsBytes())));
  }

  /// Saves an already-cropped (square) image given its encoded bytes — used by
  /// the interactive crop screen, which hands us exactly the chosen region.
  Future<String> saveAvatarBytes(Uint8List bytes) async {
    return _persist(_decode(bytes));
  }

  img.Image _decode(Uint8List bytes) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      decoded = null; // unsupported/corrupt data — treat as unreadable
    }
    if (decoded == null) {
      throw const ImageStorageException('Could not read that image.');
    }
    return decoded;
  }

  Future<String> _persist(img.Image image) async {
    final resized = img.copyResize(image, width: _size, height: _size);
    final jpg = img.encodeJpg(resized, quality: 85);
    final dir = Directory(p.join((await _baseDir()).path, _relDir));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, _avatarName));
    await file.writeAsBytes(jpg, flush: true);
    return p.join(_relDir, _avatarName);
  }

  Future<void> deleteAvatar(String relativePath) async {
    final file = File(p.join((await _baseDir()).path, relativePath));
    if (await file.exists()) await file.delete();
  }

  Future<File> resolve(String relativePath) async =>
      File(p.join((await _baseDir()).path, relativePath));

  img.Image _centerSquare(img.Image src) {
    final side = src.width < src.height ? src.width : src.height;
    final x = (src.width - side) ~/ 2;
    final y = (src.height - side) ~/ 2;
    return img.copyCrop(src, x: x, y: y, width: side, height: side);
  }
}

class ImageStorageException implements Exception {
  final String message;
  const ImageStorageException(this.message);
  @override
  String toString() => message;
}
