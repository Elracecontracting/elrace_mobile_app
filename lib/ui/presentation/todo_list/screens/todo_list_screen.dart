import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/png/todo_icon.png',
                        height: 30.w,
                        width: 30.w,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.check_box,
                          size: 30.w,
                          color: appFontColor,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        translate('home.todo_list'),
                        style: GoogleFonts.koulen(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w500,
                          color: appFontColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 51.w), // Balance spacing
            ],
          ),
          // Content
          Expanded(
            child: Center(
              child: Text(
                'TO DO List - Coming Soon',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
