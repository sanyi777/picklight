import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_provider.dart';

class DailyLog {
  final String id;
  final String date;
  final List<String> actualActivities;
  final String? reflectionNotes;
  final String createdAt;

  DailyLog({
    String? id,
    required this.date,
    List<String>? actualActivities,
    this.reflectionNotes,
    String? createdAt,
  }) : id = id ?? const Uuid().v4(),
       actualActivities = actualActivities ?? [],
       createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    List<String> activities = [];
    final raw = map['actual_activities'] as String?;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          activities = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return DailyLog(
      id: map['id'] as String,
      date: map['date'] as String,
      actualActivities: activities,
      reflectionNotes: map['reflection_notes'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'actual_activities': actualActivities.isNotEmpty
          ? jsonEncode(actualActivities)
          : null,
      'reflection_notes': reflectionNotes,
      'created_at': createdAt,
    };
  }
}

class EveningNotifier extends StateNotifier<AsyncValue<DailyLog?>> {
  final Ref _ref;

  EveningNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadTodayLog();
  }

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> loadTodayLog() async {
    state = const AsyncValue.loading();
    try {
      final db = await _ref.read(databaseProvider).database;
      final maps = await db.query(
        'daily_logs',
        where: 'date = ?',
        whereArgs: [_today],
      );
      if (maps.isNotEmpty) {
        state = AsyncValue.data(DailyLog.fromMap(maps.first));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveDailyLog({
    List<String>? actualActivities,
    String? reflectionNotes,
  }) async {
    final db = await _ref.read(databaseProvider).database;
    final log = DailyLog(
      date: _today,
      actualActivities: actualActivities,
      reflectionNotes: reflectionNotes,
    );

    await db.delete('daily_logs', where: 'date = ?', whereArgs: [_today]);
    await db.insert('daily_logs', log.toMap());
    await loadTodayLog();
  }

  /// Returns deviation data: compares today's intention vs actual activities.
  Future<Map<String, dynamic>> getDeviationData() async {
    final db = await _ref.read(databaseProvider).database;

    final intentionMaps = await db.query(
      'intentions',
      where: 'date = ?',
      whereArgs: [_today],
    );

    final logMaps = await db.query(
      'daily_logs',
      where: 'date = ?',
      whereArgs: [_today],
    );

    return {
      'date': _today,
      'intention': intentionMaps.isNotEmpty ? intentionMaps.first : null,
      'log': logMaps.isNotEmpty ? DailyLog.fromMap(logMaps.first) : null,
    };
  }
}

final todayLogProvider =
    StateNotifierProvider<EveningNotifier, AsyncValue<DailyLog?>>((ref) {
      return EveningNotifier(ref);
    });
