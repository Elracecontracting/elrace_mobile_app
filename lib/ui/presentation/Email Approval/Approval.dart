import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/Email%20Approval/Approval_confirmation.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_card_type_one.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_card_type_two.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;

import '../../widgets/header_widget.dart';
import '../home_screen/screens/main_screens.dart';
import '../home_screen/widgets/visibilty_icon.dart';

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

  // Add expanded state management for the new cards
  Set<int> expandedTypeOneItems = {};
  Set<int> expandedTypeTwoItems = {};

  @override
  void initState() {
    super.initState();
    selectedCategory=categories.first;
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

  // === التعديل الوحيد لإصلاح الأيقونات عند الترجمة ===
  // نخلي مفاتيح الـ Map هي النصوص المترجمة نفسها بدل السلاسل الإنجليزية الثابتة.
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
  bool isSearch=false;

  Widget searchWidget() {
    return Container(
      height: 35,
      width: 130,
      decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey,
          ),
          // boxShadow: const [
          //   BoxShadow(color: darkGrey, offset: Offset(2, 4), blurRadius: 12)
          // ],
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [ Color(0xff999999),Color(0xffFFFFFF),])
      ),
      child: TextFormField(
        onChanged: (value) {

        },
        style: const TextStyle(
          color: Color(0xFF1A1A53),
          fontSize: 15,
          fontFamily: 'Koulen',
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
            border: InputBorder.none,
            // hintText: 'SEARCH CONTACT',
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            hintStyle: const TextStyle(
                fontSize: 12,
                fontFamily: 'Koulen',
                fontWeight: FontWeight.w400,
                color: Color(0xFF1A1A53)),

            suffixIcon: GestureDetector(
              onTap: (){
                setState(() {
                  isSearch=false;
                });
              },
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    "assets/png/search_icon.png",
                    width: 14,
                    height: 14,
                    color: Colors.black,
                  )),
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  //  print('${SharedPref.getLoginData().result?.token}');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      floatingActionButton: const ArraowVisibalityBottomNav(),
      bottomNavigationBar:  const CustomBottomNavBar(isMain: false,),
      body: RefreshIndicator(
        onRefresh: _fetchApprovalData,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(),
                  Text(
                    translate('home.my_approval'),
                    style: GoogleFonts.koulen(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: appFontColor,
                      letterSpacing: 1.9,
                    ),
                  ),
                  isSearch? searchWidget(): GestureDetector(
                    onTap: (){
                      setState(() {
                        isSearch=true;
                      });
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor:HexColor("#ADB2BD"),
                      child:Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            "assets/png/search_icon.png",
                            width: 20,
                            height: 20,
                            color: Colors.black,
                          ))
                    ),
                  )
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
                                color:
                                    isSelected ? Colors.white : Colors.black87,
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
            // Loader or Error Message
            // if (isLoading)
            //   const Center(child: CircularProgressIndicator())
            // else if (error.isNotEmpty)
            //   Center(child: Text("Error: $error"))
            // else if (approvalItems.isEmpty)
            //   const Expanded(
            //     child: Center(
            //       child: Text("No approvals in this category."),
            //     ),
            //   )
            // else
            //
            //   Expanded(
            //     child: ListView.separated(
            //       physics: const BouncingScrollPhysics(),
            //       padding: const EdgeInsets.symmetric(horizontal: 10) + EdgeInsets.only(bottom: 40.w),
            //       itemCount: approvalItems.length,
            //       separatorBuilder: (context, index) => const SizedBox(height: 10),
            //       itemBuilder: (context, index) {
            //         final item = approvalItems[index];
            //         List<String> statuses = ['approved', 'pending', 'rejected'];
            //         String sampleStatus = statuses[index % statuses.length];
            //         final itemData = {
            //           "id": "${item["id"] ?? ""}",
            //           "name": "${item["name"] ?? ""}",
            //           "type": "${item["type"] ?? ""}",
            //           "requester": "${item["requester_name"] ?? ""}",
            //           "approver": "${item["emp_name"] ?? ""}",
            //           "location": "${item["location"] ?? ""}",
            //           "date": "${item["date"] ?? ""}",
            //           "image_emp": "${item["image_emp"] ?? ""}",
            //           "req_no":
            //               "REQ-${(item["id"] ?? "").toString().padLeft(6, '0')}",
            //           "title": "${item["name"] ?? ""}",
            //           "status": item["status"] ?? sampleStatus,
            //         };
            //         if (selectedCategory != 'My Actions') {
            //           return ApprovalCardTypeTwo(
            //             item: itemData,
            //             isExpanded: false,
            //             onTap: () {
            //               showDialog(
            //                 context: context,
            //                 builder: (BuildContext context) {
            //                   return ApprovalConfirmationScreen(
            //                     requestId: itemData["id"],
            //                     type: itemData["type"],
            //                   );
            //                 },
            //               );
            //             },
            //           );
            //         }
            //         return ApprovalCardTypeOne(
            //           item: itemData,
            //           isExpanded: expandedTypeOneItems.contains(index),
            //           onTap: () {
            //             setState(() {
            //               if (expandedTypeOneItems.contains(index)) {
            //                 expandedTypeOneItems.remove(index);
            //               } else {
            //                 expandedTypeOneItems.add(index);
            //               }
            //             });
            //           },
            //         );
            //       },
            //     ),
            //   )
          ],
        ),
      ),
    );
  }
  body(){
    //MY ACTION
    if(selectedCategory.toLowerCase()=="MY ACTION".toLowerCase()){
      return Expanded(
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10) + EdgeInsets.only(bottom: 40.w),
          itemCount: approvalItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return  InkWell(
              onTap: () {

                setState(() {
                  if (expandedTypeOneItems.contains(index)) {
                    expandedTypeOneItems.remove(index);
                  } else {
                    expandedTypeOneItems.add(index);
                    Future.delayed(const Duration(seconds: 3), () {
                      setState(() {
                        expandedTypeOneItems.remove(index);
                      });
                    });
                  }
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  expandedTypeOneItems.contains(index)
                      ? Container(
                    key: const ValueKey("expanded"),
                    height: 70.w,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A53),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 11),
                        const Spacer(),
                        Text(
                         index.isEven? 'rejected'.toUpperCase():'approved'.toUpperCase(),
                          style: GoogleFonts.inter(
                            color:  index.isEven?Colors.redAccent:Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 23.sp,
                            letterSpacing: 1,
                          ),

                        ),
                        const Spacer(),
                      ],
                    ),
                  )
                      :  Container(
                    height: 70.w,
                    alignment: Alignment.center,
                    key: const ValueKey("collapsed"),
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    margin: EdgeInsets.only(left: 4.w, top: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(28),
                      border: Border(
                        left: BorderSide(
                          color:  index.isEven?Colors.red:Color(0xff009859),
                          width:6, // 👈 سمك الحد
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 1),
                        Text(
                          '31 JAN 24',
                          // DateFormat('dd MMM yy').format(parsedDate),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: appFontColor,
                          ),
                        ),
                        const SizedBox(
                          height: 39.5,
                          child: VerticalDivider(
                              color: Colors.grey, thickness: 1),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              translate('home.REQ_NO'),
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: appFontColor,
                              ),
                            ),
                            Text(
                              'REQ/2025/02438',
                              //  reqNo,
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 39.5,
                          child: VerticalDivider(
                              color: Colors.grey, thickness: 1),
                        ),
                        SizedBox(
                          width: 90.w,
                          child: Text(
                            "Temp...",
                            // title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // AnimatedAlign(
                  //   alignment: isExpanded ? Alignment.centerLeft : Alignment.centerRight,
                  //   duration: const Duration(milliseconds: 900),
                  //   curve: Curves.easeInOut,
                  //   child: Container(
                  //     margin: EdgeInsets.symmetric(horizontal: 10.w),
                  //     key: ValueKey(isExpanded),
                  //     width: 50.w,
                  //     height: 50.w,
                  //     decoration: BoxDecoration(
                  //       shape: BoxShape.circle,
                  //       border: Border.all(color: Colors.white, width: 2),
                  //     ),
                  //     child: ClipOval(
                  //       child: (item["image_emp"] != null &&
                  //               item["image_emp"] is String &&
                  //               (item["image_emp"] as String).isNotEmpty &&
                  //               (item["image_emp"] as String).toLowerCase() != "false")
                  //           ? Image.memory(
                  //               base64Decode(item["image_emp"] as String),
                  //               fit: BoxFit.cover,
                  //               width: double.infinity,
                  //               height: double.infinity,
                  //             )
                  //           : Image.asset(
                  //               'assets/png/profile_1.png',
                  //               fit: BoxFit.cover,
                  //               width: double.infinity,
                  //               height: double.infinity,
                  //             ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            );
          },
        ),
      );
    }
    else if(selectedCategory.toLowerCase()=="HR".toLowerCase()){
      return Expanded(
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 5) + EdgeInsets.only(bottom: 40.w),
         // itemCount: approvalItems.length,
          itemCount: 5,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            // final item = approvalItems[index];
            // List<String> statuses = ['approved', 'pending', 'rejected'];
            // String sampleStatus = statuses[index % statuses.length];
            // final itemData = {
            //   "id": "${item["id"] ?? ""}",
            //   "name": "${item["name"] ?? ""}",
            //   "type": "${item["type"] ?? ""}",
            //   "requester": "${item["requester_name"] ?? ""}",
            //   "approver": "${item["emp_name"] ?? ""}",
            //   "location": "${item["location"] ?? ""}",
            //   "date": "${item["date"] ?? ""}",
            //   "image_emp": "${item["image_emp"] ?? ""}",
            //   "req_no":
            //   "REQ-${(item["id"] ?? "").toString().padLeft(6, '0')}",
            //   "title": "${item["name"] ?? ""}",
            //   "status": item["status"] ?? sampleStatus,
            // };
            return InkWell(
              onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ApprovalConfirmationScreen(
                    requestId: '1',
                    // requestId: itemData["id"],
                    // type: itemData["type"],
                    type: "type",
                  );
                },
              );
            },
              child: Container(
                height: 105.w,
                width: 350.w,
                margin: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 73.w,
                        width: 73.w,
                        padding: EdgeInsets.all(6.w),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/png/profile_1.png',
                            fit: BoxFit.cover,
                          ),
                          // child: (item["image_emp"] != null &&
                          //     item["image_emp"] is String &&
                          //     (item["image_emp"] as String).isNotEmpty &&
                          //     (item["image_emp"] as String).toLowerCase() != "false")
                          //     ? Image.memory(
                          //   base64Decode(item["image_emp"] as String),
                          //   fit: BoxFit.cover,
                          // )
                          //     : Image.asset(
                          //   'assets/png/profile_1.png',
                          //   fit: BoxFit.cover,
                          // ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 130.w,
                              child: Text(
                                'Marwan Ahmed',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(height: 5.w),
                            Text(
                              '2597',
                              style: TextStyle(color: greyText,fontSize: 13.sp),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const InfoContainer(text: 'Job Mission'),
                          SizedBox(height: 6.w),
                          InfoContainer(text: 'Req 156821'),
                          SizedBox(height: 6.w),
                          InfoContainer(
                            text: '13/08/2025',
                            icon: Icon(Icons.date_range, size: 14.w, color: const Color(0xFF1A1A53)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            // return ApprovalCardTypeTwo(
            //   item: itemData,
            //   isExpanded: false,
            //   onTap: () {
            //     showDialog(
            //       context: context,
            //       builder: (BuildContext context) {
            //         return ApprovalConfirmationScreen(
            //           requestId: itemData["id"],
            //           type: itemData["type"],
            //         );
            //       },
            //     );
            //   },
            // );
          },
        ),
      );
    }
    else if(selectedCategory.toLowerCase()=="Petty Cash".toLowerCase()){
      return Expanded(
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 5) + EdgeInsets.only(bottom: 40.w),
         // itemCount: approvalItems.length,
          itemCount: 5,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            // final item = approvalItems[index];
            // List<String> statuses = ['approved', 'pending', 'rejected'];
            // String sampleStatus = statuses[index % statuses.length];
            // final itemData = {
            //   "id": "${item["id"] ?? ""}",
            //   "name": "${item["name"] ?? ""}",
            //   "type": "${item["type"] ?? ""}",
            //   "requester": "${item["requester_name"] ?? ""}",
            //   "approver": "${item["emp_name"] ?? ""}",
            //   "location": "${item["location"] ?? ""}",
            //   "date": "${item["date"] ?? ""}",
            //   "image_emp": "${item["image_emp"] ?? ""}",
            //   "req_no":
            //   "REQ-${(item["id"] ?? "").toString().padLeft(6, '0')}",
            //   "title": "${item["name"] ?? ""}",
            //   "status": item["status"] ?? sampleStatus,
            // };
            return InkWell(
              onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ApprovalConfirmationScreen(
                    requestId: '1',
                    // requestId: itemData["id"],
                    // type: itemData["type"],
                    type: "type",
                  );
                },
              );
            },
              child: Container(
                height: 105.w,
                width: 350.w,
                margin: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 73.w,
                        width: 73.w,
                        padding: EdgeInsets.all(6.w),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/png/profile_1.png',
                            fit: BoxFit.cover,
                          ),
                          // child: (item["image_emp"] != null &&
                          //     item["image_emp"] is String &&
                          //     (item["image_emp"] as String).isNotEmpty &&
                          //     (item["image_emp"] as String).toLowerCase() != "false")
                          //     ? Image.memory(
                          //   base64Decode(item["image_emp"] as String),
                          //   fit: BoxFit.cover,
                          // )
                          //     : Image.asset(
                          //   'assets/png/profile_1.png',
                          //   fit: BoxFit.cover,
                          // ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 130.w,
                              child: Text(
                                'Marwan Ahmed',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(height: 5.w),
                            Text(
                              '2597',
                              style: TextStyle(color: greyText,fontSize: 13.sp),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const InfoContainer(text: '1245132567'),
                          SizedBox(height: 6.w),
                          InfoContainer(text: '2000 AED'),
                          SizedBox(height: 6.w),
                          InfoContainer(
                            text: '13/08/2025',
                            icon: Icon(Icons.date_range, size: 14.w, color: const Color(0xFF1A1A53)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            // return ApprovalCardTypeTwo(
            //   item: itemData,
            //   isExpanded: false,
            //   onTap: () {
            //     showDialog(
            //       context: context,
            //       builder: (BuildContext context) {
            //         return ApprovalConfirmationScreen(
            //           requestId: itemData["id"],
            //           type: itemData["type"],
            //         );
            //       },
            //     );
            //   },
            // );
          },
        ),
      );
    }
    else if(selectedCategory.toLowerCase()=="RFQ".toLowerCase()){
      return Expanded(
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 5) + EdgeInsets.only(bottom: 40.w),
          itemCount: approvalItems.length,
         // itemCount: 5,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            // final item = approvalItems[index];
            // List<String> statuses = ['approved', 'pending', 'rejected'];
            // String sampleStatus = statuses[index % statuses.length];
            // final itemData = {
            //   "id": "${item["id"] ?? ""}",
            //   "name": "${item["name"] ?? ""}",
            //   "type": "${item["type"] ?? ""}",
            //   "requester": "${item["requester_name"] ?? ""}",
            //   "approver": "${item["emp_name"] ?? ""}",
            //   "location": "${item["location"] ?? ""}",
            //   "date": "${item["date"] ?? ""}",
            //   "image_emp": "${item["image_emp"] ?? ""}",
            //   "req_no":
            //   "REQ-${(item["id"] ?? "").toString().padLeft(6, '0')}",
            //   "title": "${item["name"] ?? ""}",
            //   "status": item["status"] ?? sampleStatus,
            // };
            return InkWell(
              onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ApprovalConfirmationScreen(
                    requestId: '1',
                    // requestId: itemData["id"],
                    // type: itemData["type"],
                    type: "type",
                  );
                },
              );
            },
              child: Container(
                height: 105.w,
                width: 350.w,
                margin: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 73.w,
                        width: 73.w,
                        padding: EdgeInsets.all(6.w),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/png/police.png',
                            fit: BoxFit.cover,
                          ),
                          // child: (item["image_emp"] != null &&
                          //     item["image_emp"] is String &&
                          //     (item["image_emp"] as String).isNotEmpty &&
                          //     (item["image_emp"] as String).toLowerCase() != "false")
                          //     ? Image.memory(
                          //   base64Decode(item["image_emp"] as String),
                          //   fit: BoxFit.cover,
                          // )
                          //     : Image.asset(
                          //   'assets/png/profile_1.png',
                          //   fit: BoxFit.cover,
                          // ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 130.w,
                              child: Text(
                                'Alfouaa Police Station',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(height: 5.w),
                            Text(
                              'ADCDA/2021/154',
                              style: TextStyle(color: greyText,fontSize: 13.sp),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            SizedBox(height: 5.w),
                            SizedBox(
                              width: 150.w,
                              child: Row(
                                children: [

                                  Text(
                                    'Bella Casa ',
                                    style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  Text(
                                    '(Paint works)',
                                    style: const TextStyle(fontWeight: FontWeight.normal,fontSize: 10),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),

                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const InfoContainer(text: 'RFQ 1235812'),
                          SizedBox(height: 6.w),
                          InfoContainer(text: '200,000 AED'),
                          SizedBox(height: 6.w),
                          InfoContainer(
                            text: '13/08/2025',
                            icon: Icon(Icons.date_range, size: 14.w, color: const Color(0xFF1A1A53)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            // return ApprovalCardTypeTwo(
            //   item: itemData,
            //   isExpanded: false,
            //   onTap: () {
            //     showDialog(
            //       context: context,
            //       builder: (BuildContext context) {
            //         return ApprovalConfirmationScreen(
            //           requestId: itemData["id"],
            //           type: itemData["type"],
            //         );
            //       },
            //     );
            //   },
            // );
          },
        ),
      );
    }
    else if(selectedCategory.toLowerCase()=="INVOICE".toLowerCase()){
      return Expanded(
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 5) + EdgeInsets.only(bottom: 40.w),
          itemCount: approvalItems.length,
         // itemCount: 5,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            // final item = approvalItems[index];
            // List<String> statuses = ['approved', 'pending', 'rejected'];
            // String sampleStatus = statuses[index % statuses.length];
            // final itemData = {
            //   "id": "${item["id"] ?? ""}",
            //   "name": "${item["name"] ?? ""}",
            //   "type": "${item["type"] ?? ""}",
            //   "requester": "${item["requester_name"] ?? ""}",
            //   "approver": "${item["emp_name"] ?? ""}",
            //   "location": "${item["location"] ?? ""}",
            //   "date": "${item["date"] ?? ""}",
            //   "image_emp": "${item["image_emp"] ?? ""}",
            //   "req_no":
            //   "REQ-${(item["id"] ?? "").toString().padLeft(6, '0')}",
            //   "title": "${item["name"] ?? ""}",
            //   "status": item["status"] ?? sampleStatus,
            // };
            return InkWell(
              onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ApprovalConfirmationScreen(
                    requestId: '1',
                    // requestId: itemData["id"],
                    // type: itemData["type"],
                    type: "type",
                  );
                },
              );
            },
              child: Container(
                height: 105.w,
                width: 350.w,
                margin: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 73.w,
                        width: 73.w,
                        padding: EdgeInsets.all(6.w),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/png/police.png',
                            fit: BoxFit.cover,
                          ),
                          // child: (item["image_emp"] != null &&
                          //     item["image_emp"] is String &&
                          //     (item["image_emp"] as String).isNotEmpty &&
                          //     (item["image_emp"] as String).toLowerCase() != "false")
                          //     ? Image.memory(
                          //   base64Decode(item["image_emp"] as String),
                          //   fit: BoxFit.cover,
                          // )
                          //     : Image.asset(
                          //   'assets/png/profile_1.png',
                          //   fit: BoxFit.cover,
                          // ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 130.w,
                              child: Text(
                                'Alfouaa Police Station',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(height: 5.w),
                            Text(
                              'ADCDA/2021/154',
                              style: TextStyle(color: greyText,fontSize: 13.sp),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            SizedBox(height: 5.w),
                            SizedBox(
                              width: 150.w,
                              child: Row(
                                children: [

                                  Text(
                                    'Bella Casa ',
                                    style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  Text(
                                    '(Paint works)',
                                    style: const TextStyle(fontWeight: FontWeight.normal,fontSize: 10),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),

                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const InfoContainer(text: 'RFQ 1235812'),
                          SizedBox(height: 6.w),
                          InfoContainer(text: '200,000 AED'),
                          SizedBox(height: 6.w),
                          InfoContainer(
                            text: '13/08/2025',
                            icon: Icon(Icons.date_range, size: 14.w, color: const Color(0xFF1A1A53)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            // return ApprovalCardTypeTwo(
            //   item: itemData,
            //   isExpanded: false,
            //   onTap: () {
            //     showDialog(
            //       context: context,
            //       builder: (BuildContext context) {
            //         return ApprovalConfirmationScreen(
            //           requestId: itemData["id"],
            //           type: itemData["type"],
            //         );
            //       },
            //     );
            //   },
            // );
          },
        ),
      );
    }
    else{
      return const SizedBox.shrink();
    }
  }
}

// import 'dart:convert';

// import 'package:el_race/core/utils/shared_pref.dart';
// import 'package:el_race/ui/presentation/Email%20Approval/Approval_confirmation.dart';
// import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_card_type_one.dart';
// import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_card_type_two.dart';
// import 'package:el_race/utils/color_utils.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_translate/flutter_translate.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;

// import '../../widgets/header_widget.dart';

// class ApprovalsScreen extends StatefulWidget {
//   const ApprovalsScreen({
//     Key? key,
//   }) : super(key: key);

//   @override
//   State<ApprovalsScreen> createState() => _ApprovalsScreenState();
// }

// class _ApprovalsScreenState extends State<ApprovalsScreen> {
//   String selectedCategory = "My Actions";
//   TextEditingController searchController = TextEditingController();
//   List<dynamic> hrItems = [];
//   List<dynamic> rfqItems = [];
//   List<dynamic> invoiceItems = [];
//   List<dynamic> pettyCashItems = [];
//   List<dynamic> allItems = [];

//   List<dynamic> approvalItems = [];
//   bool isLoading = false;
//   String error = '';

//   // Add a field to store errors per category
//   Map<String, String> categoryErrors = {};

//   // Add expanded state management for the new cards
//   Set<int> expandedTypeOneItems = {};
//   Set<int> expandedTypeTwoItems = {};

//   @override
//   void initState() {
//     super.initState();
//     _fetchApprovalData(); // Initially fetch HR data
//   }

//   Future<List<dynamic>> _fetchCategoryData(String groupType) async {
//     final token = SharedPref.getLoginData().result?.token;

//     final headers = {
//       "Content-Type": "application/json",
//       "Accept": "application/json",
//       "Authorization": "Bearer $token",
//     };

//     final url = Uri.parse("https://test.elrace.com/api/my_approvals_grouped");

//     final body = jsonEncode({
//       "jsonrpc": "2.0",
//       "params": {
//         "group_type": groupType,
//       },
//     });

//     final request = http.Request('GET', url)
//       ..headers.addAll(headers)
//       ..body = body;

//     final streamedResponse = await request.send();
//     final response = await http.Response.fromStream(streamedResponse);
//     debugPrint(
//         "fetchCategoryData: ${request.url} $groupType \n${response.body}");

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);

//       // Actual key mapping
//       const Map<String, String> responseKeys = {
//         "hr": "human_resources",
//         "rfq": "rfq",
//         "invoice": "invoices",
//         "petty_cash": "petty_cash",
//       };

//       final actualKey = responseKeys[groupType] ?? groupType;

//       return data['result']['data'][actualKey] ?? [];
//     } else {
//       throw Exception("Failed to fetch $groupType: ${response.statusCode}");
//     }
//   }

//   Future<List<dynamic>> _safeFetch(String groupType) async {
//     try {
//       return await _fetchCategoryData(groupType);
//     } catch (e) {
//       categoryErrors[groupType] = e.toString();
//       return [];
//     }
//   }

//   Future<void> _fetchApprovalData() async {
//     setState(() {
//       isLoading = true;
//       error = '';
//       categoryErrors.clear();
//     });

//     try {
//       final results = await Future.wait([
//         _safeFetch("hr"),
//         _safeFetch("rfq"),
//         _safeFetch("invoice"),
//         _safeFetch("petty_cash"),
//       ]);

//       // Add type info to each item
//       hrItems = results[0].map((item) => {...item, 'type': 'HR'}).toList();
//       rfqItems = results[1].map((item) => {...item, 'type': 'RFQ'}).toList();
//       invoiceItems =
//           results[2].map((item) => {...item, 'type': 'INVOICE'}).toList();
//       pettyCashItems =
//           results[3].map((item) => {...item, 'type': 'PETTY CASH'}).toList();

//       allItems = [...hrItems, ...rfqItems, ...invoiceItems, ...pettyCashItems];

//       setState(() {
//         approvalItems = _getApprovalListForSelectedCategory();
//         isLoading = false;
//         // If all failed, show a general error
//         if (categoryErrors.length == 4) {
//           error = 'Failed to fetch all approval categories.';
//         }
//       });
//     } catch (e) {
//       setState(() {
//         error = e.toString();
//         isLoading = false;
//       });
//     }
//   }

//   List<dynamic> _getApprovalListForSelectedCategory() {
//     switch (selectedCategory.toLowerCase()) {
//       case 'hr':
//         return hrItems;
//       case 'rfq':
//         return rfqItems;
//       case 'invoice':
//         return invoiceItems;
//       case 'petty cash':
//         return pettyCashItems;
//       case 'all':
//       default:
//         return allItems;
//     }
//   }

//   final Map<String, String> categoryIcons = {
//     "My Actions": "assets/png/all-icon.png",
//     "HR": "assets/png/hr-icon.png",
//     "RFQ": "assets/png/rfq-icon.png",
//     "INVOICE": "assets/png/invoice-icon.png",
//     "PETTY CASH": "assets/png/petty-cash-icon.png",
//   };

//   final List<String> categories = [
//     translate('home.my_action'),
//     translate('home.hr'),
//     translate('home.rfq'),
//     translate('home.invoice'),
//     translate('home.petty_cash'),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     print('${SharedPref.getLoginData().result?.token}');
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: const HeaderWidget(),
//       body: RefreshIndicator(
//         onRefresh: _fetchApprovalData,
//         child: Column(
//           children: [
//             const SizedBox(height: 10),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const BackButton(),
//                   Text(
//                     'MY APPROVAL',
//                     style: GoogleFonts.koulen(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w400,
//                       color: appFontColor,
//                       letterSpacing: 1.9,
//                     ),
//                   ),
//                   const SizedBox(width: 40),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 10),

//             // Top Category Tabs (Only HR for now)
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               physics: const BouncingScrollPhysics(),
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Row(
//                 children: categories.map((cat) {
//                   bool isSelected = selectedCategory == cat;
//                   return Padding(
//                     padding: const EdgeInsets.only(right: 5.0),
//                     child: GestureDetector(
//                       onTap: () {
//                         setState(() {
//                           selectedCategory = cat;
//                           approvalItems = _getApprovalListForSelectedCategory();
//                         });
//                       },
//                       child: Container(
//                         width: 90.w,
//                         margin: const EdgeInsets.only(right: 4),
//                         padding: const EdgeInsets.symmetric(vertical: 7),
//                         decoration: BoxDecoration(
//                           color: isSelected ? appFontColor : Colors.grey[300],
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Column(
//                           children: [
//                             Image.asset(
//                               categoryIcons[cat] ?? "assets/icons/default.png",
//                               height: 30.w,
//                               width: 30.w,
//                               // color: isSelected ? Colors.white : Colors.black87,
//                             ),
//                             const SizedBox(height: 6),
//                             Text(
//                               cat,
//                               style: GoogleFonts.koulen(
//                                 fontSize: 13.sp,
//                                 fontWeight: FontWeight.bold,
//                                 color:
//                                     isSelected ? Colors.white : Colors.black87,
//                                 letterSpacing: 1.0,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Loader or Error Message
//             if (isLoading)
//               const Center(child: CircularProgressIndicator())
//             else if (error.isNotEmpty)
//               Center(child: Text("Error: $error"))
//             else if (approvalItems.isEmpty)
//               const Expanded(
//                 child: Center(
//                   child: Text("No approvals in this category."),
//                 ),
//               )
//             else
//               Expanded(
//                 child: ListView.separated(
//                   physics: const BouncingScrollPhysics(),
//                   padding: const EdgeInsets.symmetric(horizontal: 10) +
//                       EdgeInsets.only(bottom: 40.w),
//                   itemCount: approvalItems.length,
//                   separatorBuilder: (context, index) =>
//                       const SizedBox(height: 10),
//                   itemBuilder: (context, index) {
//                     final item = approvalItems[index];
//                     List<String> statuses = ['approved', 'pending', 'rejected'];
//                     String sampleStatus = statuses[index % statuses.length];

//                     final itemData = {
//                       "id": "${item["id"] ?? ""}",
//                       "name": "${item["name"] ?? ""}",
//                       "type": "${item["type"] ?? ""}",
//                       "requester": "${item["requester_name"] ?? ""}",
//                       "approver": "${item["emp_name"] ?? ""}",
//                       "location": "${item["location"] ?? ""}",
//                       "date": "${item["date"] ?? ""}",
//                       "image_emp": "${item["image_emp"] ?? ""}",
//                       "req_no":
//                           "REQ-${(item["id"] ?? "").toString().padLeft(6, '0')}",
//                       "title": "${item["name"] ?? ""}",
//                       "status": item["status"] ?? sampleStatus,
//                     };

//                     if (selectedCategory != 'My Actions') {
//                       return ApprovalCardTypeTwo(
//                         item: itemData,
//                         isExpanded: false,
//                         onTap: () {
//                           showDialog(
//                             context: context,
//                             builder: (BuildContext context) {
//                               return ApprovalConfirmationScreen(
//                                 requestId: itemData["id"],
//                                 type: itemData["type"],
//                               );
//                             },
//                           );
//                         },
//                       );
//                     }

//                     return ApprovalCardTypeOne(
//                       item: itemData,
//                       isExpanded: expandedTypeOneItems.contains(index),
//                       onTap: () {
//                         setState(() {
//                           if (expandedTypeOneItems.contains(index)) {
//                             expandedTypeOneItems.remove(index);
//                           } else {
//                             expandedTypeOneItems.add(index);
//                           }
//                         });
//                       },
//                     );
//                   },
//                 ),
//               )
//           ],
//         ),
//       ),
//     );
//   }
// }
