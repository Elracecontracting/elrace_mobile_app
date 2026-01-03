import 'package:el_race/report_module/core/constants/colors.dart';
import 'package:el_race/report_module/core/constants/text_styles.dart';
import 'package:el_race/ui/presentation/todo_list/data/todo_model.dart';
import 'package:el_race/ui/presentation/todo_list/providers/todo_provider.dart';
import 'package:el_race/ui/presentation/todo_list/screens/todo_category_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// Widget لعرض Tasks المرتبطة بـ Report
class LinkedTasksList extends StatelessWidget {
  final List<TodoModel> tasks;

  const LinkedTasksList({
    super.key,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: CustomColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: CustomColors.maroon.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: CustomColors.maroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.task_alt,
                  color: CustomColors.maroon,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Linked Tasks',
                      style: CustomTextStyle.heading.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${tasks.length} task${tasks.length > 1 ? 's' : ''}',
                      style: CustomTextStyle.reportTitle.copyWith(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _navigateToTasks(context),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: CustomColors.maroon,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),
          Divider(color: Colors.grey[200], height: 1),
          SizedBox(height: 12.h),

          // Tasks List
          ...tasks.take(3).map((task) => Builder(
                builder: (context) => _buildTaskItem(context, task),
              )),

          // Show more indicator
          if (tasks.length > 3)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Center(
                child: TextButton(
                  onPressed: () => _navigateToTasks(context),
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${tasks.length - 3} more tasks',
                        style: TextStyle(
                          color: CustomColors.maroon,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12.sp,
                        color: CustomColors.maroon,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, TodoModel task) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToTasks(context),
          borderRadius: BorderRadius.circular(12.r),
          child: Ink(
            decoration: BoxDecoration(
              color: task.isCompleted
                  ? Colors.grey[100]
                  : CustomColors.maroon.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: task.isCompleted
                    ? Colors.grey[300]!
                    : CustomColors.maroon.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  // Checkbox
                  Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted
                            ? Colors.green
                            : CustomColors.maroon,
                        width: 2,
                      ),
                      color:
                          task.isCompleted ? Colors.green : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? Icon(
                            Icons.check,
                            size: 14.sp,
                            color: Colors.white,
                          )
                        : null,
                  ),

                  SizedBox(width: 12.w),

                  // Task Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: CustomTextStyle.reportTitle.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: task.isCompleted
                                ? Colors.grey[600]
                                : CustomColors.black,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.dueDate != null) ...[
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12.sp,
                                color: _isOverdue(task.dueDate!)
                                    ? Colors.red
                                    : Colors.grey[600],
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                DateFormat('dd MMM yyyy').format(task.dueDate!),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: _isOverdue(task.dueDate!)
                                      ? Colors.red
                                      : Colors.grey[600],
                                  fontWeight: _isOverdue(task.dueDate!)
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Important Star
                  if (task.isImportant)
                    Icon(
                      Icons.star,
                      size: 18.sp,
                      color: CustomColors.maroon,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now()) &&
        !DateUtils.isSameDay(dueDate, DateTime.now());
  }

  void _navigateToTasks(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TodoCategoryScreen(
          filter: TodoFilter.tasks,
          title: 'Tasks',
        ),
      ),
    );
  }
}
