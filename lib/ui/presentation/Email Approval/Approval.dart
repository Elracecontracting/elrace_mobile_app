import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/Email%20Approval/Approval_confirmation.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/approve_card.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_card_type_one.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_card_type_two.dart';
import 'package:el_race/utils/Util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';


class ApprovalsScreen extends StatefulWidget {

  const ApprovalsScreen({Key? key, }) : super(key: key);

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  String selectedCategory = "My Actions";
  TextEditingController searchController = TextEditingController();
  List<dynamic> hrItems = [];
  List<dynamic> rfqItems = [];
  List<dynamic> invoiceItems = [];
  List<dynamic> pettyCashItems = [];
  List<dynamic> allItems = [];

  List<dynamic> approvalItems = [];
  bool isLoading = false;
  String error = '';

  // Add a field to store errors per category
  Map<String, String> categoryErrors = {};
  
  // Add expanded state management for the new cards
  Set<int> expandedTypeOneItems = {};
  Set<int> expandedTypeTwoItems = {};

  @override
  void initState() {
    super.initState();
    _fetchApprovalData(); // Initially fetch HR data
  }


  Future<List<dynamic>> _fetchCategoryData(String groupType) async {
    final token = SharedPref.getLoginData().result?.token;

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://test.elrace.com/api/my_approvals_grouped");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "group_type": groupType,
      },
    });

    final request = http.Request('GET', url)
      ..headers.addAll(headers)
      ..body = body;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    debugPrint("fetchCategoryData: ${request.url} $groupType \n${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Actual key mapping
      const Map<String, String> responseKeys = {
        "hr": "human_resources",
        "rfq": "rfq",
        "invoice": "invoices",
        "petty_cash": "petty_cash",
      };

      final actualKey = responseKeys[groupType] ?? groupType;

      return data['result']['data'][actualKey] ?? [];
    } else {
      throw Exception("Failed to fetch $groupType: ${response.statusCode}");
    }
  }

  Future<List<dynamic>> _safeFetch(String groupType) async {
    try {
      return await _fetchCategoryData(groupType);
    } catch (e) {
      categoryErrors[groupType] = e.toString();
      return [];
    }
  }

  Future<void> _fetchApprovalData() async {
    setState(() {
      isLoading = true;
      error = '';
      categoryErrors.clear();
    });

    try {
      final results = await Future.wait([
        _safeFetch("hr"),
        _safeFetch("rfq"),
        _safeFetch("invoice"),
        _safeFetch("petty_cash"),
      ]);

      // Add type info to each item
      hrItems = results[0].map((item) => {...item, 'type': 'HR'}).toList();
      rfqItems = results[1].map((item) => {...item, 'type': 'RFQ'}).toList();
      invoiceItems = results[2].map((item) => {...item, 'type': 'INVOICE'}).toList();
      pettyCashItems = results[3].map((item) => {...item, 'type': 'PETTY CASH'}).toList();

      allItems = [...hrItems, ...rfqItems, ...invoiceItems, ...pettyCashItems];

      setState(() {
        approvalItems = _getApprovalListForSelectedCategory();
        isLoading = false;
        // If all failed, show a general error
        if (categoryErrors.length == 4) {
          error = 'Failed to fetch all approval categories.';
        }
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  List<dynamic> _getApprovalListForSelectedCategory() {
    switch (selectedCategory.toLowerCase()) {
      case 'hr':
        return hrItems;
      case 'rfq':
        return rfqItems;
      case 'invoice':
        return invoiceItems;
      case 'petty cash':
        return pettyCashItems;
      case 'all':
      default:
        return allItems;
    }
  }


  final Map<String, String> categoryIcons = {
    "My Actions": "assets/png/all-icon.png",
    "HR": "assets/png/hr-icon.png",
    "RFQ": "assets/png/rfq-icon.png",
    "INVOICE": "assets/png/invoice-icon.png",
    "PETTY CASH": "assets/png/petty-cash-icon.png",
  };

  final List<String> categories = ["My Actions", "HR", "RFQ", "INVOICE", "PETTY CASH"];


  @override
  Widget build(BuildContext context) {
    print('${SharedPref.getLoginData().result?.token}');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: RefreshIndicator(
        onRefresh: _fetchApprovalData,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(),
                  Text(
                    'MY APPROVAL',
                    style: GoogleFonts.koulen(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: appFontColor,
                      letterSpacing: 1.9,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Top Category Tabs (Only HR for now)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: categories.map((cat) {
                  bool isSelected = selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = cat;
                          approvalItems = _getApprovalListForSelectedCategory();
                        });
                      },
                      child: Container(
                        width: 90.w,
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? appFontColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              categoryIcons[cat] ?? "assets/icons/default.png",
                              height: 30.w,
                              width: 30.w,
                              // color: isSelected ? Colors.white : Colors.black87,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat,
                              style: GoogleFonts.koulen(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black87,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Loader or Error Message
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (error.isNotEmpty)
              Center(child: Text("Error: $error"))
            else if (approvalItems.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text("No approvals in this category."),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 10)+EdgeInsets.only(bottom: 40.w),
                    itemCount: approvalItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = approvalItems[index];
                       List<String> statuses = ['approved', 'pending', 'rejected'];
                       String sampleStatus = statuses[index % statuses.length];
                       
                       final itemData = {
                         "id": "${item["id"] ?? ""}",
                         "name": "${item["name"] ?? ""}",
                         "type": "${item["type"] ?? ""}",
                         "requester": "${item["requester_name"] ?? ""}",
                         "approver": "${item["emp_name"] ?? ""}",
                         "location": "${item["location"] ?? ""}",
                         "date": "${item["date"] ?? ""}",
                         "image_emp": "${item["image_emp"] ?? ""}",
                         "req_no": "REQ-${(item["id"] ?? "").toString().padLeft(6, '0')}",
                         "title": "${item["name"] ?? ""}",
                         "status": item["status"] ?? sampleStatus,
                       };

                      if(selectedCategory  != 'My Actions'){
                          return ApprovalCardTypeTwo(
                            item: itemData,
                            isExpanded: false,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return ApprovalConfirmationScreen(
                                    requestId: itemData["id"],
                                    type: itemData["type"],
                                  );
                                },
                              );
                            },
                          );
                        }

                        return ApprovalCardTypeOne(
                          item: itemData,
                          isExpanded: expandedTypeOneItems.contains(index),
                          onTap: () {
                            setState(() {
                              if (expandedTypeOneItems.contains(index)) {
                                expandedTypeOneItems.remove(index);
                              } else {
                                expandedTypeOneItems.add(index);
                              }
                            });
                          },
                        );
                    },
                  ),
                )
          ],
        ),
      ),
    );
  }

}