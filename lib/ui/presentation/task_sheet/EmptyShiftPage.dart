import 'dart:convert';

import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart'; // Import login model
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/header_widget.dart'; // Import HeaderWidget
// Import EmployeeShiftRequestPage for navigation
import 'package:http/http.dart' as http;

import 'EmployeeShiftRequestPage.dart';

class EmptyShiftPage extends StatefulWidget {
  final LoginResponseModel loginResponseModel;
  final DateTime selectedDate;
  final int taskId; // <-- Task ID to send in API
  final int project_id;

  const EmptyShiftPage({Key? key, required this.loginResponseModel, required this.selectedDate,required this.taskId, required this.project_id}) : super(key: key);

  @override
  State<EmptyShiftPage> createState() => _EmptyShiftPageState();
}

class _EmptyShiftPageState extends State<EmptyShiftPage> {
  List<Map<String, dynamic>> timesheets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTimesheets();
  }

  Future<void> fetchTimesheets() async {
    final url = Uri.parse("https://erp.elrace.com/api/task/timesheets/list");

    final body = {
      "jsonrpc": "2.0",
      "params": {
        "task_id": widget.taskId, // Replace this with the actual task_id if dynamic
        "from_date": _formatDate(widget.selectedDate),
        "to_date": _formatDate(widget.selectedDate),
      }
    };

    try {
      final response = await http.post(url,
          body: jsonEncode(body),
          headers: {"Content-Type": "application/json"});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          timesheets = List<Map<String, dynamic>>.from(data['result']['timesheets']);
          isLoading = false;
        });
      } else {
        throw Exception("API Error ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching timesheets: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) =>
      "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final formattedDate = "${_getWeekday(widget.selectedDate)}, ${_getMonth(widget.selectedDate)} ${widget.selectedDate.day}";

    return Scaffold(
      appBar: const HeaderWidget(),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : timesheets.isEmpty
          ? _buildEmptyView(formattedDate)
          : _buildTimesheetList(formattedDate),
    );
  }

  Widget _buildTimesheetList(String formattedDate) {
    return Column(
      children: [


        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmployeeShiftRequestPage(
                        loginResponseModel: widget.loginResponseModel,
                        taskId: widget.taskId,
                        project_id: widget.project_id,
                        selectedDate : widget.selectedDate
                      ),
                    ),
                  );
                },
              ),
              Text(
                formattedDate.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: appFontColor,
                ),
              ),
              Container(
                width: 25,
                height: 25,
                decoration: const BoxDecoration(
                  color: appFontColor,
                  shape: BoxShape.circle,
                ),
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
                          selectedDate : widget.selectedDate

                        ),
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
        const SizedBox(height: 0),
        Expanded(
          child: ListView.builder(
            itemCount: timesheets.length,
            itemBuilder: (context, index) {
              final item = timesheets[index];
              final employee = item['employee'] ?? "No Name";
              final hours = item['unit_amount'] ?? 0;
              final status = item['state'] ?? "Unknown";

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 14.0),
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
                        color: Colors.grey.withAlpha((0.2 * 255).toInt()),
                        blurRadius: 3,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    gradient: const LinearGradient(
                      colors: [Colors.white, Colors.grey],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 16, 0, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          alignment: Alignment.center,
                          width: 30,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: appFontColor,
                            ),
                          ),
                        ),
                        Container(
                          width: 0.5,
                          height: 40,
                          color: Colors.grey,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: appFontColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$hours hrs",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: appFontColor,
                                ),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                "Status: $status",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFBA1719),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // const Padding(
                        //   padding: EdgeInsets.only(right: 18.0),
                        //   child: Icon(Icons.arrow_forward_ios, size: 19, color: appFontColor),
                        // ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

      ],
    );
  }

  Widget _buildEmptyView(String formattedDate) {
    final formattedAPIDate = _formatDate(widget.selectedDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        

        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
              Text(formattedDate.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appFontColor)),
              Container(
                width: 25,
                height: 25,
                decoration: const BoxDecoration(
                  color: appFontColor,
                  shape: BoxShape.circle,
                ),
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
                          selectedDate: widget.selectedDate,
                        ),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: Column(
            children: [
              Image.asset('assets/png/loading.png', width: 120, height: 120),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "NO SHIFTS OR ABSENCES WERE RECORDED ON, $formattedAPIDate",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 90),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: appFontColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmployeeShiftRequestPage(
                        loginResponseModel: widget.loginResponseModel,
                        taskId: widget.taskId,
                        project_id: widget.project_id,
                        selectedDate : widget.selectedDate
                      ),
                    ),
                  );
                },
                child: const Text("Add a new request", style: TextStyle(color: Colors.white)),
              ),

            ],
          ),
        ),
      ],
    );
  }

  String _getWeekday(DateTime date) {
    List<String> weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    return weekdays[date.weekday % 7];
  }

  String _getMonth(DateTime date) {
    List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[date.month - 1];
  }
}
