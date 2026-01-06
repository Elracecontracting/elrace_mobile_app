import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/tasks/logic/tasks_provider.dart';
import 'package:el_race/ui/presentation/tasks/data/task_model.dart';
import 'package:el_race/ui/presentation/tasks/task_details_screen.dart';
import 'package:el_race/report_module/data/models/report_model.dart';
import 'package:el_race/report_module/data/provider/reports_provider.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  Future<void> _showCreateTaskSheet(
      BuildContext context, TasksProvider provider) async {
    if (provider.assignableUsers.isEmpty && !provider.isLoadingUsers) {
      await provider.loadAssignableUsers();
      if (provider.errorMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage!)),
        );
      }
    }

    final nameController = TextEditingController();
    final descController = TextEditingController();
    String priority = '1';
    int? selectedUserId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.task_alt, color: appFontColor, size: 24),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Create Task',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Task Title',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter task title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: appFontColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Add a description (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: appFontColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: priority,
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.transparent),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: appFontColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          icon: const Icon(Icons.arrow_drop_down),
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: '1',
                              child: Text('🔴 High',
                                  style: TextStyle(fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: '2',
                              child: Text('🟠 Medium',
                                  style: TextStyle(fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: '3',
                              child: Text('🟢 Low',
                                  style: TextStyle(fontSize: 14)),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => priority = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: provider.isLoadingUsers
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : DropdownButtonFormField<int>(
                                value: selectedUserId,
                                decoration: InputDecoration(
                                  labelText: 'Assign to',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Colors.transparent),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: appFontColor, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                ),
                                icon: const Icon(Icons.arrow_drop_down),
                                dropdownColor: Colors.white,
                                isExpanded: true,
                                items: provider.assignableUsers
                                    .map((u) => DropdownMenuItem(
                                          value: u.id,
                                          child: Text(
                                            u.name,
                                            style:
                                                const TextStyle(fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => selectedUserId = val),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: provider.isCreating
                          ? null
                          : () async {
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Name is required')),
                                );
                                return;
                              }

                              // If no user selected, use current user ID
                              int? userIdToAssign = selectedUserId;
                              if (userIdToAssign == null) {
                                final loginData = SharedPref.getLoginData();
                                final uid = loginData.result?.data?.uid;
                                if (uid != null) {
                                  userIdToAssign = uid;
                                }
                              }

                              final msg = await provider.createTask(
                                name: nameController.text.trim(),
                                description: descController.text.trim(),
                                priority: priority,
                                userId: userIdToAssign,
                              );
                              if (context.mounted) {
                                if (msg != null) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(msg)));
                                } else if (provider.errorMessage != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text(provider.errorMessage!)));
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appFontColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: provider.isCreating
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Create Task',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Future<void> _showLinkReportDialog(
      BuildContext context, TasksProvider provider, int taskId) async {
    final reportProvider = context.read<ReportProvider>();

    // Get current task to check linked reports
    final currentTask = provider.tasks.firstWhere((t) => t.id == taskId);

    List<ReportModel> reports = [];
    String? selectedFolderId;
    bool loadingFolders = true;
    bool loadingReports = false;
    String? folderError;

    Future<void> _loadReports(String folderId, StateSetter setState) async {
      setState(() {
        loadingReports = true;
        folderError = null;
      });
      try {
        await reportProvider.fetchAllReports(folderID: folderId);
        reports = List<ReportModel>.from(reportProvider.reports);
      } catch (_) {
        reports = [];
        folderError = 'Failed to load reports. Please try again.';
      } finally {
        setState(() => loadingReports = false);
      }
    }

    Future<void> _loadFolders(StateSetter setState) async {
      setState(() {
        loadingFolders = true;
        folderError = null;
      });
      try {
        await reportProvider.init(base: 'https://erp.elrace.com');
        await reportProvider.fetchAllFolders();
        if (reportProvider.folders.isEmpty) {
          folderError = 'No folders available';
        } else {
          selectedFolderId = reportProvider.folders.first.id;
          await _loadReports(selectedFolderId!, setState);
        }
      } catch (_) {
        folderError = 'Failed to load folders. Please try again.';
      } finally {
        setState(() => loadingFolders = false);
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          // kick off folder loading on first build
          if (loadingFolders &&
              folderError == null &&
              selectedFolderId == null) {
            Future.microtask(() => _loadFolders(setState));
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Link report to task',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (loadingFolders)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(),
                  ))
                else if (folderError != null)
                  Text(folderError!,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w600))
                else if (reportProvider.folders.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedFolderId,
                    items: reportProvider.folders
                        .map((f) => DropdownMenuItem(
                              value: f.id,
                              child: Text(f.name),
                            ))
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Folder',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      if (val == null) return;
                      selectedFolderId = val;
                      _loadReports(val, setState);
                    },
                  )
                else
                  const Text('No folders available'),
                const SizedBox(height: 12),
                if (loadingReports)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(),
                  ))
                else
                  SizedBox(
                    height: 320,
                    child: reports.isEmpty
                        ? const Center(child: Text('No reports in this folder'))
                        : ListView.separated(
                            itemCount: reports.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (_, index) {
                              final report = reports[index];
                              final isAlreadyLinked =
                                  currentTask.reportIds.contains(report.id);
                              return ListTile(
                                title: Text(report.name),
                                subtitle: Text('ID: ${report.id}'),
                                enabled: !isAlreadyLinked,
                                trailing: isAlreadyLinked
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : null,
                                onTap: isAlreadyLinked
                                    ? null
                                    : () async {
                                        final msg = await provider.linkReport(
                                          taskId: taskId,
                                          reportId: report.id,
                                        );
                                        if (context.mounted) {
                                          if (msg != null) {
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(msg)));
                                          } else if (provider.errorMessage !=
                                              null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(provider
                                                        .errorMessage!)));
                                          }
                                        }
                                      },
                              );
                            },
                          ),
                  ),
              ],
            ),
          );
        });
      },
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_outlined,
                  size: 24.w,
                  color: appFontColor,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Tasks',
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
          Expanded(
            child: _buildTasksBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showCreateTaskSheet(context, context.read<TasksProvider>()),
        backgroundColor: appFontColor,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        elevation: 6,
      ),
    );
  }

  Widget _buildTasksBody() {
    return Consumer<TasksProvider>(
      builder: (context, provider, _) {
        switch (provider.status) {
          case TasksStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case TasksStatus.error:
            return _ErrorState(
              message: provider.errorMessage ?? 'Failed to load tasks',
              onRetry: provider.loadTasks,
            );
          case TasksStatus.empty:
            return const _EmptyState();
          case TasksStatus.loaded:
            return RefreshIndicator(
              onRefresh: provider.refreshTasks,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (_, index) {
                  final task = provider.tasks[index];
                  final isCompleting =
                      provider.completingTaskIds.contains(task.id ?? -1);
                  final isLinking =
                      provider.linkingTaskIds.contains(task.id ?? -1);
                  return _TaskTile(
                    task: task,
                    formattedDate: _formatDate(task.createdAt),
                    priorityColor: _priorityColor(task.priority),
                    onComplete: task.id == null
                        ? null
                        : () async {
                            final msg = await provider.completeTask(task.id!);
                            if (context.mounted) {
                              if (msg != null) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text(msg)));
                              } else if (provider.errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(provider.errorMessage!)));
                              }
                            }
                          },
                    onLinkReport: task.id == null
                        ? null
                        : () =>
                            _showLinkReportDialog(context, provider, task.id!),
                    isCompleting: isCompleting,
                    isLinking: isLinking,
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: provider.tasks.length,
              ),
            );
          case TasksStatus.initial:
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  final String formattedDate;
  final Color priorityColor;
  final Future<void> Function()? onComplete;
  final VoidCallback? onLinkReport;
  final bool isCompleting;
  final bool isLinking;

  const _TaskTile({
    required this.task,
    required this.formattedDate,
    required this.priorityColor,
    this.onComplete,
    this.onLinkReport,
    this.isCompleting = false,
    this.isLinking = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(task: task),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
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
                BoxShadow(
                  color: appFontColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            priorityColor,
                            priorityColor.withOpacity(0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: priorityColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.name ?? 'Untitled Task',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: appFontColor,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            priorityColor.withOpacity(0.15),
                            priorityColor.withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: priorityColor.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: priorityColor.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'P${task.priority ?? '-'}',
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if ((task.stage ?? '').isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          appFontColor.withOpacity(0.12),
                          appFontColor.withOpacity(0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: appFontColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_rounded, size: 16, color: appFontColor),
                        const SizedBox(width: 7),
                        Text(
                          task.stage ?? '-',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: appFontColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Icon(Icons.folder_open,
                        size: 16, color: appFontColor.withOpacity(0.6)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task.projectId ?? '-',
                        style: TextStyle(
                          fontSize: 13,
                          color: appFontColor.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.calendar_today,
                        size: 14, color: appFontColor.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: appFontColor.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if ((task.assignedUser ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: appFontColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16, color: appFontColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            task.assignedUser ?? '-',
                            style: TextStyle(
                              fontSize: 13,
                              color: appFontColor.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if ((task.team ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: appFontColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.group, size: 16, color: appFontColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            task.team ?? '-',
                            style: TextStyle(
                              fontSize: 13,
                              color: appFontColor.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if ((task.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      task.description ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: appFontColor.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                if (task.reportIds.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Consumer<ReportProvider>(
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

                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.insert_drive_file,
                                    size: 16, color: Colors.blue.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  'Linked Reports (${parsedReports.length}):',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...parsedReports.map((reportData) {
                              final report = reportProvider.reports.firstWhere(
                                (r) => r.id == reportData.id,
                                orElse: () => ReportModel(
                                  id: reportData.id,
                                  name: reportData.name ??
                                      'Report ${reportData.id}',
                                  companyId: '',
                                  folderId: '',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                ),
                              );

                              return Padding(
                                padding:
                                    const EdgeInsets.only(left: 22, top: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.circle,
                                        size: 6, color: Colors.blue.shade600),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        report.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 14),
                if (task.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade600,
                          Colors.green.shade500,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Task Completed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isCompleting ? null : onComplete,
                          icon: isCompleting
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_outline,
                                  size: 18),
                          label: const Text('Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isLinking ? null : onLinkReport,
                          icon: isLinking
                              ? SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: appFontColor,
                                  ),
                                )
                              : Icon(Icons.link, color: appFontColor),
                          label: Text('Link report',
                              style: TextStyle(color: appFontColor)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                                color: appFontColor.withOpacity(0.5),
                                width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    priorityColor.withOpacity(0.1),
                    priorityColor.withOpacity(0.03),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(60),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: appFontColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.task_outlined,
              size: 64,
              color: appFontColor.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: appFontColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first task to get started',
            style: TextStyle(
              fontSize: 14,
              color: appFontColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 56,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: appFontColor.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: appFontColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
