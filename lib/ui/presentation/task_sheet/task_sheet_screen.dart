import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/task_sheet/TaskDetailsPage.dart';
import 'package:el_race/ui/presentation/task_sheet/add_task_sheet.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../widgets/header_widget.dart';

class TaskSheetPage extends StatefulWidget {
  const TaskSheetPage({
    Key? key,
  }) : super(key: key);

  @override
  State<TaskSheetPage> createState() => _TaskSheetPageState();
}

class _TaskSheetPageState extends State<TaskSheetPage> {
  List<dynamic> tasks = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    final userId = SharedPref.getLoginData().result?.data?.uid;
    final token = SharedPref.getLoginData().result?.token;
    print("UID: ${SharedPref.getLoginData().result?.data?.uid}");
    print("Token: ${SharedPref.getLoginData().result?.token}");

    if (userId == null || token == null) {
      setState(() {
        isLoading = false;
        errorMessage = "User ID or token is missing.";
      });
      return;
    }

    final url = Uri.parse("https://test.elrace.com/api/tasks/list");
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "user_id": userId,
      }
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded["result"] != null) {
        setState(() {
          tasks = decoded["result"]["tasks"];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load tasks.";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await fetchTasks();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const HeaderWidget(),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 22),
                    Text(
                      translate('home.time_sheet'),
                      style: GoogleFonts.koulen(
                        fontSize: 19,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.0,
                        color: appFontColor,
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                          color: appFontColor, shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.add,
                            size: 16, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddTaskSheet(),
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
            ),
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = tasks[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 7.0, horizontal: 14.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailsPage(
                                loginResponseModel: SharedPref.getLoginData(),
                                taskId: tasks[index][
                                    'id'], // <-- Make sure 'id' exists in your task map
                                project_id: tasks[index][
                                    'project_id'], // <-- Make sure 'id' exists in your task map
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width *
                              0.9, // 90% of screen width
                          height: 120,
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage('assets/png/TIMESHEET.png'),
                              fit: BoxFit.none,
                            ),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.grey.withAlpha((0.2 * 255).toInt()),
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
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task["name"] ?? '',
                                          style: GoogleFonts.koulen(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            color: appFontColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Project Name: ${task["project_name"] ?? ''}",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFBA1719),
                                          ),
                                        ),
                                        Text(
                                          "Client: ${task["customer_name"] ?? ''}",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFBA1719),
                                          ),
                                        ),
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
                  childCount: tasks.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
