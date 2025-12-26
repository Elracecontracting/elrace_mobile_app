# نظام المهام - Tasks System

## توثيق شامل ومفصل

---

## 📋 نظرة عامة (Overview)

نظام المهام في تطبيق El Race يتكون من نظامين منفصلين:

1. **TODO System** - نظام المهام الشخصية (Microsoft To-Do Style)
2. **Task Sheet System** - نظام مهام العمل الميدانية

كل نظام له استخداماته وميزاته الخاصة.

---

## 🔷 الجزء الأول: TODO System (المهام الشخصية)

### نظرة عامة

نظام مهام شخصي مستوحى من Microsoft To-Do، يتيح للمستخدم إنشاء قوائم مهام، تصنيفها، وتتبعها.

### الموقع في المشروع

```
lib/ui/presentation/todo_list/
├── data/
│   ├── todo_model.dart           # نموذج المهمة
│   └── todo_list_model.dart      # نموذج القائمة
├── providers/
│   └── todo_provider.dart        # إدارة الحالة
├── services/
│   └── todo_database_service.dart # خدمة قاعدة البيانات
├── screens/
│   ├── todo_list_screen.dart     # الشاشة الرئيسية
│   ├── todo_category_screen.dart # شاشة الفئة
│   └── todo_search_screen.dart   # شاشة البحث
└── widgets/
    ├── add_todo_bottom_sheet.dart # إضافة/تعديل مهمة
    ├── todo_item_widget.dart      # عنصر المهمة
    └── add_list_dialog.dart       # إضافة قائمة
```

---

## 📦 نماذج البيانات (Data Models)

### 1. TodoModel

```dart
class TodoModel {
  final int? id;                    // معرف فريد
  final String title;               // عنوان المهمة (إجباري)
  final String? description;        // وصف تفصيلي
  final bool isCompleted;           // هل اكتملت؟
  final bool isImportant;           // هل مهمة؟
  final bool isMyDay;               // في "يومي"؟
  final DateTime? dueDate;          // تاريخ الاستحقاق
  final String? assignedTo;         // مسندة إلى (للمستقبل)
  final int? listId;                // معرف القائمة
  final int sortOrder;              // ترتيب العرض
  final DateTime createdAt;         // تاريخ الإنشاء
  final DateTime updatedAt;         // آخر تحديث
}
```

**الحقول الرئيسية:**

- `title`: العنوان الوحيد الإجباري
- `isCompleted`: `false` افتراضياً
- `isImportant`: للمهام ذات الأولوية
- `isMyDay`: لمهام اليوم الحالي
- `sortOrder`: للترتيب بالسحب والإفلات

**الدوال المساعدة:**

```dart
TodoModel copyWith({...})          // نسخ مع تعديلات
TodoModel clearDueDate()           // إزالة تاريخ الاستحقاق
TodoModel clearDescription()       // إزالة الوصف
Map<String, dynamic> toMap()       // للتخزين في SQLite
factory TodoModel.fromMap(...)     // للقراءة من SQLite
```

---

### 2. TodoListModel

```dart
class TodoListModel {
  final int? id;                    // معرف فريد
  final String name;                // اسم القائمة
  final String? iconName;           // اسم الأيقونة
  final String? color;              // لون القائمة (Hex)
  final int sortOrder;              // الترتيب
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**أمثلة على القوائم:**

- "قائمة المشتريات" - icon: `shopping_cart` - color: `#FF5722`
- "مهام العمل" - icon: `work` - color: `#2196F3`
- "أهداف شخصية" - icon: `flag` - color: `#4CAF50`

---

## 🗂️ الفئات المدمجة (Built-in Filters)

```dart
enum TodoFilter {
  all,            // جميع المهام
  myDay,          // مهام اليوم
  important,      // المهمة
  planned,        // المخططة (لها due date)
  assignedToMe,   // المسندة إلي
  tasks,          // المهام فقط (بدون completed)
  customList,     // قائمة مخصصة
}
```

