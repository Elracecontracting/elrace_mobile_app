import 'dart:convert';

import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:el_race/ui/presentation/task_sheet/task_sheet_screen.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../widgets/header_widget.dart';
import 'EmployeeShiftRequestPage.dart';
import 'EmptyShiftPage.dart';

class AddTaskSheet extends StatefulWidget {
  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  String? selectedEmployee;
  final TextEditingController noteController = TextEditingController();
  List<Map<String, dynamic>> employees = [];
  String? selectedEmployeeId;
  bool isLoading = true;
// State variables
// In your State:
  final TextEditingController _employeeSearchController =
      TextEditingController();
  String _employeeSearchQuery = '';
  Map<String, dynamic>? _selectedEmployee;
  bool isLeaveSelected = false;

  DateTime? startDateTime;
  DateTime? endDateTime;
  Duration breakDuration = const Duration(hours: 1);

  String getWorkingHours() {
    if (startDateTime == null || endDateTime == null) return '0:0';

    final total = endDateTime!.difference(startDateTime!) - breakDuration;
    final hours = total.inHours;
    final minutes = total.inMinutes % 60;
    return "$hours:$minutes";
  }

  final List<String> leaveTypes = [
    'Pilgrimage/Umrah Leave',
    'Bereavement Leave',
    'Education Leave',
    'Absent',
  ];

  String? selectedLeaveType;

  int _getLeaveTypeId(String leaveType) {
    switch (leaveType) {
      case 'Absent':
        return 15;
      case 'Pilgrimage/Umrah Leave':
        return 12;
      case 'Education Leave':
        return 14;
      case 'Bereavement Leave':
        return 13;
      default:
        return 0; // You can return 0 or handle differently
    }
  }

// Sample employees
  @override
  void initState() {
    super.initState();
    _fetchEmployees();

    final selected = DateTime.now();
    //  final selected = widget.selectedDate;
    final now = DateTime.now();

    // Take selectedDate's year, month, day but apply time
    startDateTime = DateTime(
      selected.year,
      selected.month,
      selected.day,
      now.hour,
      now.minute,
    ).subtract(const Duration(hours: 9)); // minus 9 hours

    endDateTime = DateTime(
      selected.year,
      selected.month,
      selected.day,
      now.hour,
      now.minute,
    ); // current time
  }

