
# Interactive Tutorial Guide - Highlight & Guide Users Through UI

This guide shows how to add interactive tutorials that highlight specific UI elements and guide users through your app's features.

## What are Interactive Tutorials?

Interactive tutorials (also called "coach marks" or "showcases") highlight actual UI elements in your app with tooltips and descriptions. They're different from the slideshow tutorials - they show users WHERE things are located in the real interface.

### Example Flow:
1. User opens Home Screen for first time
2. A highlight appears around the "Report Emergency" button
3. Tooltip says: "Tap here to report an emergency"
4. User taps "Next" or the button itself
5. Next UI element gets highlighted
6. Continues until tour is complete

## 📦 Package Used

**ShowcaseView** - ^3.0.0

This package provides:
- Highlight overlays for any widget
- Customizable tooltips
- Sequential tour functionality
- Shape highlighting (rectangle, circle, etc.)
- Auto-progression or manual control

---

## 🚀 Quick Start

### Step 1: Add Dependency

Already added to `pubspec.yaml`:
```yaml
dependencies:
  showcaseview: ^3.0.0
```

Run:
```bash
flutter pub get
```

### Step 2: Wrap Your Screen

Wrap your screen with `InteractiveTutorialWrapper`:

```dart
import '../widgets/interactive_tutorial_wrapper.dart';

class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  // Create keys for each element you want to highlight
  final GlobalKey _button1Key = GlobalKey();
  final GlobalKey _button2Key = GlobalKey();
  
  @override
  Widget build(BuildContext context) {
    return InteractiveTutorialWrapper(
      showcaseKey: 'my_screen_tour',  // Unique ID for this tour
      showcaseKeys: [_button1Key, _button2Key],  // Order of highlights
      child: Scaffold(
        // Your screen content
      ),
    );
  }
}
```

### Step 3: Wrap UI Elements

Wrap widgets you want to highlight with `CustomShowcase`:

```dart
CustomShowcase(
  showcaseKey: _button1Key,
  title: 'Emergency Button',
  description: 'Tap here to report emergencies quickly',
  child: ElevatedButton(
    onPressed: () {},
    child: Text('Report Emergency'),
  ),
)
```

That's it! The tour will start automatically on first visit.

---

## 📚 Complete Implementation Example

### Example 1: Home Screen with Multiple Highlights

```dart
import 'package:flutter/material.dart';
import '../widgets/interactive_tutorial_wrapper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Step 1: Create GlobalKeys for each UI element
  final GlobalKey _emergencyKey = GlobalKey();
  final GlobalKey _reportsKey = GlobalKey();
  final GlobalKey _weatherKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // Step 2: Wrap with InteractiveTutorialWrapper
    return InteractiveTutorialWrapper(
      showcaseKey: 'home_tour',
      showcaseKeys: [
        _emergencyKey,    // First highlight
        _reportsKey,      // Second highlight
        _weatherKey,      // Third highlight
        _profileKey,      // Fourth highlight
      ],
      onComplete: () {
        print('Tour completed!');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          actions: [
            // Step 3: Wrap widgets with CustomShowcase
            CustomShowcase(
              showcaseKey: _profileKey,
              title: 'Your Profile',
              description: 'Access your profile and settings here',
              child: IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {},
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Weather Widget
            CustomShowcase(
              showcaseKey: _weatherKey,
              title: 'Live Weather',
              description: 'Check current weather and forecasts',
              child: WeatherWidget(),
            ),
            
            // Emergency Button
            CustomShowcase(
              showcaseKey: _emergencyKey,
              title: 'Report Emergency',
              description: 'Quickly report emergencies with one tap',
              tooltipBackgroundColor: Colors.red.shade700,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Report Emergency'),
              ),
            ),
            
            // My Reports Button
            CustomShowcase(
              showcaseKey: _reportsKey,
              title: 'My Reports',
              description: 'View and track your submitted reports',
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('My Reports'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎨 Customization Options

### Custom Colors

```dart
CustomShowcase(
  showcaseKey: _key,
  title: 'Emergency',
  description: 'For urgent situations',
  tooltipBackgroundColor: Colors.red.shade700,  // Red tooltip
  titleTextStyle: const TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  ),
  descTextStyle: const TextStyle(
    color: Colors.white70,
    fontSize: 15,
  ),
  child: MyWidget(),
)
```

### Custom Shapes

```dart
// Circle highlight (good for FABs)
CustomShowcase(
  showcaseKey: _fabKey,
  title: 'Call Emergency',
  description: 'Quick call button',
  targetShapeBorder: const CircleBorder(),
  child: FloatingActionButton(/*...*/),
)

