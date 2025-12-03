import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage interactive tutorial showcases (highlighting UI elements)
class InteractiveTutorialService {
  static const String _showcasePrefix = 'showcase_shown_';

  /// Check if a specific showcase was shown
  static Future<bool> isShowcaseShown(String showcaseKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_showcasePrefix$showcaseKey') ?? false;
  }

  /// Mark a showcase as shown
  static Future<void> markShowcaseShown(String showcaseKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_showcasePrefix$showcaseKey', true);
  }

  /// Reset a specific showcase
  static Future<void> resetShowcase(String showcaseKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_showcasePrefix$showcaseKey');
  }

  /// Reset all showcases
  static Future<void> resetAllShowcases() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_showcasePrefix)) {
        await prefs.remove(key);
      }
    }
  }
}

