import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/services/notification_service.dart';
import 'schedule_item_model.dart';

class ScheduleNotifier extends StateNotifier<AsyncValue<List<ScheduleItem>>> {
  final Ref _ref;
  String _currentDate;

  ScheduleNotifier(this._ref)
    : _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now()),
      super(const AsyncValue.loading()) {
    loadScheduleForDate(_currentDate);
  }

  String get currentDate => _currentDate;

  Future<void> loadScheduleForDate(String date) async {
    _currentDate = date;
    state = const AsyncValue.loading();
    try {
      final db = await _ref.read(databaseProvider).database;
      final maps = await db.query(
        'schedule_items',
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'created_at ASC',
      );
      final items = maps.map((m) => ScheduleItem.fromMap(m)).toList();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem(ScheduleItem item) async {
    final db = await _ref.read(databaseProvider).database;
    await db.insert(
      'schedule_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await loadScheduleForDate(_currentDate);

    // Show notification as confirmation that reminder is set
    final timeSlot = item.timeSlot ?? '';
    final timeHint = timeSlot.isNotEmpty ? '（$timeSlot）' : '';
    NotificationService().showScheduleReminder(
      '日程已添加',
      '${item.title}$timeHint',
    );
  }

  Future<void> toggleCompleted(String id) async {
    final db = await _ref.read(databaseProvider).database;
    final maps = await db.query(
      'schedule_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return;

    final item = ScheduleItem.fromMap(maps.first);
    await db.update(
      'schedule_items',
      {
        'is_completed': item.isCompleted ? 0 : 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadScheduleForDate(_currentDate);
  }

  Future<void> removeItem(String id) async {
    final db = await _ref.read(databaseProvider).database;
    await db.delete('schedule_items', where: 'id = ?', whereArgs: [id]);
    await loadScheduleForDate(_currentDate);
  }

  Future<List<ScheduleItem>> getItemsForDate(String date) async {
    final db = await _ref.read(databaseProvider).database;
    final maps = await db.query(
      'schedule_items',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => ScheduleItem.fromMap(m)).toList();
  }

  /// Loads all schedule items for the week containing [monday].
  /// Returns a map of dateKey -> list of ScheduleItem.
  Future<Map<String, List<ScheduleItem>>> loadScheduleForWeek(
    String monday,
  ) async {
    final mondayDate = DateTime.parse(monday);
    final sundayDate = mondayDate.add(const Duration(days: 6));
    final sunday = DateFormat('yyyy-MM-dd').format(sundayDate);

    final db = await _ref.read(databaseProvider).database;
    final maps = await db.query(
      'schedule_items',
      where: 'date >= ? AND date <= ?',
      whereArgs: [monday, sunday],
      orderBy: 'time_slot ASC, created_at ASC',
    );

    final week = <String, List<ScheduleItem>>{};
    for (var i = 0; i < 7; i++) {
      final d = DateFormat(
        'yyyy-MM-dd',
      ).format(mondayDate.add(Duration(days: i)));
      week[d] = [];
    }

    for (final m in maps) {
      final item = ScheduleItem.fromMap(m);
      if (week.containsKey(item.date)) {
        week[item.date]!.add(item);
      }
    }

    return week;
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, AsyncValue<List<ScheduleItem>>>((
      ref,
    ) {
      return ScheduleNotifier(ref);
    });
