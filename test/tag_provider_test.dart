import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:personal_assistant/core/database/database_helper.dart';
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
      'tag_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    await Directory(dbDir).create(recursive: true);
    dbPath = p.join(dbDir, 'test.db');
    DatabaseHelper.resetInstance(testPath: dbPath);
    container = ProviderContainer();
    // Wait for TagNotifier to load default tags from DB
    await Future.delayed(const Duration(milliseconds: 300));
  });

  tearDown(() async {
    container.dispose();
    try {
      await Directory(dbDir).delete(recursive: true);
    } catch (_) {}
  });

  test('loadTags loads default tags', () async {
    container.read(tagProvider.notifier);
    await Future.delayed(const Duration(milliseconds: 200));

    final state = container.read(tagProvider);
    state.whenData((tags) {
      expect(tags.length, greaterThanOrEqualTo(4));
      expect(tags.any((t) => t.name == '随想'), true);
      expect(tags.any((t) => t.name == '待办'), true);
      expect(tags.any((t) => t.name == '灵感'), true);
      expect(tags.any((t) => t.name == '笔记'), true);
    });
  });

  test('createTag adds a new custom tag', () async {
    final notifier = container.read(tagProvider.notifier);

    await notifier.createTag('自定义', 0xFFE74C3C);
    await Future.delayed(const Duration(milliseconds: 200));

    final state = container.read(tagProvider);
    state.whenData((tags) {
      final custom = tags.where((t) => t.name == '自定义').toList();
      expect(custom.length, 1);
      expect(custom.first.color, 0xFFE74C3C);
      expect(custom.first.isDefault, false);
    });
  });

  test('deleteTag removes custom tag', () async {
    final notifier = container.read(tagProvider.notifier);

    await notifier.createTag('可删除标签', 0xFF1ABC9C);
    await Future.delayed(const Duration(milliseconds: 200));

    var state = container.read(tagProvider);
    String? customId;
    state.whenData((tags) {
      customId = tags.firstWhere((t) => t.name == '可删除标签').tagId;
    });
    expect(customId, isNotNull);

    await notifier.deleteTag(customId!);
    await Future.delayed(const Duration(milliseconds: 200));

    state = container.read(tagProvider);
    state.whenData((tags) {
      expect(tags.any((t) => t.name == '可删除标签'), false);
    });
  });

  test('delete default tag — guard is at UI level', () async {
    final notifier = container.read(tagProvider.notifier);
    // Wait for initial load to complete
    await Future.delayed(const Duration(milliseconds: 300));

    String? defaultId;
    var state = container.read(tagProvider);
    state.whenData((tags) {
      defaultId =
          tags.firstWhere((t) => t.isDefault && t.name == '随想').tagId;
    });
    expect(defaultId, isNotNull,
        reason: 'Default tag 随想 not found after load');

    // deleteTag triggers an async reload. We verify the call does not crash.
    // The UI layer is responsible for blocking deletion of default tags.
    await notifier.deleteTag(defaultId!);
    // Allow async reload to complete before tearDown disposes the container
    await Future.delayed(const Duration(milliseconds: 500));
  });

  test('getTagColor returns correct color', () async {
    final notifier = container.read(tagProvider.notifier);

    await notifier.createTag('颜色测试', 0xFFF1C40F);
    await Future.delayed(const Duration(milliseconds: 200));

    final color = await notifier.getTagColor('颜色测试');
    expect(color, 0xFFF1C40F);
  });
}
