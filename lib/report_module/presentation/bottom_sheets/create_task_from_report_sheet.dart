import 'package:el_race/report_module/core/constants/colors.dart';
import 'package:el_race/report_module/core/constants/text_styles.dart';
import 'package:el_race/report_module/data/models/report_detail_model.dart';
import 'package:el_race/ui/presentation/todo_list/providers/todo_provider.dart';
import 'package:el_race/ui/presentation/todo_list/screens/todo_category_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Bottom sheet لإنشاء Task من Report مع pre-filled data
/// UX: سهل، واضح، وسريع
class CreateTaskFromReportSheet extends StatefulWidget {
  final ReportDetailModel reportDetail;

  const CreateTaskFromReportSheet({
    super.key,
    required this.reportDetail,
  });

  @override
  State<CreateTaskFromReportSheet> createState() =>
      _CreateTaskFromReportSheetState();
}

class _CreateTaskFromReportSheetState extends State<CreateTaskFromReportSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isImportant = false;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Pre-fill title with report name
    _titleController = TextEditingController(
      text: widget.reportDetail.report.name,
    );

    // Pre-fill description with report info
    _descriptionController = TextEditingController(
      text: _generateDescriptionFromReport(),
    );
  }

  String _generateDescriptionFromReport() {
    final buffer = StringBuffer();
    buffer.writeln('📋 Report: ${widget.reportDetail.report.name}');
    buffer.writeln(
        '📅 Created: ${DateFormat('dd MMM yyyy, HH:mm').format(widget.reportDetail.report.createdAt)}');
    buffer.writeln();

    // Add report items summary
    if (widget.reportDetail.reportItems.isNotEmpty) {
      buffer.writeln(
          '📸 Report Items (${widget.reportDetail.reportItems.length}):');
      int imageCount = 0;
      int textCount = 0;
      int locationCount = 0;

      for (var item in widget.reportDetail.reportItems) {
        if (item.type == 'image') imageCount++;
        if (item.type == 'text') textCount++;
        if (item.type == 'location') locationCount++;
      }

      if (imageCount > 0) buffer.writeln('  • Images: $imageCount');
      if (textCount > 0) buffer.writeln('  • Text notes: $textCount');
      if (locationCount > 0) buffer.writeln('  • Locations: $locationCount');
      buffer.writeln();
    }

    // Add cover page info if exists
    if (widget.reportDetail.coverPage != null) {
      buffer.writeln('📄 Has cover page');
      buffer.writeln();
    }

    buffer.writeln('🔗 Linked to Report ID: ${widget.reportDetail.report.id}');

    return buffer.toString();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: CustomColors.maroon,
              onPrimary: CustomColors.white,
              surface: CustomColors.white,
              onSurface: CustomColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _createTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    final task = await todoProvider.createTaskFromReport(
      reportId: widget.reportDetail.report.id,
      reportName: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      isImportant: _isImportant,
      dueDate: _dueDate,
    );

    setState(() {
      _isLoading = false;
    });

    if (task != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Task created successfully!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to Todo List
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TodoCategoryScreen(
                    filter: TodoFilter.tasks,
                    title: 'Tasks',
                  ),
                ),
              );
            },
          ),
        ),
      );
      Navigator.pop(context, true); // Return true to indicate success
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create task'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      decoration: BoxDecoration(
        color: CustomColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.task_alt,
                  color: CustomColors.maroon,
                  size: 28.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Create Task from Report',
                    style: CustomTextStyle.heading.copyWith(fontSize: 18.sp),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 24.sp),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Title Field
            Text(
              'Task Title',
              style: CustomTextStyle.reportTitle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter task title',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: CustomColors.maroon, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
              ),
              style: CustomTextStyle.reportTitle,
            ),

            SizedBox(height: 16.h),

            // Description Field
            Text(
              'Description',
              style: CustomTextStyle.reportTitle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _descriptionController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Task description (auto-generated from report)',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: CustomColors.maroon, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
              ),
              style: CustomTextStyle.reportTitle.copyWith(fontSize: 13.sp),
            ),

            SizedBox(height: 16.h),

            // Options Row
            Row(
              children: [
                // Important Toggle
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isImportant = !_isImportant;
                      });
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: _isImportant
                            ? CustomColors.maroon.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: _isImportant
                              ? CustomColors.maroon
                              : Colors.grey[300]!,
                          width: _isImportant ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isImportant ? Icons.star : Icons.star_border,
                            color: _isImportant
                                ? CustomColors.maroon
                                : Colors.grey[600],
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Important',
                            style: CustomTextStyle.reportTitle.copyWith(
                              fontSize: 13.sp,
                              color: _isImportant
                                  ? CustomColors.maroon
                                  : Colors.grey[700],
                              fontWeight: _isImportant
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // Due Date Picker
                Expanded(
                  child: InkWell(
                    onTap: _selectDueDate,
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: _dueDate != null
                            ? CustomColors.maroon.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: _dueDate != null
                              ? CustomColors.maroon
                              : Colors.grey[300]!,
                          width: _dueDate != null ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: _dueDate != null
                                ? CustomColors.maroon
                                : Colors.grey[600],
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              _dueDate != null
                                  ? DateFormat('dd MMM').format(_dueDate!)
                                  : 'Due Date',
                              style: CustomTextStyle.reportTitle.copyWith(
                                fontSize: 13.sp,
                                color: _dueDate != null
                                    ? CustomColors.maroon
                                    : Colors.grey[700],
                                fontWeight: _dueDate != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Clear due date button
            if (_dueDate != null)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _dueDate = null;
                    });
                  },
                  icon: Icon(Icons.clear, size: 16.sp),
                  label: const Text('Clear due date'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                  ),
                ),
              ),

            SizedBox(height: 24.h),

            // Create Task Button
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.maroon,
                  foregroundColor: CustomColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 24.h,
                        width: 24.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Create Task',
                        style: CustomTextStyle.reportTitle.copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: CustomColors.white,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}