// Rounded rectangle with custom radius
CustomShowcase(
  showcaseKey: _cardKey,
  title: 'Weather Card',
  description: 'Current conditions',
  targetShapeBorder: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  child: WeatherCard(),
)
```

### Custom Padding

```dart
CustomShowcase(
  showcaseKey: _key,
  title: 'Feature',
  description: 'Description',
  targetPadding: const EdgeInsets.all(16),  // Space around highlight
  child: MyWidget(),
)
```

---

## 🔄 Manual Control

### Start Tour Manually

```dart
// In your widget
void _startTour() {
  ShowCaseWidget.of(context).startShowCase([
    _key1,
    _key2,
    _key3,
  ]);
}

// Trigger from a button
ElevatedButton(
  onPressed: _startTour,
  child: Text('Show Tour'),
)
```

### Show Single Showcase

```dart
void _showSpecificFeature() {
  ShowCaseWidget.of(context).startShowCase([_emergencyKey]);
}
```

### Disable Auto-Start

```dart
InteractiveTutorialWrapper(
  showcaseKey: 'my_tour',
  showcaseKeys: keys,
  autoStart: false,  // Won't start automatically
  child: MyScreen(),
)
```

---

## 💾 State Management

The system automatically remembers which tours have been shown using `SharedPreferences`.

### Check if Tour was Shown

```dart
final wasShown = await InteractiveTutorialService.isShowcaseShown('home_tour');
if (!wasShown) {
  // Show tour
}
```

### Reset a Specific Tour

```dart
await InteractiveTutorialService.resetShowcase('home_tour');
// Tour will show again next time
```

### Reset All Tours

```dart
await InteractiveTutorialService.resetAllShowcases();
// All tours will show again
```

---

## 🎯 Best Practices

### 1. Limit Number of Steps

**Good:** 3-5 highlights per tour
**Too many:** 10+ highlights (users will skip)

```dart
// Good
showcaseKeys: [_step1, _step2, _step3, _step4]

// Too many - split into multiple tours
showcaseKeys: [_s1, _s2, _s3, _s4, _s5, _s6, _s7, _s8, _s9, _s10]
```

### 2. Logical Order

Highlight in the order users would naturally use features:

```dart
showcaseKeys: [
  _emergencyButton,  // Most important first
  _myReports,        // Related feature
  _profile,          // Settings last
]
```

### 3. Clear Descriptions

**Good:**
```dart
description: 'Tap here to report an emergency with photos and location'
```

**Bad:**
```dart
description: 'Emergency button'  // Too vague
```

### 4. Use Appropriate Colors

```dart
// Red for emergency/critical features
tooltipBackgroundColor: Colors.red.shade700

// Blue for informational
tooltipBackgroundColor: const Color(0xFF3b82f6)

// Green for positive/safe actions
tooltipBackgroundColor: Colors.green.shade700
```

### 5. Context-Aware Tours

Show tours when relevant:

```dart
// Show emergency report tour only when on that screen
void _checkEmergencyTour() async {
  final shown = await InteractiveTutorialService.isShowcaseShown('emergency_tour');
  if (!shown && _isOnEmergencyScreen) {
    _startTour();
  }
}
```

---

## 📱 Real-World Examples

### Example 1: Emergency Report Screen Tour

```dart
class EmergencyReportScreen extends StatefulWidget {
  @override
  State<EmergencyReportScreen> createState() => _EmergencyReportScreenState();
}

