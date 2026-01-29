import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:provider/provider.dart';
import 'dart:math' as Math;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:el_race/ui/presentation/tasks_dashboard/screens/add_task.dart';
import 'package:el_race/ui/presentation/tasks_dashboard/screens/task_details.dart';
import 'package:el_race/ui/presentation/tasks_dashboard/screens/user_reports_screen.dart';
import 'package:el_race/ui/presentation/todo_list/providers/todo_firebase_provider.dart';
import 'package:el_race/ui/presentation/todo_list/data/todo_model.dart';

enum TaskFilter { all, pending, notCompleted, completed }

class TasksDashboardScreen extends StatefulWidget {
  const TasksDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TasksDashboardScreen> createState() => _TasksDashboardScreenState();
}

class _TasksDashboardScreenState extends State<TasksDashboardScreen> {
  TaskFilter _selectedFilter = TaskFilter.all;

  @override
  void initState() {
    super.initState();
    // Load tasks from Firebase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoFirebaseProvider>().loadTodos();
    });
  }

  List<TodoModel> _filterTodos(List<TodoModel> todos) {
    switch (_selectedFilter) {
      case TaskFilter.all:
        return todos;
      case TaskFilter.pending:
        return todos
            .where((t) =>
                !t.isCompleted &&
                t.dueDate != null &&
                t.dueDate!.isAfter(DateTime.now()))
            .toList();
      case TaskFilter.notCompleted:
        return todos.where((t) => !t.isCompleted).toList();
      case TaskFilter.completed:
        return todos.where((t) => t.isCompleted).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: Consumer<TodoFirebaseProvider>(
        builder: (context, provider, child) {
          final allTodos = provider.todos;
          final filteredTodos = _filterTodos(allTodos);

          // Calculate statistics
          final totalTasks = allTodos.length;
          final completedTasks = allTodos.where((t) => t.isCompleted).length;
          final overdueTasks = allTodos
              .where((t) =>
                  !t.isCompleted &&
                  t.dueDate != null &&
                  t.dueDate!.isBefore(DateTime.now()))
              .length;
          final pendingReports = allTodos
              .where((t) => t.reportId != null && !t.isCompleted)
              .length;

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            "assets/png/Tasks.svg",
                            height: 24.w,
                            width: 24.w,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'TASKS DASHBOARD',
                            style: GoogleFonts.koulen(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w500,
                              color: appFontColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _TotalTasksCard(
                                totalTasks: totalTasks,
                                overdueTasks: overdueTasks,
                                completedTasks: completedTasks,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _PendingReportsCard(
                                pendingReports: pendingReports,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _FilterTabs(
                      selectedFilter: _selectedFilter,
                      onFilterChanged: (filter) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Text(
                            'Total TASKS (${filteredTodos.length})',
                            style: const TextStyle(
                              color: Color(0xFFB0B0B0),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const Spacer(),
                          const AddTaskButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (filteredTodos.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 80.w,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No tasks',
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final todo = filteredTodos[index];
                      return _TaskCard(
                        todo: todo,
                        onToggleComplete: () {
                          provider.updateTodo(
                            todo.copyWith(isCompleted: !todo.isCompleted),
                          );
                        },
                      );
                    },
                    childCount: filteredTodos.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// بطاقة إجمالي المهام
class _TotalTasksCard extends StatelessWidget {
  final int totalTasks;
  final int overdueTasks;
  final int completedTasks;

  const _TotalTasksCard({
    required this.totalTasks,
    required this.overdueTasks,
    required this.completedTasks,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        gradient: const LinearGradient(
          colors: [Color(0xFF039BE5), Color(0xFF4DD0E1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Center(
                  child: Text(
                    'TOTAL TASKS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$totalTasks',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 50.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6.0),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Overdue ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                      TextSpan(
                        text: 'Tasks $overdueTasks',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 12.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24.0),
                bottomRight: Radius.circular(24.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$completedTasks task completed',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3.0),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6.0,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة التقارير المعلقة
class _PendingReportsCard extends StatelessWidget {
  final int pendingReports;

  const _PendingReportsCard({required this.pendingReports});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF90CAF9),
                  Color(0xFF9FA8DA),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PENDING REPORTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '$pendingReports',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserReportsScreen(),
                ),
              );
            },
            child: Container(
              height: 52,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: const Center(
                child: Text(
                  'View Reports',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// فلاتر المهام
class _FilterTabs extends StatelessWidget {
  final TaskFilter selectedFilter;
  final Function(TaskFilter) onFilterChanged;

  const _FilterTabs({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab('ALL TASKS', TaskFilter.all),
          const SizedBox(width: 12),
          _buildTab('PENDING', TaskFilter.pending),
          const SizedBox(width: 12),
          _buildTab('NOT COMPLETED', TaskFilter.notCompleted),
          const SizedBox(width: 12),
          _buildTab('COMPLETED', TaskFilter.completed),
        ],
      ),
    );
  }

  Widget _buildTab(String text, TaskFilter filter) {
    final isSelected = selectedFilter == filter;
    return GestureDetector(
      onTap: () => onFilterChanged(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF8BC6EC), Color(0xFF9599E2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFFC0DBEE),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// بطاقة المهمة
class _TaskCard extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onToggleComplete;

  const _TaskCard({
    required this.todo,
    required this.onToggleComplete,
  });

  TaskStatus get _status {
    if (todo.isCompleted) return TaskStatus.completed;
    if (todo.dueDate != null && todo.dueDate!.isBefore(DateTime.now())) {
      return TaskStatus.overdue;
    }
    return TaskStatus.pending;
  }

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return const Color(0xFFFF9800);
      case TaskStatus.completed:
        return const Color(0xFF0F9D58);
      case TaskStatus.overdue:
        return const Color(0xFFC62828);
    }
  }

  int get _remainingDays {
    if (todo.dueDate == null) return 0;
    return todo.dueDate!.difference(DateTime.now()).inDays;
  }

  double get _progress {
    if (todo.isCompleted) return 1.0;
    if (todo.dueDate == null || todo.createdAt == null) return 0.0;

    final total = todo.dueDate!.difference(todo.createdAt!).inDays;
    final elapsed = DateTime.now().difference(todo.createdAt!).inDays;

    if (total <= 0) return 0.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final statusColor = _statusColor(status);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, TaskDetailsScreen.routeName);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD0D0D0)),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // LEFT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 32),
                        child: Text(
                          todo.title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD9D9D9),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: const Color(0xFFEFEFEF),
                              child: Text(
                                (todo.assignedToName ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  todo.assignedToName ?? 'Unassigned',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (todo.listId != null)
                                  Consumer<TodoFirebaseProvider>(
                                    builder: (context, provider, _) {
                                      final list = provider.todoLists.firstWhere(
                                        (l) => l.firebaseId == todo.listId,
                                        orElse: () => provider.todoLists.isNotEmpty
                                            ? provider.todoLists.first
                                            : throw Exception('No list found'),
                                      );
                                      return Text(
                                        list.name.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF9AA3AE),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final trackWidth = constraints.maxWidth;
                          final progress = _progress;

                          const double iconSize = 16;
                          final double coloredWidth = trackWidth * progress;
                          final double iconLeft = (coloredWidth - iconSize / 2)
                              .clamp(0.0, trackWidth - iconSize);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 24,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Container(
                                        height: 4,
                                        width: double.infinity,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Container(
                                        height: 4,
                                        width: coloredWidth,
                                        color: statusColor,
                                      ),
                                    ),
                                    Positioned(
                                      left: iconLeft,
                                      bottom: 4,
                                      child: Image.asset(
                                        progress < 1.0
                                            ? 'assets/png/walker-man.png'
                                            : 'assets/png/stand.png',
                                        width: iconSize,
                                        height: iconSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                todo.dueDate != null
                                    ? DateFormat('h:mm a').format(todo.dueDate!)
                                    : '--:--',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF9AA3AE),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 72,
                  color: const Color(0xFFD9D9D9),
                ),
                const SizedBox(width: 10),
                // RIGHT
                SizedBox(
                  width: 86,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'START DATE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF11A84A),
                        ),
                      ),
                      Text(
                        todo.createdAt != null
                            ? DateFormat('dd MMM yyyy')
                                .format(todo.createdAt!)
                                .toUpperCase()
                            : '--',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9AA3AE),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'END DATE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                      Text(
                        todo.dueDate != null
                            ? DateFormat('dd MMM yyyy')
                                .format(todo.dueDate!)
                                .toUpperCase()
                            : '--',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9AA3AE),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${_remainingDays.abs()}',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFBDBDBD),
                              height: 0.9,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _remainingDays >= 0 ? 'Days' : 'Late',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _remainingDays >= 0
                                  ? const Color(0xFFBDBDBD)
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onToggleComplete,
                child: StarburstBadge(
                  size: 22,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum TaskStatus { completed, pending, overdue }

/// ⭐ Starburst badge مثل الصورة (مسنن)
class StarburstBadge extends StatelessWidget {
  final double size;
  final Color color;

  const StarburstBadge({
    Key? key,
    required this.size,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _StarburstPainter(color: color, points: 12, innerRatio: 0.72),
    );
  }
}

class _StarburstPainter extends CustomPainter {
  final Color color;
  final int points;
  final double innerRatio;

  _StarburstPainter({
    required this.color,
    required this.points,
    required this.innerRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;
    final innerR = outerR * innerRatio;

    final path = Path();
    final total = points * 2;
    for (int i = 0; i < total; i++) {
      final isOuter = i.isEven;
      final r = isOuter ? outerR : innerR;
      final angle =
          (i * (3.141592653589793 * 2) / total) - (3.141592653589793 / 2);
      final x = cx + r * Math.cos(angle);
      final y = cy + r * Math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarburstPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.points != points ||
        oldDelegate.innerRatio != innerRatio;
  }
}

class AddTaskButton extends StatelessWidget {
  const AddTaskButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddTaskScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [Color(0xFF8BC6EC), Color(0xFF9599E2)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'ADD TASK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