  Future<bool> _submitTimesheetWithFeedback() async {
    if (_selectedEmployee == null) {
      _showDialogMessage("Please select an employee.");
      return false;
    }

    final body = {
      "jsonrpc": "2.0",
      "params": {
        "project_id": " widget.project_id",
        // "project_id": widget.project_id,
        "task_id": "widget.taskId",
        //"task_id": widget.taskId,
        "name": _selectedEmployee!['name'],
        "break_time":
            breakDuration.inHours, // Sending break in hours (example: 1)
        "leave_type_id": selectedLeaveType != null
            ? _getLeaveTypeId(selectedLeaveType!)
            : false,
        "employee_ids": [_selectedEmployee!['id']],
        "date": DateFormat('yyyy-MM-dd').format(startDateTime!), // Picked date
        "date_time": DateFormat('yyyy-MM-dd HH:mm:ss')
            .format(startDateTime!), // Start datetime
        "date_time_end": DateFormat('yyyy-MM-dd HH:mm:ss')
            .format(endDateTime!), // End datetime
      }
    };

    try {
      final response = await http.post(
        Uri.parse("https://test.elrace.com/api/timesheet/submit"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['result']['success'] == true) {
        return true;
      } else {
        _showDialogMessage(result['result']['message'] ?? "Submission failed.");
        return false;
      }
    } catch (e) {
      _showDialogMessage("Error submitting timesheet: $e");
      return false;
    }
  }

  void _showDialogMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        );
      },
    );
  }

  Future<void> _fetchEmployees() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      const token = "token";
      //  final token = widget.loginResponseModel.result?.token;

      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      final body = jsonEncode({
        "jsonrpc": "2.0",
        "params": {},
      });

      final url = Uri.parse("https://test.elrace.com/api/employee/listx");

      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          employees =
              List<Map<String, dynamic>>.from(data['result']['employees']);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load employees: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      print("Error fetching employees: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ Prevents keyboard overlap
      appBar: const HeaderWidget(),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding:
                const EdgeInsets.only(bottom: 20), // Extra space at the bottom
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: Text(
                      'TIME SHEET',
                      style: GoogleFonts.koulen(
                        fontSize: 19,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.0,
                        color: appFontColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ Searchable Employee Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Employee",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A53), // matches mockup color
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _employeeSearchController,
                        onChanged: (value) {
                          setState(() {
                            _employeeSearchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search employee...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                if (_employeeSearchQuery.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: employees
                            .where((emp) => emp['name']
                                .toString()
                                .toLowerCase()
                                .contains(_employeeSearchQuery.toLowerCase()))
                            .length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade300),
                        itemBuilder: (context, index) {
                          final filteredEmployees = employees.where((emp) {
                            return emp['name']
                                .toString()
                                .toLowerCase()
                                .contains(_employeeSearchQuery.toLowerCase());
                          }).toList();

                          final employee = filteredEmployees[index];

                          return ListTile(
                            dense: true,
                            title: Text(employee['name']),
                            tileColor: _selectedEmployee == employee
                                ? Colors.deepPurple
                                    .withAlpha((0.1 * 255).toInt())
                                : Colors.transparent,
                            onTap: () {
                              setState(() {
                                _selectedEmployee = employee;
                                selectedEmployeeId = employee['id'].toString();
                                _employeeSearchQuery = '';
                                _employeeSearchController.text =
                                    employee['name'];
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 15),

                // ✅ Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0), // 👈 padding added here
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => isLeaveSelected = false),
                        child: _buildActionButton(
                          "Add shift",
                          backgroundColor:
                              isLeaveSelected ? Colors.white : appFontColor,
                          textColor:
                              isLeaveSelected ? Colors.black : Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => isLeaveSelected = true),
                        child: _buildActionButton(
                          "Add leave",
                          backgroundColor:
                              isLeaveSelected ? appFontColor : Colors.white,
                          textColor:
                              isLeaveSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (!isLeaveSelected) ...[
                  _buildTimeRow("Starts", startDateTime,
                      (picked) => setState(() => startDateTime = picked)),
                  _buildTimeRow("Ends", endDateTime,
                      (picked) => setState(() => endDateTime = picked)),
                  _buildBreakRow("Break Time", breakDuration),
                  _buildInfoRow("Working Hours", "", getWorkingHours(),
                      highlight: true),
                ],

                const SizedBox(height: 20),

                // ✅ Leave Type Dropdown
                if (isLeaveSelected)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    child: DropdownButtonFormField<String>(
                      value: selectedLeaveType,
                      decoration: InputDecoration(
                        labelText: 'Choose leave type',
                        labelStyle:
                            const TextStyle(fontSize: 13, color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.arrow_drop_down),
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      items: leaveTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child:
                              Text(type, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedLeaveType = value;
                        });
                      },
                    ),
                  ),

                const SizedBox(height: 20),

                // ✅ Note Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: noteController,
                    minLines: 2,
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Attach a note to your request",
                      hintStyle:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 19),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    "All requests will be sent for a manager’s approval",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: appFontColor),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ Submit Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBottomButton("Cancel", greyText3, Colors.black, () {
                        Navigator.pop(context);
                      }),
                      _buildBottomButton(
                          "Send for approval", appFontColor, Colors.white, () {
                        _showApprovalPopup(context);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(
      String label, DateTime? dateTime, Function(DateTime) onDateTimePicked) {
    return Column(
      children: [
        const Divider(color: Colors.grey, height: 2, thickness: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
          child: InkWell(
            onTap: () async {
              DateTime initialDate = dateTime ?? DateTime.now();
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (pickedDate != null) {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(initialDate),
                );
                if (pickedTime != null) {
                  final combined = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                  onDateTimePicked(combined);
                }
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A53))),
                Row(
                  children: [
                    Text(
                      dateTime != null
                          ? _formatDateTime(dateTime)
                          : "-- | --:--",
                      style: const TextStyle(
                        color: appFontColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    String month = _getMonthShortName(dateTime.month);
    String daySuffix = _getDaySuffix(dateTime.day);
    String formattedDate =
        "$month ${dateTime.day}$daySuffix ${dateTime.year % 100}";
    String formattedTime = TimeOfDay.fromDateTime(dateTime).format(context);
    return "$formattedDate | $formattedTime";
  }

  String _getMonthShortName(int month) {
    const monthNames = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return monthNames[month - 1];
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return "th";
    switch (day % 10) {
      case 1:
        return "st";
      case 2:
        return "nd";
      case 3:
        return "rd";
      default:
        return "th";
    }
  }

  Widget _buildBreakRow(String label, Duration breakDuration) {
    return Column(
      children: [
        const Divider(color: Colors.grey, height: 2, thickness: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: appFontColor)),
              Text(
                "${breakDuration.inHours.toString().padLeft(2, '0')}:00",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: appFontColor,
                    fontSize: 12),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.black, height: 2, thickness: 2),
      ],
    );
  }

  // ✅ Build Action Buttons (Add Shift / Add Leave)
  Widget _buildActionButton(
    String text, {
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).toInt()),
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  // ✅ Build Time Detail Rows
  Widget _buildInfoRow(String label, String time, String hours,
      {bool highlight = false}) {
    return Container(
      decoration: highlight
          ? BoxDecoration(
              color: const Color(0xFFD9D9D9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.4 * 255).toInt()),
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: appFontColor,
            ),
          ),
          Text(
            hours,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: appFontColor,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Build Bottom Buttons (Cancel / Send for Approval)
  Widget _buildBottomButton(
      String text, Color bgColor, Color textColor, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: onPressed, // Calls the function when clicked
          child: Text(
            text,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
      ),
    );
  }

  void _showApprovalPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ✅ Send Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appFontColor, // Dark blue background
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                      ),
                      icon:
                          const Icon(Icons.send, color: Colors.white, size: 16),
                      label: const Text("Send",
                          style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        final success = await _submitTimesheetWithFeedback();
                        if (success) {
                          await Future.delayed(const Duration(seconds: 1));
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TaskSheetPage(),
                            ),
                            (route) => route.isFirst,
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 10),

                    // ✅ Cancel Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Red background
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                      ),
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                      label: const Text("Cancel",
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.pop(context); // Close the popup
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // ✅ Confirmation Text
                const Text(
                  "Are you sure you want to send your request?",
                  style: TextStyle(fontSize: 10, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
