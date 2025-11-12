import 'dart:convert';
import 'dart:io';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/signin/data/repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:el_race/utils/color_utils.dart';
import '../../widgets/custom_slider_button.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:flutter_translate/flutter_translate.dart';


class RequestDetailsPage extends StatefulWidget {
  final loginResponseModel;

  const RequestDetailsPage({Key? key, required this.loginResponseModel}) : super(key: key);

  @override
  _RequestDetailsPageState createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  String description = '';
  String duration = '';
  DateTime? startDate;
  LoginResponseModel? _loginResponse;
  DateTime? endDate;
  String selectedLeaveType = "SHORT";
  String? base64Attachment;
  String? leaveBalance;
  static String empID = "";
  String? fileName;
  final GlobalKey<CustomSliderButtonState> _sliderKey = GlobalKey<CustomSliderButtonState>();
  final UserRepo userRepo = UserRepo();

  // End date is readonly; calculated from startDate + duration (if both present)
  void _updateEndDate() {
    if (startDate != null && int.tryParse(duration) != null) {
      final days = int.parse(duration);
      setState(() {
        endDate = startDate!.add(Duration(days: days > 0 ? days - 1 : 0));
      });
    } else {
      setState(() {
        endDate = null;
      });
    }
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
      });
      _updateEndDate();
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final fileBytes = await File(result.files.single.path!).readAsBytes();
      setState(() {
        base64Attachment = base64Encode(fileBytes);
        fileName = result.files.single.name;
      });
    }
  }

  Future<void> _submitRequest() async {
    // Validations
    if (startDate == null || duration.isEmpty || description.isEmpty || selectedLeaveType.isEmpty) {
      _sliderKey.currentState?.resetSlider(); // ⬅️ Reset on validation failure
      _showErrorDialog("Please fill in all required fields.");
      return;
    }
    if (selectedLeaveType == "SICK" && base64Attachment == null) {
      _sliderKey.currentState?.resetSlider(); // ⬅️ Reset on validation failure
      _showErrorDialog("Please attach a file for sick leave.");
      return;
    }

    // Prepare request
    final token = SharedPref.getLoginData().result?.token;
    final url = Uri.parse("https://test.elrace.com/api/submit_request");
    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "request_type": "leave",
        "leave_type": selectedLeaveType.toLowerCase(),
        "joined_date": null,
        "start_date": DateFormat('yyyy-MM-dd').format(startDate!),
        "duration": duration,
        "end_date": DateFormat('yyyy-MM-dd').format(endDate!),
        "description": description,
        "note": description,
        "job_type": null,
        "job_time": null,
        "job_date": null,
        "e_reason": null,
        "join_date": null,
        "late_days": null,
        "attachment": base64Attachment,
        "client_details": null,
        "project_details": null,
        "duration_type": "days",
        "hour_from": null,
        "hour_to": null
      }
    });
    print("🔥 Submitting Body:\n${jsonEncode(body)}"); // Log the full body

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token"
    };
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final response = await http.post(url, body: body, headers: headers);
      Navigator.pop(context); // remove loading
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["result"]?['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request submitted successfully!")),
        );
        Navigator.pop(context, true); // ✅ Go back to MyRequestsPage with refresh flag

      } else {
        String errorMsg = "Failed to submit request.";
        if (data['result']?['message'] != null) {
          errorMsg = data['result']['message'];
          _sliderKey.currentState?.resetSlider(); // 👈 Reset the slider position

        }
        _sliderKey.currentState?.resetSlider(); // 👈 Reset the slider position
        _showErrorDialog(errorMsg);
      }
    } catch (e) {
      Navigator.pop(context);
      _sliderKey.currentState?.resetSlider(); // 👈 Reset the slider position
      _showErrorDialog("An error occurred while submitting the request.");
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Submission Failed"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future<void> _initAsync() async {
    await fetchleaveBalance();
  }


  Future<void> fetchleaveBalance() async {
  // Ensure empID and companyId are initialized before proceeding
    await init(); // Ensure init is complete

}
  Future<void> init() async {
    print("initcalled");
    leaveBalance = (await userRepo.getLoginResponse())!.result!.data!.leaveBalance.toString();
    print("0000");
    print(leaveBalance);
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Content
          Container(
            color: Colors.black,
            child: Column(
              children: [
                const SizedBox(height: 50),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
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
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            // Header Row
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
                                      'assets/png/leave_type.png',
                                      width: 180,
                                      height: 60,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 40),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Leave Type Buttons
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedLeaveType = "SHORT";
                                      });
                                    },
                                    child: _buildLeaveTypeButton("SHORT", "LEAVE", selectedLeaveType == "SHORT"),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedLeaveType = "SICK";
                                      });
                                    },
                                    child: _buildLeaveTypeButton("  SICK  ", "LEAVE", selectedLeaveType == "SICK"),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Date Pickers and Duration
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () async => await _selectDate(context),
                                    child: _buildInfoRow("Start Date", _formatDate(startDate)),
                                  ),
                                  const SizedBox(width: 15),
                                  const Text('TO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: appFontColor)),
                                  const SizedBox(width: 15),
                                  AbsorbPointer(
                                    child: _buildInfoRow(
                                      "End Date",
                                      endDate != null ? _formatDate(endDate) : "-",
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 50.0),
                              child: Row(
                                children: [
                                  Text(
                                    'DURATION  :  ',
                                    style: GoogleFonts.koulen(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: appFontColor,
                                      letterSpacing: 2.2, // Adjust as needed
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40, // slightly wider for visibility
                                    height: 40,
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      style: _infoTextStyle(),
                                      decoration: InputDecoration(
                                        hintText: '0',
                                        hintStyle: TextStyle(color: Colors.grey.shade500),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        filled: true,
                                        fillColor: Colors.grey.shade100,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                                        ),
                                      ),
                                      onChanged: (val) {
                                        duration = val;
                                        _updateEndDate();
                                      },
                                    ),
                                  ),

                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 50.0),
                              child: Text(
                                translate('common.balance_leave'),
                                style: GoogleFonts.koulen(
                                  fontSize: 16, // You can adjust size as needed
                                  fontWeight: FontWeight.w500,
                                  color: appFontColor,
                                  letterSpacing: 2.2, // Optional for styling
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 50.0),
                              child: Text(
                                translate('common.description'),
                                style: GoogleFonts.koulen(
                                  fontSize: 17, // Adjust as needed
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFB0B0B0), // Your specified color
                                  letterSpacing: 2.2, // Optional for visual spacing
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
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
                                        const Text('Max words', style: TextStyle(fontSize: 10, color: Colors.black)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Attach Button
// Show attachment only if leave type is "SICK"
                            if (selectedLeaveType == "SICK")
                              Center(
                                child: ElevatedButton(
                                  onPressed: _pickAttachment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset('assets/png/attachment_icon.png', width: 30, height: 30),
                                      const SizedBox(width: 6),
                                      Text(
                                        fileName == null ? 'ATTACH YOUR FILE' : 'FILE: $fileName',
                                        style: GoogleFonts.koulen(
                                          color: appFontColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                          letterSpacing: 1.6,
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  child: Image.asset('assets/png/notice_icon.png', width: 34, height: 34),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    translate('notification.annual_leave_notice'),
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
                              onSlideComplete: _submitRequest,
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
          // ❌ Close Button
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

  Widget _buildInfoRow(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('assets/png/bg_petty.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildLeaveTypeButton(String title, String subtitle, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? appFontColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? appFontColor : Colors.grey.shade300,
          width: isSelected ? 3 : 1,
        ),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: appFontColor.withAlpha((0.4 * 255).toInt()),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ]
            : [],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.koulen(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : appFontColor,
              letterSpacing: 2.2, // Adjust as needed
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.koulen(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : appFontColor,
              letterSpacing: 1.0, // Adjust as needed
            ),
          ),

        ],
      ),
    );
  }


  TextStyle _infoTextStyle() =>
      const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: appFontColor);

  TextStyle _infoTextStyle_1() =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey);
}
