import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_provider.dart';
import 'focus_session_model.dart';

class FocusNotifier extends StateNotifier<AsyncValue<List<FocusSession>>> {
  final Ref _ref;

  FocusNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadTodaySessions();
  }

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> loadTodaySessions() async {
    state = const AsyncValue.loading();
    try {
      final db = await _ref.read(databaseProvider).database;
      final maps = await db.query(
        'focus_sessions',
        where: 'date = ?',
        whereArgs: [_today],
        orderBy: 'created_at DESC',
      );
      final sessions = maps.map((m) => FocusSession.fromMap(m)).toList();
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> startSession({String type = 'pomodoro'}) async {
    final db = await _ref.read(databaseProvider).database;
    final session = FocusSession(
      date: _today,
      type: type,
      startTime: DateTime.now().toIso8601String(),
    );
    await db.insert('focus_sessions', session.toMap());
    await loadTodaySessions();
    return session.id;
  }

  Future<void> endSession(String sessionId, {int durationMinutes = 25}) async {
    final db = await _ref.read(databaseProvider).database;
    await db.update(
      'focus_sessions',
      {
        'end_time': DateTime.now().toIso8601String(),
        'duration_minutes': durationMinutes,
        'completed': 1,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    await loadTodaySessions();
  }

  Future<void> addBrainDumpItem(String sessionId, String item) async {
    final db = await _ref.read(databaseProvider).database;
    final maps = await db.query(
      'focus_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    if (maps.isEmpty) return;

    final session = FocusSession.fromMap(maps.first);
    final updatedItems = List<String>.from(session.brainDumpItems)..add(item);

    await db.update(
      'focus_sessions',
      {'brain_dump_items': jsonEncode(updatedItems)},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    await loadTodaySessions();
  }
}

final todayFocusSessionsProvider =
    StateNotifierProvider<FocusNotifier, AsyncValue<List<FocusSession>>>((ref) {
      return FocusNotifier(ref);
    });
