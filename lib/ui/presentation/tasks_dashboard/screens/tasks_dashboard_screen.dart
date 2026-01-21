import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
// وبأعلى الملف:
import 'dart:math' as Math;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Task {
  final String title;
  final String assignedUser;
  final String department;
  final DateTime startDate;
  final DateTime endDate;
  final String time;
  final int remainingDays;
  final double progress;
  final TaskStatus status;

  Task({
    required this.title,
    required this.assignedUser,
    required this.department,
    required this.startDate,
    required this.endDate,
    required this.time,
    required this.remainingDays,
    required this.progress,
    required this.status,
  });
}

enum TaskStatus { completed, pending, overdue }

class TasksDashboardScreen extends StatelessWidget {
  const TasksDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tasks = _generateFakeTasks();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: CustomScrollView(
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
                          child: SummaryCard(
                            title: 'Total Tasks',
                            value: '32',
                            subtitle: 'Overdue Tasks 12',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF039BE5), Color(0xFF4DD0E1)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            bottomSection: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '20 task completed',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12.0,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Container(
                                  height: 5.0,
                                  width: 80.0,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(2.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: PendingReportsCard(),
                        ),
                      ],
                    ),
                  ),
                ),
                const FilterTabs(),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Row(
                    children: [
                      Text(
                        'Total TASKS',
                        style: TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Spacer(),
                      AddTaskButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final task = tasks[index];
                return TaskDashboardCardV2(task: task);
              },
              childCount: tasks.length,
            ),
          ),
        ],
      ),
    );
  }

  List<Task> _generateFakeTasks() {
    return [
      Task(
        title: 'Create new design for mobile',
        assignedUser: 'Marwan Abdel Sattar',
        department: 'Media Department',
        startDate: DateTime(2026, 1, 14),
        endDate: DateTime(2026, 1, 19),
        time: '11:00',
        remainingDays: 5,
        progress: 0.5,
        status: TaskStatus.pending,
      ),
      Task(
        title: 'Fix login issue',
        assignedUser: 'Jane Smith',
        department: 'Development',
        startDate: DateTime(2026, 1, 10),
        endDate: DateTime(2026, 1, 15),
        time: '2:00 PM',
        remainingDays: -1,
        progress: 1.0,
        status: TaskStatus.overdue,
      ),
    ];
  }
}

class TaskDashboardCardV2 extends StatelessWidget {
  final Task task;

  const TaskDashboardCardV2({Key? key, required this.task}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(task.status);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10,horizontal: 16),
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
                        task.title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
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
                              task.assignedUser[0].toUpperCase(),
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
                                task.assignedUser,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                task.department.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF9AA3AE),
                                ),
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
                        final progress = task.progress.clamp(0.0, 1.0);

                        const double iconSize = 16;

                        // عرض الجزء الملوّن
                        final double coloredWidth = trackWidth * progress;

                        // مكان الأيقونة (مربوطة بنهاية اللون)
                        final double iconLeft = (coloredWidth - iconSize / 2)
                            .clamp(0.0, trackWidth - iconSize);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 24, // 🔑 ارتفاع ثابت يمنع التداخل
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

                            // الوقت
                            Text(
                              task.time,
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
                      'STAT DATE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF11A84A),
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy')
                          .format(task.startDate)
                          .toUpperCase(),
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
                      DateFormat('dd MMM yyyy')
                          .format(task.endDate)
                          .toUpperCase(),
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
                          task.remainingDays.toString(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFBDBDBD),
                            height: 0.9,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Days',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFBDBDBD),
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
            child: StarburstBadge(
              size: 22,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

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
  final int points; // عدد الأسنان
  final double innerRatio; // نسبة الداخل

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
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
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

// لازم تضيف هاد فوق الملف:
double cos(double x) => Math.cos(x);
double sin(double x) => Math.sin(x);

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Gradient gradient;
  final Widget? bottomSection;

  const SummaryCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.gradient,
    this.bottomSection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 50.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: subtitle!.split(' ')[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 0.6, // 🔑 يقلل الفراغ العمودي

                            fontSize: 12.0,
                          ),
                        ),
                        TextSpan(
                          text: ' ${subtitle!.split(' ').sublist(1).join(' ')}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            height: 0.6, // 🔑 يقلل الفراغ العمودي

                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (bottomSection != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 29.05, vertical: 12.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.0),
                  bottomRight: Radius.circular(24.0),
                ),
              ),
              child: bottomSection,
            ),
        ],
      ),
    );
  }
}

class PendingReportsCard extends StatelessWidget {
  const PendingReportsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🔑 مهم جداً
        children: [
          // 🔵 Gradient Top
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PENDING REPORTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    '10',
                    style: TextStyle(
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

          // ⬜ White Bottom Section (FULL WIDTH)
          Container(
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
        ],
      ),
    );
  }
}

class FilterTabs extends StatelessWidget {
  const FilterTabs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab('ALL TASKS', true),
          const SizedBox(width: 12),
          _buildTab('PENDING', false),
          const SizedBox(width: 12),
          _buildTab('NOT COMPLETED', false),
          const SizedBox(width: 12),
          _buildTab('COMPLETED', false),
        ],
      ),
    );
  }

  Widget _buildTab(String text, bool isSelected) {
    return Container(
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
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'TOTAL TASKS',
          style: TextStyle(
            color: Color(0xFFB0B0B0),
            fontWeight: FontWeight.w500,
            letterSpacing: 1.1,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF90CAF9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: const [
              Icon(Icons.add, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                '+ ADD TASK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget buildSummaryCards() {
  return Row(
    children: [
      Expanded(
        child: SummaryCard(
          title: 'Total Tasks',
          value: '32',
          subtitle: 'Overdue Tasks 12',
          gradient: const LinearGradient(
            colors: [Color(0xFF80D0C7),Color(0xFF0093E9)],
            begin: Alignment.bottomRight,
            end: Alignment.centerLeft,
          ),
          bottomSection: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '20 task completed',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12.0,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4.0),
              Container(
                height: 4.0,
                width: 80.0,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: PendingReportsCard(),
      ),
    ],
  );
}

class AddTaskButton extends StatelessWidget {
  const AddTaskButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
