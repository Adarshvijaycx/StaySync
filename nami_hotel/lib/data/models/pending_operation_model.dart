import 'dart:convert';
import 'package:uuid/uuid.dart';

class PendingOperation {
  final String id;
  final String collectionId;
  final String operationType; // 'create', 'update', 'delete'
  final String payload; // JSON string
  final DateTime createdAt;
  final int retryCount;

  PendingOperation({
    String? id,
    required this.collectionId,
    required this.operationType,
    required this.payload,
    DateTime? createdAt,
    this.retryCount = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  PendingOperation copyWith({
    String? id,
    String? collectionId,
    String? operationType,
    String? payload,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return PendingOperation(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      operationType: operationType ?? this.operationType,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collection_id': collectionId,
      'operation_type': operationType,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  factory PendingOperation.fromMap(Map<String, dynamic> map) {
    return PendingOperation(
      id: map['id'],
      collectionId: map['collection_id'],
      operationType: map['operation_type'],
      payload: map['payload'],
      createdAt: DateTime.parse(map['created_at']),
      retryCount: map['retry_count']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory PendingOperation.fromJson(String source) =>
      PendingOperation.fromMap(json.decode(source));
}
