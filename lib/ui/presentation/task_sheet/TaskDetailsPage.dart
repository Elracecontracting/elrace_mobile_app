import 'dart:convert';

import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../widgets/header_widget.dart';
import 'EmployeeShiftRequestPage.dart';
import 'EmptyShiftPage.dart';

class TaskDetailsPage extends StatefulWidget {
  final LoginResponseModel loginResponseModel;
  final int taskId; // <-- Task ID to send in API
  final int project_id;

  const TaskDetailsPage(
      {Key? key,
      required this.loginResponseModel,
      required this.taskId,
      required this.project_id})
      : super(key: key);

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  DateTime selectedStartDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime selectedEndDate = DateTime.now();
  List<Map<String, dynamic>> timesheetData = [];

  @override
  void initState() {
    super.initState();
    _fetchTimesheetData();
  }

  Future<void> _fetchTimesheetData() async {
    final url =
        Uri.parse("https://test.elrace.com/api/count/timesheets/by/days");

    final body = {
      "jsonrpc": "2.0",
      "params": {
        "task_id": widget.taskId,
        "date_list": List.generate(
          selectedEndDate.difference(selectedStartDate).inDays + 1,
          (i) => DateFormat('yyyy-MM-dd')
              .format(selectedStartDate.add(Duration(days: i))),
        ),
      }
    };

    try {
      final response = await http.post(url, body: jsonEncode(body), headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          timesheetData =
              List<Map<String, dynamic>>.from(data['result']['timesheets']);
        });
      } else {
        print("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? selectedStartDate : selectedEndDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          selectedStartDate = picked;
        } else {
          selectedEndDate = picked;
        }
      });
      _fetchTimesheetData();
    }
  }

  @override
  Widget build(BuildContext context) {
    String startDateFormatted =
        DateFormat('MM/dd/yyyy').format(selectedStartDate);
    String endDateFormatted = DateFormat('MM/dd/yyyy').format(selectedEndDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
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
                  translate('home.time_sheet'),
                  style: GoogleFonts.koulen(
                    fontSize: 19,
                    fontWeight: FontWeight.w400,
                    color: appFontColor,
                    letterSpacing: 1.9, // ⬅️ Adjust spacing as needed
                  ),
                ),
                Container(
                  width: 25,
                  height: 25,
                  decoration: const BoxDecoration(
                      color: appFontColor, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.add, size: 20, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeeShiftRequestPage(
                              loginResponseModel: widget.loginResponseModel,
                              taskId: widget.taskId,
                              project_id: widget.project_id,
                              selectedDate: selectedStartDate),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Date pickers
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _selectDate(context, true),
                  child: _buildDateContainer(startDateFormatted),
                ),
                const SizedBox(width: 15),
                Text(translate('home.to'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(width: 15),
                GestureDetector(
                  onTap: () => _selectDate(context, false),
                  child: _buildDateContainer(endDateFormatted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                translate('home.OVERALL_HOURS'),
                style: GoogleFonts.koulen(
                  fontSize: 17,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
              const Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.grey,
                      thickness: 0.5,
                      endIndent: 8,
                    ),
                  ),
                  SizedBox(width: 95), // Width of the text above (roughly)
                  Expanded(
                    child: Divider(
                      color: Colors.grey,
                      thickness: 0.5,
                      indent: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Task list
          Expanded(
            child: timesheetData.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: timesheetData.length,
                    itemBuilder: (context, index) {
                      final item = timesheetData[index];

                      // ✅ Try parsing the date safely
                      DateTime? date;
                      try {
                        date = DateTime.parse(item['date']);
                      } catch (_) {
                        return const SizedBox(); // Skip rendering invalid entries
                      }
                      final weekday = DateFormat('E').format(date);
                      final day = DateFormat('dd').format(date);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EmptyShiftPage(
                                  loginResponseModel: widget.loginResponseModel,
                                  selectedDate: date!,
                                  taskId: widget.taskId,
                                  project_id: widget
                                      .project_id, // 👈 Ensure 'date' is parsed correctly earlier in your loop
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              image: const DecorationImage(
                                image: AssetImage('assets/png/TIMESHEET.png'),
                                fit: BoxFit.none,
                              ),
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey
                                        .withAlpha((0.2 * 255).toInt()),
                                    blurRadius: 6,
                                    spreadRadius: 1)
                              ],
                              gradient: const LinearGradient(
                                  colors: [Colors.white, Colors.grey],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomRight),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 16, 0, 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 50,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(day,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black)),
                                        Text(weekday,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: appFontColor)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 0.5,
                                    height: 50,
                                    color: Colors.grey,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildStatusLabel(
                                              "In Progress (${item['inprogress']})",
                                              const Color(0xFFBA1719)),
                                          _buildStatusLabel(
                                              "Submitted (${item['submitted']})",
                                              Colors.blue),
                                          _buildStatusLabel(
                                              "Approved (${item['approved']})",
                                              const Color(0xFF00D17A)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(right: 18.0),
                                    child: Icon(Icons.arrow_forward_ios,
                                        size: 19, color: appFontColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateContainer(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        color: appFontColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha((0.2 * 255).toInt()),
              blurRadius: 6,
              spreadRadius: 2,
              offset: const Offset(0, 4))
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
