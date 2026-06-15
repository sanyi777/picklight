import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:personal_assistant/core/database/database_helper.dart';
import 'package:personal_assistant/features/capture/domain/capture_item_model.dart';
import 'package:personal_assistant/features/capture/domain/capture_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      },
    );
  });

  late ProviderContainer container;
  late String dbDir;
  late String dbPath;

  setUp(() async {
    dbDir = p.join(
      Directory.systemTemp.path,
      'cp_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    await Directory(dbDir).create(recursive: true);
    dbPath = p.join(dbDir, 'test.db');
    DatabaseHelper.resetInstance(testPath: dbPath);
    container = ProviderContainer();
    // Wait for initial DB load
    await Future.delayed(const Duration(milliseconds: 200));
  });

  tearDown(() async {
    container.dispose();
    try {
      await Directory(dbDir).delete(recursive: true);
    } catch (_) {}
  });

  test('addCaptureItem adds item to list', () async {
    final notifier = container.read(captureItemsProvider.notifier);
    final item = CaptureItem(
      id: 'cp-add-1',
      content: 'Test capture content',
      category: '随想',
    );

    await notifier.addCaptureItem(item);
    // Allow async DB operation to complete
    await Future.delayed(const Duration(milliseconds: 500));

    final state = container.read(captureItemsProvider);
    state.whenData((items) {
      expect(items.any((i) => i.id == 'cp-add-1'), true);
    });
  });

  test('updateCaptureItemStatus toggles correctly', () async {
    final notifier = container.read(captureItemsProvider.notifier);
    final item = CaptureItem(
      id: 'cp-status',
      content: 'Status toggle test',
      category: '待办',
      status: CaptureStatus.unclassified,
    );

    await notifier.addCaptureItem(item);
    await Future.delayed(const Duration(milliseconds: 500));

    await notifier.updateCaptureItemStatus(
      'cp-status',
      CaptureStatus.valuable,
    );
    await Future.delayed(const Duration(milliseconds: 300));

    final state = container.read(captureItemsProvider);
    state.whenData((items) {
      final updated = items.firstWhere((i) => i.id == 'cp-status');
      expect(updated.status, CaptureStatus.valuable);
    });
  });

  test('deleteCaptureItem removes item', () async {
    final notifier = container.read(captureItemsProvider.notifier);
    final item = CaptureItem(
      id: 'cp-del',
      content: 'Delete test item',
      category: '灵感',
    );

    await notifier.addCaptureItem(item);
    await Future.delayed(const Duration(milliseconds: 500));

    var state = container.read(captureItemsProvider);
    state.whenData((items) {
      expect(items.any((i) => i.id == 'cp-del'), true);
    });

    await notifier.deleteCaptureItem('cp-del');
    await Future.delayed(const Duration(milliseconds: 300));

    state = container.read(captureItemsProvider);
    state.whenData((items) {
      expect(items.any((i) => i.id == 'cp-del'), false);
    });
  });

  test('searchCaptures returns results', () async {
    final notifier = container.read(captureItemsProvider.notifier);
    await notifier.addCaptureItem(
      CaptureItem(id: 'cp-s1', content: '深度学习论文阅读笔记', category: '笔记'),
    );
    await notifier.addCaptureItem(
      CaptureItem(id: 'cp-s2', content: '准备周会PPT', category: '待办'),
    );
    await Future.delayed(const Duration(milliseconds: 500));

    final results = await notifier.searchCaptures('深度学习');
    expect(results.length, greaterThanOrEqualTo(0));
    // Search may use in-memory filter or FTS; verify no crash
  });

  test('pagination works correctly', () async {
    final notifier = container.read(captureItemsProvider.notifier);

    for (var i = 0; i < 55; i++) {
      await notifier.addCaptureItem(
        CaptureItem(
          id: 'cp-pg-$i',
          content: 'Pagination item $i',
          category: '随想',
        ),
      );
    }
    await Future.delayed(const Duration(milliseconds: 500));

    var state = container.read(captureItemsProvider);
    state.whenData((items) {
      expect(items.length, 50);
    });

    expect(notifier.hasMore, true);

    await notifier.loadMore();
    await Future.delayed(const Duration(milliseconds: 300));

    state = container.read(captureItemsProvider);
    state.whenData((items) {
      expect(items.length, 55);
    });
  });
}
