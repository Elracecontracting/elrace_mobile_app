class TodoModel {
  final int? id;
  final String title;
  final String? description;
  final bool isCompleted;
  final bool isImportant;
  final bool isMyDay;
  final DateTime? dueDate;
  final String? assignedTo;
  final int? listId;
  final String? reportId; // Reference to Report
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TodoModel({
    this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.isImportant = false,
    this.isMyDay = false,
    this.dueDate,
    this.assignedTo,
    this.listId,
    this.reportId,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: (map['is_completed'] as int?) == 1,
      isImportant: (map['is_important'] as int?) == 1,
      isMyDay: (map['is_my_day'] as int?) == 1,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      assignedTo: map['assigned_to'] as String?,
      listId: map['list_id'] as int?,
      reportId: map['report_id'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted ? 1 : 0,
      'is_important': isImportant ? 1 : 0,
      'is_my_day': isMyDay ? 1 : 0,
      'due_date': dueDate?.toIso8601String(),
      'assigned_to': assignedTo,
      'list_id': listId,
      'report_id': reportId,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TodoModel copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    bool? isImportant,
    bool? isMyDay,
    DateTime? dueDate,
    String? assignedTo,
    int? listId,
    String? reportId,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      isMyDay: isMyDay ?? this.isMyDay,
      dueDate: dueDate ?? this.dueDate,
      assignedTo: assignedTo ?? this.assignedTo,
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
      title: title,
      description: description,
      isCompleted: isCompleted,
      isImportant: isImportant,
      isMyDay: isMyDay,
      dueDate: null,
      assignedTo: assignedTo,
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
    return other is TodoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
