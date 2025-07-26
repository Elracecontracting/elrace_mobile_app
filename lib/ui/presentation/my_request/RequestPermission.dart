import 'package:el_race/core/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:el_race/utils/color_utils.dart'; // Import global colors
import '../../widgets/custom_slider_button.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_translate/flutter_translate.dart';

class RequestPermission extends StatefulWidget {
  final dynamic loginResponseModel;

  const RequestPermission({Key? key, required this.loginResponseModel}) : super(key: key);

  @override
  _RequestPermissionState createState() => _RequestPermissionState();
}


class _RequestPermissionState extends State<RequestPermission> {
  String selectedReason = "New hire";
  DateTime selectedStartDate = DateTime.now();
  DateTime selectedEndDate = DateTime.now();
  DateTime joinedDate = DateTime.now();
  DateTime leaveEndDate = DateTime.now();
  String description = '';
  String selectedDay = 'Today';
  final GlobalKey<CustomSliderButtonState> _sliderKey = GlobalKey<CustomSliderButtonState>();

  // Add missing time variables
  String startTimeFormatted = 'Select Time';
  String endTimeFormatted = 'Select Time';

  Future<void> _selectDate(BuildContext context, bool isJoinedDate) async {
    DateTime initialDate = isJoinedDate ? joinedDate : leaveEndDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isJoinedDate) {
          joinedDate = picked;
        } else {
          leaveEndDate = picked;
        }
      });
    }
  }

  int calculateLateDays() {
    return leaveEndDate.difference(joinedDate).inDays;
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          startTimeFormatted = picked.format(context);
        } else {
          endTimeFormatted = picked.format(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          Container(
            color: Colors.black, // Dark background
            child: Column(
              children: [
                const SizedBox(height: 60),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((0.1 * 255).toInt()),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Title Bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  Center(
                                    child: Image.asset(
                                      'assets/png/temporary.png',
                                      width: 200,
                                      height: 60,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 40),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 10),

                                  // Date row
                                  const SizedBox(height: 10),
                                  Text(
                                    "SELECT DATE",
                                    style: GoogleFonts.koulen(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.9,
                                      color: appFontColor,
                                    ),
                                  ),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Radio(
                                        value: 'Today',
                                        groupValue: selectedDay,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedDay = value.toString();
                                            _updateDateBasedOnRadio();
                                          });
                                        },
                                      ),
                                      Text(
                                        'Today',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Radio(
                                        value: 'Tomorrow',
                                        groupValue: selectedDay,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedDay = value.toString();
                                            _updateDateBasedOnRadio();
                                          });
                                        },
                                      ),
                                      Text(
                                        translate('request_permission.tomorrow'),
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        translate('request_permission.date'),
                                        style: GoogleFonts.koulen(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 1.9,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          DateFormat('dd/MM/yyyy').format(joinedDate),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),

                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 25),

                                  // Balance Leave
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,

                                    children: [
                                      Text(
                                        translate('common.balance_leave'),
                                        style: GoogleFonts.koulen(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 1.9,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        "20",
                                        style: GoogleFonts.koulen(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: 1.9,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],

                                  ),

                                  const SizedBox(height: 30),

                                  Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        translate('common.description'),
                                        style: GoogleFonts.koulen(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFFB0B0B0),
                                          letterSpacing: 2.2,
                                        ),
                                      ),
                                    ),
                                  ),


                                  const SizedBox(height: 10),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(18),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                                                spreadRadius: 1,
                                                blurRadius: 5,
                                                offset: const Offset(2, 3),
                                              ),
                                            ],
                                            image: const DecorationImage(
                                              image: AssetImage('assets/png/desc_box.png'),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          child: TextField(
                                            maxLines: 2,
                                            onChanged: (value) => setState(() => description = value),
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(22),
                                                borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(22),
                                                borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(22),
                                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                                              ),
                                              filled: true,
                                              fillColor: Colors.transparent,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 6,
                                          right: 10,
                                          child: Column(
                                            children: [
                                              Text(
                                                '${description.trim().isEmpty ? 1 : description.trim().split(RegExp(r'\s+')).length}/50',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(translate('request_permission.max_words'), style: const TextStyle(fontSize: 10, color: Colors.black)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Notice
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Image.asset('assets/png/notice_icon.png', width: 34, height: 34),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'Please be aware that temporary permission request is deducted from your balance.',
                                          style: GoogleFonts.inter(
                                            color: appFontColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Submit
                                  CustomSliderButton(
                                    key: _sliderKey,
                                    onSlideComplete: _submitTempPermissionRequest,
                                    loginResponseModel: widget.loginResponseModel,
                                  ),

                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ❌ Floating close button
          Positioned(
            top: 56,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.3 * 255).toInt()),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.close, size: 20, color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTempPermissionRequest() async {
    try {
      final token = SharedPref.getLoginData().result?.token;

      // Extract hour in 24-hour format
      String parseTime(String time) {
        try {
          final format = DateFormat.jm(); // e.g., 1:00 PM
          final dateTime = format.parse(time);
          return DateFormat.H().format(dateTime); // returns hour in 24-hour format as string
        } catch (e) {
          return ""; // fallback if time is "Select Time" or invalid
        }
      }

      final response = await http.post(
        Uri.parse('https://test.elrace.com/api/submit_request'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "params": {
            "request_type": "temp_permission",
            "leave_type": null,
            "joined_date": null,
            "start_date": DateFormat('yyyy-MM-dd').format(joinedDate),
            "duration": null,
            "end_date": null,
            "description": description,
            "note": description,
            "job_type": null,
            "job_time": null,
            "job_date": null,
            "e_reason": null,
            "join_date": null,
            "late_days": null,
            "attachment": null,
            "client_details": null,
            "project_details": null,
            "duration_type": "custom_hours",
            "hour_from": parseTime(startTimeFormatted),
            "hour_to": parseTime(endTimeFormatted),
          }
        }),
      );


      final data = jsonDecode(response.body);
      print("🔥 Submitting Body:\n${jsonEncode(data)}"); // Log the full body

      if (response.statusCode == 200 && data["result"]?['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request submitted successfully!")),
        );
        Navigator.pop(context, true); // ✅ Go back to MyRequestsPage with refresh flag

      } else {
        _sliderKey.currentState?.resetSlider(); // 👈 Reset the slider position
        _showErrorDialog(data["result"]?['message'] ?? "Request failed");
      }

    } catch (e) {
      _sliderKey.currentState?.resetSlider(); // 👈 Reset the slider position
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }




  @override
  void initState() {
    super.initState();
    _updateDateBasedOnRadio(); // initialize selected date
  }

  void _updateDateBasedOnRadio() {
    setState(() {
      joinedDate = selectedDay == 'Today'
          ? DateTime.now()
          : DateTime.now().add(const Duration(days: 1));
    });
  }

}