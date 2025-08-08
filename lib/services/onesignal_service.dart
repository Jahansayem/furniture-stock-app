import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class OneSignalService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final SupabaseClient _supabase = Supabase.instance.client;
  static bool _isInitialized = false;
  static String? _playerId;

  // Initialize OneSignal
  static Future<void> initialize() async {
    print('🔔 Initializing OneSignal...');

    try {
      // Remove this method to stop OneSignal Debugging
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // OneSignal Initialization
      OneSignal.initialize("ae49f2db-a82d-4149-81fa-7308b0338cd2");

      // IMPORTANT: Provide user consent immediately for proper functionality
      // In a production app, you should ask the user for consent first
      OneSignal.consentGiven(true);

      // Request notification permission - especially important for Android 13+
      print('📱 Requesting notification permissions...');
      await OneSignal.Notifications.requestPermission(true);

      // For Android 13+, also handle runtime permission
      if (Platform.isAndroid) {
        await _requestAndroidNotificationPermission();
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up notification handlers
      _setupNotificationHandlers();

      // Wait a bit for OneSignal to fully initialize before getting player ID
      print('⏳ Waiting for OneSignal to fully initialize...');
      await Future.delayed(const Duration(seconds: 2));

      _isInitialized = true;
      print('✅ OneSignal initialized successfully');

      // Get player ID and save to database (with retry logic)
      await _getPlayerIdAndSaveWithRetry();
    } catch (e) {
      print('❌ Error initializing OneSignal: $e');
      _isInitialized = false;
      // Don't throw - let the app continue without OneSignal
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'furnitruck_channel',
        'FurniTruck Notifications',
        description: 'This channel is used for FurniTruck app notifications.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      print('✅ Local notifications initialized');
    } catch (e) {
      print('❌ Error initializing local notifications: $e');
    }
  }

  // Set up notification handlers
  static void _setupNotificationHandlers() {
    // Handle notification opened
    OneSignal.Notifications.addClickListener((event) {
      print(
          '🔔 OneSignal notification clicked: ${event.notification.notificationId}');
      _handleNotificationTap(event.notification.additionalData);
    });

    // Handle notification received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('🔔 OneSignal notification received in foreground');
      // Display the notification as local notification
      _showLocalNotification(
        event.notification.title ?? 'FurniTruck',
        event.notification.body ?? 'You have a new notification',
        event.notification.additionalData,
      );
    });
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        _handleNotificationTap(data);
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }

  // Handle notification tap logic
  static void _handleNotificationTap(Map<String, dynamic>? data) {
    if (data == null) return;

    print('🔔 Handling notification tap with data: $data');

    // Add your navigation logic here based on notification data
    // For example:
    // if (data['type'] == 'stock_alert') {
    //   // Navigate to stock screen
    // } else if (data['type'] == 'sale_notification') {
    //   // Navigate to sales screen
    // }
  }

  // Get OneSignal player ID and save to database with retry logic
  static Future<void> _getPlayerIdAndSaveWithRetry() async {
    const int maxRetries = 5;
    const Duration retryDelay = Duration(seconds: 3);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔄 Attempting to get Player ID (attempt $attempt/$maxRetries)');

        final user = _supabase.auth.currentUser;
        if (user == null) {
          print('⚠️ No authenticated user - cannot save player ID');
          return;
        }

        // Get player ID
        final playerId = await OneSignal.User.getOnesignalId();
        if (playerId == null || playerId.isEmpty) {
          print('⚠️ Player ID is null or empty on attempt $attempt');
          if (attempt < maxRetries) {
            print('⏳ Waiting ${retryDelay.inSeconds} seconds before retry...');
            await Future.delayed(retryDelay);
            continue;
          } else {
            print(
                '❌ Failed to get OneSignal player ID after $maxRetries attempts');
            return;
          }
        }

        _playerId = playerId;
        print('📱 OneSignal Player ID retrieved: $playerId');

        // Save to database
        await _supabase.from(SupabaseConfig.profilesTable).upsert({
          'id': user.id,
          'onesignal_player_id': playerId,
          'updated_at': DateTime.now().toIso8601String(),
        });

        print('✅ OneSignal Player ID saved to database successfully');
        return; // Success - exit the retry loop
      } catch (e) {
        print(
            '❌ Error getting/saving OneSignal Player ID (attempt $attempt): $e');
        if (attempt < maxRetries) {
          print('⏳ Waiting ${retryDelay.inSeconds} seconds before retry...');
          await Future.delayed(retryDelay);
        } else {
          print('❌ Failed to get/save Player ID after $maxRetries attempts');
        }
      }
    }
  }

  // Show local notification
  static Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic>? data,
  ) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'furnitruck_channel',
        'FurniTruck Notifications',
        channelDescription:
            'This channel is used for FurniTruck app notifications.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF1976D2),
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
        payload: data != null ? json.encode(data) : null,
      );
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  // Send notification to all users
  static Future<bool> sendNotificationToAll({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (!_isInitialized) {
        print('⚠️ OneSignal not initialized - notification not sent');
        return false;
      }

      print('📤 Sending notification to all users via OneSignal');
      print('Title: $title');
      print('Message: $message');
      print('Data: $data');

      // Send via Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'send-notification',
        body: {
          'title': title,
          'message': message,
          'data': data,
        },
      );

      if (response.status == 200) {
        print('✅ Notification sent successfully via OneSignal');
        return true;
      } else {
        print('❌ Failed to send notification: ${response.status}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending notification to all: $e');
      return false;
    }
  }

  // Send notification to specific user
  static Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (!_isInitialized) {
        print('⚠️ OneSignal not initialized - notification not sent');
        return false;
      }

      // Get user's OneSignal player ID from database
      final userResponse = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select('onesignal_player_id')
          .eq('id', userId)
          .single();

      final playerId = userResponse['onesignal_player_id'] as String?;
      if (playerId == null) {
        print('⚠️ No OneSignal player ID found for user: $userId');
        return false;
      }

      print('📤 Sending notification to user: $userId');
      print('Player ID: $playerId');
      print('Title: $title');
      print('Message: $message');

      // Send via Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'send-notification',
        body: {
          'title': title,
          'message': message,
          'playerIds': [playerId],
          'data': data,
        },
      );

      if (response.status == 200) {
        print('✅ Notification sent successfully to user');
        return true;
      } else {
        print('❌ Failed to send notification to user: ${response.status}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending notification to user: $e');
      return false;
    }
  }

  // Get current player ID
  static String? get playerId => _playerId;

  // Check if OneSignal is initialized
  static bool get isInitialized => _isInitialized;

  // Manually refresh player ID (useful for debugging)
  static Future<String?> refreshPlayerId() async {
    print('🔄 Manually refreshing OneSignal Player ID...');
    await _getPlayerIdAndSaveWithRetry();
    return _playerId;
  }

  // Update user tags (for segmentation)
  static Future<void> setUserTags(Map<String, String> tags) async {
    try {
      await OneSignal.User.addTags(tags);
      print('✅ OneSignal user tags updated: $tags');
    } catch (e) {
      print('❌ Error updating OneSignal user tags: $e');
    }
  }

  // Remove user tags
  static Future<void> removeUserTags(List<String> tags) async {
    try {
      await OneSignal.User.removeTags(tags);
      print('✅ OneSignal user tags removed: $tags');
    } catch (e) {
      print('❌ Error removing OneSignal user tags: $e');
    }
  }

  // Request Android notification permission for Android 13+
  static Future<void> _requestAndroidNotificationPermission() async {
    try {
      final status = await Permission.notification.status;

      if (status.isDenied) {
        print('📱 Requesting Android notification permission...');
        final result = await Permission.notification.request();

        if (result.isGranted) {
          print('✅ Android notification permission granted');
        } else if (result.isDenied) {
          print('❌ Android notification permission denied');
        } else if (result.isPermanentlyDenied) {
          print('❌ Android notification permission permanently denied');
          // You might want to show a dialog here directing users to settings
        }
      } else if (status.isGranted) {
        print('✅ Android notification permission already granted');
      }
    } catch (e) {
      print('❌ Error requesting Android notification permission: $e');
    }
  }

  // Get device registration token for debugging
  static Future<String?> getDeviceToken() async {
    try {
      final deviceState = await OneSignal.User.getOnesignalId();
      print('📱 Device OneSignal ID: $deviceState');
      return deviceState;
    } catch (e) {
      print('❌ Error getting device token: $e');
      return null;
    }
  }

  // Test notification delivery
  static Future<void> sendTestNotification() async {
    try {
      await sendNotificationToAll(
        title: 'Test Notification',
        message: 'This is a test notification from FurniTrack',
        data: {
          'type': 'test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print('✅ Test notification sent');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }
}

Future<bool> sendOneSignalNotificationToAllUsers({
  required String appId,
  required String restApiKey,
  required String title,
  required String message,
}) async {
  final url = Uri.parse('https://onesignal.com/api/v1/notifications');

  final body = jsonEncode({
    'app_id': appId,
    'included_segments': ['All'], // send to all subscribed users
    'headings': {'en': title},
    'contents': {'en': message},
  });

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Basic $restApiKey',
    },
    body: body,
  );

  if (response.statusCode == 200) {
    print('Notification sent successfully!');
    return true;
  } else {
    print('Failed to send notification. Status: ${response.statusCode}');
    print('Response: ${response.body}');
    return false;
  }
}
