import 'package:flutter/material.dart';

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? imagePath;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    this.color = const Color(0xFF3b82f6),
    this.imagePath,
  });
}

class FeatureTutorial {
  final String featureKey;
  final String title;
  final List<TutorialStep> steps;

  FeatureTutorial({
    required this.featureKey,
    required this.title,
    required this.steps,
  });
}

// Predefined tutorials for each feature
class AppTutorials {
  static final mainTutorial = FeatureTutorial(
    featureKey: 'main_tutorial',
    title: 'Welcome to LSPU DRES',
    steps: [
      TutorialStep(
        title: 'Welcome to Kapiyu!',
        description: 'Your disaster preparedness and emergency response companion. Let\'s take a quick tour of the app.',
        icon: Icons.waving_hand,
        color: const Color(0xFF3b82f6),
      ),
      TutorialStep(
        title: 'Report Emergencies',
        description: 'Quickly report emergencies with your location, photos, and description. Help arrives faster!',
        icon: Icons.emergency,
        color: Colors.red,
      ),
      TutorialStep(
        title: 'Track Your Reports',
        description: 'View all your submitted reports and their status in real-time. Stay informed about the response.',
        icon: Icons.assignment,
        color: Colors.blue,
      ),
      TutorialStep(
        title: 'Learning Modules',
        description: 'Access educational materials about disaster preparedness, safety tips, and emergency procedures.',
        icon: Icons.menu_book,
        color: Colors.purple,
      ),
      TutorialStep(
        title: 'Emergency Contacts',
        description: 'Quick access to emergency hotlines. Call for help with just one tap when you need it.',
        icon: Icons.call,
        color: const Color(0xFFef4444),
      ),
      TutorialStep(
        title: 'Real-time Weather',
        description: 'Stay updated with live weather information and alerts for your area.',
        icon: Icons.wb_sunny,
        color: Colors.orange,
      ),
      TutorialStep(
        title: 'Get Notified',
        description: 'Receive instant notifications about emergencies, weather alerts, and report updates.',
        icon: Icons.notifications,
        color: const Color(0xFF10b981),
      ),
    ],
  );

  static final emergencyReportTutorial = FeatureTutorial(
    featureKey: 'emergency_report',
    title: 'How to Report Emergency',
    steps: [
      TutorialStep(
        title: 'Select Emergency Type',
        description: 'Choose the type of emergency you\'re reporting (Fire, Flood, Medical, etc.)',
        icon: Icons.list_alt,
        color: Colors.red,
      ),
      TutorialStep(
        title: 'Add Details',
        description: 'Provide a description and severity level. The more details, the better the response!',
        icon: Icons.description,
        color: Colors.orange,
      ),
      TutorialStep(
        title: 'Capture Photos',
        description: 'Take photos of the situation to help responders understand the emergency better.',
        icon: Icons.camera_alt,
        color: Colors.blue,
      ),
      TutorialStep(
        title: 'Confirm Location',
        description: 'Your location is automatically detected. Verify it\'s correct before submitting.',
        icon: Icons.location_on,
        color: Colors.green,
      ),
    ],
  );

  static final weatherTutorial = FeatureTutorial(
    featureKey: 'weather_dashboard',
    title: 'Weather Dashboard Guide',
    steps: [
      TutorialStep(
        title: 'Current Weather',
        description: 'View real-time temperature, conditions, and feels-like temperature for LSPU campus.',
        icon: Icons.thermostat,
        color: Colors.orange,
      ),
      TutorialStep(
        title: 'Rain Forecast',
        description: 'Check rain probability and volume to plan your activities accordingly.',
        icon: Icons.water_drop,
        color: Colors.blue,
      ),
      TutorialStep(
        title: 'Hourly Forecast',
        description: 'Scroll through upcoming hours to see temperature and rain predictions.',
        icon: Icons.schedule,
        color: Colors.purple,
      ),
      TutorialStep(
        title: 'Refresh Data',
        description: 'Tap the refresh button to get the latest weather information anytime.',
        icon: Icons.refresh,
        color: Colors.green,
      ),
    ],
  );

  static final modulesTutorial = FeatureTutorial(
    featureKey: 'learning_modules',
    title: 'Learning Modules',
    steps: [
      TutorialStep(
        title: 'Browse Modules',
        description: 'Explore various educational modules about disaster preparedness and safety.',
        icon: Icons.library_books,
        color: Colors.purple,
      ),
      TutorialStep(
        title: 'Take Quizzes',
        description: 'Test your knowledge with interactive quizzes after each module.',
        icon: Icons.quiz,
        color: Colors.blue,
      ),
      TutorialStep(
        title: 'Track Progress',
        description: 'See your completed modules and quiz scores to track your learning journey.',
        icon: Icons.check_circle,
        color: Colors.green,
      ),
    ],
  );

  static final myReportsTutorial = FeatureTutorial(
    featureKey: 'my_reports',
    title: 'My Reports Guide',
    steps: [
      TutorialStep(
        title: 'View Your Reports',
        description: 'See all emergency reports you\'ve submitted in one place.',
        icon: Icons.list,
        color: Colors.blue,
      ),
      TutorialStep(
        title: 'Check Status',
        description: 'Monitor the status of your reports: Pending, In Progress, or Resolved.',
        icon: Icons.info,
        color: Colors.orange,
      ),
      TutorialStep(
        title: 'Get Updates',
        description: 'Receive notifications when responders update your report status.',
        icon: Icons.notifications_active,
        color: Colors.green,
      ),
    ],
  );

  static final safetyTipsTutorial = FeatureTutorial(
    featureKey: 'safety_tips',
    title: 'Safety Tips Guide',
    steps: [
      TutorialStep(
        title: 'Browse Safety Tips',
        description: 'Access essential safety information for different types of disasters.',
        icon: Icons.shield,
        color: Colors.green,
      ),
      TutorialStep(
        title: 'Learn Best Practices',
        description: 'Discover what to do before, during, and after emergencies.',
        icon: Icons.checklist,
        color: Colors.blue,
      ),
      TutorialStep(
        title: 'Share Knowledge',
        description: 'Help your community stay safe by sharing these tips with family and friends.',
        icon: Icons.share,
        color: Colors.purple,
      ),
    ],
  );

  static final mapTutorial = FeatureTutorial(
    featureKey: 'map_simulation',
    title: 'Map & Evacuation Guide',
    steps: [
      TutorialStep(
        title: 'View Your Location',
        description: 'See your current location on the interactive map.',
        icon: Icons.my_location,
        color: Colors.blue,
      ),
      TutorialStep(
        title: 'Find Evacuation Centers',
        description: 'Locate nearby evacuation centers and safe zones during emergencies.',
        icon: Icons.location_city,
        color: Colors.green,
      ),
      TutorialStep(
        title: 'Emergency Zones',
        description: 'View areas affected by current emergencies and avoid them.',
        icon: Icons.warning,
        color: Colors.red,
      ),
    ],
  );
}

