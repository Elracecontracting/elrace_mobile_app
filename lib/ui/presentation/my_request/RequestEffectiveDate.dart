import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../widgets/custom_slider_button.dart';

class EffectiveDatePage extends StatefulWidget {
  final loginResponseModel;

  const EffectiveDatePage({super.key, required this.loginResponseModel});

  @override
  _EffectiveDatePageState createState() => _EffectiveDatePageState();
}

class _EffectiveDatePageState extends State<EffectiveDatePage> {
  String selectedMissionType = "Reason";
  DateTime joinedDate = DateTime.now();
  DateTime leaveEndDate = DateTime.now();
  String description = '';
  final GlobalKey<CustomSliderButtonState> _sliderKey =
      GlobalKey<CustomSliderButtonState>();

  final List<String> options = [
    "New Hire",
    "Work Resumption",
    "Temporary Work Permit",
  ];
  bool dropdownOpen = false;

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

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
  String _formatDateTime(DateTime date) =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(date);

  Future<void> _submitEffectiveDateRequest() async {
    final token = SharedPref.getLoginData().result?.token;
    final url = Uri.parse("https://erp.elrace.com/api/submit_request");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "request_type": "effective_date",
        "leave_type": null,
        "joined_date": DateFormat('yyyy-MM-dd').format(joinedDate),
        "start_date": _formatDateTime(joinedDate),
        "end_date": _formatDateTime(leaveEndDate),
        "description": description,
        "note": description,
        "job_type": null,
        "job_time": null,
        "job_date": null,
        "e_reason": _mapReasonToApiValue(selectedMissionType),
        "join_date": null,
        "late_days": calculateLateDays(),
        "attachment": null,
        "client_details": null,
        "project_details": null,
        "duration_type": null,
        "hour_from": null,
        "hour_to": null,
      }
    });

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(url, headers: headers, body: body);
      Navigator.pop(context);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["result"]?['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request submitted successfully!")),
        );
        Navigator.pop(
            context, true); // ✅ Go back to MyRequestsPage with refresh flag
      } else {
        _sliderKey.currentState?.resetSlider(); // 👈 Reset the slider position
        _showErrorDialog(data["result"]?['message'] ?? "Request failed");
      }
    } catch (e) {
      Navigator.pop(context);
      _sliderKey.currentState?.resetSlider(); // 👈 Reset the slider position
      _showErrorDialog("Something went wrong. Please try again later.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            color: Colors.transparent,
            child: Column(
              children: [
                const SizedBox(height: 70),
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
                              color:
                                  Colors.black.withAlpha((0.1 * 255).toInt()),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  Image.asset(
                                    'assets/png/effective.png',
                                    width: 200,
                                    height: 60,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 40),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildDropdownHeader(),
                            const SizedBox(height: 20),
                            _buildDateRow("JOINED DATE :  ", joinedDate, true),
                            const SizedBox(height: 10),
                            if (selectedMissionType == "Work Resumption")
                              _buildDateRow(
                                  "LEAVE END DATE :  ", leaveEndDate, false),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.only(left: 36.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  translate('common.late_days', args: {
                                    'days': calculateLateDays().toString()
                                  }),
                                  style: GoogleFonts.koulen(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.9,
                                    color: appFontColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 36.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  translate('common.description'),
                                  style: GoogleFonts.koulen(
                                    fontSize: 17, // Adjust as needed
                                    fontWeight: FontWeight.w500,
                                    color: const Color(
                                        0xFFB0B0B0), // Your specified color
                                    letterSpacing:
                                        2.2, // Optional for visual spacing
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildDescriptionField(),
                            const SizedBox(height: 10),
                            _buildNotice(),
                            const SizedBox(height: 20),
                            CustomSliderButton(
                              key: _sliderKey,
                              onSlideComplete: _submitEffectiveDateRequest,
                              loginResponseModel: widget.loginResponseModel,
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
          Positioned(
            top: 66,
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

          // ░░░░░ FLOATING DROPDOWN ░░░░░
          Positioned(
            top: 250.h,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !dropdownOpen,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOut,
                opacity: dropdownOpen ? 1.0 : 0.0,
                child: Center(
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(22.r),
                    child: Container(
                      width: 260.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(options.length, (i) {
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedMissionType = options[i];
                                    dropdownOpen = false;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 14.h, horizontal: 20.w),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    options[i],
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              if (i != options.length - 1)
                                Divider(height: 1, color: Colors.grey.shade300)
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, DateTime date, bool isJoinedDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(36, 0, 0, 0),
          child: Text(
            label,
            style: GoogleFonts.koulen(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.9,
              color: appFontColor, // Optional: add if needed
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _selectDate(context, isJoinedDate),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatDate(date),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownHeader() {
    return GestureDetector(
      onTap: () => setState(() => dropdownOpen = !dropdownOpen),
      child: Container(
        width: 260.w,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF020024), Color(0xFF090979)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              selectedMissionType,
              style: GoogleFonts.koulen(
                color: Colors.white,
                fontSize: 15.sp,
                letterSpacing: 2,
              ),
            ),
            Icon(
              dropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26.0),
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
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
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
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(translate('request_permission.max_words'),
                    style: const TextStyle(fontSize: 10, color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/png/notice_icon.png', width: 34, height: 34),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              translate('request_effective_date.late_days_notice'),
              style: GoogleFonts.inter(
                color: appFontColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String text) {
    return PopupMenuItem<String>(
      value: text,
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          text,
          style: GoogleFonts.koulen(
            fontSize: 14, // original 14 + 2
            fontWeight: FontWeight.w300,
            color: appFontColor,
            letterSpacing: 1.9,
          ),
        ),
      ),
    );
  }

  TextStyle _infoTextStyle_1() => const TextStyle(
      fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey);
}

String _mapReasonToApiValue(String reason) {
  switch (reason) {
    case 'New Hire':
      return 'new_hire';
    case 'Temporary Work Permit':
      return 'temporary_work permit'; // Note: space after "work"
    case 'Work Resumption':
      return 'work_resumption';
    default:
      return '';
  }
}
