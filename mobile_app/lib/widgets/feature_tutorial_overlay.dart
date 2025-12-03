import 'package:flutter/material.dart';
import '../models/tutorial_model.dart';
import '../services/tutorial_service.dart';
import '../screens/tutorial_screen.dart';

class FeatureTutorialOverlay extends StatelessWidget {
  final String featureKey;
  final Widget child;
  final FeatureTutorial tutorial;

  const FeatureTutorialOverlay({
    super.key,
    required this.featureKey,
    required this.child,
    required this.tutorial,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: TutorialService.isFeatureTutorialShown(featureKey),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return child;
        }

        final isShown = snapshot.data!;
        
        // Show tutorial overlay on first visit
        if (!isShown) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showFeatureTutorial(context);
          });
        }

        return child;
      },
    );
  }

  Future<void> _showFeatureTutorial(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TutorialScreen(
          tutorial: tutorial,
        ),
      ),
    );
  }
}