### استخدام الفئات:

- **My Day (يومي):** مهام مميزة بـ `isMyDay = true`
- **Important (المهم):** مهام مميزة بـ `isImportant = true`
- **Planned (المخطط):** مهام لها `dueDate`
- **Tasks (المهام):** جميع المهام غير المكتملة

---

## 💾 قاعدة البيانات (SQLite Database)

### TodoDatabaseService

**الموقع:** `lib/ui/presentation/todo_list/services/todo_database_service.dart`

### بنية الجداول

#### جدول `todo_lists`

```sql
CREATE TABLE todo_lists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  icon_name TEXT,
  color TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

#### جدول `todos`

```sql
CREATE TABLE todos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  is_completed INTEGER DEFAULT 0,      -- 0 or 1
  is_important INTEGER DEFAULT 0,      -- 0 or 1
  is_my_day INTEGER DEFAULT 0,         -- 0 or 1
  due_date TEXT,                       -- ISO8601 format
  assigned_to TEXT,
  list_id INTEGER,                     -- Foreign key
  sort_order INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (list_id) REFERENCES todo_lists (id) ON DELETE SET NULL
)
```

#### الفهارس (Indexes)

```sql
CREATE INDEX idx_todos_is_completed ON todos(is_completed);
CREATE INDEX idx_todos_is_important ON todos(is_important);
CREATE INDEX idx_todos_is_my_day ON todos(is_my_day);
CREATE INDEX idx_todos_due_date ON todos(due_date);
CREATE INDEX idx_todos_list_id ON todos(list_id);
```

**الغرض:** تسريع الاستعلامات عند الفلترة

---

## 🔄 مزود الحالة (TodoProvider)

**الموقع:** `lib/ui/presentation/todo_list/providers/todo_provider.dart`

### المتغيرات الرئيسية

```dart
class TodoProvider extends ChangeNotifier {
  final TodoDatabaseService _dbService = TodoDatabaseService();

  List<TodoModel> _todos = [];              // جميع المهام
  List<TodoModel> _filteredTodos = [];      // المهام المفلترة
  List<TodoListModel> _todoLists = [];      // القوائم المخصصة

  TodoFilter _currentFilter = TodoFilter.all;
  int? _currentListId;                      // القائمة الحالية
  String _searchQuery = '';
  bool _isLoading = false;

