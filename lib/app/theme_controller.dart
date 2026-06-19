import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides the [SharedPreferences] instance. Overridden in main() with the
/// resolved instance, and in tests with a mock.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

/// The user's theme choices: which skin, and light/dark/system.
@immutable
class ThemePrefs {
  final String themeId;
  final ThemeMode mode;
  const ThemePrefs({required this.themeId, required this.mode});

  ThemePrefs copyWith({String? themeId, ThemeMode? mode}) =>
      ThemePrefs(themeId: themeId ?? this.themeId, mode: mode ?? this.mode);
}

/// Owns the theme selection and persists it. Defaults to the Sand skin
/// following the system brightness.
class ThemeController extends Notifier<ThemePrefs> {
  static const _kTheme = 'hg.themeId';
  static const _kMode = 'hg.mode';

  late final SharedPreferences _prefs;

  @override
  ThemePrefs build() {
    _prefs = ref.read(sharedPrefsProvider);
    final id = _prefs.getString(_kTheme) ?? 'sand';
    final modeIndex = _prefs.getInt(_kMode) ?? ThemeMode.system.index;
    final mode = ThemeMode.values[modeIndex.clamp(0, ThemeMode.values.length - 1)];
    return ThemePrefs(themeId: id, mode: mode);
  }

  void setMode(ThemeMode mode) {
    _prefs.setInt(_kMode, mode.index);
    state = state.copyWith(mode: mode);
  }

  void setTheme(String themeId) {
    _prefs.setString(_kTheme, themeId);
    state = state.copyWith(themeId: themeId);
  }

  /// Clears the persisted theme choice back to the default (Sand, follow
  /// system) — used by "Clear all data" so a factory reset is complete.
  Future<void> reset() async {
    await _prefs.remove(_kTheme);
    await _prefs.remove(_kMode);
    state = const ThemePrefs(themeId: 'sand', mode: ThemeMode.system);
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemePrefs>(ThemeController.new);
