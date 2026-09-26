import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/smoking_log.dart';
import '../models/craving_log.dart';

class ApiService {
  // 10.0.2.2 is Android emulator loopback to host; 127.0.0.1 for local
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  static const Duration timeoutDuration = Duration(seconds: 4);

  static Future<bool> checkBackendHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/dev/health')).timeout(timeoutDuration);
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> syncSmokingLog(SmokingLog log) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/smoking/log'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'timestamp': log.timestamp.toIso8601String(),
          'trigger': log.trigger,
          'mood': log.mood,
          'location': log.location,
          'note': log.note,
          'delayed_first': log.delayedFirst,
          'delay_minutes': log.delayMinutes,
        }),
      ).timeout(timeoutDuration);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Sync smoking log fallback to offline storage: $e');
      return false;
    }
  }

  static Future<bool> syncCravingLog(CravingLog log) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/cravings/log'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'timestamp': log.timestamp.toIso8601String(),
          'trigger': log.trigger,
          'intensity': log.intensity,
          'micro_action': log.microAction,
          'delayed_minutes_completed': log.delayedMinutesCompleted,
          'outcome': log.outcome,
        }),
      ).timeout(timeoutDuration);
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Sync craving log fallback to offline storage: $e');
      return false;
    }
  }
}
