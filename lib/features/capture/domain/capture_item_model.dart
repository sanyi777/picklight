import 'dart:convert';
import 'package:uuid/uuid.dart';

enum CaptureStatus {
  unclassified,
  valuable,
  pending,
  discarded;

  static CaptureStatus fromString(String value) {
    return CaptureStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CaptureStatus.unclassified,
    );
  }
}

class CaptureItem {
  final String id;
  final String content;
  final String category;
  final String sourceType;
  final Map<String, dynamic>? externalRefs;
  final CaptureStatus status;
  final String createdAt;
  final String updatedAt;

  /// Phase 5: color of the associated tag, resolved at display time.
  final int? tagColor;

  CaptureItem({
    String? id,
    required this.content,
    this.category = '随想',
    this.sourceType = 'manual',
    this.externalRefs,
    this.status = CaptureStatus.unclassified,
    String? createdAt,
    String? updatedAt,
    this.tagColor,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  factory CaptureItem.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? externalRefs;
    final externalRefsRaw = map['external_refs'] as String?;
    if (externalRefsRaw != null && externalRefsRaw.isNotEmpty) {
      try {
        externalRefs = jsonDecode(externalRefsRaw) as Map<String, dynamic>;
      } catch (_) {
        externalRefs = {};
      }
    }

    return CaptureItem(
      id: map['id'] as String,
      content: map['content'] as String,
      category: (map['category'] as String?) ?? '随想',
      sourceType: (map['source_type'] as String?) ?? 'manual',
      externalRefs: externalRefs,
      status: CaptureStatus.fromString(
        (map['status'] as String?) ?? 'unclassified',
      ),
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      tagColor: map['tag_color'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'category': category,
      'source_type': sourceType,
      'external_refs': externalRefs != null ? jsonEncode(externalRefs) : null,
      'status': status.name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  CaptureItem copyWith({
    String? id,
    String? content,
    String? category,
    String? sourceType,
    Map<String, dynamic>? externalRefs,
    CaptureStatus? status,
    String? createdAt,
    String? updatedAt,
    int? tagColor,
  }) {
    return CaptureItem(
      id: id ?? this.id,
      content: content ?? this.content,
      category: category ?? this.category,
      sourceType: sourceType ?? this.sourceType,
      externalRefs: externalRefs ?? this.externalRefs,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
      tagColor: tagColor ?? this.tagColor,
    );
  }
}

/// Phase 5: Tag model
class Tag {
  final String tagId;
  final String name;
  final int color;
  final String createdAt;

  const Tag({
    required this.tagId,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      tagId: map['tag_id'] as String,
      name: map['name'] as String,
      color: map['color'] as int,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tag_id': tagId,
      'name': name,
      'color': color,
      'created_at': createdAt,
    };
  }

  bool get isDefault => tagId.startsWith('tag_default_');
}
