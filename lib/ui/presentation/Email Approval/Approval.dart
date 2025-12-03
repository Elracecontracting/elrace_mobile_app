import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/hr_and_pettycash_card.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/invoice_and_rfq_card.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/my_action_card.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/visibilty_icon.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import '../../widgets/header_widget.dart';
import '../home_screen/screens/main_screens.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({
    Key? key,
  }) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    selectedCategory = categories.first;
    searchController.addListener(_onSearchChanged);
    _fetchApprovalData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      approvalItems = _getFilteredItems();
    });
  }

  List<dynamic> _getFilteredItems() {
    final allFiltered = _getApprovalListForSelectedCategory();
    if (searchController.text.isEmpty) {
      return allFiltered;
    }

    final searchLower = searchController.text.toLowerCase();
    return allFiltered.where((item) {
      final name = item["name"]?.toString().toLowerCase() ?? "";
      final requestNo = item["request_no"]?.toString().toLowerCase() ?? "";
      final reqNo = item["req_no"]?.toString().toLowerCase() ?? "";
      final title = item["title"]?.toString().toLowerCase() ?? "";
      final employeeName =
          item["employee_name"]?.toString().toLowerCase() ?? "";
      final vendor = item["vendor"]?.toString().toLowerCase() ?? "";

      return name.contains(searchLower) ||
          requestNo.contains(searchLower) ||
          reqNo.contains(searchLower) ||
          title.contains(searchLower) ||
          employeeName.contains(searchLower) ||
          vendor.contains(searchLower);
    }).toList();
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
    debugPrint(
        "fetchCategoryData: ${request.url} $groupType \n${response.body}");

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
      invoiceItems =
          results[2].map((item) => {...item, 'type': 'INVOICE'}).toList();
      pettyCashItems =
          results[3].map((item) => {...item, 'type': 'PETTY CASH'}).toList();

      allItems = [...hrItems, ...rfqItems, ...invoiceItems, ...pettyCashItems];

      setState(() {
        approvalItems = _getFilteredItems();
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

  Map<String, String> get categoryIcons => {
        translate('home.my_action'): "assets/png/all-icon.png",
        translate('home.hr'): "assets/png/hr-icon.png",
        translate('home.rfq'): "assets/png/rfq-icon.png",
        translate('home.invoice'): "assets/png/invoice-icon.png",
        translate('home.petty_cash'): "assets/png/petty-cash-icon.png",
      };

  final List<String> categories = [
    translate('home.my_action'),
    translate('home.hr'),
    translate('home.rfq'),
    translate('home.invoice'),
    translate('home.petty_cash'),
  ];
  bool isSearch = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      bottomNavigationBar: const CustomBottomNavBar(
        isMain: false,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchApprovalData,
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BackButton(),
                      /*AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        height: 40,
                        width: isSearch ? 310.w : 43.w,
                        decoration: BoxDecoration(
                          color: isSearch ? Colors.white : HexColor("#ADB2BD"),
                          border:
                              isSearch ? Border.all(color: Colors.grey) : null,
                          borderRadius: BorderRadius.circular(20),
                          gradient: isSearch
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xffD6D6D6),
                                    Color(0xffADB2BD),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            if (isSearch)
                              Expanded(
                                child: TextFormField(
                                  controller: searchController,
                                  autofocus: true,
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A53),
                                    fontSize: 14,
                                    fontFamily: 'Koulen',
                                    fontWeight: FontWeight.w400,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.only(bottom: 10, left: 10),
                                    hintText: 'Search...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isSearch = !isSearch;
                                  if (!isSearch) {
                                    searchController.clear();
                                  }
                                });
                              },
                              child: Container(
                                width: 40.w,
                                height: 40.w,
                                alignment: Alignment.center,
                                child: Image.asset(
                                  "assets/png/search_icon.png",
                                  width: 20.w,
                                  height: 20.w,
                                  color: Colors.black,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )*/
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
                              approvalItems = _getFilteredItems();
                            });
                          },
                          child: Container(
                            width: 90.w,
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? appFontColor : Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [
                                        Color.fromARGB(255, 27, 27, 27),
                                        appFontColor,
                                      ],
                                      stops: [
                                        0.02,
                                        0.9,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xffD6D6D6),
                                        Color(0xffADB2BD),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                            ),
                            child: Column(
                              children: [
                                Image.asset(
                                  categoryIcons[cat] ??
                                      "assets/icons/default.png",
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
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
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
                body()
              ],
            ),
            // const ArraowVisibalityBottomNav(
            //   bottomMargin: 120,
            // ),
          ],
        ),
      ),
    );
  }

  body() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    //MY ACTION
    if (selectedCategory.toLowerCase() == "MY ACTION".toLowerCase()) {
      return MyActionCard(approvalItems: approvalItems);
    } else if (selectedCategory.toLowerCase() == "HR".toLowerCase()) {
      return HrAndPettycashCard(approvalItems: approvalItems);
    } else if (selectedCategory.toLowerCase() == "Petty Cash".toLowerCase()) {
      return HrAndPettycashCard(approvalItems: approvalItems);
    } else if (selectedCategory.toLowerCase() == "RFQ".toLowerCase()) {
      return InvoiceAndRfqCard(approvalItems: approvalItems);
    } else if (selectedCategory.toLowerCase() == "INVOICE".toLowerCase()) {
      return InvoiceAndRfqCard(approvalItems: approvalItems);
    } else {
      return const SizedBox.shrink();
    }
  }
}