  // العدادات
  int _totalCount = 0;
  int _myDayCount = 0;
  int _importantCount = 0;
  int _plannedCount = 0;
}
```

---

### الوظائف الرئيسية

#### 1. التهيئة والتحديث

```dart
Future<void> initialize() async
```

- يجلب جميع المهام والقوائم
- يحسب العدادات
- ينادى عند فتح التطبيق

```dart
Future<void> refreshCounts() async
```

- يحدث عدادات الفئات
- ينادى بعد كل عملية CRUD

---

#### 2. إدارة المهام (CRUD Operations)

**إضافة مهمة:**

```dart
Future<TodoModel?> addTodo({
  required String title,
  String? description,
  bool isImportant = false,
  bool isMyDay = false,
  DateTime? dueDate,
  String? assignedTo,
  int? listId,
}) async
```

- يضيف المهمة في البداية (`insert(0, ...)`)
- يعيد `TodoModel` أو `null` عند الفشل

**تحديث مهمة:**

```dart
Future<bool> updateTodo(TodoModel todo) async
```

- يحدّث في القاعدة
- يحدّث في القائمة المحلية

**حذف مهمة:**

```dart
Future<bool> deleteTodo(int id) async
```

- يحذف من القاعدة والذاكرة

**إكمال/إلغاء إكمال:**

```dart
Future<void> toggleComplete(int id) async
```

- يقلب حالة `isCompleted`

**تبديل الأهمية:**

```dart
Future<void> toggleImportant(int id) async
```

- يقلب حالة `isImportant`

**إعادة الترتيب:**

```dart
Future<void> reorderTodos(int oldIndex, int newIndex) async
```

- يحرك المهمة في القائمة
- يحدّث `sortOrder` في القاعدة

---

#### 3. الفلترة والبحث

**تطبيق فلتر:**

```dart
void setFilter(TodoFilter filter, {int? listId}) {
  _currentFilter = filter;
  _currentListId = listId;
  _applyFilter();
  notifyListeners();
}
```

**منطق الفلترة:**

```dart
void _applyFilter() {
  switch (_currentFilter) {
    case TodoFilter.myDay:
      _filteredTodos = _todos.where(
        (t) => t.isMyDay && !t.isCompleted
      ).toList();
      break;

    case TodoFilter.important:
      _filteredTodos = _todos.where(
        (t) => t.isImportant && !t.isCompleted
      ).toList();
      break;

    case TodoFilter.planned:
      _filteredTodos = _todos.where(
        (t) => t.dueDate != null && !t.isCompleted
      ).toList();
      break;

    case TodoFilter.customList:
      _filteredTodos = _todos.where(
        (t) => t.listId == _currentListId && !t.isCompleted
      ).toList();
      break;

    // ... باقي الحالات
  }

  // تطبيق البحث
  if (_searchQuery.isNotEmpty) {
    _filteredTodos = _filteredTodos.where((t) =>
      t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (t.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }
}
```

**البحث:**

```dart
void searchTodos(String query) {
  _searchQuery = query;
  _applyFilter();
  notifyListeners();
}
```

---

#### 4. إدارة القوائم المخصصة

**إضافة قائمة:**

```dart
Future<TodoListModel?> addTodoList({
  required String name,
  String? iconName,
  String? color,
}) async
```

**تحديث قائمة:**

```dart
Future<bool> updateTodoList(TodoListModel list) async
```

**حذف قائمة:**

```dart
Future<bool> deleteTodoList(int id) async
```

- المهام تبقى ولكن `listId` يصبح `null`

---

## 🎨 واجهة المستخدم (UI Screens)

### 1. الشاشة الرئيسية (TodoListScreen)

**الموقع:** `lib/ui/presentation/todo_list/screens/todo_list_screen.dart`

**المكونات:**

```
┌─────────────────────────────┐
│   TODO                      │  <- العنوان
├─────────────────────────────┤
│ 🔍 Search                   │  <- زر البحث
├─────────────────────────────┤
│ 🌞 My Day           (5)    │  <- مهام اليوم
│ ⭐ Important        (3)    │  <- المهمة
│ 📅 Planned          (8)    │  <- المخططة
│ ✅ Tasks            (12)   │  <- جميع المهام
├─────────────────────────────┤
│ 📋 قائمة المشتريات  (4)   │  <- قوائم مخصصة
│ 💼 مهام العمل       (7)   │
│ + إنشاء قائمة جديدة        │
└─────────────────────────────┘
```

**التفاعلات:**

- الضغط على فئة → فتح `TodoCategoryScreen`
- الضغط على قائمة → فتح مهام القائمة
- الضغط المطول على قائمة → تعديل/حذف

---

### 2. شاشة الفئة (TodoCategoryScreen)

**الموقع:** `lib/ui/presentation/todo_list/screens/todo_category_screen.dart`

**المكونات:**

```
┌─────────────────────────────┐
│ ← MY DAY                    │  <- رجوع + العنوان
├─────────────────────────────┤
│ ☐ شراء البقالة             │  <- مهمة
│   📝 حليب، خبز، بيض          │  <- الوصف
│   ⭐                         │  <- نجمة الأهمية
│                             │
│ ☑ قراءة كتاب (مكتملة)      │  <- مهمة مكتملة
│                             │
│ ☐ اجتماع الساعة 3           │
│   📅 26 Dec 2025            │  <- تاريخ الاستحقاق
│                             │
└─────────────────────────────┘
      │ + إضافة مهمة │           <- FAB
```

**الميزات:**

- **Reorderable List:** السحب لإعادة الترتيب
- **Swipe to Delete:** السحب لليسار للحذف
- **Tap:** الضغط على المهمة لتحريرها
- **Checkbox:** تأشير لإكمال المهمة
- **Star:** نجمة لتبديل الأهمية

---

### 3. شاشة البحث (TodoSearchScreen)

**الموقع:** `lib/ui/presentation/todo_list/screens/todo_search_screen.dart`

**الميزات:**

- بحث فوري في العنوان والوصف
- عرض النتائج مع highlight
- لا توجد نتائج؟ عرض رسالة ودية

---

### 4. Bottom Sheet إضافة/تعديل

**الموقع:** `lib/ui/presentation/todo_list/widgets/add_todo_bottom_sheet.dart`

**الحقول:**

```
┌─────────────────────────────┐
│ Title                       │  <- TextField
│ [What do you want to do?]   │
├─────────────────────────────┤
│ Description (optional)      │  <- TextField (3 lines)
│ [Add notes...]              │
├─────────────────────────────┤
│ ⭐ Mark as Important        │  <- Switch
│ 🌞 Add to My Day            │  <- Switch
│ 📅 Due Date: [Pick Date]    │  <- Date Picker
├─────────────────────────────┤
│ [Cancel]         [Save]     │  <- Actions
└─────────────────────────────┘
```

**التحقق:**

- العنوان إجباري
- عرض رسالة خطأ إن كان فارغاً

---

## 🔢 نظام العدادات (Counters)

### منطق الحساب

**في TodoDatabaseService:**

```dart
Future<int> getMyDayCount() async {
  final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM todos
     WHERE is_my_day = 1 AND is_completed = 0'
  );
  return Sqflite.firstIntValue(result) ?? 0;
}

Future<int> getImportantCount() async {
  final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM todos
     WHERE is_important = 1 AND is_completed = 0'
  );
  return Sqflite.firstIntValue(result) ?? 0;
}

