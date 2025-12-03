import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';
import 'notification_sound_service.dart';

/// Service to handle OneSignal push notifications
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  static const String _onesignalAppId = '8d6aa625-a650-47ac-b9ba-00a247840952';
  String? _playerId;

  /// Initialize OneSignal SDK
  Future<void> initialize() async {
    try {
      // Initialize notification sound service
      await NotificationSoundService().initialize();
      
      // Set app ID
      OneSignal.initialize(_onesignalAppId);

      // Request permission for notifications
      final permissionGranted = await OneSignal.Notifications.requestPermission(true);
      
      if (permissionGranted) {
        debugPrint('✅ OneSignal notification permission granted');
      } else {
        debugPrint('❌ OneSignal notification permission denied');
        return;
      }

      // Listen for subscription changes FIRST (before checking current state)
      // This ensures we catch the subscription ID when it becomes available
      OneSignal.User.pushSubscription.addObserver((state) {
        final newPlayerId = state.current.id;
        if (newPlayerId != null && newPlayerId.isNotEmpty) {
          if (newPlayerId != _playerId) {
          _playerId = newPlayerId;
          debugPrint('OneSignal Player ID updated: $_playerId');
          _savePlayerIdToSupabase(newPlayerId);
        }
        } else {
          debugPrint('⚠️ OneSignal subscription ID not available yet');
        }
      });

      // Get the current subscription ID (may be null initially)
      final subscription = OneSignal.User.pushSubscription;
      _playerId = subscription.id;
      
      if (_playerId != null && _playerId!.isNotEmpty) {
        debugPrint('OneSignal Player ID (initial): $_playerId');
        // Save player ID to Supabase
        await _savePlayerIdToSupabase(_playerId!);
      } else {
        debugPrint('⚠️ OneSignal subscription ID not ready yet, will save when available');
        // Wait a bit for subscription to be ready (max 5 seconds)
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          final currentId = OneSignal.User.pushSubscription.id;
          if (currentId != null && currentId.isNotEmpty) {
            _playerId = currentId;
            debugPrint('OneSignal Player ID (after wait): $_playerId');
            await _savePlayerIdToSupabase(_playerId!);
            break;
          }
        }
      }

      // Handle notification received (when app is in foreground or background)
      OneSignal.Notifications.addClickListener((event) {
        debugPrint('OneSignal notification clicked: ${event.notification.body}');
        // Handle notification tap - you can navigate to appropriate screen here
        _handleNotificationTap(event);
        // Also play sound when notification is clicked (for foreground notifications)
        _handleNotificationReceived(event);
      });

    } catch (e) {
      debugPrint('Error initializing OneSignal: $e');
    }
  }

  /// Save player ID to Supabase
  Future<void> _savePlayerIdToSupabase(String playerId) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        debugPrint('⚠️ Cannot save OneSignal Player ID: User not authenticated');
        return;
      }

      if (playerId.isEmpty) {
        debugPrint('⚠️ Cannot save OneSignal Player ID: Player ID is empty');
        return;
      }

      debugPrint('💾 Saving OneSignal Player ID to Supabase: $playerId for user: $userId');

      // Save to Supabase - use upsert to handle both insert and update
      final response = await SupabaseService.client
          .from('onesignal_subscriptions')
          .upsert({
            'user_id': userId,
            'player_id': playerId,
            'platform': 'android',
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,player_id')
          .select();
      
      if (response != null) {
      debugPrint('✅ OneSignal Player ID saved to Supabase: $playerId');
      } else {
        debugPrint('⚠️ OneSignal Player ID save returned null response');
      }
    } catch (e) {
      debugPrint('❌ Error saving OneSignal Player ID: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(OSNotificationClickEvent event) {
    try {
      final data = event.notification.additionalData;
      if (data != null) {
        final type = data['type'] as String?;
        
        if (type == 'assignment') {
          // Handle assignment notification (for responders)
          final assignmentId = data['assignment_id'] as String?;
          final reportId = data['report_id'] as String?;
          final isCritical = data['is_critical'] as bool?;
          
          debugPrint('🚨 Assignment notification tapped:');
          debugPrint('  - Assignment ID: $assignmentId');
          debugPrint('  - Report ID: $reportId');
          debugPrint('  - Critical: ${isCritical == true ? 'YES' : 'NO'}');
          
          // TODO: Navigate to assignment details or report screen
          // You can use a navigator key or callback here
          // Example: NavigationService.navigateToAssignment(assignmentId);
          
        } else if (type == 'critical_report') {
          // Handle critical report notification (for super users/admins)
          final reportId = data['report_id'] as String?;
          final reportType = data['report_type'] as String?;
          final priority = data['priority'];
          final severity = data['severity'] as String?;
          
          debugPrint('🚨 CRITICAL REPORT notification tapped:');
          debugPrint('  - Report ID: $reportId');
          debugPrint('  - Type: $reportType');
          debugPrint('  - Priority: $priority');
          debugPrint('  - Severity: $severity');
          debugPrint('  ⚠️ ACTION REQUIRED: Assign responder immediately!');
          
          // TODO: Navigate to reports screen to assign responder
          // Example: NavigationService.navigateToReports(reportId: reportId);
          
        } else if (type == 'emergency') {
          // Handle emergency announcement
          final announcementId = data['announcement_id'] as String?;
          debugPrint('Emergency notification tapped: $announcementId');
          // TODO: Navigate to map or announcement details
        }
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  /// Handle notification received (play custom sound if enabled)
  void _handleNotificationReceived(OSNotificationClickEvent event) {
    try {
      final data = event.notification.additionalData;
      if (data != null) {
        final type = data['type'] as String?;
        final soundService = NotificationSoundService();
        
        // Play custom sound for emergency notifications and critical assignments
        if (type == 'emergency') {
          soundService.playEmergencySound();
        } else if (type == 'assignment') {
          // Check if assignment is critical/high priority
          final isCritical = data['is_critical'] as bool?;
          if (isCritical == true) {
            // Play emergency sound for critical/high priority assignments
            debugPrint('🔊 Playing emergency sound for CRITICAL/HIGH priority assignment');
            soundService.playEmergencySound();
          } else {
            // Play default sound for normal priority assignments
            debugPrint('🔔 Playing default sound for normal priority assignment');
            soundService.playDefaultSound();
          }
        } else if (type == 'critical_report') {
          // ALWAYS play emergency sound for critical reports (super users/admins)
          debugPrint('🚨 Playing emergency sound for CRITICAL REPORT (super user alert)');
          soundService.playEmergencySound();
        }
      }
    } catch (e) {
      debugPrint('Error handling notification received: $e');
    }
  }

  /// Get current player ID
  String? get playerId => _playerId;

  /// Send tags to OneSignal (for user segmentation)
  Future<void> setTag(String key, String value) async {
    try {
      await OneSignal.User.addTags({key: value});
      debugPrint('OneSignal tag set: $key = $value');
    } catch (e) {
      debugPrint('Error setting OneSignal tag: $e');
    }
  }

  /// Set user email (for targeting)
  Future<void> setEmail(String email) async {
    try {
      await OneSignal.User.addEmail(email);
      debugPrint('OneSignal email set: $email');
    } catch (e) {
      debugPrint('Error setting OneSignal email: $e');
    }
  }
}

