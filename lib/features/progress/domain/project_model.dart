import 'package:uuid/uuid.dart';

class ProjectProgress {
  final String projectId;
  final String title;
  final String? description;
  final int totalUnits;
  final int completedUnits;
  final String unitLabel;
  final String status;
  final String? startDate;
  final String? targetDate;
  final String createdAt;
  final String updatedAt;

  ProjectProgress({
    String? projectId,
    required this.title,
    this.description,
    this.totalUnits = 1,
    this.completedUnits = 0,
    this.unitLabel = '章',
    this.status = 'active',
    this.startDate,
    this.targetDate,
    String? createdAt,
    String? updatedAt,
  }) : projectId = projectId ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  factory ProjectProgress.fromMap(Map<String, dynamic> map) {
    return ProjectProgress(
      projectId: map['project_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      totalUnits: (map['total_units'] as int?) ?? 1,
      completedUnits: (map['completed_units'] as int?) ?? 0,
      unitLabel: (map['unit_label'] as String?) ?? '章',
      status: (map['status'] as String?) ?? 'active',
      startDate: map['start_date'] as String?,
      targetDate: map['target_date'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'project_id': projectId,
      'title': title,
      'description': description,
      'total_units': totalUnits,
      'completed_units': completedUnits,
      'unit_label': unitLabel,
      'status': status,
      'start_date': startDate,
      'target_date': targetDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  ProjectProgress copyWith({
    String? projectId,
    String? title,
    String? description,
    int? totalUnits,
    int? completedUnits,
    String? unitLabel,
    String? status,
    String? startDate,
    String? targetDate,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProjectProgress(
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      totalUnits: totalUnits ?? this.totalUnits,
      completedUnits: completedUnits ?? this.completedUnits,
      unitLabel: unitLabel ?? this.unitLabel,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  double get progress =>
      totalUnits > 0 ? (completedUnits / totalUnits).clamp(0.0, 1.0) : 0.0;
}
