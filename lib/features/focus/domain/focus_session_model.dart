import 'dart:convert';
import 'package:uuid/uuid.dart';

class FocusSession {
  final String id;
  final String date;
  final String? startTime;
  final String? endTime;
  final int? durationMinutes;
  final String type;
  final List<String> brainDumpItems;
  final bool completed;
  final String createdAt;

  FocusSession({
    String? id,
    required this.date,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.type = 'pomodoro',
    List<String>? brainDumpItems,
    this.completed = false,
    String? createdAt,
  }) : id = id ?? const Uuid().v4(),
       brainDumpItems = brainDumpItems ?? [],
       createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    List<String> brainDumpItems = [];
    final brainDumpRaw = map['brain_dump_items'] as String?;
    if (brainDumpRaw != null && brainDumpRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(brainDumpRaw);
        if (decoded is List) {
          brainDumpItems = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return FocusSession(
      id: map['id'] as String,
      date: map['date'] as String,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      durationMinutes: map['duration_minutes'] as int?,
      type: (map['type'] as String?) ?? 'pomodoro',
      brainDumpItems: brainDumpItems,
      completed: (map['completed'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'duration_minutes': durationMinutes,
      'type': type,
      'brain_dump_items': brainDumpItems.isNotEmpty
          ? jsonEncode(brainDumpItems)
          : null,
      'completed': completed ? 1 : 0,
      'created_at': createdAt,
    };
  }

  FocusSession copyWith({
    String? id,
    String? date,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    String? type,
    List<String>? brainDumpItems,
    bool? completed,
    String? createdAt,
  }) {
    return FocusSession(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      brainDumpItems: brainDumpItems ?? this.brainDumpItems,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
