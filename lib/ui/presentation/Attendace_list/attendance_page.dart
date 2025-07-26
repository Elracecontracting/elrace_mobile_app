import 'dart:developer';

import 'package:el_race/ui/presentation/Attendace_list/repository/attendance_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'bloc/attendance_bloc.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart'; // Import the login model
import '../../widgets/header_widget.dart';
import 'package:el_race/ui/presentation/Attendace_list/model/attendance_model.dart'; // Import the login model
import 'package:el_race/utils/color_utils.dart'; // Import global colors


class AttendancePage extends StatefulWidget {
  const AttendancePage({Key? key,}) : super(key: key);

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
    String startDateFormatted = DateFormat('MM/dd/yyyy').format(selectedStartDate);
    String endDateFormatted = DateFormat('MM/dd/yyyy').format(selectedEndDate);

    return Scaffold(
      backgroundColor: Colors.white,
      // bottomNavigationBar: CustomBottomNavbar(
      //   currentIndex: _selectedIndex,
      //   onItemTapped: _onItemTapped,
      // ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Widget
          const HeaderWidget(),

          const SizedBox(height: 20),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: appFontColor,
                    letterSpacing: 1.9, // ⬅️ adjust value as needed
                  ),
                ),


                TextButton(
                  onPressed: () {
                    _showAttendancePopup(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8), // Add padding to the button
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // Background color of the button
                      borderRadius: BorderRadius.circular(20), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.2 * 255).toInt()), // Shadow color
                          blurRadius: 6, // Spread of the shadow
                          offset: const Offset(0, 4), // Shadow offset
                        ),
                      ],
                    ),
                    child: Text(
                      'Report',
                      style: GoogleFonts.koulen(
                        fontSize: 12,
                        color: appFontColor,
                        letterSpacing: 1.0, // Adjust as needed
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
                  onTap: () async {
                    await _selectDate(context, true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.2 * 255).toInt()), // Shadow color with opacity
                          blurRadius: 3, // Softness of the shadow
                          spreadRadius: 2, // Spread of the shadow
                          offset: const Offset(0, 4), // Vertical shadow direction
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
                  onTap: () async {
                    await _selectDate(context, false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.2 * 255).toInt()), // Shadow color with opacity
                          blurRadius: 3, // Softness of the shadow
                          spreadRadius: 2, // Spread of the shadow
                          offset: const Offset(0, 4), // Vertical shadow direction
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
                  return ListView.builder(
                    itemCount: state.attendanceList.length,
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
                      String backgroundImage = 'assets/png/item_bg_green.png'; // Default
                      Color textColor = Colors.white;

                      if (checkOutTime == null) {
                        status = "ABSENT";
                        backgroundImage = 'assets/png/item_bg_red.png';
                        textColor = Colors.white;
                      } else if (checkInTime.isAfter(DateTime(checkInTime.year, checkInTime.month, checkInTime.day, 8, 15))) {
                        final lateMinutes = checkInTime.difference(DateTime(checkInTime.year, checkInTime.month, checkInTime.day, 8, 15)).inMinutes;
                        status = "$lateMinutes MINS LATE";
                        backgroundImage = 'assets/png/item_bg_yellow.png';
                        textColor = Colors.red;
                      }

                      Color bgColorStart = const Color(0xFF0F0C29);
                      Color bgColorEnd = const Color(0xFF302B63);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpanded ? expandedItems.remove(index) : expandedItems.add(index);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 100),
                            switchInCurve: Curves.easeOutExpo,
                            transitionBuilder: (child, animation) {
                              final offsetAnimation = Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(animation);
                              return SlideTransition(position: offsetAnimation, child: child);
                            },
                            child: isExpanded
                                ? Container(
                              key: const ValueKey("expanded"),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [bgColorStart, bgColorEnd]),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: bgColorEnd.withAlpha((0.3 * 255).toInt()),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            )
                                : Container(
                              key: const ValueKey("collapsed"),
                              padding: const EdgeInsets.fromLTRB(15, 8, 8, 11),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(backgroundImage),
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha((0.08 * 255).toInt()),
                                    blurRadius: 4,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Date
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      DateFormat('dd MMM yy').format(checkInTime),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: appFontColor,
                                      ),
                                    ),

                                  ),
                                  const SizedBox(width: 0),
                                  const SizedBox(
                                    height: 30,
                                    child: VerticalDivider(color: Colors.grey, thickness: 2),
                                  ),
                                  const SizedBox(width: 5),

                                  // Check-in
                                  SizedBox(
                                    width: 100,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
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
                                          DateFormat('HH:mm:ss').format(checkInTime),
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
                                  const SizedBox(
                                    height: 30,
                                    child: VerticalDivider(color: Colors.grey, thickness: 2),
                                  ),
                                  const SizedBox(width: 0),

                                  // Check-out
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
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
                                              ? DateFormat('HH:mm:ss').format(checkOutTime)
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
                                ],
                              ),
                            ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  _buildReportItem("Working Days", "${summaryData['working_days']} Days", Colors.green),
                  const Divider(color: Colors.grey, thickness: 0.5),
                  _buildReportItem("Late Hours", "${summaryData['late_hours']} min", Colors.red),
                  const Divider(color: Colors.grey, thickness: 0.5),
                  _buildReportItem("Absent", "${summaryData['absent_days']} Days", Colors.black),
                  const Divider(color: Colors.grey, thickness: 0.5),
                  _buildReportItem("Sick Leave", "${summaryData['sick_leaves']} Days", Colors.orange),
                  const Divider(color: Colors.grey, thickness: 0.5),
                  _buildReportItem("Annual Leave", "${summaryData['annual_leaves']} Days", Colors.blue),
                  const Divider(color: Colors.grey, thickness: 0.5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close", style: TextStyle(color: appFontColor, fontSize: 12)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to load report")));
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

              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),

              const SizedBox(width: 8),

              Text(title, style: const TextStyle(fontSize: 11,fontWeight: FontWeight.bold)),

            ],

          ),

          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),

        ],

      ),

    );

  }
}