Future<int> getPlannedCount() async {
  final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM todos
     WHERE due_date IS NOT NULL AND is_completed = 0'
  );
  return Sqflite.firstIntValue(result) ?? 0;
}

Future<int> getTodoCountByListId(int listId) async {
  final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM todos
     WHERE list_id = ? AND is_completed = 0',
    [listId]
  );
  return Sqflite.firstIntValue(result) ?? 0;
}
```

**في TodoProvider:**

```dart
Future<void> refreshCounts() async {
  _totalCount = await _dbService.getTodosCount();
  _myDayCount = await _dbService.getMyDayCount();
  _importantCount = await _dbService.getImportantCount();
  _plannedCount = await _dbService.getPlannedCount();
  notifyListeners();
}
```

---

## 🌐 دعم اللغات (i18n)

### ملفات الترجمة

**English (`assets/i18n/en.json`):**

```json
{
  "todo": {
    "my_day": "MY DAY",
    "important": "IMPORTANT",
    "planned": "PLANNED",
    "tasks": "TASKS",
    "add_task": "Add Task",
    "edit_task": "Edit Task",
    "delete_task": "Delete Task",
    "task_title_hint": "What do you want to do?",
    "description_hint": "Add notes (optional)",
    "due_date": "Due Date"
  }
}
```

**Arabic (`assets/i18n/ar.json`):**

```json
{
  "todo": {
    "my_day": "يومي",
    "important": "المهم",
    "planned": "المخطط",
    "tasks": "المهام",
    "add_task": "إضافة مهمة",
    "edit_task": "تعديل المهمة",
    "delete_task": "حذف المهمة",
    "task_title_hint": "ماذا تريد أن تفعل؟",
    "description_hint": "أضف ملاحظات (اختياري)",
    "due_date": "تاريخ الاستحقاق"
  }
}
```

**الاستخدام في الكود:**

```dart
Text(translate('todo.my_day'))
```

---

## 🎯 مثال على سير العمل (TODO Workflow)

### سيناريو: إنشاء مهمة يومية

**الخطوة 1: فتح الشاشة الرئيسية**

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => TodoListScreen())
);
```

