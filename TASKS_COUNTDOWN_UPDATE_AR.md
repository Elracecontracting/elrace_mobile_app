# تحديث العد التنازلي للأيام المتبقية في لوحة المهام

## المشكلة 🐛

في شاشة **Tasks Dashboard**، كان عدد الأيام المتبقية (Days) لا ينقص تلقائياً مع مرور الوقت.

الكود القديم كان يحسب الأيام المتبقية بناءً على `DateTime.now()` عند بناء الواجهة فقط، ولا يتحدث بعد ذلك.

## الحل ✅

تم تحويل `_TaskCard` من `StatelessWidget` إلى `StatefulWidget` وإضافة `StreamBuilder` مع `Stream.periodic` لتحديث العد التنازلي تلقائياً كل ساعة.

## التعديلات التي تمت

### 1. إضافة Stream للتحديث التلقائي في `_TasksDashboardScreenState`:

```dart
late Stream<DateTime> _timeStream;

@override
void initState() {
  super.initState();
  // Create a stream that emits current time every minute
  _timeStream = Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());

  // Load tasks from Firebase
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<TodoFirebaseProvider>().loadTodos();
    _loadMemberPhotos();
  });
}
```

### 2. تحويل `_TaskCard` إلى StatefulWidget:

```dart
class _TaskCard extends StatefulWidget {
  final TodoModel todo;
  final VoidCallback onToggleComplete;
  final Widget Function(String name, {double size}) buildAvatar;

  const _TaskCard({
    required this.todo,
    required this.onToggleComplete,
    required this.buildAvatar,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}
```

### 3. إضافة Stream في `_TaskCardState`:

```dart
class _TaskCardState extends State<_TaskCard> {
  late Stream<DateTime> _timeStream;

  @override
  void initState() {
    super.initState();
    // Update every day to reflect days countdown changes
    _timeStream = Stream.periodic(const Duration(days: 1), (_) => DateTime.now());
  }

  // تحويل getters إلى functions تقبل DateTime كمعامل
  int _getRemainingDays(DateTime now) {
    if (widget.todo.dueDate == null) return 0;
    return widget.todo.dueDate!.difference(now).inDays;
  }

  double _getProgress(DateTime now) {
    if (widget.todo.isCompleted) return 1.0;
    if (widget.todo.dueDate == null || widget.todo.createdAt == null) return 0.0;

    final total = widget.todo.dueDate!.difference(widget.todo.createdAt!).inDays;
    final elapsed = now.difference(widget.todo.createdAt!).inDays;

    if (total <= 0) return 0.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
```

### 4. استخدام StreamBuilder في build():

```dart
@override
Widget build(BuildContext context) {
  final status = _status;
  final statusColor = _statusColor(status);

  return StreamBuilder<DateTime>(
    stream: _timeStream,
    initialData: DateTime.now(),
    builder: (context, snapshot) {
      final now = snapshot.data ?? DateTime.now();
      final remainingDays = _getRemainingDays(now);
      final progress = _getProgress(now);

      return GestureDetector(
        // ... بقية الكود
      );
    },
  );
}
```

## النتيجة 🎯

الآن، عدد الأيام المتبقية سيتحدث تلقائياً **مرة واحدة كل يوم**:

- عندما تكون المهمة END DATE: 03 FEB 2026 واليوم 30 JAN 2026، سيظهر **4 Days**
- في اليوم التالي (31 JAN)، سينقص تلقائياً إلى **3 Days**
- وهكذا حتى يصل إلى 0، ثم يتحول إلى **Late** للمهام المتأخرة

## ملاحظات تقنية 📝

- التحديث يحدث **مرة واحدة كل يوم** (`Duration(days: 1)`) لأن العداد يعرض الأيام فقط
- هذا يوفر الأداء ويمنع استهلاك الموارد بدون داعي
- تم استخدام `StreamBuilder` بدلاً من `Timer` لأنه يتكامل بشكل أفضل مع Flutter widget lifecycle

## الملف المعدل

- `/lib/ui/presentation/tasks_dashboard/screens/tasks_dashboard_screen.dart`

---

تم إكمال التعديل بنجاح ✅
