import 'package:el_race/report_module/data/models/report_model.dart';
import 'package:el_race/report_module/data/provider/reports_provider.dart';
import 'package:el_race/report_module/presentation/screens/report_detail/report_detail.dart';
import 'package:el_race/ui/presentation/tasks/data/task_model.dart';
import 'package:el_race/ui/presentation/tasks/logic/tasks_provider.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TaskDetailsScreen extends StatelessWidget {
  final TaskModel task;

  const TaskDetailsScreen({super.key, required this.task});

  Color _priorityColor(String? priority) {
    switch (priority) {
      case '1':
        return Colors.red.shade600;
      case '2':
        return Colors.orange.shade600;
      case '3':
        return Colors.green.shade600;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(task.priority);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Header with icon and title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: appFontColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Icon(Icons.task_outlined, size: 24.w, color: appFontColor),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Task Details',
                      style: GoogleFonts.koulen(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w500,
                        color: appFontColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Task Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: priorityColor.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: priorityColor.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with Priority
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                priorityColor,
                                priorityColor.withOpacity(0.6)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            task.name ?? 'Untitled Task',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: appFontColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                priorityColor.withOpacity(0.15),
                                priorityColor.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: priorityColor.withOpacity(0.4),
                                width: 1.5),
                          ),
                          child: Text(
                            'P${task.priority ?? '-'}',
                            style: TextStyle(
                              color: priorityColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Status Badge
                    if (task.stage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? Colors.green.shade50
                              : appFontColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: task.isCompleted
                                ? Colors.green
                                : appFontColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              task.isCompleted
                                  ? Icons.check_circle
                                  : Icons.flag_rounded,
                              size: 16,
                              color: task.isCompleted
                                  ? Colors.green.shade700
                                  : appFontColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              task.stage ?? '-',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: task.isCompleted
                                    ? Colors.green.shade700
                                    : appFontColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 16),

                    // Description
                    if ((task.description ?? '').isNotEmpty) ...[
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: appFontColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          task.description ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: appFontColor.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Project
                    if ((task.projectId ?? '').isNotEmpty) ...[
                      _buildInfoRow(
                        Icons.folder_open,
                        'Project',
                        task.projectId ?? '-',
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Assigned User
                    if ((task.assignedUser ?? '').isNotEmpty) ...[
                      _buildInfoRow(
                        Icons.person,
                        'Assigned to',
                        task.assignedUser ?? '-',
                        Colors.purple,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Team
                    if ((task.team ?? '').isNotEmpty) ...[
                      _buildInfoRow(
                        Icons.group,
                        'Team',
                        task.team ?? '-',
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Created Date
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Created',
                      _formatDate(task.createdAt),
                      Colors.teal,
                    ),

                    // Linked Reports Section
                    if (task.reportIds.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Divider(color: Colors.grey.shade200),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.insert_drive_file,
                              size: 18, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Linked Reports (${task.reportIds.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: appFontColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLinkedReports(context),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            if (!task.isCompleted) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Consumer<TasksProvider>(
                  builder: (context, provider, _) {
                    final isCompleting =
                        provider.completingTaskIds.contains(task.id ?? -1);
                    final isLinking =
                        provider.linkingTaskIds.contains(task.id ?? -1);

                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: task.id == null || isCompleting
                                ? null
                                : () async {
                                    final msg =
                                        await provider.completeTask(task.id!);
                                    if (context.mounted) {
                                      if (msg != null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text(msg)),
                                        );
                                        Navigator.pop(context);
                                      }
                                    }
                                  },
                            icon: isCompleting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_circle, size: 20),
                            label: const Text(
                              'Mark as Complete',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: task.id == null || isLinking
                                ? null
                                : () {
                                    // Open link report dialog
                                    Navigator.pop(context);
                                  },
                            icon: isLinking
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: appFontColor,
                                    ),
                                  )
                                : Icon(Icons.link, color: appFontColor),
                            label: Text(
                              'Link Report',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: appFontColor,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: appFontColor, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: appFontColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedReports(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, _) {
        final parsedReports = task.reportIds.map((e) {
          if (e is Map && e['id'] != null) {
            return (
              id: e['id'].toString(),
              name: e['name']?.toString(),
            );
          }
          return (id: e.toString(), name: null);
        }).toList();

        return Column(
          children: parsedReports.map((reportData) {
            final report = reportProvider.reports.firstWhere(
              (r) => r.id == reportData.id,
              orElse: () => ReportModel(
                id: reportData.id,
                name: reportData.name ?? 'Report ${reportData.id}',
                companyId: '',
                folderId: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.description,
                      color: Colors.blue.shade700, size: 20),
                ),
                title: Text(
                  report.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: appFontColor,
                  ),
                ),
                subtitle: Text(
                  'ID: ${report.id}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.blue.shade700),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportDetailScreen(
                        report: report,
                        folderName: report.name,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
