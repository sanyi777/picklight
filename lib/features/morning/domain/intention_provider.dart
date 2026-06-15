import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_provider.dart';
import 'intention_model.dart';

class IntentionNotifier extends StateNotifier<AsyncValue<Intention?>> {
  final Ref _ref;

  IntentionNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadTodayIntention();
  }

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> loadTodayIntention() async {
    state = const AsyncValue.loading();
    try {
      final db = await _ref.read(databaseProvider).database;
      final maps = await db.query(
        'intentions',
        where: 'date = ?',
        whereArgs: [_today],
      );
      if (maps.isNotEmpty) {
        state = AsyncValue.data(Intention.fromMap(maps.first));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setTodayIntention({
    String? highlight,
    String? intentionText,
  }) async {
    final db = await _ref.read(databaseProvider).database;
    final now = DateTime.now().toIso8601String();
    final intention = Intention(
      date: _today,
      highlight: highlight,
      intentionText: intentionText,
      createdAt: now,
      updatedAt: now,
    );

    // Upsert: delete existing today's intention, then insert
    await db.delete('intentions', where: 'date = ?', whereArgs: [_today]);
    await db.insert('intentions', intention.toMap());
    await loadTodayIntention();
  }

  Future<void> toggleCompletion() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final db = await _ref.read(databaseProvider).database;
    await db.update(
      'intentions',
      {
        'is_completed': current.isCompleted ? 0 : 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [current.id],
    );
    await loadTodayIntention();
  }
}

final todayIntentionProvider =
    StateNotifierProvider<IntentionNotifier, AsyncValue<Intention?>>((ref) {
      return IntentionNotifier(ref);
    });
