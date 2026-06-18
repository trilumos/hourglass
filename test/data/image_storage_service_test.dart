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

  test('saveAvatar writes a 512x512 jpg and returns the relative path',
      () async {
    final rel = await service.saveAvatar(writePng(200, 120));
    expect(rel, p.join('profile', 'avatar.jpg'));

    final saved = await service.resolve(rel);
    expect(await saved.exists(), isTrue);
    final decoded = img.decodeImage(await saved.readAsBytes())!;
    expect(decoded.width, 512);
    expect(decoded.height, 512);
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
