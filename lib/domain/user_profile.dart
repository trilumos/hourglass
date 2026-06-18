/// The single on-device user profile, as the app sees it (ORM-independent).
class UserProfile {
  final int id;
  final String uuid;
  final String name;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.uuid,
    required this.name,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasName => name.trim().isNotEmpty;
  bool get hasImage => imagePath != null;

  /// Whether the user has configured their profile (drives the "set up" nudge).
  bool get isSetUp => hasName;
}
