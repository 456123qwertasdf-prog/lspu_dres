# Tutorial Implementation Examples

This document provides practical code examples for implementing tutorials in different screens of the LSPU DRES app.

## Quick Implementation Guide

### 1. Emergency Report Screen

Add tutorial overlay to automatically show tutorial on first visit:

```dart
// File: lib/screens/emergency_report_screen.dart

// Add these imports at the top
import '../widgets/feature_tutorial_overlay.dart';
import '../models/tutorial_model.dart';

// Then wrap your Scaffold with FeatureTutorialOverlay
class EmergencyReportScreen extends StatefulWidget {
  const EmergencyReportScreen({super.key});

  @override
  State<EmergencyReportScreen> createState() => _EmergencyReportScreenState();
}

class _EmergencyReportScreenState extends State<EmergencyReportScreen> {
  @override
  Widget build(BuildContext context) {
    return FeatureTutorialOverlay(
      featureKey: 'emergency_report',
      tutorial: AppTutorials.emergencyReportTutorial,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Report Emergency'),
          actions: [
            // Optional: Add help button to manually show tutorial
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'How to report',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TutorialScreen(
                      tutorial: AppTutorials.emergencyReportTutorial,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: // ... your existing body widget
      ),
    );
  }
}
```

### 2. My Reports Screen

```dart
// File: lib/screens/my_reports_screen.dart

// Add these imports
import '../widgets/feature_tutorial_overlay.dart';
import '../models/tutorial_model.dart';
import '../screens/tutorial_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return FeatureTutorialOverlay(
      featureKey: 'my_reports',
      tutorial: AppTutorials.myReportsTutorial,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Reports'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TutorialScreen(
                      tutorial: AppTutorials.myReportsTutorial,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: // ... your existing body widget
      ),
    );
  }
}
```

### 3. Safety Tips Screen

```dart
// File: lib/screens/safety_tips_screen.dart

// Add these imports
import '../widgets/feature_tutorial_overlay.dart';
import '../models/tutorial_model.dart';
import '../screens/tutorial_screen.dart';

class SafetyTipsScreen extends StatefulWidget {
  const SafetyTipsScreen({super.key});

  @override
  State<SafetyTipsScreen> createState() => _SafetyTipsScreenState();
}

class _SafetyTipsScreenState extends State<SafetyTipsScreen> {
  @override
  Widget build(BuildContext context) {
    return FeatureTutorialOverlay(
      featureKey: 'safety_tips',
      tutorial: AppTutorials.safetyTipsTutorial,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Safety Tips'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TutorialScreen(
                      tutorial: AppTutorials.safetyTipsTutorial,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: // ... your existing body widget
      ),
    );
  }
}
```

### 4. Map Simulation Screen

```dart
// File: lib/screens/map_simulation_screen.dart

// Add these imports
import '../widgets/feature_tutorial_overlay.dart';
import '../models/tutorial_model.dart';
import '../screens/tutorial_screen.dart';

class MapSimulationScreen extends StatefulWidget {
  const MapSimulationScreen({super.key});

  @override
  State<MapSimulationScreen> createState() => _MapSimulationScreenState();
}

class _MapSimulationScreenState extends State<MapSimulationScreen> {
  @override
  Widget build(BuildContext context) {
    return FeatureTutorialOverlay(
      featureKey: 'map_simulation',
      tutorial: AppTutorials.mapTutorial,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Map & Evacuation'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TutorialScreen(
                      tutorial: AppTutorials.mapTutorial,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: // ... your existing body widget
      ),
    );
  }
}
```

### 5. Learning Modules Screen

```dart
// File: lib/screens/learning_modules_screen.dart

// Add these imports
import '../widgets/feature_tutorial_overlay.dart';
import '../models/tutorial_model.dart';
import '../screens/tutorial_screen.dart';

class LearningModulesScreen extends StatefulWidget {
  const LearningModulesScreen({super.key});

  @override
  State<LearningModulesScreen> createState() => _LearningModulesScreenState();
}

class _LearningModulesScreenState extends State<LearningModulesScreen> {
  @override
  Widget build(BuildContext context) {
    return FeatureTutorialOverlay(
      featureKey: 'learning_modules',
      tutorial: AppTutorials.modulesTutorial,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Learning Modules'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TutorialScreen(
                      tutorial: AppTutorials.modulesTutorial,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: // ... your existing body widget
      ),
    );
  }
}
```

