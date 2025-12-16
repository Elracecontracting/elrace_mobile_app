import 'package:el_race/ui/presentation/todo_list/data/todo_model.dart';
import 'package:el_race/ui/presentation/todo_list/providers/todo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddTodoBottomSheet extends StatefulWidget {
  final TodoFilter filter;
  final int? listId;
  final TodoModel? todo;

  const AddTodoBottomSheet({
    super.key,
    required this.filter,
    this.listId,
    this.todo,
  });

  @override
  State<AddTodoBottomSheet> createState() => _AddTodoBottomSheetState();
}

class _AddTodoBottomSheetState extends State<AddTodoBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late bool _isImportant;
  late bool _isMyDay;
  DateTime? _dueDate;
  bool _isLoading = false;

  bool get isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.todo?.description ?? '');
    _isImportant =
        widget.todo?.isImportant ?? widget.filter == TodoFilter.important;
    _isMyDay = widget.todo?.isMyDay ?? widget.filter == TodoFilter.myDay;
    _dueDate = widget.todo?.dueDate;

    // If coming from planned, set due date to today by default
    if (widget.filter == TodoFilter.planned && _dueDate == null && !isEditing) {
      _dueDate = DateTime.now();
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              // Title
              Text(
                isEditing
                    ? translate('todo.edit_task')
                    : translate('todo.add_task'),
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A53),
                ),
              ),
              SizedBox(height: 20.h),
              // Task title input
              TextField(
                controller: _titleController,
                autofocus: !isEditing,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: translate('todo.task_title_hint'),
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF1A1A53),
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  color: const Color(0xFF1A1A53),
                ),
              ),
              SizedBox(height: 16.h),
              // Description input
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: translate('todo.description_hint'),
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF1A1A53),
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 20.h),
              // Options
              Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: [
                  // My Day Toggle
                  _buildOptionChip(
                    icon: Icons.wb_sunny_outlined,
                    label: translate('todo.my_day'),
                    isSelected: _isMyDay,
                    onTap: () => setState(() => _isMyDay = !_isMyDay),
                  ),
                  // Important Toggle
                  _buildOptionChip(
                    icon: Icons.star_border,
                    label: translate('todo.important'),
                    isSelected: _isImportant,
                    selectedColor: const Color(0xFFFFB800),
                    onTap: () => setState(() => _isImportant = !_isImportant),
                  ),
                  // Due Date
                  _buildOptionChip(
                    icon: Icons.calendar_today_outlined,
                    label: _dueDate != null
                        ? DateFormat('MMM d, yyyy').format(_dueDate!)
                        : translate('todo.due_date'),
                    isSelected: _dueDate != null,
                    onTap: _selectDueDate,
                    onLongPress: _dueDate != null
                        ? () => setState(() => _dueDate = null)
                        : null,
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              // Action buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        translate('common.cancel'),
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Save button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveTodo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A53),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isEditing
                                  ? translate('common.save')
                                  : translate('todo.add_task'),
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              // Delete button (only for editing)
              if (isEditing) ...[
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _deleteTodo,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text(
                      translate('common.delete'),
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Color selectedColor = const Color(0xFF2196F3),
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18.w,
              color: isSelected ? selectedColor : Colors.grey.shade600,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? selectedColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A1A53),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A53),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _saveTodo() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translate('todo.title_required')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<TodoProvider>();
    bool success;

    if (isEditing) {
      final updatedTodo = widget.todo!.copyWith(
        title: title,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isImportant: _isImportant,
        isMyDay: _isMyDay,
        dueDate: _dueDate,
        updatedAt: DateTime.now(),
      );
      success = await provider.updateTodo(updatedTodo);
    } else {
      final newTodo = await provider.addTodo(
        title: title,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isImportant: _isImportant,
        isMyDay: _isMyDay,
        dueDate: _dueDate,
        listId: widget.listId,
      );
      success = newTodo != null;
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteTodo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate('todo.delete_task')),
        content: Text(translate('todo.delete_task_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(translate('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              translate('common.delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<TodoProvider>().deleteTodo(widget.todo!.id!);
      if (mounted) Navigator.pop(context);
    }
  }
}
