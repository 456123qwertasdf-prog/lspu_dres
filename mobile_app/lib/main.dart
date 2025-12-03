import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'services/onesignal_service.dart';
import 'services/tutorial_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/emergency_report_screen.dart';
import 'screens/safety_tips_screen.dart';
import 'screens/my_reports_screen.dart';
import 'screens/learning_modules_screen.dart';
import 'screens/responder_dashboard_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/map_simulation_screen.dart';
import 'screens/super_user_dashboard_screen.dart';
import 'screens/super_user_reports_screen.dart';
import 'screens/super_user_announcements_screen.dart';
import 'screens/super_user_map_screen.dart';
import 'screens/super_user_early_warning_screen.dart';
import 'screens/report_detail_edit_screen.dart';
import 'screens/tutorial_screen.dart';
import 'models/tutorial_model.dart';

// Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Initialize OneSignal for push notifications
  await OneSignalService().initialize();
  
  // Set up notification tap handlers
  _setupNotificationHandlers();
  
  runApp(const MyApp());
}

/// Set up handlers for notification taps
void _setupNotificationHandlers() {
  final oneSignal = OneSignalService();
  
  // 1. Handle assignment notification taps (RESPONDER)
  oneSignal.setOnAssignmentNotificationTap((reportId, assignmentId) async {
    print('📱 [RESPONDER] Opening assignment - Report ID: $reportId');
    
    try {
      // Fetch the full report data
      final response = await SupabaseService.client
          .from('reports')
          .select('*')
          .eq('id', reportId)
          .single();
      
      if (response != null) {
        // Navigate to report details screen
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ReportDetailEditScreen(report: response),
          ),
        );
      }
    } catch (e) {
      print('❌ Error loading report for assignment notification: $e');
    }
  });
  
  // 2. Handle critical report notification taps (SUPER USER)
  oneSignal.setOnCriticalReportNotificationTap((reportId) async {
    print('📱 [SUPER USER] Opening critical report - Report ID: $reportId');
    
    try {
      // Fetch the full report data
      final response = await SupabaseService.client
          .from('reports')
          .select('*')
          .eq('id', reportId)
          .single();
      
      if (response != null) {
        // Navigate to report details screen
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ReportDetailEditScreen(report: response),
          ),
        );
      }
    } catch (e) {
      print('❌ Error loading critical report: $e');
    }
  });
  
  // 3. Handle report update notification taps (CITIZEN - their own reports)
  oneSignal.setOnReportUpdateNotificationTap((reportId) async {
    print('📱 [CITIZEN] Opening report update - Report ID: $reportId');
    
    try {
      // Fetch the full report data
      final response = await SupabaseService.client
          .from('reports')
          .select('*')
          .eq('id', reportId)
          .single();
      
      if (response != null) {
        // Navigate to report details screen
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ReportDetailEditScreen(report: response),
          ),
        );
      }
    } catch (e) {
      print('❌ Error loading report update: $e');
    }
  });
  
  // 4. Handle emergency announcement taps (ALL USERS)
  oneSignal.setOnEmergencyNotificationTap((announcementId) {
    print('📱 [ALL USERS] Opening emergency announcement: $announcementId');
    // Navigate to map to see emergency location
    navigatorKey.currentState?.pushNamed('/map');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Add global navigator key
      title: 'LSPU DRES',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3b82f6), // Web admin blue
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: _AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/emergency-report': (context) => const EmergencyReportScreen(),
        '/safety-tips': (context) => const SafetyTipsScreen(),
        '/learning-modules': (context) => const LearningModulesScreen(),
        '/my-reports': (context) => const MyReportsScreen(),
        '/responder-dashboard': (context) => const ResponderDashboardScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/map': (context) => const MapSimulationScreen(),
        '/super-user': (context) => const SuperUserDashboardScreen(),
        '/super-user-reports': (context) => const SuperUserReportsScreen(),
        '/super-user-announcements': (context) => const SuperUserAnnouncementsScreen(),
        '/super-user-map': (context) => const SuperUserMapScreen(),
        '/super-user-early-warning': (context) => const SuperUserEarlyWarningScreen(),
      },
    );
  }
}

class _AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: SupabaseService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is authenticated
        if (SupabaseService.isAuthenticated) {
          return const RoleRouter();
        }

        return const LoginScreen();
      },
    );
  }
}

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  bool _isLoading = true;
  String? _role;
  bool _shouldShowTutorial = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _determineRole();
    await _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final tutorialCompleted = await TutorialService.isTutorialCompleted();
    setState(() {
      _shouldShowTutorial = !tutorialCompleted;
      _isLoading = false;
    });
  }

  Future<void> _determineRole() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        setState(() {
          _role = null;
        });
        return;
      }

      final response = await SupabaseService.client
          .from('user_profiles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['role'] != null) {
        _role = (response['role'] as String?)?.toLowerCase();
      } else {
        final responderMatch = await SupabaseService.client
            .from('responder')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();

        if (responderMatch != null) {
          _role = 'responder';
        } else {
          final metadataRole =
              SupabaseService.currentUser?.userMetadata?['role'] as String?;
          _role = metadataRole?.toLowerCase();
        }
      }

      // Check for super_user in metadata if not found in profile
      if (_role != 'super_user') {
        final metadataRole =
            SupabaseService.currentUser?.userMetadata?['role'] as String?;
        if (metadataRole?.toLowerCase() == 'super_user') {
          _role = 'super_user';
        }
      }

      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
      _role = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show tutorial if needed (first time login)
    if (_shouldShowTutorial) {
      return TutorialScreen(
        tutorial: AppTutorials.mainTutorial,
        canSkip: true,
        onComplete: () {
          setState(() {
            _shouldShowTutorial = false;
          });
        },
      );
    }

    // Route super_user to super user dashboard
    if (_role == 'super_user') {
      return const SuperUserDashboardScreen();
    }

    if (_role == 'responder' || _role == 'admin') {
      return const ResponderDashboardScreen();
    }

    return const HomeScreen();
  }
}