class _EmergencyReportScreenState extends State<EmergencyReportScreen> {
  final _typeKey = GlobalKey();
  final _photoKey = GlobalKey();
  final _locationKey = GlobalKey();
  final _submitKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return InteractiveTutorialWrapper(
      showcaseKey: 'emergency_report_tour',
      showcaseKeys: [_typeKey, _photoKey, _locationKey, _submitKey],
      child: Scaffold(
        appBar: AppBar(title: const Text('Report Emergency')),
        body: Column(
          children: [
            CustomShowcase(
              showcaseKey: _typeKey,
              title: 'Select Type',
              description: 'Choose the type of emergency (Fire, Flood, etc.)',
              child: DropdownButton(/*...*/),
            ),
            
            CustomShowcase(
              showcaseKey: _photoKey,
              title: 'Add Photos',
              description: 'Take or upload photos to help responders',
              child: ImagePicker(/*...*/),
            ),
            
            CustomShowcase(
              showcaseKey: _locationKey,
              title: 'Location',
              description: 'Your location is detected automatically',
              child: LocationDisplay(/*...*/),
            ),
            
            CustomShowcase(
              showcaseKey: _submitKey,
              title: 'Submit Report',
              description: 'Tap to send your emergency report',
              tooltipBackgroundColor: Colors.red.shade700,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example 2: Bottom Navigation Tour

```dart
class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _homeTabKey = GlobalKey();
  final _modulesTabKey = GlobalKey();
  final _callTabKey = GlobalKey();
  final _notifTabKey = GlobalKey();
  final _profileTabKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return InteractiveTutorialWrapper(
      showcaseKey: 'navigation_tour',
      showcaseKeys: [
        _homeTabKey,
        _modulesTabKey,
        _callTabKey,
        _notifTabKey,
        _profileTabKey,
      ],
      child: Scaffold(
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: CustomShowcase(
                showcaseKey: _homeTabKey,
                title: 'Home',
                description: 'Weather updates and quick actions',
                child: const Icon(Icons.home),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: CustomShowcase(
                showcaseKey: _modulesTabKey,
                title: 'Learning',
                description: 'Educational modules and quizzes',
                child: const Icon(Icons.book),
              ),
              label: 'Learn',
            ),
            BottomNavigationBarItem(
              icon: CustomShowcase(
                showcaseKey: _callTabKey,
                title: 'Emergency Call',
                description: 'Quick access to emergency hotlines',
                tooltipBackgroundColor: Colors.red.shade700,
                child: const Icon(Icons.call),
              ),
              label: 'Call',
            ),
            BottomNavigationBarItem(
              icon: CustomShowcase(
                showcaseKey: _notifTabKey,
                title: 'Notifications',
                description: 'Alerts and updates',
                child: const Icon(Icons.notifications),
              ),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: CustomShowcase(
                showcaseKey: _profileTabKey,
                title: 'Profile',
                description: 'Your account and settings',
                child: const Icon(Icons.person),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example 3: Context-Sensitive Tour

```dart
class MyReportsScreen extends StatefulWidget {
  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final _filterKey = GlobalKey();
  final _reportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkAndShowTour();
  }

  Future<void> _checkAndShowTour() async {
    // Wait for screen to build
    await Future.delayed(const Duration(milliseconds: 500));
    
    final shown = await InteractiveTutorialService.isShowcaseShown('reports_tour');
    
    if (!shown && mounted) {
      ShowCaseWidget.of(context).startShowCase([_filterKey, _reportKey]);
      await InteractiveTutorialService.markShowcaseShown('reports_tour');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: () {},
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Reports'),
          actions: [
            CustomShowcase(
              showcaseKey: _filterKey,
              title: 'Filter Reports',
              description: 'Filter by status: All, Pending, Resolved',
              child: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {},
              ),
            ),
          ],
        ),
        body: CustomShowcase(
          showcaseKey: _reportKey,
          title: 'Your Reports',
          description: 'Tap any report to see details and updates',
          child: ListView(/*...*/),
        ),
      ),
    );
  }
}
```

---

## 🔧 Integration with Existing Tutorial System

You can combine slideshow tutorials with interactive tours:

### 1. Show Slideshow First, Then Interactive Tour

```dart
// After completing slideshow tutorial
TutorialScreen(
  tutorial: AppTutorials.mainTutorial,
  onComplete: () {
    // Navigate to home and show interactive tour
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreenWithTour(),
      ),
    );
  },
)
```

### 2. Offer Choice

```dart
// In profile menu
_buildMenuItem(
  icon: Icons.touch_app,
  title: 'Interactive Tour',
  onTap: () async {
    await InteractiveTutorialService.resetShowcase('home_tour');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  },
)
```

---

## 🎮 Adding to Profile Menu

Add options to replay interactive tours:

```dart
// In home_screen.dart profile menu
_buildMenuItem(
  icon: Icons.tips_and_updates,
  title: 'Show Interactive Guide',
  color: const Color(0xFF10b981),
  onTap: () async {
    // Reset and restart home tour
    await InteractiveTutorialService.resetShowcase('home_tour');
    
    // Restart the app or navigate to home
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (route) => false,
    );
  },
),
_buildMenuItem(
  icon: Icons.replay,
  title: 'Reset All Interactive Tours',
  color: const Color(0xFFf59e0b),
  onTap: () async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Interactive Tours?'),
        content: const Text(
          'All interactive guides will show again when you visit each feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await InteractiveTutorialService.resetAllShowcases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interactive tours reset successfully!'),
            backgroundColor: Color(0xFF10b981),
          ),
        );
      }
    }
  },
),
```

---

## 🐛 Troubleshooting

### Tour Not Starting

**Problem:** Tour doesn't start automatically

**Solutions:**
1. Check `autoStart` is true (default)
2. Ensure `showcaseKeys` list is not empty
3. Verify widgets with keys are rendered
4. Add delay if needed:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) async {
  await Future.delayed(const Duration(milliseconds: 500));
  ShowCaseWidget.of(context).startShowCase(keys);
});
```

