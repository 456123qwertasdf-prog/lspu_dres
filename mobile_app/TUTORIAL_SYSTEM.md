# Tutorial System Documentation

## Overview

The LSPU DRES mobile app now includes a comprehensive tutorial system that guides users through app features step-by-step. The tutorial automatically appears on first login and can be skipped by users.

## Features

✅ **Main Tutorial on First Login** - Shows automatically after user authentication
✅ **Skip Functionality** - Users can skip tutorials with confirmation dialog
✅ **Feature-Specific Tutorials** - Individual tutorials for each major feature
✅ **Progress Tracking** - Remembers which tutorials were shown using SharedPreferences
✅ **Beautiful UI** - Modern design with animations and progress indicators
✅ **Reset Option** - Users can view tutorials again anytime from profile
✅ **Navigation** - Forward/backward navigation between tutorial steps

## File Structure

```
mobile_app/lib/
├── models/
│   └── tutorial_model.dart          # Tutorial data models
├── services/
│   └── tutorial_service.dart        # Tutorial state management
├── screens/
│   └── tutorial_screen.dart         # Main tutorial UI screen
└── widgets/
    └── feature_tutorial_overlay.dart # Auto-show tutorial on first visit
```

## How It Works

### 1. Tutorial Models (`tutorial_model.dart`)

Define tutorial steps and predefined tutorials:

```dart
// Individual tutorial step
TutorialStep(
  title: 'Welcome to Kapiyu!',
  description: 'Your disaster preparedness companion...',
  icon: Icons.waving_hand,
  color: const Color(0xFF3b82f6),
)

// Complete feature tutorial
FeatureTutorial(
  featureKey: 'main_tutorial',
  title: 'Welcome to LSPU DRES',
  steps: [/* list of TutorialStep */],
)
```

### 2. Tutorial Service (`tutorial_service.dart`)

Manages tutorial state using SharedPreferences:

- `isTutorialCompleted()` - Check if main tutorial was shown
- `completeTutorial()` - Mark main tutorial as completed
- `resetTutorial()` - Reset all tutorials
- `isFeatureTutorialShown(key)` - Check if specific feature tutorial was shown
- `markFeatureTutorialShown(key)` - Mark feature tutorial as shown

### 3. Tutorial Screen (`tutorial_screen.dart`)

Beautiful paginated UI for displaying tutorials:
- Page indicators
- Next/Previous navigation
- Skip button with confirmation
- Completion callback

## Usage Examples

### Example 1: Show Tutorial on First Login (Already Implemented)

The main tutorial automatically shows after login in `main.dart`:

```dart
if (_shouldShowTutorial) {
  return TutorialScreen(
    tutorial: AppTutorials.mainTutorial,
    onComplete: () {
      setState(() {
        _shouldShowTutorial = false;
      });
    },
  );
}
```

### Example 2: Add Tutorial to Emergency Report Screen

Wrap your screen with `FeatureTutorialOverlay`:

```dart
// In emergency_report_screen.dart
import '../widgets/feature_tutorial_overlay.dart';
import '../models/tutorial_model.dart';

@override
Widget build(BuildContext context) {
  return FeatureTutorialOverlay(
    featureKey: 'emergency_report',
    tutorial: AppTutorials.emergencyReportTutorial,
    child: Scaffold(
      appBar: AppBar(title: const Text('Report Emergency')),
      body: // ... your existing widget tree
    ),
  );
}
```

### Example 3: Add Tutorial to My Reports Screen

```dart
// In my_reports_screen.dart
import '../widgets/feature_tutorial_overlay.dart';
import '../models/tutorial_model.dart';

@override
Widget build(BuildContext context) {
  return FeatureTutorialOverlay(
    featureKey: 'my_reports',
    tutorial: AppTutorials.myReportsTutorial,
    child: Scaffold(
      // ... your existing widget tree
    ),
  );
}
```

### Example 4: Add Tutorial to Safety Tips Screen

```dart
// In safety_tips_screen.dart
import '../widgets/feature_tutorial_overlay.dart';
import '../models/tutorial_model.dart';

@override
Widget build(BuildContext context) {
  return FeatureTutorialOverlay(
    featureKey: 'safety_tips',
    tutorial: AppTutorials.safetyTipsTutorial,
    child: Scaffold(
      // ... your existing widget tree
    ),
  );
}
```

### Example 5: Add Help Button to Show Tutorial Manually

```dart
// Add a help button to any screen's AppBar
AppBar(
  title: const Text('Weather Dashboard'),
  actions: [
    IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: 'How to use',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TutorialScreen(
              tutorial: AppTutorials.weatherTutorial,
            ),
          ),
        );
      },
    ),
  ],
)
```

