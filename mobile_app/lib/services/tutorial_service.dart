import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const String _tutorialCompletedKey = 'tutorial_completed';
  static const String _featureTutorialsKey = 'feature_tutorials';

  // Check if main tutorial is completed
  static Future<bool> isTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialCompletedKey) ?? false;
  }

  // Mark main tutorial as completed
  static Future<void> completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);
  }

  // Reset tutorial (for testing or user request)
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, false);
    await prefs.remove(_featureTutorialsKey);
  }

  // Check if specific feature tutorial was shown
  static Future<bool> isFeatureTutorialShown(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getStringList(_featureTutorialsKey) ?? [];
    return shown.contains(featureKey);
  }

  // Mark feature tutorial as shown
  static Future<void> markFeatureTutorialShown(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getStringList(_featureTutorialsKey) ?? [];
    if (!shown.contains(featureKey)) {
      shown.add(featureKey);
      await prefs.setStringList(_featureTutorialsKey, shown);
    }
  }
}

