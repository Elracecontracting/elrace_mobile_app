import 'package:el_race/ui/presentation/Attendace_list/attendance_widgets/colleasped_card.dart';
import 'package:el_race/ui/presentation/Attendace_list/attendance_widgets/expand_card.dart';
import 'package:el_race/ui/presentation/Attendace_list/attendance_widgets/report_dialog.dart';
import 'package:el_race/ui/presentation/Attendace_list/model/attendance_model.dart'; // Import the logi
import 'package:el_race/utils/color_utils.dart'; // Import global colors
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../widgets/header_widget.dart';
import 'bloc/attendance_bloc.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({
    super.key,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late AttendanceBloc _attendanceBloc;
  var _selectedIndex = 0;
  Set<int> expandedItems = {};
  late DateTime selectedStartDate;
  late DateTime selectedEndDate;

  @override
  void initState() {
    super.initState();

    // Set date range to 7 days prior to today
    selectedEndDate = DateTime.now();
    selectedStartDate = selectedEndDate.subtract(const Duration(days: 7));

    _attendanceBloc = AttendanceBloc();

    // Dispatch API call with proper date range
    _attendanceBloc.add(GetAttendanceListET(
      startDate: DateFormat('yyyy-MM-dd').format(selectedStartDate),
      endDate: DateFormat('yyyy-MM-dd').format(selectedEndDate),
    ));
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime picked = await showDatePicker(
          context: context,
          initialDate: isStartDate ? selectedStartDate : selectedEndDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        ) ??
        DateTime.now();

    setState(() {
      if (isStartDate) {
        selectedStartDate = picked;
      } else {
        selectedEndDate = picked;
      }
    });

    // Trigger API call after selection
    _attendanceBloc.add(GetAttendanceListET(
      startDate: DateFormat('yyyy-MM-dd').format(selectedStartDate),
      endDate: DateFormat('yyyy-MM-dd').format(selectedEndDate),
    ));
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    String startDateFormatted =
        DateFormat('MM/dd/yyyy').format(selectedStartDate);
    String endDateFormatted = DateFormat('MM/dd/yyyy').format(selectedEndDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        bloc: _attendanceBloc,
        builder: (context, state) {
          if (state is AttendanceLoadingState && state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AttendanceListLoaded) {
            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: state.attendanceList.length + 1,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemBuilder: (context, index) {
                // Header as first item
                if (index == 0) {
                  return Column(
                    children: [
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 48),
                          Text(
                            translate('home.attendance'),
                            style: GoogleFonts.koulen(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: appFontColor,
                              letterSpacing: 1.9,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                AttendanceDialogs.showAttendancePopup(context,
                                    selectedStartDate, selectedEndDate),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 3,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(21),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withAlpha((0.2 * 255).toInt()),
                                    blurRadius: 6,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                translate('home.report'),
                                style: GoogleFonts.koulen(
                                  fontSize: 14,
                                  color: appFontColor,
                                  letterSpacing: .10,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }

                // Attendance items
                final itemIndex = index - 1;
                final AttendanceData item = state.attendanceList[itemIndex];
                final bool isExpanded = expandedItems.contains(itemIndex);

                // Parse check-in/out times (format: "2026-02-02 10:23")
                final checkInTime = DateTime.parse(item.checkIn.replaceAll(' ', 'T'));
                DateTime? checkOutTime;
                if (item.checkOut != null && item.checkOut != false && item.checkOut.toString().isNotEmpty) {
                  try {
                    checkOutTime = DateTime.parse(item.checkOut.toString().replaceAll(' ', 'T'));
                  } catch (e) {
                    checkOutTime = null;
                  }
                }

                // Attendance Status Calculation
                String status = "ONTIME";
                String backgroundImage =
                    'assets/png/item_bg_green.png'; // Default
                Color textColor = Colors.green;

                if (checkOutTime == null || item.isOpen) {
                  status = "OPEN";
                  backgroundImage = '';
                  textColor = const Color(0xff535353);
                } else if (checkInTime.isAfter(DateTime(checkInTime.year,
                    checkInTime.month, checkInTime.day, 8, 15))) {
                  final lateMinutes = checkInTime
                      .difference(DateTime(checkInTime.year, checkInTime.month,
                          checkInTime.day, 8, 15))
                      .inMinutes;
                  status = "$lateMinutes MINS LATE";
                  backgroundImage = 'assets/png/item_bg_red.png';
                  textColor = red;
                } else {
                  textColor = const Color(0xff535353);
                }

                Color bgColorStart = const Color(0xFF0F0C29);
                Color bgColorEnd = const Color(0xFF302B63);

                return Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        itemIndex < state.attendanceList.length - 1 ? 4 : 20,
                    left: itemIndex == 0 ? 0 : 0,
                    right: 0,
                    top: itemIndex == 0 ? 0 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (!isExpanded) {
                        expandedItems.add(itemIndex);
                      } else {
                        expandedItems.remove(itemIndex);
                      }
                      setState(() {});
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: isExpanded
                              ? ExpandCard(
                                  key: ValueKey('expanded_$itemIndex'),
                                  status: status,
                                  textColor: textColor,
                                  bgColorStart: bgColorStart,
                                  bgColorEnd: bgColorEnd,
                                  employeeName: item.employeeName,
                                  employeeImageUrl: item.employeeImageUrl)
                              : ColleaspedCard(
                                  key: ValueKey('collapsed_$itemIndex'),
                                  status: status,
                                  textColor: textColor,
                                  bgColorStart: bgColorStart,
                                  bgColorEnd: bgColorEnd,
                                  isExpanded: isExpanded,
                                  checkInTime: checkInTime,
                                  checkOutTime: checkOutTime,
                                  backgroundImage: backgroundImage,
                                  employeeName: item.employeeName,
                                  employeeImageUrl: item.employeeImageUrl),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (state is AttendanceErrorState) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text("No attendance data available."));
        },
      ),
    );
  }
}
