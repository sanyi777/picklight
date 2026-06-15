import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_provider.dart';
import '../../progress/domain/project_model.dart';

class StatsData {
  final Map<String, int> dailyCaptures;
  final int totalFocusSessions;
  final int totalFocusMinutes;
  final Map<String, int> categoryDistribution;

  /// Phase 5: daily focus minutes for bar chart (date -> minutes)
  final Map<String, int> dailyFocusMinutes;
  final List<ProjectProgress> projects;

  StatsData({
    this.dailyCaptures = const {},
    this.totalFocusSessions = 0,
    this.totalFocusMinutes = 0,
    this.categoryDistribution = const {},
    this.dailyFocusMinutes = const {},
    this.projects = const [],
  });
}

class StatsNotifier extends StateNotifier<AsyncValue<StatsData>> {
  final Ref _ref;

  StatsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadStats();
  }

  String _daysAgo(int days) {
    final d = DateTime.now().subtract(Duration(days: days));
    return DateFormat('yyyy-MM-dd').format(d);
  }

  String _weekStart() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(monday);
  }

  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    try {
      final db = await _ref.read(databaseProvider).database;

      // Past 7 days captures
      final sevenDaysAgo = _daysAgo(6);
      final captureMaps = await db.query(
        'capture_items',
        where: 'created_at >= ?',
        whereArgs: [sevenDaysAgo],
      );

      final dailyCaptures = <String, int>{};
      for (var i = 0; i < 7; i++) {
        dailyCaptures[_daysAgo(6 - i)] = 0;
      }
      for (final m in captureMaps) {
        final ts = m['created_at'] as String;
        final dateKey = ts.substring(0, 10);
        dailyCaptures[dateKey] = (dailyCaptures[dateKey] ?? 0) + 1;
      }

      // This week focus stats
      final weekStart = _weekStart();
      final focusMaps = await db.query(
        'focus_sessions',
        where: 'date >= ?',
        whereArgs: [weekStart],
      );
      int totalFocusSessions = focusMaps.length;
      int totalFocusMinutes = 0;

      final dailyFocusMinutes = <String, int>{};
      for (var i = 0; i < 7; i++) {
        dailyFocusMinutes[_daysAgo(6 - i)] = 0;
      }
      for (final m in focusMaps) {
        final mins = (m['duration_minutes'] as int?) ?? 0;
        totalFocusMinutes += mins;
        final dateKey = (m['date'] as String?) ?? '';
        if (dateKey.isNotEmpty) {
          dailyFocusMinutes[dateKey] = (dailyFocusMinutes[dateKey] ?? 0) + mins;
        }
      }

      // Category / tag distribution
      final catMaps = await db.rawQuery(
        'SELECT category, COUNT(*) as cnt FROM capture_items GROUP BY category ORDER BY cnt DESC',
      );
      final categoryDistribution = <String, int>{};
      for (final m in catMaps) {
        categoryDistribution[m['category'] as String] = (m['cnt'] as int?) ?? 0;
      }

      // Project progress
      final projMaps = await db.query(
        'project_progress',
        orderBy: 'created_at DESC',
      );
      final projects = projMaps.map((m) => ProjectProgress.fromMap(m)).toList();

      state = AsyncValue.data(
        StatsData(
          dailyCaptures: dailyCaptures,
          totalFocusSessions: totalFocusSessions,
          totalFocusMinutes: totalFocusMinutes,
          categoryDistribution: categoryDistribution,
          dailyFocusMinutes: dailyFocusMinutes,
          projects: projects,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final statsProvider =
    StateNotifierProvider<StatsNotifier, AsyncValue<StatsData>>((ref) {
      return StatsNotifier(ref);
    });
