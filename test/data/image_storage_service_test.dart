import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/data/image_storage_service.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late ImageStorageService service;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hg_img');
    service = ImageStorageService(baseDirOverride: () async => tmp);
  });
  tearDown(() async => tmp.delete(recursive: true));

  File writePng(int w, int h) {
    final file = File(p.join(tmp.path, 'src.png'));
    file.writeAsBytesSync(img.encodePng(img.Image(width: w, height: h)));
    return file;
  }

  void expectAvatarPath(String rel) {
    // Unique per save (busts the path-keyed image cache); lives in profile/.
    expect(p.dirname(rel), 'profile');
    expect(p.basename(rel), startsWith('avatar_'));
    expect(p.extension(rel), '.jpg');
  }

  test('saveAvatar writes a 512x512 jpg and returns a unique relative path',
      () async {
    final rel = await service.saveAvatar(writePng(200, 120));
    expectAvatarPath(rel);

    final saved = await service.resolve(rel);
    expect(await saved.exists(), isTrue);
    final decoded = img.decodeImage(await saved.readAsBytes())!;
    expect(decoded.width, 512);
    expect(decoded.height, 512);
  });

  test('saveAvatarBytes persists a 512x512 jpg from encoded bytes', () async {
    final rel = await service.saveAvatarBytes(
        img.encodePng(img.Image(width: 300, height: 300)));
    expectAvatarPath(rel);
    final decoded =
        img.decodeImage(await (await service.resolve(rel)).readAsBytes())!;
    expect(decoded.width, 512);
    expect(decoded.height, 512);
  });

  test('each save replaces the previous avatar (only one file remains)',
      () async {
    await service.saveAvatar(writePng(64, 64));
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final rel2 = await service.saveAvatar(writePng(80, 80));
    final dir = Directory(p.join(tmp.path, 'profile'));
    final files = dir.listSync().whereType<File>().toList();
    expect(files.length, 1); // old avatar cleaned up
    expect(p.basename(files.single.path), p.basename(rel2));
  });

  test('deleteAvatar removes the file', () async {
    final rel = await service.saveAvatar(writePng(64, 64));
    await service.deleteAvatar(rel);
    expect(await (await service.resolve(rel)).exists(), isFalse);
  });

  test('saveAvatar throws on undecodable bytes', () async {
    final bad = File(p.join(tmp.path, 'bad.png'))..writeAsBytesSync([1, 2, 3]);
    expect(() => service.saveAvatar(bad), throwsA(isA<ImageStorageException>()));
  });
}