**الخطوة 2: اختيار "My Day"**

```dart
provider.setFilter(TodoFilter.myDay);
```

**الخطوة 3: إضافة مهمة جديدة**

```dart
showModalBottomSheet(
  context: context,
  builder: (_) => AddTodoBottomSheet(filter: TodoFilter.myDay)
);
```

**الخطوة 4: ملء البيانات**

```dart
await provider.addTodo(
  title: "اجتماع فريق المشروع",
  description: "مناقشة خطة الربع القادم",
  isMyDay: true,
  isImportant: true,
  dueDate: DateTime.now().add(Duration(hours: 2))
);
```

**الخطوة 5: عرض في القائمة**

- تظهر المهمة في "My Day"
- تظهر أيضاً في "Important"
- تظهر في "Planned"

**الخطوة 6: إكمال المهمة**

```dart
await provider.toggleComplete(todo.id!);
```

- تختفي من الفئات
- تبقى في "Tasks" (مع تأشير)

---

## 🔷 الجزء الثاني: Task Sheet System (مهام العمل)

### نظرة عامة

نظام مهام ميدانية مرتبط بالمشاريع والموظفين، يستخدم API خارجي.

### الموقع في المشروع

```
lib/ui/presentation/task_sheet/
├── task_sheet_screen.dart         # قائمة المهام
├── add_task_sheet.dart            # إضافة مهمة جديدة
├── TaskDetailsPage.dart           # تفاصيل المهمة
├── EmployeeShiftRequestPage.dart  # طلبات الورديات
└── EmptyShiftPage.dart            # الورديات الفارغة
```

---

## 📡 API Integration

### Base URL

```dart
https://test.elrace.com/api
```

### Authentication

```dart
final token = SharedPref.getLoginData().result?.token;
headers: {
  "Content-Type": "application/json",
  "Authorization": "Bearer $token"
}
```

---

### API Endpoints

#### 1. جلب قائمة المهام

```
POST /api/tasks/list
Body: {
  "jsonrpc": "2.0",
  "params": {
    "user_id": int
  }
}
Response: {
  "result": {
    "tasks": [
      {
        "id": int,
        "task_name": string,
        "project_id": int,
        "project_name": string,
        "status": string,
        "priority": string,
        "due_date": string
      }
    ]
  }
}
```

#### 2. تفاصيل المهمة

```
POST /api/tasks/details
Body: {
  "jsonrpc": "2.0",
  "params": {
    "task_id": int,
    "project_id": int
  }
}
Response: { ... }
```

---

## 🎨 واجهة Task Sheet

### TaskSheetPage

**المكونات:**

```dart
class _TaskSheetPageState extends State<TaskSheetPage> {
  List<dynamic> tasks = [];        // قائمة المهام
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }
}
```

**الشاشة:**

```
┌─────────────────────────────┐
│   TIME SHEET           +    │  <- العنوان + زر إضافة
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ مهمة: فحص الموقع        │ │  <- بطاقة مهمة
│ │ المشروع: بناء 123       │ │
│ │ الحالة: قيد التنفيذ     │ │
│ │ 📅 25 Dec 2025         │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ مهمة: كتابة تقرير       │ │
│ │ ...                     │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

**الميزات:**

- Pull to Refresh
- الضغط على بطاقة → فتح التفاصيل
- زر `+` → إضافة مهمة جديدة

---

### TaskDetailsPage

**المعلومات المعروضة:**

- اسم المهمة
- المشروع المرتبط
- الحالة الحالية
- الأولوية
- تاريخ البدء/الانتهاء
- الموظفين المعينين
- ساعات العمل
- الملاحظات

**الإجراءات:**

- تحديث الحالة
- إضافة ملاحظات
- طلب تمديد الوقت
- رفع الملفات

---

### AddTaskSheet

**الحقول:**

- اسم المهمة (إجباري)
- اختيار المشروع
- الوصف
- تاريخ البدء/الانتهاء
- اختيار الموظفين
- الأولوية

**التحقق:**

```dart
if (taskName.isEmpty) {
  showError("الرجاء إدخال اسم المهمة");
  return;
}

