import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../widgets/interactive_tutorial_wrapper.dart';
import '../services/interactive_tutorial_service.dart';

/// Example: Home Screen with Interactive Tutorial Highlights
/// This is a reference implementation showing how to add interactive tutorials
/// Copy this pattern to your actual home_screen.dart

class HomeScreenWithInteractiveTutorial extends StatefulWidget {
  const HomeScreenWithInteractiveTutorial({super.key});

  @override
  State<HomeScreenWithInteractiveTutorial> createState() =>
      _HomeScreenWithInteractiveTutorialState();
}

class _HomeScreenWithInteractiveTutorialState
    extends State<HomeScreenWithInteractiveTutorial> {
  // Create GlobalKeys for each UI element you want to highlight
  final GlobalKey _emergencyButtonKey = GlobalKey();
  final GlobalKey _myReportsKey = GlobalKey();
  final GlobalKey _weatherKey = GlobalKey();
  final GlobalKey _callButtonKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return InteractiveTutorialWrapper(
      showcaseKey: 'home_screen_tour',
      showcaseKeys: [
        _emergencyButtonKey,
        _myReportsKey,
        _weatherKey,
        _callButtonKey,
        _profileKey,
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          actions: [
            // Highlight the profile icon
            CustomShowcase(
              showcaseKey: _profileKey,
              title: 'Your Profile',
              description: 'Tap here to access your profile, view tutorials, and logout',
              child: IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  // Navigate to profile
                },
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Weather Widget with Highlight
              CustomShowcase(
                showcaseKey: _weatherKey,
                title: 'Live Weather',
                description: 'Check real-time weather conditions and forecasts for your area',
                child: _buildWeatherCard(),
              ),
              const SizedBox(height: 20),

              // Quick Actions Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Emergency Report Button with Highlight
                  CustomShowcase(
                    showcaseKey: _emergencyButtonKey,
                    title: 'Report Emergency',
                    description: 'Tap here to quickly report an emergency with photos and location',
                    tooltipBackgroundColor: Colors.red.shade700,
                    child: _buildActionCard(
                      icon: Icons.emergency,
                      title: 'Report Emergency',
                      color: Colors.red,
                      onTap: () {
                        // Navigate to emergency report
                      },
                    ),
                  ),

                  // My Reports Button with Highlight
                  CustomShowcase(
                    showcaseKey: _myReportsKey,
                    title: 'Track Reports',
                    description: 'View and track the status of all your submitted reports',
                    child: _buildActionCard(
                      icon: Icons.assignment,
                      title: 'My Reports',
                      color: Colors.blue,
                      onTap: () {
                        // Navigate to my reports
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Learn'),
            BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Call'),
          ],
          currentIndex: 0,
          onTap: (index) {
            if (index == 2) {
              // Show call button showcase if not shown
              _showCallButtonShowcase();
            }
          },
        ),
        floatingActionButton: CustomShowcase(
          showcaseKey: _callButtonKey,
          title: 'Emergency Call',
          description: 'Quick access to emergency hotline. Tap to call for immediate help',
          tooltipBackgroundColor: Colors.red.shade700,
          targetShapeBorder: const CircleBorder(),
          child: FloatingActionButton(
            onPressed: () {
              // Launch phone call
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.call),
          ),
        ),
      ),
    );
  }

  Future<void> _showCallButtonShowcase() async {
    final isShown = await InteractiveTutorialService.isShowcaseShown('call_button');
    if (!isShown && mounted) {
      ShowCaseWidget.of(context).startShowCase([_callButtonKey]);
      await InteractiveTutorialService.markShowcaseShown('call_button');
    }
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.wb_sunny, size: 48, color: Colors.orange),
          SizedBox(height: 8),
          Text(
            '28°C',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          Text('Partly Cloudy'),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

