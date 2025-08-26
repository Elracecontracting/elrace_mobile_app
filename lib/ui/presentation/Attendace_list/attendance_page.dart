import 'dart:convert';
import 'dart:developer';
import 'package:el_race/ui/presentation/Attendace_list/model/attendance_model.dart'; // Import the login model
import 'package:el_race/ui/presentation/Attendace_list/repository/attendance_repository.dart';
import 'package:el_race/utils/color_utils.dart'; // Import global colors
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
                  'MY ATTENDANCE',
                  style: GoogleFonts.koulen(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: appFontColor,
                    letterSpacing: 1.9, // ⬅️ adjust value as needed
                  ),
                ),
                TextButton(
                  onPressed: () => _showAttendancePopup(context),
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
                      'Report',
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
                                ? Container(
                                    key: const ValueKey("expanded"),
                                    height: 70.w,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                          colors: [bgColorStart, bgColorEnd]),
                                      borderRadius: BorderRadius.circular(30),
                                      // boxShadow: [
                                      //   BoxShadow(
                                      //     color: bgColorEnd
                                      //         .withAlpha((0.3 * 255).toInt()),
                                      //     blurRadius: 6,
                                      //     spreadRadius: 1,
                                      //     offset: const Offset(0, 4),
                                      //   )
                                      // ],
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 11,
                                        ),
                                      
                                        const Spacer(),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const Spacer(),
                                      ],
                                    ),
                                  )
                                : Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      if (backgroundImage != '' && !isExpanded)
                                        Container(
                                          width: 70.w,
                                          height: 71.w,
                                          margin: const EdgeInsets.only(top: 3,),
                                          decoration: BoxDecoration(
                                            color: textColor,
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                        ),
                                      Container(
                                        height: 70.w,
                                        key: const ValueKey("collapsed"),
                                        padding:EdgeInsets.symmetric(horizontal: 10.w),
                                        margin: EdgeInsets.only(left: 4.w, top: 3),
                                        decoration: backgroundImage == ''
                                            ? BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              )
                                            : BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFFD6D6D6), Color(0xFFADB2BD)],
                                                  begin: Alignment.bottomRight,
                                                  end: Alignment.topLeft,
                                                ),
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                        child: Row(
                                          children: [
                                            // Date
                                            SizedBox(
                                              width: 80,
                                              child: Text(
                                                DateFormat('dd MMM yy')
                                                    .format(checkInTime),
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.inter(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: appFontColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 39.5,
                                              child: VerticalDivider(
                                                  color: Colors.grey, thickness: 1),
                                            ),
                            
                                            // Check-in
                                            SizedBox(
                                              width: 90.w,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Check-in',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: appFontColor,
                                                    ),
                                                  ),
                                                  Text(
                                                    DateFormat('HH:mm:ss')
                                                        .format(checkInTime),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                           
                            
                                            // Check-out
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Check-out',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: appFontColor,
                                                    ),
                                                  ),
                                                  Text(
                                                    checkOutTime != null
                                                        ? DateFormat('HH:mm:ss')
                                                            .format(checkOutTime)
                                                        : '--:--:--',
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 40.w), 

                                           
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                 
                            AnimatedAlign(
                              alignment:
                                  isExpanded ? Alignment.centerLeft : Alignment.centerRight,
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeInOut,
                              child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 10.w),
                                  key: ValueKey( isExpanded), // triggers rebuild on expand/collapse
                                  width: 50.w,
                                  height: 50.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white,
                                        width: 2),
                                  ),
                                  child: ClipOval(
                                    child: _isValidBase64(
                                            _imageBase64)
                                        ? Image.memory(
                                            base64Decode(
                                                _imageBase64),
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

  void _showAttendancePopup(BuildContext context) async {
    final startDateStr = DateFormat('yyyy-MM-dd').format(selectedStartDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(selectedEndDate);

    try {
      final summaryData = await AttendanceRepo().getAttendanceSummary(
        startDate: startDateStr,
        endDate: endDateStr,
      );

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFFD9D9D9),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 26, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "ATTENDANCE REPORT",
                    style: GoogleFonts.koulen(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5, // Adjust as needed
                      color: appFontColor,
                    ),
                  ),
                  Text(
                    DateFormat('MMM yyyy').format(selectedEndDate),
                    style: GoogleFonts.koulen(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: appFontColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildReportItem("Working Days",
                      "${summaryData['working_days']} Days", Colors.green),
                  const Divider(color: Colors.grey, thickness: 0.5),
                  _buildReportItem("Late Hours",
                      "${summaryData['late_hours']} min", Colors.red),
                  const Divider(color: Colors.grey, thickness: 0.5),
                  _buildReportItem("Absent",
                      "${summaryData['absent_days']} Days", Colors.black),
                  const Divider(color: Colors.grey, thickness: 0.5),
                  _buildReportItem("Sick Leave",
                      "${summaryData['sick_leaves']} Days", Colors.orange),
                  const Divider(color: Colors.grey, thickness: 0.5),
                  _buildReportItem("Annual Leave",
                      "${summaryData['annual_leaves']} Days", Colors.blue),
                  const Divider(color: Colors.grey, thickness: 0.5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close",
                          style: TextStyle(color: appFontColor, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      log("Failed to fetch summary: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to load report")));
    }
  }

  Widget _buildReportItem(String title, String value, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(value,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}



class BouncingIconToggle extends StatefulWidget {
  final IconData icon;
  final bool isExpanded;
  final ValueChanged<bool> onToggle;

  const BouncingIconToggle({
    Key? key,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<BouncingIconToggle> createState() => _BouncingIconToggleState();
}

class _BouncingIconToggleState extends State<BouncingIconToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _setAnimation();
  }

  void _setAnimation() {
    final double bounceAmount = 10; // how far it bounces
    final double start = widget.isExpanded ? 0.0 : 0.0;
    final double peak =
        widget.isExpanded ? -bounceAmount : bounceAmount; // direction
    final double end = widget.isExpanded ? bounceAmount : -bounceAmount;

    _offsetAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: start, end: peak)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: peak, end: end)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  void _handleTap() {
    _setAnimation();
    _controller.forward(from: 0).whenComplete(() {
      widget.onToggle(!widget.isExpanded);
    });
  }

  @override
  void didUpdateWidget(covariant BouncingIconToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _offsetAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_offsetAnimation.value, 0),
            child: Icon(widget.icon, size: 28),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
