import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String authorId;
  final bool isImportant;
  final DateTime? validUntil;
  final String tenantId;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.authorId,
    this.isImportant = false,
    this.validUntil,
    required this.tenantId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'authorId': authorId,
      'isImportant': isImportant,
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
      'tenantId': tenantId,
    };
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String docId) {
    return AnnouncementModel(
      id: docId,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      authorId: map['authorId'] ?? '',
      isImportant: map['isImportant'] ?? false,
      validUntil: (map['validUntil'] as Timestamp?)?.toDate(),
      tenantId: map['tenantId'] ?? '',
    );
  }

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    String? authorId,
    bool? isImportant,
    DateTime? validUntil,
    String? tenantId,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      authorId: authorId ?? this.authorId,
      isImportant: isImportant ?? this.isImportant,
      validUntil: validUntil ?? this.validUntil,
      tenantId: tenantId ?? this.tenantId,
    );
  }
}
