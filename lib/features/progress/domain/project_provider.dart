import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import 'project_model.dart';

class ProjectNotifier extends StateNotifier<AsyncValue<List<ProjectProgress>>> {
  final Ref _ref;

  ProjectNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    state = const AsyncValue.loading();
    try {
      final db = await _ref.read(databaseProvider).database;
      final maps = await db.query(
        'project_progress',
        orderBy: 'created_at DESC',
      );
      final projects = maps.map((m) => ProjectProgress.fromMap(m)).toList();
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProject(ProjectProgress project) async {
    final db = await _ref.read(databaseProvider).database;
    await db.insert(
      'project_progress',
      project.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await loadProjects();
  }

  Future<void> incrementProgress(String projectId) async {
    final db = await _ref.read(databaseProvider).database;
    final maps = await db.query(
      'project_progress',
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
    if (maps.isEmpty) return;

    final project = ProjectProgress.fromMap(maps.first);
    if (project.completedUnits >= project.totalUnits) return;

    final newCompleted = project.completedUnits + 1;
    await db.update(
      'project_progress',
      {
        'completed_units': newCompleted,
        'status': newCompleted >= project.totalUnits ? 'completed' : 'active',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
    await loadProjects();
  }

  Future<void> decrementProgress(String projectId) async {
    final db = await _ref.read(databaseProvider).database;
    final maps = await db.query(
      'project_progress',
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
    if (maps.isEmpty) return;

    final project = ProjectProgress.fromMap(maps.first);
    if (project.completedUnits <= 0) return;

    final newCompleted = project.completedUnits - 1;
    await db.update(
      'project_progress',
      {
        'completed_units': newCompleted,
        'status': 'active',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
    await loadProjects();
  }

  Future<void> markCompleted(String projectId) async {
    final db = await _ref.read(databaseProvider).database;
    final maps = await db.query(
      'project_progress',
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
    if (maps.isEmpty) return;

    final project = ProjectProgress.fromMap(maps.first);
    await db.update(
      'project_progress',
      {
        'completed_units': project.totalUnits,
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
    await loadProjects();
  }

  Future<void> removeProject(String projectId) async {
    final db = await _ref.read(databaseProvider).database;
    await db.delete(
      'project_progress',
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
    await loadProjects();
  }
}

final projectProgressProvider =
    StateNotifierProvider<ProjectNotifier, AsyncValue<List<ProjectProgress>>>((
      ref,
    ) {
      return ProjectNotifier(ref);
    });