if (selectedProject == null) {
  showError("الرجاء اختيار المشروع");
  return;
}
```

---

## 🔄 سير العمل (Task Sheet Workflow)

### سيناريو: إنشاء مهمة ميدانية جديدة

**1. الوصول إلى Task Sheet:**

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => TaskSheetPage())
);
```

**2. الضغط على زر `+`:**

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => AddTaskSheet())
);
```

**3. ملء بيانات المهمة:**

```dart
{
  "task_name": "فحص أساسات المبنى",
  "project_id": 42,
  "description": "فحص شامل لجودة الأساسات",
  "start_date": "2025-12-26",
  "end_date": "2025-12-27",
  "priority": "high",
  "assigned_employees": [12, 34, 56]
}
```

**4. إرسال إلى API:**

```dart
POST /api/tasks/create
```

**5. تحديث القائمة:**

```dart
await fetchTasks();  // Re-fetch from server
```

**6. عرض التفاصيل:**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => TaskDetailsPage(
      taskId: newTask.id,
      projectId: newTask.projectId
    )
  )
);
```

---

## 🆚 مقارنة بين النظامين

| الميزة        | TODO System | Task Sheet System    |
| ------------- | ----------- | -------------------- |
| **التخزين**   | SQLite محلي | API خارجي            |
| **الاستخدام** | مهام شخصية  | مهام العمل الميدانية |
| **المزامنة**  | لا يوجد     | مع السيرفر           |
| **المشاركة**  | فردي        | جماعي (فريق)         |
| **التعقيد**   | بسيط        | متقدم                |
| **المشاريع**  | لا يوجد     | مرتبط بمشاريع        |
| **الموظفين**  | مستخدم واحد | عدة موظفين           |
| **الصلاحيات** | كاملة       | حسب الدور            |

---

## 🛠️ معالجة الأخطاء (Error Handling)

### TODO System

**أخطاء قاعدة البيانات:**

```dart
try {
  await _dbService.insertTodo(todo);
} catch (e) {
  _errorMessage = 'Failed to add todo: $e';
  notifyListeners();
  return null;
}
```

**عرض الأخطاء:**

```dart
if (provider.errorMessage != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(provider.errorMessage!))
  );
}
```

---

### Task Sheet System

**أخطاء الشبكة:**

```dart
try {
  final response = await http.post(url, ...);
  if (response.statusCode == 200) {
    // Success
  } else {
    setState(() {
      errorMessage = "Failed to load tasks.";
    });
  }
} catch (e) {
  setState(() {
    errorMessage = "Error: $e";
  });
}
```

**عرض الأخطاء:**

```dart
if (errorMessage != null)
  Center(
    child: Text(
      errorMessage!,
      style: TextStyle(color: Colors.red)
    )
  )
```

---

## 🔐 الأمان (Security)

### TODO System

- البيانات محلية فقط
- لا تترك الجهاز
- SQLite مشفر (إذا تم تفعيله)

### Task Sheet System

- مصادقة بـ Bearer Token
- HTTPS للاتصالات
- التحقق من الصلاحيات في السيرفر

---

## 📊 الأداء (Performance)

### TODO System

- سريع جداً (محلي)
- لا يعتمد على الإنترنت
- الفهارس تسرع الاستعلامات

### Task Sheet System

- يعتمد على سرعة الشبكة
- Loading states ضرورية
- Caching للبيانات المتكررة

---

