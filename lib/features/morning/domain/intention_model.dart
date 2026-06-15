import 'package:uuid/uuid.dart';

class Intention {
  final String id;
  final String date;
  final String? highlight;
  final String? intentionText;
  final bool isCompleted;
  final String createdAt;
  final String updatedAt;

  Intention({
    String? id,
    required this.date,
    this.highlight,
    this.intentionText,
    this.isCompleted = false,
    String? createdAt,
    String? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  factory Intention.fromMap(Map<String, dynamic> map) {
    return Intention(
      id: map['id'] as String,
      date: map['date'] as String,
      highlight: map['highlight'] as String?,
      intentionText: map['intention_text'] as String?,
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'highlight': highlight,
      'intention_text': intentionText,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Intention copyWith({
    String? id,
    String? date,
    String? highlight,
    String? intentionText,
    bool? isCompleted,
    String? createdAt,
    String? updatedAt,
  }) {
    return Intention(
      id: id ?? this.id,
      date: date ?? this.date,
      highlight: highlight ?? this.highlight,
      intentionText: intentionText ?? this.intentionText,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }
}
