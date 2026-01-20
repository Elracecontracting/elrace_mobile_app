import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:el_race/ui/widgets/header_widget.dart';

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
      appBar: const HeaderWidget(),
      body: Column(
        children: [
          // Header
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
              )),

          // Filters Tabs
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: FilterTabs(),
          ),

          // Tasks List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskDashboardCard(task: task);
              },
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

class TaskDashboardCard extends StatelessWidget {
  final Task task;

  const TaskDashboardCard({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E2E2E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CircleAvatar(
                radius: 12.0,
                backgroundColor: task.status == TaskStatus.completed
                    ? const Color(0xFFE8F5E9)
                    : task.status == TaskStatus.overdue
                        ? const Color(0xFFFDECEA)
                        : const Color(0xFFFFF3E0),
                child: Icon(
                  task.status == TaskStatus.completed
                      ? Icons.star
                      : task.status == TaskStatus.overdue
                          ? Icons.error
                          : Icons.settings,
                  size: 14.0,
                  color: task.status == TaskStatus.completed
                      ? const Color(0xFF43A047)
                      : task.status == TaskStatus.overdue
                          ? const Color(0xFFE53935)
                          : const Color(0xFFFB8C00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // User Section
          Row(
            children: [
              CircleAvatar(
                radius: 12.0,
                child: Text(task.assignedUser[0]),
              ),
              const SizedBox(width: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.assignedUser,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.0,
                    ),
                  ),
                  Text(
                    task.department,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // Dates Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'START DATE',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(task.startDate),
                    style: const TextStyle(fontSize: 10.0),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'END DATE',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(task.endDate),
                    style: const TextStyle(fontSize: 10.0),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // Progress Line
          Container(
            height: 2.0,
            width: double.infinity,
            color: task.status == TaskStatus.completed
                ? const Color(0xFF43A047)
                : task.status == TaskStatus.overdue
                    ? const Color(0xFFE53935)
                    : const Color(0xFFFB8C00),
          ),
          const SizedBox(height: 8.0),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    task.time,
                    style: const TextStyle(fontSize: 11.0),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    '${task.remainingDays} Days',
                    style: const TextStyle(fontSize: 11.0),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF8BC6EC), Color(0xFF9599E2)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isSelected ? null : const Color(0xFFE3F2FD),
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
            colors: [Color(0xFF0093E9), Color(0xFF80D0C7)],
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