## Creating New Tutorials

### Step 1: Define Tutorial in `tutorial_model.dart`

```dart
static final myNewFeatureTutorial = FeatureTutorial(
  featureKey: 'my_new_feature', // Unique identifier
  title: 'My New Feature Guide',
  steps: [
    TutorialStep(
      title: 'Step 1 Title',
      description: 'Explain what this step does...',
      icon: Icons.check_circle,
      color: Colors.blue,
    ),
    TutorialStep(
      title: 'Step 2 Title',
      description: 'Explain the next step...',
      icon: Icons.arrow_forward,
      color: Colors.green,
    ),
    // Add more steps...
  ],
);
```

### Step 2: Apply Tutorial to Your Screen

Choose one of the methods:

**Method A: Auto-show on first visit**
```dart
return FeatureTutorialOverlay(
  featureKey: 'my_new_feature',
  tutorial: AppTutorials.myNewFeatureTutorial,
  child: YourScreenWidget(),
);
```

**Method B: Manual trigger (button)**
```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TutorialScreen(
          tutorial: AppTutorials.myNewFeatureTutorial,
        ),
      ),
    );
  },
  child: const Text('Show Tutorial'),
)
```

## Available Predefined Tutorials

1. **mainTutorial** - Overview of entire app (7 steps)
2. **emergencyReportTutorial** - How to report emergencies (4 steps)
3. **weatherTutorial** - Weather dashboard guide (4 steps)
4. **modulesTutorial** - Learning modules guide (3 steps)
5. **myReportsTutorial** - My reports guide (3 steps)
6. **safetyTipsTutorial** - Safety tips guide (3 steps)
7. **mapTutorial** - Map & evacuation guide (3 steps)

## User Controls

### In Profile Menu:

1. **View Tutorials** - Re-watch the main tutorial anytime
2. **Reset All Tutorials** - Clear tutorial history and show all tutorials again

## Technical Details

### Storage
- Uses `SharedPreferences` for persistent storage
- Keys:
  - `tutorial_completed` - Boolean for main tutorial
  - `feature_tutorials` - List of shown feature tutorial keys

### Tutorial Flow
1. User logs in
2. Check if main tutorial completed
3. If not completed, show main tutorial
4. User can skip or complete
5. When visiting new feature, check feature tutorial status
6. Show feature tutorial if not shown before
7. Mark as shown after completion/skip

### Customization

**Change Tutorial Colors:**
```dart
TutorialStep(
  color: const Color(0xFFYOURCOLOR),
  // ...
)
```

**Change Animation Duration:**
```dart
// In tutorial_screen.dart, _nextPage() method:
_pageController.nextPage(
  duration: const Duration(milliseconds: 300), // Adjust here
  curve: Curves.easeInOut, // Change animation curve
);
```

**Disable Skip Button:**
```dart
TutorialScreen(
  tutorial: AppTutorials.mainTutorial,
  canSkip: false, // User must complete
)
```

## Testing

### Test Tutorial Flow:
1. Run the app on a fresh install or emulator
2. Login with test credentials
3. Tutorial should appear automatically
4. Test navigation (Next/Back buttons)
5. Test skip functionality
6. Visit different features to see feature tutorials

### Reset Tutorials for Testing:
1. Go to Profile → Reset All Tutorials
2. Or clear app data in device settings
3. Or use the service directly:
```dart
await TutorialService.resetTutorial();
```

## Best Practices

1. **Keep steps concise** - 3-7 steps per tutorial
2. **Clear descriptions** - Explain benefits, not just features
3. **Consistent icons** - Use Material Icons that match the feature
4. **Appropriate colors** - Match your app's color scheme
5. **Test thoroughly** - Ensure tutorials make sense to new users
6. **Update regularly** - Keep tutorials in sync with app changes

## Troubleshooting

**Tutorial not showing:**
- Check SharedPreferences is not blocking
- Verify featureKey is unique
- Ensure tutorial is wrapped correctly

**Tutorial showing every time:**
- Check TutorialService.markFeatureTutorialShown() is called
- Verify SharedPreferences has write permissions

**Navigation issues:**
- Ensure Navigator context is valid
- Check route is properly defined

## Future Enhancements

Possible improvements:
- [ ] Add video tutorials
- [ ] Interactive tutorial overlays (highlight specific buttons)
- [ ] Tutorial analytics (track which tutorials are skipped)
- [ ] Multi-language tutorial support
- [ ] Tutorial search functionality
- [ ] Animated GIFs in tutorial steps

