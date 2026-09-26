import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/smoking_log.dart';
import '../models/craving_log.dart';
import '../models/experiment.dart';
import '../models/personal_record.dart';
import '../models/target_history_entry.dart';
import '../models/target_cycle.dart';
import '../models/daily_coverage.dart';

class StorageService {
  static const int currentSchemaVersion = 2;

  static const String _keySchemaVersion = 'clarity_schema_version';
  static const String _keyProfile = 'clarity_user_profile';
  static const String _keySmokingLogs = 'clarity_smoking_logs';
  static const String _keyCravingLogs = 'clarity_craving_logs';
  static const String _keyExperiments = 'clarity_experiments';
  static const String _keyPersonalRecords = 'clarity_personal_records';
  static const String _keyTargetHistory = 'clarity_target_history';
  static const String _keyTargetCycles = 'clarity_target_cycles';
  static const String _keyDailyCoverage = 'clarity_daily_coverage';
  static const String _keyThemeMode = 'clarity_theme_mode';
  static const String _keyAuthToken = 'clarity_auth_token';
  static const String _keyBackup = 'clarity_backup_v1';

  /// Load all persisted app state with automated, non-destructive migration.
  static Future<Map<String, dynamic>> loadData() async {
    final result = <String, dynamic>{};
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check and execute schema migration if needed (Section 48 & 49)
      final savedVersion = prefs.getInt(_keySchemaVersion) ?? 1;
      if (savedVersion < currentSchemaVersion) {
        await _migrateData(prefs, fromVersion: savedVersion, toVersion: currentSchemaVersion);
      }

      // 1. Profile
      final profileStr = prefs.getString(_keyProfile);
      if (profileStr != null && profileStr.isNotEmpty) {
        result['profile'] = jsonDecode(profileStr);
      }

      // 2. Smoking Logs
      final smokingStr = prefs.getString(_keySmokingLogs);
      if (smokingStr != null && smokingStr.isNotEmpty) {
        result['smokingLogs'] = jsonDecode(smokingStr);
      }

      // 3. Craving Logs
      final cravingStr = prefs.getString(_keyCravingLogs);
      if (cravingStr != null && cravingStr.isNotEmpty) {
        result['cravingLogs'] = jsonDecode(cravingStr);
      }

      // 4. Experiments
      final expStr = prefs.getString(_keyExperiments);
      if (expStr != null && expStr.isNotEmpty) {
        result['experiments'] = jsonDecode(expStr);
      }

      // 5. Personal Records
      final recStr = prefs.getString(_keyPersonalRecords);
      if (recStr != null && recStr.isNotEmpty) {
        result['records'] = jsonDecode(recStr);
      }

      // 6. Target History
      final thStr = prefs.getString(_keyTargetHistory);
      if (thStr != null && thStr.isNotEmpty) {
        result['targetHistory'] = jsonDecode(thStr);
      }

      // 7. Target Cycles
      final tcStr = prefs.getString(_keyTargetCycles);
      if (tcStr != null && tcStr.isNotEmpty) {
        result['targetCycles'] = jsonDecode(tcStr);
      }

      // 8. Daily Coverage
      final dcStr = prefs.getString(_keyDailyCoverage);
      if (dcStr != null && dcStr.isNotEmpty) {
        result['dailyCoverage'] = jsonDecode(dcStr);
      }

      // 9. Theme Mode & Auth
      result['themeMode'] = prefs.getString(_keyThemeMode) ?? 'dark';
      result['authToken'] = prefs.getString(_keyAuthToken) ?? '';
    } catch (e) {
      debugPrint('StorageService loadData error: $e');
    }
    return result;
  }

  /// Safe, non-destructive migration handler (Section 48, 49, 50)
  static Future<void> _migrateData(
    SharedPreferences prefs, {
    required int fromVersion,
    required int toVersion,
  }) async {
    try {
      debugPrint('StorageService: Migrating schema from v$fromVersion to v$toVersion');

      // Backup existing data before schema upgrade
      final profileRaw = prefs.getString(_keyProfile);
      final logsRaw = prefs.getString(_keySmokingLogs);
      final cravingsRaw = prefs.getString(_keyCravingLogs);

      final backup = <String, dynamic>{
        'profile': profileRaw,
        'logs': logsRaw,
        'cravings': cravingsRaw,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_keyBackup, jsonEncode(backup));

      if (fromVersion < 2) {
        // v1 -> v2 migration: ensure Profile has INR currency, name field, strategyMode
        if (profileRaw != null) {
          final map = jsonDecode(profileRaw) as Map<String, dynamic>;
          map['currency'] = '₹'; // Guarantee strict INR
          if (!map.containsKey('name')) {
            map['name'] = map['displayName'] ?? '';
          }
          if (!map.containsKey('strategyMode')) {
            map['strategyMode'] = 'REDUCE';
          }
          if (!map.containsKey('cigarettesPerDay')) {
            map['cigarettesPerDay'] = map['baselineCpd'] ?? 10;
          }
          if (!map.containsKey('targetCigarettesPerDay')) {
            map['targetCigarettesPerDay'] = map['targetCpd'] ?? 9;
          }
          await prefs.setString(_keyProfile, jsonEncode(map));
        }
      }

      await prefs.setInt(_keySchemaVersion, toVersion);
      debugPrint('StorageService: Migration to v$toVersion succeeded.');
    } catch (e) {
      debugPrint('StorageService migration failure: $e. Old data preserved.');
    }
  }

  /// Persists current application state deterministically.
  static Future<void> saveData({
    UserProfile? profile,
    List<SmokingLog>? smokingLogs,
    List<CravingLog>? cravingLogs,
    List<BehavioralExperiment>? experiments,
    PersonalRecords? records,
    List<TargetHistoryEntry>? targetHistory,
    List<TargetCycle>? targetCycles,
    List<DailyCoverage>? dailyCoverage,
    String? themeMode,
    String? authToken,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (profile != null) {
        await prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
      }
      if (smokingLogs != null) {
        final list = smokingLogs.map((e) => e.toJson()).toList();
        await prefs.setString(_keySmokingLogs, jsonEncode(list));
      }
      if (cravingLogs != null) {
        final list = cravingLogs.map((e) => e.toJson()).toList();
        await prefs.setString(_keyCravingLogs, jsonEncode(list));
      }
      if (experiments != null) {
        final list = experiments.map((e) => e.toJson()).toList();
        await prefs.setString(_keyExperiments, jsonEncode(list));
      }
      if (records != null) {
        await prefs.setString(_keyPersonalRecords, jsonEncode(records.toJson()));
      }
      if (targetHistory != null) {
        final list = targetHistory.map((e) => e.toJson()).toList();
        await prefs.setString(_keyTargetHistory, jsonEncode(list));
      }
      if (targetCycles != null) {
        final list = targetCycles.map((e) => e.toJson()).toList();
        await prefs.setString(_keyTargetCycles, jsonEncode(list));
      }
      if (dailyCoverage != null) {
        final list = dailyCoverage.map((e) => e.toJson()).toList();
        await prefs.setString(_keyDailyCoverage, jsonEncode(list));
      }
      if (themeMode != null) {
        await prefs.setString(_keyThemeMode, themeMode);
      }
      if (authToken != null) {
        await prefs.setString(_keyAuthToken, authToken);
      }
    } catch (e) {
      debugPrint('StorageService saveData error: $e');
    }
  }

  /// Exports all personal data as structured JSON (Section 9: Privacy & Data Export)
  static Future<String> exportUserData() async {
    final data = await loadData();
    data['exportedAt'] = DateTime.now().toIso8601String();
    data['app'] = 'Clarity — Anti-Smoking Coach';
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Clears all user data on account deletion (Section 9 & 42)
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyProfile);
      await prefs.remove(_keySmokingLogs);
      await prefs.remove(_keyCravingLogs);
      await prefs.remove(_keyExperiments);
      await prefs.remove(_keyPersonalRecords);
      await prefs.remove(_keyTargetHistory);
      await prefs.remove(_keyTargetCycles);
      await prefs.remove(_keyDailyCoverage);
      await prefs.remove(_keyThemeMode);
      await prefs.remove(_keyAuthToken);
    } catch (e) {
      debugPrint('StorageService clearAll error: $e');
    }
  }
}
