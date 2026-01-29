import 'package:cloud_firestore/cloud_firestore.dart';

class TodoModel {
  final int? id; // Local SQLite ID (deprecated)
  final String? firebaseId; // Firebase document ID
  final String title;
  final String? description;
  final bool isCompleted;
  final bool isImportant;
  final bool isMyDay;
  final DateTime? dueDate;
  final String? assignedTo;
  final String? assignedToName; // Name of the assigned member
  final String? listId; // Firebase list ID (changed from int)
  final String? reportId; // Reference to Report
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TodoModel({
    this.id,
    this.firebaseId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.isImportant = false,
    this.isMyDay = false,
    this.dueDate,
    this.assignedTo,
    this.assignedToName,
    this.listId,
    this.reportId,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as int?,
      firebaseId: map['firebase_id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: (map['is_completed'] as int?) == 1,
      isImportant: (map['is_important'] as int?) == 1,
      isMyDay: (map['is_my_day'] as int?) == 1,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      assignedTo: map['assigned_to'] as String?,
      assignedToName: map['assigned_to_name'] as String?,
      listId: map['list_id'] as String?,
      reportId: map['report_id'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Create from Firestore document
  factory TodoModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TodoModel(
      firebaseId: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      isCompleted: data['is_completed'] as bool? ?? false,
      isImportant: data['is_important'] as bool? ?? false,
      isMyDay: data['is_my_day'] as bool? ?? false,
      dueDate: data['due_date'] != null
          ? (data['due_date'] as Timestamp).toDate()
          : null,
      assignedTo: data['assigned_to'] as String?,
      assignedToName: data['assigned_to_name'] as String?,
      listId: data['list_id'] as String?,
      reportId: data['report_id'] as String?,
      sortOrder: data['sort_order'] as int? ?? 0,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (firebaseId != null) 'firebase_id': firebaseId,
      'title': title,
      'description': description,
      'is_completed': isCompleted ? 1 : 0,
      'is_important': isImportant ? 1 : 0,
      'is_my_day': isMyDay ? 1 : 0,
      'due_date': dueDate?.toIso8601String(),
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'list_id': listId,
      'report_id': reportId,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'is_important': isImportant,
      'is_my_day': isMyDay,
      'due_date': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'list_id': listId,
      'report_id': reportId,
      'sort_order': sortOrder,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  TodoModel copyWith({
    int? id,
    String? firebaseId,
    String? title,
    String? description,
    bool? isCompleted,
    bool? isImportant,
    bool? isMyDay,
    DateTime? dueDate,
    String? assignedTo,
    String? assignedToName,
    String? listId,
    String? reportId,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoModel(
      id: id ?? this.id,
      firebaseId: firebaseId ?? this.firebaseId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      isMyDay: isMyDay ?? this.isMyDay,
      dueDate: dueDate ?? this.dueDate,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      listId: listId ?? this.listId,
      reportId: reportId ?? this.reportId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create a new todo with cleared optional fields
  TodoModel clearDueDate() {
    return TodoModel(
      id: id,
      firebaseId: firebaseId,
      title: title,
      description: description,
      isCompleted: isCompleted,
      isImportant: isImportant,
      isMyDay: isMyDay,
      dueDate: null,
      assignedTo: assignedTo,
      assignedToName: assignedToName,
      listId: listId,
      reportId: reportId,
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TodoModel &&
        (other.firebaseId == firebaseId || other.id == id);
  }

  @override
  int get hashCode => firebaseId?.hashCode ?? id.hashCode;
}
