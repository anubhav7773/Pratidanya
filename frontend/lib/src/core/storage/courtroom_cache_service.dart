import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/02_case_input/domain/criminal_case.dart';

/// Courtroom Offline Cache Service
/// Provides crash-resilient, atomic JSON-based local storage for advocate
/// criminal case dockets, 360 bail drafts, and offline mutation queues.
class CourtroomCacheService {
  final Directory? _customDirectory;

  CourtroomCacheService({Directory? customDirectory})
      : _customDirectory = customDirectory;

  Future<Directory> _getStorageDirectory() async {
    if (_customDirectory != null) {
      if (!await _customDirectory.exists()) {
        await _customDirectory.create(recursive: true);
      }
      return _customDirectory;
    }
    final docDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${docDir.path}/courtroom_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  File _getFile(Directory dir, String filename) {
    return File('${dir.path}/$filename');
  }

  /// Atomic file write using temporary file to prevent corruption
  Future<void> _writeAtomically(File targetFile, String content) async {
    final tempFile = File('${targetFile.path}.tmp');
    await tempFile.writeAsString(content, flush: true);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await tempFile.rename(targetFile.path);
  }

  // --------------------------------------------------------------------------
  // Criminal Cases Docket Cache
  // --------------------------------------------------------------------------

  Future<void> saveCases(String advocateId, List<CriminalCase> cases) async {
    try {
      final dir = await _getStorageDirectory();
      final file = _getFile(dir, 'cases_$advocateId.json');
      final data = {
        'advocate_id': advocateId,
        'cached_at': DateTime.now().toUtc().toIso8601String(),
        'cases': cases.map((c) => c.toJson()).toList(),
      };
      await _writeAtomically(file, jsonEncode(data));
      debugPrint('[CourtroomCache] Successfully cached ${cases.length} cases for advocate $advocateId');
    } catch (e) {
      debugPrint('[CourtroomCache] Error caching cases: $e');
    }
  }

  Future<List<CriminalCase>> getCachedCases(String advocateId) async {
    try {
      final dir = await _getStorageDirectory();
      final file = _getFile(dir, 'cases_$advocateId.json');
      if (!await file.exists()) {
        return [];
      }
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = decoded['cases'] as List<dynamic>? ?? [];
      return list
          .map((item) => CriminalCase.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[CourtroomCache] Error reading cached cases: $e');
      return [];
    }
  }

  Future<DateTime?> getLastSyncTime(String advocateId) async {
    try {
      final dir = await _getStorageDirectory();
      final file = _getFile(dir, 'cases_$advocateId.json');
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final str = decoded['cached_at'] as String?;
      return str != null ? DateTime.tryParse(str) : null;
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Draft Studio 360 Bail Drafts Cache
  // --------------------------------------------------------------------------

  Future<void> saveDraft(String caseId, Map<String, dynamic> draftJson) async {
    try {
      final dir = await _getStorageDirectory();
      final file = _getFile(dir, 'draft_$caseId.json');
      final data = {
        'case_id': caseId,
        'cached_at': DateTime.now().toUtc().toIso8601String(),
        'draft': draftJson,
      };
      await _writeAtomically(file, jsonEncode(data));
      debugPrint('[CourtroomCache] Successfully cached draft for case $caseId');
    } catch (e) {
      debugPrint('[CourtroomCache] Error caching draft: $e');
    }
  }

  Future<Map<String, dynamic>?> getCachedDraft(String caseId) async {
    try {
      final dir = await _getStorageDirectory();
      final file = _getFile(dir, 'draft_$caseId.json');
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded['draft'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[CourtroomCache] Error reading cached draft: $e');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Offline Mutations Outbox Queue
  // --------------------------------------------------------------------------

  Future<void> queueOfflineAction(Map<String, dynamic> action) async {
    try {
      final dir = await _getStorageDirectory();
      final file = _getFile(dir, 'pending_queue.json');
      List<dynamic> queue = [];
      if (await file.exists()) {
        final raw = await file.readAsString();
        queue = jsonDecode(raw) as List<dynamic>? ?? [];
      }
      queue.add(action);
      await _writeAtomically(file, jsonEncode(queue));
      debugPrint('[CourtroomCache] Queued offline action: ${action['type']} (Queue length: ${queue.length})');
    } catch (e) {
      debugPrint('[CourtroomCache] Error queuing offline action: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    try {
      final dir = await _getStorageDirectory();
      final file = _getFile(dir, 'pending_queue.json');
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[CourtroomCache] Error reading pending queue: $e');
      return [];
    }
  }

  Future<void> clearPendingAction(String actionId) async {
    try {
      final dir = await _getStorageDirectory();
      final file = _getFile(dir, 'pending_queue.json');
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      final list = (jsonDecode(raw) as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      list.removeWhere((item) => item['id'] == actionId);
      await _writeAtomically(file, jsonEncode(list));
      debugPrint('[CourtroomCache] Cleared pending action $actionId. Remaining: ${list.length}');
    } catch (e) {
      debugPrint('[CourtroomCache] Error clearing pending action: $e');
    }
  }

  Future<void> clearAllCache(String advocateId) async {
    try {
      final dir = await _getStorageDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[CourtroomCache] Error clearing all cache: $e');
    }
  }
}
