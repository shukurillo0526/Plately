import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_service.dart';
import 'gamification_service.dart';

class AnalyticsEvent {
  final String eventName;
  final Map<String, dynamic> properties;
  final DateTime timestamp;

  AnalyticsEvent(this.eventName, this.properties, [DateTime? time])
      : timestamp = time ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'event_name': eventName,
        'properties': properties,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      json['event_name'],
      json['properties'] ?? {},
      DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class AnalyticsService {
  static const String _queueKey = 'analytics_event_queue';

  /// Log an event. It attempts to send it immediately; if it fails, it queues it locally.
  static Future<void> logEvent(String eventName, [Map<String, dynamic>? properties]) async {
    final event = AnalyticsEvent(eventName, properties ?? {});
    
    // Attempt immediate sync
    final success = await _syncEvent(event);
    if (!success) {
      await _queueEvent(event);
    }
  }

  static Future<bool> _syncEvent(AnalyticsEvent event) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return false;

      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/analytics/event');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode(event.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['gamification'] != null) {
          // Fire gamification UI events if needed
          GamificationService.handleGamificationResult(data['gamification']);
        }
        return true;
      }
    } catch (e) {
      debugPrint('Failed to sync analytics event: $e');
    }
    return false;
  }

  static Future<void> _queueEvent(AnalyticsEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_queueKey) ?? [];
      list.add(jsonEncode(event.toJson()));
      await prefs.setStringList(_queueKey, list);
    } catch (e) {
      debugPrint('Local analytics queue error: $e');
    }
  }

  /// Called on app startup or network reconnect to sync queued events
  static Future<void> syncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_queueKey) ?? [];
      if (list.isEmpty) return;

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;

      final events = list.map((s) => jsonDecode(s)).toList();
      
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/analytics/events/batch');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({'events': events}),
      );

      if (response.statusCode == 200) {
        // Clear queue on success
        await prefs.setStringList(_queueKey, []);
        
        final data = jsonDecode(response.body);
        if (data['gamification_results'] != null) {
          for (var res in data['gamification_results']) {
            GamificationService.handleGamificationResult(res['gamification']);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to sync analytics queue: $e');
    }
  }
}
