import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:el_race/core/utils/shared_pref.dart';

import '../data/todo_list_model.dart';
import '../data/todo_model.dart';
import '../data/task_member_model.dart';

/// Firebase Service for Task Management
/// All CRUD operations are done through Firebase Firestore
/// Only members are fetched from backend API
class TodoFirebaseService {
  static TodoFirebaseService? _instance;
  static TodoFirebaseService get instance =>
      _instance ??= TodoFirebaseService._();

  TodoFirebaseService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID - fallback to firebase_uid from login data if Firebase Auth not signed in
  String? get _currentUid {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid != null) return firebaseUid;
    // Fallback: use firebase_uid from backend login data
    return SharedPref.getLoginData().result?.data?.firebase_uid;
  }

  // Ensure Firebase Auth is signed in using the custom token from login data
  Future<void> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    final loginData = SharedPref.getLoginData();
    final customToken = loginData.result?.data?.firebase_custom_token;
    if (customToken != null && customToken.isNotEmpty && customToken != 'false') {
      try {
        await FirebaseAuth.instance.signInWithCustomToken(customToken);
        print('✅ TodoFirebaseService: Signed in to Firebase with custom token');
      } catch (e) {
        print('⚠️ TodoFirebaseService: Could not sign in with custom token: $e');
      }
    }
  }

  // Get current user name from SharedPref
  String get _currentUserName {
    final loginData = SharedPref.getLoginData();
    return loginData.result?.data?.name ?? 'Unknown';
  }

  // Get current user photo URL from SharedPref
  String? get _currentUserPhoto {
    return SharedPref.preferences.getUserBase64Image();
  }

  // Collection references
  CollectionReference<Map<String, dynamic>> get _todosCollection =>
      _firestore.collection('todos');

  CollectionReference<Map<String, dynamic>> get _todoListsCollection =>
      _firestore.collection('todoLists');

  // User-specific todos path
  CollectionReference<Map<String, dynamic>> _userTodosCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('todos');

  CollectionReference<Map<String, dynamic>> _userTodoListsCollection(
          String uid) =>
      _firestore.collection('users').doc(uid).collection('todoLists');

  // ==================== TODO OPERATIONS ====================

  /// Insert a new todo
  Future<String> insertTodo(TodoModel todo) async {
    await _ensureSignedIn();
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final docRef = await _userTodosCollection(uid).add(todo.toFirestore());
      print('✅ TodoFirebaseService: Created todo ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ TodoFirebaseService: Error creating todo: $e');
      rethrow;
    }
  }

  /// Update an existing todo
  Future<void> updateTodo(TodoModel todo) async {
    await _ensureSignedIn();
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');
    if (todo.firebaseId == null) throw Exception('Todo has no Firebase ID');

    try {
      await _userTodosCollection(uid)
          .doc(todo.firebaseId)
          .update(todo.toFirestore());
      print('✅ TodoFirebaseService: Updated todo ${todo.firebaseId}');
    } catch (e) {
      print('❌ TodoFirebaseService: Error updating todo: $e');
      rethrow;
    }
  }

  /// Delete a todo
  Future<void> deleteTodo(String todoId) async {
    await _ensureSignedIn();
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _userTodosCollection(uid).doc(todoId).delete();
      print('✅ TodoFirebaseService: Deleted todo $todoId');
    } catch (e) {
      print('❌ TodoFirebaseService: Error deleting todo: $e');
      rethrow;
    }
  }

  /// Get todo by ID
  Future<TodoModel?> getTodoById(String todoId) async {
    await _ensureSignedIn();
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final doc = await _userTodosCollection(uid).doc(todoId).get();
      if (doc.exists) {
        return TodoModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ TodoFirebaseService: Error getting todo: $e');
      rethrow;
    }
  }

  /// Get all todos for current user
  Future<List<TodoModel>> getAllTodos() async {
    await _ensureSignedIn();
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _userTodosCollection(uid)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ TodoFirebaseService: Error getting all todos: $e');
      rethrow;
    }
  }

  /// Stream all todos for real-time updates
  Stream<List<TodoModel>> streamAllTodos() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    return _userTodosCollection(uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList());
  }

  /// Get incomplete todos
  Future<List<TodoModel>> getIncompleteTodos() async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _userTodosCollection(uid)
          .where('is_completed', isEqualTo: false)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ TodoFirebaseService: Error getting incomplete todos: $e');
      rethrow;
    }
  }

  /// Get My Day todos
  Future<List<TodoModel>> getMyDayTodos() async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _userTodosCollection(uid)
          .where('is_my_day', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ TodoFirebaseService: Error getting my day todos: $e');
      rethrow;
    }
  }

  /// Get Important todos
  Future<List<TodoModel>> getImportantTodos() async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _userTodosCollection(uid)
          .where('is_important', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ TodoFirebaseService: Error getting important todos: $e');
      rethrow;
    }
  }

  /// Get Planned todos (with due date)
  Future<List<TodoModel>> getPlannedTodos() async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _userTodosCollection(uid)
          .where('due_date', isNull: false)
          .orderBy('due_date')
          .get();

      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ TodoFirebaseService: Error getting planned todos: $e');
      rethrow;
    }
  }

  /// Get Assigned To Me todos
  Future<List<TodoModel>> getAssignedToMeTodos(String? assignee) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      Query<Map<String, dynamic>> query = _userTodosCollection(uid);

      if (assignee != null) {
        query = query.where('assigned_to', isEqualTo: assignee);
      } else {
        // Get todos where assigned_to is not null
        query = query.where('assigned_to', isNull: false);
      }

      final snapshot = await query.orderBy('created_at', descending: true).get();

      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ TodoFirebaseService: Error getting assigned todos: $e');
      rethrow;
    }
  }

  /// Get todos by list ID
  Future<List<TodoModel>> getTodosByListId(String listId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _userTodosCollection(uid)
          .where('list_id', isEqualTo: listId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ TodoFirebaseService: Error getting todos by list: $e');
      rethrow;
    }
  }

  /// Get todos by report ID
  Future<List<TodoModel>> getTodosByReportId(String reportId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _userTodosCollection(uid)
          .where('report_id', isEqualTo: reportId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ TodoFirebaseService: Error getting todos by report: $e');
      rethrow;
    }
  }

  /// Get tasks count by report ID
  Future<int> getTasksCountByReportId(String reportId) async {
    final todos = await getTodosByReportId(reportId);
    return todos.length;
  }

  /// Search todos
  Future<List<TodoModel>> searchTodos(String query) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      // Firestore doesn't support full-text search natively
      // We'll get all todos and filter locally
      final allTodos = await getAllTodos();
      final queryLower = query.toLowerCase();

      return allTodos
          .where((todo) =>
              todo.title.toLowerCase().contains(queryLower) ||
              (todo.description?.toLowerCase().contains(queryLower) ?? false))
          .toList();
    } catch (e) {
      print('❌ TodoFirebaseService: Error searching todos: $e');
      rethrow;
    }
  }

  /// Toggle todo complete status
  Future<void> toggleTodoComplete(String todoId, bool isCompleted) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _userTodosCollection(uid).doc(todoId).update({
        'is_completed': isCompleted,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ TodoFirebaseService: Error toggling complete: $e');
      rethrow;
    }
  }

  /// Toggle todo important status
  Future<void> toggleTodoImportant(String todoId, bool isImportant) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _userTodosCollection(uid).doc(todoId).update({
        'is_important': isImportant,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ TodoFirebaseService: Error toggling important: $e');
      rethrow;
    }
  }

  /// Toggle todo my day status
  Future<void> toggleTodoMyDay(String todoId, bool isMyDay) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _userTodosCollection(uid).doc(todoId).update({
        'is_my_day': isMyDay,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ TodoFirebaseService: Error toggling my day: $e');
      rethrow;
    }
  }

  /// Update todo order
  Future<void> updateTodoOrder(List<TodoModel> todos) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final batch = _firestore.batch();

      for (int i = 0; i < todos.length; i++) {
        if (todos[i].firebaseId != null) {
          final docRef = _userTodosCollection(uid).doc(todos[i].firebaseId);
          batch.update(docRef, {
            'sort_order': i,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      print('❌ TodoFirebaseService: Error updating order: $e');
      rethrow;
    }
  }

  // ==================== COUNTS ====================

  Future<int> getTodosCount() async {
    final todos = await getIncompleteTodos();
    return todos.length;
  }

  Future<int> getMyDayCount() async {
    final uid = _currentUid;
    if (uid == null) return 0;

    try {
      final snapshot = await _userTodosCollection(uid)
          .where('is_my_day', isEqualTo: true)
          .where('is_completed', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getImportantCount() async {
    final uid = _currentUid;
    if (uid == null) return 0;

    try {
      final snapshot = await _userTodosCollection(uid)
          .where('is_important', isEqualTo: true)
          .where('is_completed', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getPlannedCount() async {
    final uid = _currentUid;
    if (uid == null) return 0;

    try {
      final snapshot = await _userTodosCollection(uid)
          .where('due_date', isNull: false)
          .where('is_completed', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Reset My Day at midnight
  Future<void> resetMyDay() async {
    final uid = _currentUid;
    if (uid == null) return;

    try {
      final snapshot = await _userTodosCollection(uid)
          .where('is_my_day', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'is_my_day': false,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('❌ TodoFirebaseService: Error resetting my day: $e');
    }
  }

  // ==================== TODO LIST OPERATIONS ====================

  /// Insert a new todo list
  Future<String> insertTodoList(TodoListModel list) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final docRef =
          await _userTodoListsCollection(uid).add(list.toFirestore());
      print('✅ TodoFirebaseService: Created list ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ TodoFirebaseService: Error creating list: $e');
      rethrow;
    }
  }

  /// Update a todo list
  Future<void> updateTodoList(TodoListModel list) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');
    if (list.firebaseId == null) throw Exception('List has no Firebase ID');

    try {
      await _userTodoListsCollection(uid)
          .doc(list.firebaseId)
          .update(list.toFirestore());
    } catch (e) {
      print('❌ TodoFirebaseService: Error updating list: $e');
      rethrow;
    }
  }

  /// Delete a todo list
  Future<void> deleteTodoList(String listId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      // First update all todos in this list to have no list
      final todosInList = await getTodosByListId(listId);
      final batch = _firestore.batch();

      for (final todo in todosInList) {
        if (todo.firebaseId != null) {
          batch.update(_userTodosCollection(uid).doc(todo.firebaseId), {
            'list_id': null,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }

      // Delete the list
      batch.delete(_userTodoListsCollection(uid).doc(listId));

      await batch.commit();
      print('✅ TodoFirebaseService: Deleted list $listId');
    } catch (e) {
      print('❌ TodoFirebaseService: Error deleting list: $e');
      rethrow;
    }
  }

  /// Get all todo lists
  Future<List<TodoListModel>> getAllTodoLists() async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _userTodoListsCollection(uid)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TodoListModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ TodoFirebaseService: Error getting lists: $e');
      rethrow;
    }
  }

  /// Stream all todo lists
  Stream<List<TodoListModel>> streamAllTodoLists() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    return _userTodoListsCollection(uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TodoListModel.fromFirestore(doc))
            .toList());
  }

  /// Get todo list by ID
  Future<TodoListModel?> getTodoListById(String listId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final doc = await _userTodoListsCollection(uid).doc(listId).get();
      if (doc.exists) {
        return TodoListModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ TodoFirebaseService: Error getting list: $e');
      rethrow;
    }
  }

  /// Get todo count by list ID
  Future<int> getTodoCountByListId(String listId) async {
    final todos = await getTodosByListId(listId);
    return todos.where((t) => !t.isCompleted).length;
  }

  // ==================== COMMENTS OPERATIONS ====================

  /// Get comments collection for a todo
  CollectionReference<Map<String, dynamic>> _todoCommentsCollection(String uid, String todoId) =>
      _userTodosCollection(uid).doc(todoId).collection('comments');

  /// Add a comment to a todo
  Future<String> addComment(String todoId, String content) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final commentData = {
        'author_name': _currentUserName,
        'author_id': uid,
        'author_photo': _currentUserPhoto,
        'content': content,
        'type': 'text',
        'created_at': FieldValue.serverTimestamp(),
      };
      
      final docRef = await _todoCommentsCollection(uid, todoId).add(commentData);
      print('✅ TodoFirebaseService: Added comment ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ TodoFirebaseService: Error adding comment: $e');
      rethrow;
    }
  }

  /// Add a voice comment to a todo
  Future<String> addVoiceComment(String todoId, String audioUrl, String duration) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final commentData = {
        'author_name': _currentUserName,
        'author_id': uid,
        'author_photo': _currentUserPhoto,
        'content': '🎤 Voice comment ($duration)',
        'audio_url': audioUrl,
        'duration': duration,
        'type': 'voice',
        'created_at': FieldValue.serverTimestamp(),
      };
      
      final docRef = await _todoCommentsCollection(uid, todoId).add(commentData);
      print('✅ TodoFirebaseService: Added voice comment ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ TodoFirebaseService: Error adding voice comment: $e');
      rethrow;
    }
  }

  /// Get comments for a todo
  Future<List<Map<String, dynamic>>> getComments(String todoId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _todoCommentsCollection(uid, todoId)
          .orderBy('created_at', descending: false)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ TodoFirebaseService: Error getting comments: $e');
      rethrow;
    }
  }

  /// Stream comments for a todo
  Stream<List<Map<String, dynamic>>> streamComments(String todoId) {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    return _todoCommentsCollection(uid, todoId)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  /// Delete a comment
  Future<void> deleteComment(String todoId, String commentId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _todoCommentsCollection(uid, todoId).doc(commentId).delete();
      print('✅ TodoFirebaseService: Deleted comment $commentId');
    } catch (e) {
      print('❌ TodoFirebaseService: Error deleting comment: $e');
      rethrow;
    }
  }

  // ==================== MEMBER OPERATIONS ====================

  /// Update member completion status by name
  Future<void> updateMemberStatus(
    String todoId, 
    String memberName, 
    bool isCompleted, 
    {required bool isAssigned}
  ) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      final todo = await getTodoById(todoId);
      if (todo == null) throw Exception('Todo not found');

      if (isAssigned) {
        // Update assigned members
        if (todo.assignedMembers == null || todo.assignedMembers!.isEmpty) {
          throw Exception('No assigned members found');
        }

        final memberIndex = todo.assignedMembers!.indexWhere((m) => m.name == memberName);
        if (memberIndex == -1) throw Exception('Member not found');

        final updatedMembers = List<TaskMember>.from(todo.assignedMembers!);
        updatedMembers[memberIndex] = updatedMembers[memberIndex].copyWith(
          isCompleted: isCompleted,
          completedAt: isCompleted ? DateTime.now() : null,
        );

        // Check if all assigned members completed - mark task as complete
        final allCompleted = updatedMembers.every((m) => m.isCompleted);

        await _userTodosCollection(uid).doc(todoId).update({
          'assigned_members': updatedMembers.map((m) => m.toMap()).toList(),
          'is_completed': allCompleted,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Update followed by members
        if (todo.followedUpBy == null || todo.followedUpBy!.isEmpty) {
          throw Exception('No followers found');
        }

        final memberIndex = todo.followedUpBy!.indexWhere((m) => m.name == memberName);
        if (memberIndex == -1) throw Exception('Follower not found');

        final updatedFollowers = List<TaskMember>.from(todo.followedUpBy!);
        updatedFollowers[memberIndex] = updatedFollowers[memberIndex].copyWith(
          isCompleted: isCompleted,
          completedAt: isCompleted ? DateTime.now() : null,
        );

        await _userTodosCollection(uid).doc(todoId).update({
          'followed_up_by': updatedFollowers.map((m) => m.toMap()).toList(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      print('✅ TodoFirebaseService: Updated member status');
    } catch (e) {
      print('❌ TodoFirebaseService: Error updating member status: $e');
      rethrow;
    }
  }
}
