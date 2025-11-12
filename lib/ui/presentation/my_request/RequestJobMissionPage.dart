import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../widgets/custom_slider_button.dart';

class RequestJobMissionPage extends StatefulWidget {
  final loginResponseModel;

  const RequestJobMissionPage({Key? key, required this.loginResponseModel})
      : super(key: key);

  @override
  _RequestJobMissionPageState createState() => _RequestJobMissionPageState();
}

class _RequestJobMissionPageState extends State<RequestJobMissionPage> {
  final GlobalKey<CustomSliderButtonState> _sliderKey =
      GlobalKey<CustomSliderButtonState>();

  String description = '';
  String clientDetails = '';
  String projectDetails = '';
  DateTime selectedDate = DateTime.now();
  String selectedMissionType = "Job Mission Type";
  String selectedDuration = "Morning";
  String selectedDay = 'Today'; // or 'Tomorrow'

  Future<void> _selectDate(BuildContext context) async {
    if (selectedDay == 'Tomorrow') return; // Disable manual selection

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _submitJobMissionRequest() async {
    try {
      final token = SharedPref.getLoginData().result?.token;

      final url = Uri.parse("https://test.elrace.com/api/submit_request");

      final body = jsonEncode({
        "jsonrpc": "2.0",
        "params": {
          "request_type": "job_mission",
          "leave_type": null,
          "joined_date": DateFormat('yyyy-MM-dd').format(selectedDate),
          "start_date": DateFormat('yyyy-MM-dd 00:00:00').format(selectedDate),
          "duration": null,
          "end_date": DateFormat('yyyy-MM-dd 00:00:00').format(selectedDate),
          "description": description,
          "note": description,
          "job_type": selectedMissionType == "Client Visit"
              ? "client_meeting"
              : selectedMissionType.toLowerCase().replaceAll(' ', '_'),
          "job_time": selectedDuration.toLowerCase(),
          "job_date": null,
          "e_reason": null,
          "join_date": null,
          "late_days": null,
          "attachment": null,
          "client_details": selectedMissionType.toLowerCase() == 'client visit'
              ? clientDetails
              : null,
          "project_details": selectedMissionType.toLowerCase() == 'client visit'
              ? projectDetails
              : null,
          "duration_type": null,
          "hour_from": null,
          "hour_to": null,
          "jm_start": selectedDay.toLowerCase(),
          "job_time": selectedDuration.toLowerCase(),
        }
      });

      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token"
      };

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final response = await http.post(url, body: body, headers: headers);
      final data = jsonDecode(response.body);

      Navigator.pop(context); // ✅ Close loading dialog

      if (response.statusCode == 200 &&
          data['result']?['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('request.job_mission_success'))),
        );
        Navigator.pop(
            context, true); // ✅ Go back to MyRequestsPage with refresh flag
      } else {
        _sliderKey.currentState?.resetSlider(); // ✅ Reset slider on API failure
        _showErrorDialog(
            data['result']?['message'] ?? translate('request.request_failed'));
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _sliderKey.currentState?.resetSlider(); // ✅ Reset slider on exception
      _showErrorDialog(translate('request.error_occurred'));
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate('request.submission_failed')),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(translate('common.ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String dateFormatted = formatDate(selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            child: Column(
              children: [
                const SizedBox(height: 50),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
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
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                    'assets/png/job_mission.png',
                                    width: 180,
                                    height: 60,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 40),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Builder(
                                builder: (context) => PopupMenuButton<String>(
                                  onSelected: (value) {
                                    setState(() {
                                      selectedMissionType = value;
                                    });
                                  },
                                  position: PopupMenuPosition.under,
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                    _buildMenuItem('Client Visit'),
                                    _buildMenuItem('Media'),
                                    _buildMenuItem('Support'),
                                  ],
                                  color: Colors.white,
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SizedBox(
                                    width:
                                        240, // 👈 Fixed width of dropdown button
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 7, horizontal: 36),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF1A237E),
                                            Color(0xFF3F51B5)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              selectedMissionType,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.koulen(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing:
                                                    2.2, // Optional for extra spacing
                                              ),
                                            ),
                                          ),
                                          const Icon(Icons.arrow_drop_down,
                                              color: Colors.white),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Text(
                                translate('request.select_day'),
                                style: GoogleFonts.koulen(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: appFontColor,
                                  letterSpacing:
                                      1.6, // Optional for stylistic effect
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Radio(
                                      value: 'Today',
                                      groupValue: selectedDay,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedDay = value!;
                                          selectedDate = DateTime.now();
                                          selectedDuration =
                                              'Afternoon'; // ✅ Morning disabled, so set Afternoon
                                        });
                                      },
                                    ),
                                    Text(
                                      translate('request.today'),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Radio(
                                      value: 'Tomorrow',
                                      groupValue: selectedDay,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedDay = value!;
                                          selectedDate = DateTime.now()
                                              .add(const Duration(days: 1));
                                          selectedDuration =
                                              'Morning'; // ✅ default when both options allowed
                                        });
                                      },
                                    ),
                                    Text(
                                      translate('request.tomorrow'),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                translate('request.duration_type'),
                                style: GoogleFonts.koulen(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: appFontColor,
                                  letterSpacing: 1.9, // Optional for spacing
                                ),
                              ),
                            ),
                            const SizedBox(height: 0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Radio(
                                      value: 'Morning',
                                      groupValue: selectedDuration,
                                      onChanged: selectedDay == 'Today'
                                          ? null // ✅ Disable Morning when Today is selected
                                          : (value) {
                                              setState(() {
                                                selectedDuration =
                                                    value.toString();
                                              });
                                            },
                                    ),
                                    Text(
                                      translate('request.morning'),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Radio(
                                      value: 'Afternoon',
                                      groupValue: selectedDuration,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedDuration = value.toString();
                                        });
                                      },
                                    ),
                                    Text(
                                      translate('request.afternoon'),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (selectedMissionType == 'Client Visit') ...[
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 26.0),
                                child: TextField(
                                  onChanged: (value) =>
                                      setState(() => clientDetails = value),
                                  decoration: InputDecoration(
                                    labelText:
                                        translate('request.client_details'),
                                    labelStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12), // reduced height
                                    isDense: true, // makes it more compact
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 26.0),
                                child: TextField(
                                  onChanged: (value) =>
                                      setState(() => projectDetails = value),
                                  decoration: InputDecoration(
                                    labelText:
                                        translate('request.project_details'),
                                    labelStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12), // reduced height
                                    isDense: true, // makes it more compact
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            Center(
                              child: Text(
                                translate('request.date'),
                                style: GoogleFonts.koulen(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: appFontColor,
                                  letterSpacing:
                                      1.9, // Optional for extra spacing
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: GestureDetector(
                                onTap: () async {
                                  // Disable manual selection when Today or Tomorrow is selected
                                  return;
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 22),
                                  decoration: BoxDecoration(
                                    image: const DecorationImage(
                                      image:
                                          AssetImage('assets/png/desc_box.png'),
                                      fit: BoxFit.cover,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    formatDate(selectedDate),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors
                                          .black, // Optional: adjust if needed
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Center(
                              child: Text(
                                translate('common.reason'),
                                style: GoogleFonts.koulen(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: appFontColor,
                                  letterSpacing:
                                      1.9, // Optional for extra emphasis
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 26.0),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey
                                              .withAlpha((0.3 * 255).toInt()),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: const Offset(2, 3),
                                        ),
                                      ],
                                      image: const DecorationImage(
                                        image: AssetImage(
                                            'assets/png/desc_box.png'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: TextField(
                                      maxLines: 2,
                                      onChanged: (value) =>
                                          setState(() => description = value),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          borderSide: const BorderSide(
                                              color: Colors.grey, width: 0.5),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          borderSide: const BorderSide(
                                              color: Colors.grey, width: 0.5),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          borderSide: const BorderSide(
                                              color: Colors.blue, width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 18, horizontal: 12),
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
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(translate('request.max_words'),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  child: Image.asset(
                                      'assets/png/notice_icon.png',
                                      width: 34,
                                      height: 34),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    translate(
                                        'notification.job_mission_notice'),
                                    style: GoogleFonts.inter(
                                      color: Colors.black87,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            CustomSliderButton(
                              key: _sliderKey,
                              onSlideComplete: _submitJobMissionRequest,
                              loginResponseModel: widget.loginResponseModel,
                            )
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
            top: 46,
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

  PopupMenuItem<String> _buildMenuItem(String text) {
    return PopupMenuItem<String>(
      value: text,
      child: Container(
        width: 145, // 👈 Set desired width
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
