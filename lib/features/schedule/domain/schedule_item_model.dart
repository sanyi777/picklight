import 'package:uuid/uuid.dart';

class ScheduleItem {
  final String id;
  final String date;
  final String title;
  final String? timeSlot;
  final bool isCompleted;
  final String createdAt;
  final String updatedAt;

  ScheduleItem({
    String? id,
    required this.date,
    required this.title,
    this.timeSlot,
    this.isCompleted = false,
    String? createdAt,
    String? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id'] as String,
      date: map['date'] as String,
      title: map['title'] as String,
      timeSlot: map['time_slot'] as String?,
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'time_slot': timeSlot,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  ScheduleItem copyWith({
    String? id,
    String? date,
    String? title,
    String? timeSlot,
    bool? isCompleted,
    String? createdAt,
    String? updatedAt,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      timeSlot: timeSlot ?? this.timeSlot,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }
}
