import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../services/interactive_tutorial_service.dart';

/// Wrapper widget that enables interactive tutorials with highlights
class InteractiveTutorialWrapper extends StatefulWidget {
  final Widget child;
  final String showcaseKey;
  final List<GlobalKey> showcaseKeys;
  final VoidCallback? onComplete;
  final bool autoStart;

  const InteractiveTutorialWrapper({
    super.key,
    required this.child,
    required this.showcaseKey,
    required this.showcaseKeys,
    this.onComplete,
    this.autoStart = true,
  });

  @override
  State<InteractiveTutorialWrapper> createState() =>
      _InteractiveTutorialWrapperState();
}

class _InteractiveTutorialWrapperState
    extends State<InteractiveTutorialWrapper> {
  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      _checkAndStartShowcase();
    }
  }

  Future<void> _checkAndStartShowcase() async {
    final isShown =
        await InteractiveTutorialService.isShowcaseShown(widget.showcaseKey);

    if (!isShown && mounted) {
      // Wait for the widget tree to build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.showcaseKeys.isNotEmpty) {
          ShowCaseWidget.of(context).startShowCase(widget.showcaseKeys);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: () async {
        await InteractiveTutorialService.markShowcaseShown(widget.showcaseKey);
        widget.onComplete?.call();
      },
      onComplete: (index, key) {
        // Called when each showcase step completes
      },
      blurValue: 1,
      disableBarrierInteraction: true,
      disableMovingAnimation: false,
      autoPlayDelay: const Duration(seconds: 3),
      child: widget.child,
    );
  }
}

/// Custom showcase widget with better styling
class CustomShowcase extends StatelessWidget {
  final GlobalKey showcaseKey;
  final Widget child;
  final String title;
  final String description;
  final ShapeBorder? targetShapeBorder;
  final Color? tooltipBackgroundColor;
  final TextStyle? titleTextStyle;
  final TextStyle? descTextStyle;
  final EdgeInsets? targetPadding;

  const CustomShowcase({
    super.key,
    required this.showcaseKey,
    required this.child,
    required this.title,
    required this.description,
    this.targetShapeBorder,
    this.tooltipBackgroundColor,
    this.titleTextStyle,
    this.descTextStyle,
    this.targetPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Showcase(
      key: showcaseKey,
      title: title,
      description: description,
      targetShapeBorder: targetShapeBorder ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
      tooltipBackgroundColor:
          tooltipBackgroundColor ?? const Color(0xFF1e293b),
      titleTextStyle: titleTextStyle ??
          const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
      descTextStyle: descTextStyle ??
          const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
      targetPadding: targetPadding ?? const EdgeInsets.all(8),
      child: child,
    );
  }
}

