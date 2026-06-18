import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/user_profile.dart';

UserProfile _p({String name = '', String? imagePath}) => UserProfile(
      id: 1,
      uuid: 'u',
      name: name,
      imagePath: imagePath,
      createdAt: DateTime(2026, 6, 17),
      updatedAt: DateTime(2026, 6, 17),
    );

void main() {
  test('isSetUp is false for blank/whitespace name', () {
    expect(_p(name: '').isSetUp, isFalse);
    expect(_p(name: '   ').isSetUp, isFalse);
    expect(_p(name: 'Deep').isSetUp, isTrue);
  });

  test('hasImage reflects imagePath', () {
    expect(_p().hasImage, isFalse);
    expect(_p(imagePath: 'profile/avatar.jpg').hasImage, isTrue);
  });
}
