import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_provider.dart';
import 'capture_item_model.dart';

// ==================== Tag Provider ====================

class TagNotifier extends StateNotifier<AsyncValue<List<Tag>>> {
  final Ref _ref;

  TagNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadTags();
  }

  Future<void> loadTags() async {
    state = const AsyncValue.loading();
    try {
      final db = await _ref.read(databaseProvider).database;
      final maps = await db.query('tags', orderBy: 'created_at ASC');
      final tags = maps.map((m) => Tag.fromMap(m)).toList();
      state = AsyncValue.data(tags);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createTag(String name, int color) async {
    final db = await _ref.read(databaseProvider).database;
    final tagId = 'tag_${const Uuid().v4()}';
    await db.insert('tags', {
      'tag_id': tagId,
      'name': name,
      'color': color,
      'created_at': DateTime.now().toIso8601String(),
    });
    await loadTags();
  }

  Future<void> deleteTag(String tagId) async {
    final db = await _ref.read(databaseProvider).database;
    await db.delete('tags', where: 'tag_id = ?', whereArgs: [tagId]);
    await loadTags();
  }

  /// Look up tag color by name.
  Future<int?> getTagColor(String name) async {
    final db = await _ref.read(databaseProvider).database;
    final result = await db.query(
      'tags',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['color'] as int?;
    }
    return null;
  }
}

final tagProvider = StateNotifierProvider<TagNotifier, AsyncValue<List<Tag>>>((
  ref,
) {
  return TagNotifier(ref);
});

// ==================== Capture Provider ====================

class CaptureNotifier extends StateNotifier<AsyncValue<List<CaptureItem>>> {
  final Ref _ref;
  static const int _pageSize = 50;
  int _offset = 0;
  bool _hasMore = true;

  CaptureNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadItems();
  }

  /// Resolves tag colors for a list of capture items.
  Future<List<CaptureItem>> _resolveTagColors(List<CaptureItem> items) async {
    final db = await _ref.read(databaseProvider).database;
    final tagMaps = await db.query('tags');
    final colorMap = <String, int>{};
    for (final t in tagMaps) {
      colorMap[t['name'] as String] = t['color'] as int;
    }
    return items.map((item) {
      final c = colorMap[item.category];
      return c != null ? item.copyWith(tagColor: c) : item;
    }).toList();
  }

  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    try {
      final db = await _ref.read(databaseProvider).database;
      final maps = await db.query(
        'capture_items',
        orderBy: 'created_at DESC',
        limit: _pageSize,
      );
      _offset = maps.length;
      _hasMore = maps.length >= _pageSize;
      final items = maps.map((m) => CaptureItem.fromMap(m)).toList();
      final resolved = await _resolveTagColors(items);
      state = AsyncValue.data(resolved);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Phase 5: load more items (pagination)
  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? [];
    try {
      final db = await _ref.read(databaseProvider).database;
      final maps = await db.query(
        'capture_items',
        orderBy: 'created_at DESC',
        limit: _pageSize,
        offset: _offset,
      );
      if (maps.isEmpty) {
        _hasMore = false;
        return;
      }
      _offset += maps.length;
      _hasMore = maps.length >= _pageSize;
      final newItems = maps.map((m) => CaptureItem.fromMap(m)).toList();
      final resolved = await _resolveTagColors(newItems);
      state = AsyncValue.data([...current, ...resolved]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool get hasMore => _hasMore;

  Future<void> addCaptureItem(CaptureItem item) async {
    final db = await _ref.read(databaseProvider).database;
    await db.insert(
      'capture_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await loadItems();
  }

  Future<void> updateCaptureItemStatus(String id, CaptureStatus status) async {
    final db = await _ref.read(databaseProvider).database;
    await db.update(
      'capture_items',
      {'status': status.name, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadItems();
  }

  Future<void> deleteCaptureItem(String id) async {
    final db = await _ref.read(databaseProvider).database;
    await db.delete('capture_items', where: 'id = ?', whereArgs: [id]);
    await loadItems();
  }

  Future<void> updateCaptureItem(CaptureItem item) async {
    final db = await _ref.read(databaseProvider).database;
    await db.update(
      'capture_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    await loadItems();
  }

  Future<List<CaptureItem>> searchCaptures(String query) async {
    if (query.trim().isEmpty) {
      await loadItems();
      return state.valueOrNull ?? [];
    }
    try {
      final dbHelper = _ref.read(databaseProvider);
      final maps = await dbHelper.searchCapturesFts(query);
      if (maps.isEmpty) {
        return [];
      }
      final items = maps.map((m) => CaptureItem.fromMap(m)).toList();
      return await _resolveTagColors(items);
    } catch (_) {
      return [];
    }
  }
}

final captureItemsProvider =
    StateNotifierProvider<CaptureNotifier, AsyncValue<List<CaptureItem>>>((
      ref,
    ) {
      return CaptureNotifier(ref);
    });

final captureItemByStatusProvider = FutureProvider.family
    .autoDispose<List<CaptureItem>, CaptureStatus>((ref, status) async {
      final db = await ref.read(databaseProvider).database;
      final maps = await db.query(
        'capture_items',
        where: 'status = ?',
        whereArgs: [status.name],
        orderBy: 'created_at DESC',
        limit: 50,
      );
      return maps.map((m) => CaptureItem.fromMap(m)).toList();
    });