## 🚀 ميزات مستقبلية (Future Features)

### TODO System

- [ ] مزامنة بين الأجهزة (Cloud Sync)
- [ ] إشعارات للمهام
- [ ] تكرار المهام (Daily, Weekly)
- [ ] المهام الفرعية (Sub-tasks)
- [ ] المرفقات (Files)
- [ ] الملصقات (Tags)

### Task Sheet System

- [ ] إشعارات push عند تعيين مهمة
- [ ] تتبع الوقت الفعلي
- [ ] التقارير الإحصائية
- [ ] رفع الصور والملفات
- [ ] الدردشة بين الفريق
- [ ] GPS Tracking للمهام الميدانية

---

## 💡 نصائح للمطورين (Developer Tips)

### TODO System

**1. إضافة فلتر مخصص:**

```dart
case TodoFilter.overdue:
  _filteredTodos = _todos.where((t) =>
    t.dueDate != null &&
    t.dueDate!.isBefore(DateTime.now()) &&
    !t.isCompleted
  ).toList();
  break;
```

**2. تخصيص التنسيق:**

```dart
// في TodoItemWidget
if (todo.isImportant) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.red, width: 2)
    ),
    child: ...
  );
}
```

**3. إضافة حقل جديد:**

```sql
ALTER TABLE todos ADD COLUMN priority INTEGER DEFAULT 0;
```

ثم تحديث `TodoModel` و `toMap()` و `fromMap()`

---

### Task Sheet System

**1. إضافة فلترة محلية:**

```dart
List<dynamic> get urgentTasks {
  return tasks.where(
    (t) => t['priority'] == 'high'
  ).toList();
}
```

**2. Caching الاستجابات:**

```dart
final cachedTasks = await Hive.box('tasks_cache').get('tasks_list');
if (cachedTasks != null && !forceRefresh) {
  setState(() {
    tasks = cachedTasks;
    isLoading = false;
  });
  return;
}
```

**3. Retry Logic:**

```dart
int retries = 0;
while (retries < 3) {
  try {
    final response = await http.post(...);
    if (response.statusCode == 200) break;
  } catch (e) {
    retries++;
    await Future.delayed(Duration(seconds: 2));
  }
}
```

---

## 📱 دعم الأجهزة (Device Support)

### TODO System

- ✅ Android 5.0+
- ✅ iOS 11.0+
- ✅ يعمل بدون إنترنت
- ✅ التخزين المحلي

### Task Sheet System

- ✅ Android 5.0+
- ✅ iOS 11.0+
- ❗ يتطلب اتصال إنترنت
- ✅ يدعم التحديث التلقائي

---

## 📞 الدعم والمساعدة

للأسئلة والمشاكل:

**TODO System:**

- راجع `lib/ui/presentation/todo_list/`
- تحقق من SQLite Database في Device Inspector
- استخدم `debugPrint` لتتبع المشاكل

**Task Sheet System:**

- راجع `lib/ui/presentation/task_sheet/`
- تحقق من استجابات API في Network Inspector
- استخدم Postman لاختبار Endpoints

---

## ✅ Checklist للتنفيذ

### عند إضافة ميزة جديدة للـ TODO:

- [ ] تحديث `TodoModel`
- [ ] تحديث جدول SQLite
- [ ] تحديث `TodoProvider`
- [ ] تحديث UI
- [ ] تحديث i18n
- [ ] اختبار جميع الفئات
- [ ] تحديث التوثيق

### عند إضافة ميزة جديدة للـ Task Sheet:

- [ ] تنسيق مع فريق Backend
- [ ] توثيق API Endpoint
- [ ] تحديث Models
- [ ] تحديث UI
- [ ] معالجة الأخطاء
- [ ] إضافة Loading States
- [ ] تحديث التوثيق

---

**آخر تحديث:** 26 ديسمبر 2025  
**الإصدار:** 1.0.0  
**الحالة:** قيد التطوير النشط ✅
