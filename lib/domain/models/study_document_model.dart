import 'package:cloud_firestore/cloud_firestore.dart';

class StudyDocumentModel {
  final String id;
  final String topicId; // e.g. 'apostila', 'biblioteca'
  final String title;
  final String fileUrl;
  final DateTime createdAt;
  final String authorId;

  StudyDocumentModel({
    required this.id,
    required this.topicId,
    required this.title,
    required this.fileUrl,
    required this.createdAt,
    required this.authorId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topicId': topicId,
      'title': title,
      'fileUrl': fileUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'authorId': authorId,
    };
  }

  factory StudyDocumentModel.fromMap(Map<String, dynamic> map, String docId) {
    return StudyDocumentModel(
      id: docId,
      topicId: map['topicId'] ?? '',
      title: map['title'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      authorId: map['authorId'] ?? '',
    );
  }
}