### Key Already Used Error

**Problem:** "GlobalKey used multiple times"

**Solution:** Each GlobalKey must be unique:
```dart
// Bad - same key used twice
final _key = GlobalKey();
CustomShowcase(showcaseKey: _key, /*...*/);
CustomShowcase(showcaseKey: _key, /*...*/);  // Error!

// Good - unique keys
final _key1 = GlobalKey();
final _key2 = GlobalKey();
CustomShowcase(showcaseKey: _key1, /*...*/);
CustomShowcase(showcaseKey: _key2, /*...*/);
```

### Highlight Not Visible

**Problem:** Highlight appears but widget is off-screen

**Solution:** Ensure widget is visible before starting:
```dart
// Scroll to widget first
_scrollController.animateTo(
  position,
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
).then((_) {
  ShowCaseWidget.of(context).startShowCase([_key]);
});
```

---

## 📖 Summary

Interactive tutorials are perfect for:
- ✅ Showing WHERE features are located
- ✅ Guiding users through complex interfaces
- ✅ Highlighting new features
- ✅ Onboarding new users
- ✅ Context-sensitive help

Use them alongside slideshow tutorials for the best onboarding experience!

**Slideshow Tutorial:** Overview of what the app does  
**Interactive Tutorial:** Show where things are and how to use them

---

## 🚀 Next Steps

1. Install the package: `flutter pub get`
2. Choose a screen to add interactive tour
3. Create GlobalKeys for important UI elements
4. Wrap screen with `InteractiveTutorialWrapper`
5. Wrap widgets with `CustomShowcase`
6. Test the tour
7. Add more tours to other screens!

For more examples, check `home_screen_with_interactive_tutorial.dart`

