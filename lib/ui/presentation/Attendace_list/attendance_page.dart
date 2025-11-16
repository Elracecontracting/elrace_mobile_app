import 'dart:convert';
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
    Key? key,
  }) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String _imageBase64 = '';
  late AttendanceBloc _attendanceBloc;
  var _selectedIndex = 0;
  Set<int> expandedItems = {};
  late DateTime selectedStartDate;
  late DateTime selectedEndDate;

  bool _isValidBase64(String str) {
    try {
      if (str.trim().isEmpty || str.length % 4 != 0) return false;
      base64Decode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

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
      // bottomNavigationBar: CustomBottomNavbar(
      //   currentIndex: _selectedIndex,
      //   onItemTapped: _onItemTapped,
      // ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Widget
          const SizedBox(height: 10),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  translate('home.attendance'),
                  style: GoogleFonts.koulen(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: appFontColor,
                    letterSpacing: 1.9, // ⬅️ adjust value as needed
                  ),
                ),
                TextButton(
                  onPressed: () => AttendanceDialogs.showAttendancePopup(context, selectedStartDate, selectedEndDate),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 3,
                      horizontal: 8,
                    ), // Add padding to the button
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // Background color of the button
                      borderRadius:
                          BorderRadius.circular(21), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withAlpha((0.2 * 255).toInt()), // Shadow color
                          blurRadius: 6, // Spread of the shadow
                          offset: const Offset(0, 4), // Shadow offset
                        ),
                      ],
                    ),
                    child: Text(
                      translate('home.report'),
                      style: GoogleFonts.koulen(
                        fontSize: 14,
                        color: appFontColor,
                        letterSpacing: .10, // Adjust as needed
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Date Range Selectors
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async => await _selectDate(context, true),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(
                              (0.2 * 255).toInt()), // Shadow color with opacity
                          blurRadius: 3, // Softness of the shadow
                          spreadRadius: 2, // Spread of the shadow
                          offset:
                              const Offset(0, 4), // Vertical shadow direction
                        ),
                      ],
                    ),
                    child: Text(
                      startDateFormatted,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                const Text(
                  'to',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 15),
                GestureDetector(
                  onTap: () async => await _selectDate(context, false),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(
                              (0.2 * 255).toInt()), // Shadow color with opacity
                          blurRadius: 3, // Softness of the shadow
                          spreadRadius: 2, // Spread of the shadow
                          offset:
                              const Offset(0, 4), // Vertical shadow direction
                        ),
                      ],
                    ),
                    child: Text(
                      endDateFormatted,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Attendance List
          const SizedBox(height: 10),
          Expanded(
            child: BlocBuilder<AttendanceBloc, AttendanceState>(
              bloc: _attendanceBloc,
              builder: (context, state) {
                if (state is AttendanceLoadingState && state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is AttendanceListLoaded) {
                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.attendanceList.length,
                    padding:
                        EdgeInsets.symmetric(horizontal: 15.w, vertical: 30.h),
                    itemBuilder: (context, index) {
                      final AttendanceData item = state.attendanceList[index];
                      final bool isExpanded = expandedItems.contains(index);

                      final checkInTime = DateTime.parse(item.checkIn);
                      DateTime? checkOutTime;
                      if (item.checkOut != null && item.checkOut != false) {
                        checkOutTime = DateTime.parse(item.checkOut!);
                      }

                      // Attendance Status Calculation
                      String status = "ONTIME";
                      String backgroundImage =
                          'assets/png/item_bg_green.png'; // Default
                      Color textColor = Colors.green;

                      if (checkOutTime == null) {
                        status = "ABSENT";
                        backgroundImage = '';
                        textColor = const Color(0xff535353);
                      } else if (item == "SICK") {
                        status = "SICK LEAVE";
                        backgroundImage = 'assets/png/item_bg_yellow.png';
                        textColor = const Color(0xffF9FF46);
                      } else if (item == "ANNUAL") {
                        // الشرط الجديد
                        status = "ANNUAL LEAVE";
                        backgroundImage = '';
                        textColor = const Color(0xff007AFF);
                      } else if (checkInTime.isAfter(DateTime(checkInTime.year,
                          checkInTime.month, checkInTime.day, 8, 15))) {
                        final lateMinutes = checkInTime
                            .difference(DateTime(checkInTime.year,
                                checkInTime.month, checkInTime.day, 8, 15))
                            .inMinutes;
                        status = "$lateMinutes MINS LATE";
                        backgroundImage = 'assets/png/item_bg_red.png';
                        textColor = red;
                      } else {
                        textColor = const Color(0xff535353);
                      }

                      // ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇
                      // else if () {
                      //   status = "SICK LEAVE";
                      //   backgroundImage = 'assets/png/item_bg_yellow.png';
                      //   textColor = const Color(0xffF9FF46);
                      // } else if (){
                      // status = "ANNUAL LEAVE";
                      //   backgroundImage = '';
                      //   textColor = const Color(0xff007AFF);
                      //  }
                      // ⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆⬆

                      Color bgColorStart = const Color(0xFF0F0C29);
                      Color bgColorEnd = const Color(0xFF302B63);

                      return GestureDetector(
                        onTap: () {
                          // setState(() {
                          //   isExpanded
                          //       ? expandedItems.remove(index)
                          //       : expandedItems.add(index);
                          // });

                          setState(() {
                            if (!isExpanded) {
                              Future.delayed(const Duration(milliseconds: 200),
                                  () {
                                expandedItems.add(index);
                                setState(() {});
                              });
                            } else {
                              expandedItems.remove(index);
                            }
                          });
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            isExpanded
                                ? ExpandCard(
                                    status: status,
                                    textColor: textColor,
                                    bgColorStart: bgColorStart,
                                    bgColorEnd: bgColorEnd)
                                : ColleaspedCard(
                                    status: status,
                                    textColor: textColor,
                                    bgColorStart: bgColorStart,
                                    bgColorEnd: bgColorEnd,
                                    isExpanded: isExpanded,
                                    checkInTime: checkInTime,
                                    checkOutTime: checkOutTime,
                                    backgroundImage: backgroundImage),
                            AnimatedAlign(
                              alignment: isExpanded
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeInOut,
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 10.w),
                                key: ValueKey(
                                    isExpanded), // triggers rebuild on expand/collapse
                                width: 53.w,
                                height: 53.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: ClipOval(
                                  child: _isValidBase64(_imageBase64)
                                      ? Image.memory(
                                          base64Decode(_imageBase64),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        )
                                      : Image.asset(
                                          'assets/png/profile_1.png',
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 13),
                  );
                } else if (state is AttendanceErrorState) {
                  return Center(child: Text(state.message));
                }
                return const Center(
                    child: Text("No attendance data available."));
              },
            ),
          ),
        ],
      ),
    );
  }

}