## Alternative: Add Help Button Without Auto-Tutorial

If you want to add a help button without auto-showing the tutorial on first visit:

```dart
// In any screen's AppBar
AppBar(
  title: const Text('Your Screen Title'),
  actions: [
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'help') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TutorialScreen(
                tutorial: AppTutorials.yourFeatureTutorial,
              ),
            ),
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'help',
          child: Row(
            children: [
              Icon(Icons.help_outline),
              SizedBox(width: 8),
              Text('Help & Tutorial'),
            ],
          ),
        ),
      ],
    ),
  ],
)
```

## Add Floating Action Button with Help

```dart
// Add this to your Scaffold
Scaffold(
  appBar: AppBar(/* ... */),
  body: // ... your body widget
  floatingActionButton: FloatingActionButton.extended(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TutorialScreen(
            tutorial: AppTutorials.yourFeatureTutorial,
          ),
        ),
      );
    },
    icon: const Icon(Icons.help_outline),
    label: const Text('Help'),
    backgroundColor: const Color(0xFF8b5cf6),
  ),
)
```

## Show Tutorial Based on Condition

```dart
// Show tutorial only if user hasn't completed a certain task
class YourScreen extends StatefulWidget {
  const YourScreen({super.key});

  @override
  State<YourScreen> createState() => _YourScreenState();
}

class _YourScreenState extends State<YourScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndShowTutorial();
  }

  Future<void> _checkAndShowTutorial() async {
    // Check if tutorial should be shown
    final shouldShow = await TutorialService.isFeatureTutorialShown('your_feature');
    
    if (!shouldShow && mounted) {
      // Show tutorial after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TutorialScreen(
                tutorial: AppTutorials.yourFeatureTutorial,
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... your widget tree
    );
  }
}
```

## Programmatically Show Tutorial

```dart
// In any widget/screen, call this method to show tutorial
void _showTutorial() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TutorialScreen(
        tutorial: AppTutorials.mainTutorial,
        canSkip: true,
      ),
    ),
  );
}

// Usage in a button
ElevatedButton(
  onPressed: _showTutorial,
  child: const Text('Show Tutorial'),
)
```

## Create Custom Tutorial Dialog

```dart
// For quick inline tutorials without full screen
void _showQuickTip(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.orange),
          SizedBox(width: 8),
          Text('Quick Tip'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Did you know?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('You can long-press on reports to see more options!'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TutorialScreen(
                    tutorial: AppTutorials.myReportsTutorial,
                  ),
                ),
              );
            },
            child: Text('View Full Tutorial'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Got it!'),
        ),
      ],
    ),
  );
}
```

## Bottom Sheet Tutorial

```dart
// Show tutorial as bottom sheet
void _showTutorialSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Quick Guide',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'Need help getting started? We have a step-by-step tutorial ready for you!',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Maybe Later'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TutorialScreen(
                          tutorial: AppTutorials.mainTutorial,
                        ),
                      ),
                    );
                  },
                  child: Text('Start Tutorial'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
```

## Testing Checklist

After implementing tutorials in your screens:

- [ ] Test tutorial appears on first visit
- [ ] Test skip button works
- [ ] Test navigation (next/previous)
- [ ] Test tutorial doesn't show again after completion
- [ ] Test manual help button opens tutorial
- [ ] Test reset tutorials from profile
- [ ] Test on different screen sizes
- [ ] Verify text is readable
- [ ] Check animations are smooth
- [ ] Test with real users for clarity

## Common Issues and Solutions

### Issue: Tutorial shows every time
**Solution:** Ensure `markFeatureTutorialShown()` is called when tutorial completes.

### Issue: Tutorial never shows
**Solution:** Check that `isFeatureTutorialShown()` returns false initially.

### Issue: Navigation breaks
**Solution:** Verify context is valid and routes are properly defined.

### Issue: Icons don't match feature
**Solution:** Update icons in `tutorial_model.dart` to better represent the feature.

## Tips for Great Tutorials

1. **Keep it simple** - Focus on essential features only
2. **Use visuals** - Icons and colors help understanding
3. **Be concise** - Short descriptions are better than long ones
4. **Test with real users** - Get feedback from actual users
5. **Update regularly** - Keep tutorials in sync with app updates
6. **Make it skippable** - Don't force users to complete tutorials
7. **Provide help access** - Always allow users to re-watch tutorials

