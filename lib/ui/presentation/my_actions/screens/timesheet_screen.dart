import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/ui/presentation/my_actions/data/my_actions_models.dart';
import 'package:el_race/ui/presentation/my_actions/data/my_actions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  final MyActionsRepository _repo = MyActionsRepository();
  late final Future<List<MyActionItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchByType(MyActionsType.timesheet);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Title Bar with Add Button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'TIME SHEET',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      shape: BoxShape.circle,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // TODO: Add new timesheet
                        },
                        borderRadius: BorderRadius.circular(18.r),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 22.w,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // List
            Expanded(
              child: FutureBuilder<List<MyActionItem>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    );
                  }

                  final items = snapshot.data ?? const <MyActionItem>[];

                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No timesheets found',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9AA0A6),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _TimesheetCard(
                        index: index + 1,
                        name: items[index].employeeName,
                        projectName: items[index].name,
                        client: 'Abu Dhabi Police',
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimesheetCard extends StatelessWidget {
  final int index;
  final String name;
  final String projectName;
  final String client;

  const _TimesheetCard({
    required this.index,
    required this.name,
    required this.projectName,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      height: 100.h,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Stack(
        children: [
          // Background icon
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/png/tsIcon.png',
                width: 120.w,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          // Content
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // TODO: Navigate to timesheet details
              },
              borderRadius: BorderRadius.circular(16.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    // Number
                    Container(
                      width: 28.w,
                      alignment: Alignment.center,
                      child: Text(
                        '$index',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Employee Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              height: 1.2,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6.h),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Project Name: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                                TextSpan(
                                  text: projectName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Client: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                                TextSpan(
                                  text: client,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Arrow
                    Icon(
                      Icons.chevron_right,
                      color: Colors.black,
                      size: 24.w,
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
}
