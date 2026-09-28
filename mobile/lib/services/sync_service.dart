import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/smoking_log.dart';
import '../models/craving_log.dart';

class SyncResult {
  final int syncedSmokingCount;
  final int syncedCravingCount;
  final bool hasErrors;

  const SyncResult({
    required this.syncedSmokingCount,
    required this.syncedCravingCount,
    required this.hasErrors,
  });
}

class SyncService {
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  static const Duration timeoutDuration = Duration(seconds: 4);

  /// Pushes a single smoking event to server with auth and idempotency.
  /// Returns true if successfully acknowledged by server.
  static Future<bool> pushSmokingEvent({
    required SmokingLog log,
    String? authToken,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final res = await http.post(
        Uri.parse('$baseUrl/smoking/log'),
        headers: headers,
        body: jsonEncode({
          'id': log.id,
          'logged_at': log.timestamp.toIso8601String(),
          'trigger': log.trigger,
          'mood': log.mood,
          'location': log.location,
          'notes': log.note,
          'is_quick_log': log.source == 'quick_log',
          'craving_intensity': log.cravingIntensity,
          'source': log.source,
          'user_id': log.userId,
        }),
      ).timeout(timeoutDuration);

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('SyncService pushSmokingEvent error (offline fallback): $e');
      return false;
    }
  }

  /// Pushes a single craving event to server with auth.
  static Future<bool> pushCravingEvent({
    required CravingLog log,
    String? authToken,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final res = await http.post(
        Uri.parse('$baseUrl/cravings/log'),
        headers: headers,
        body: jsonEncode({
          'id': log.id,
          'created_at': log.timestamp.toIso8601String(),
          'trigger': log.trigger,
          'intensity': log.intensity,
          'micro_action': log.microAction,
          'delayed_minutes_completed': log.delayedMinutesCompleted,
          'outcome': log.outcome,
          'did_smoke': log.didSmoke,
        }),
      ).timeout(timeoutDuration);

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('SyncService pushCravingEvent error (offline fallback): $e');
      return false;
    }
  }

  /// Process pending local events queue.
  /// Sync Invariants:
  /// - Never duplicate events
  /// - Idempotent
  /// - Preserve timestamps and IDs
  /// - Deterministic conflict resolution
  static Future<SyncResult> syncPendingQueue({
    required List<SmokingLog> allSmokingLogs,
    required List<CravingLog> allCravingLogs,
    String? authToken,
  }) async {
    int syncedSmoking = 0;
    int syncedCravings = 0;
    bool hasErrors = false;

    // 1. Process pending smoking logs
    for (int i = 0; i < allSmokingLogs.length; i++) {
      final log = allSmokingLogs[i];
      if (log.syncStatus != 'synced') {
        final success = await pushSmokingEvent(log: log, authToken: authToken);
        if (success) {
          allSmokingLogs[i] = log.copyWith(
            syncStatus: 'synced',
            isSynced: true,
          );
          syncedSmoking++;
        } else {
          hasErrors = true;
        }
      }
    }

    // 2. Process pending craving logs
    for (int i = 0; i < allCravingLogs.length; i++) {
      final craving = allCravingLogs[i];
      if (!craving.isSynced) {
        final success = await pushCravingEvent(log: craving, authToken: authToken);
        if (success) {
          allCravingLogs[i] = craving.copyWith(isSynced: true);
          syncedCravings++;
        } else {
          hasErrors = true;
        }
      }
    }

    return SyncResult(
      syncedSmokingCount: syncedSmoking,
      syncedCravingCount: syncedCravings,
      hasErrors: hasErrors,
    );
  }
}
