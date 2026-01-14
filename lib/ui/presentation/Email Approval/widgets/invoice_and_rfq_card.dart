import 'dart:convert';
import 'package:el_race/core/services/approval_viewed_service.dart';
import 'package:el_race/core/services/approval_count_service.dart';
import 'package:el_race/ui/presentation/Email%20Approval/Approval_confirmation.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_card_type_two.dart';
import 'package:el_race/utils/safe_insets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class InvoiceAndRfqCard extends StatelessWidget {
  final List<dynamic> approvalItems;
  final VoidCallback? onRefresh;
  const InvoiceAndRfqCard(
      {super.key, required this.approvalItems, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (approvalItems.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('No items found'),
        ),
      );
    }

    // Calculate safe bottom padding for devices with navigation bars
    final totalBottomPadding =
        kBottomNavigationBarHeight + context.systemBottomInset + 16;

    return Expanded(
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 5) +
            EdgeInsets.only(bottom: totalBottomPadding, top: 100.w),
        itemCount: approvalItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 1),
        itemBuilder: (context, index) {
          final item = approvalItems[index];
          String type = item["type"] ?? "";
          String id = item["id"]?.toString() ?? "";

          // Helper function to safely get string value
          String _getSafeString(dynamic value, {String fallback = "N/A"}) {
            if (value == null || value == false || value == true)
              return fallback;
            String str = value.toString();
            if (str.isEmpty ||
                str.toLowerCase() == 'false' ||
                str.toLowerCase() == 'true' ||
                str.toLowerCase() == 'null') {
              return fallback;
            }
            return str;
          }

          // For Invoice: client_name, For RFQ: client or vendor
          String vendor = _getSafeString(
              item["client_name"] ?? item["client"] ?? item["vendor"]);

          // For Invoice: name might be ID, For RFQ: name has ref number
          String refNo = _getSafeString(item["name"] ??
              item["ref_no"] ??
              item["title"] ??
              item["request_no"]);

          String materialType =
              _getSafeString(item["material_type"], fallback: "");

          // For Invoice: project_title, For RFQ: project
          String project = _getSafeString(
              item["project_title"] ?? item["project"] ?? item["work_order"],
              fallback: "");

          String work =
              _getSafeString(item["work"] ?? item["agreement"], fallback: "");

          // Check multiple amount fields
          String amount = _getSafeString(
              item["amount_total"] ?? item["amount"] ?? item["total"],
              fallback: "0");

          String date = _getSafeString(
              item["date"] ?? item["request_date"] ?? item["date_order"]);

          return GestureDetector(
            onTap: () async {
              // Mark item as viewed
              print('🔵 Marking as viewed - Type: $type, ID: $id');
              await ApprovalViewedService.markAsViewed(
                type,
                id,
              );

              if (context.mounted) {
                final result = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return ApprovalConfirmationScreen(
                      requestId: id,
                      type: type,
                    );
                  },
                );
                // Trigger a rebuild to update the list after dialog closes
                if (result == true) {
                  // Update approval count badge
                  ApprovalCountService.onCountChanged?.call();
                  // Refresh the list
                  onRefresh?.call();
                }
              }
            },
            child: Container(
              height: 105.w,
              width: 350.w,
              margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 1.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xffD6D6D6),
                    Color(0xffADB2BD),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipOval(
                      child: (item["image_emp"] != null &&
                              item["image_emp"] is String &&
                              (item["image_emp"] as String).isNotEmpty &&
                              (item["image_emp"] as String).toLowerCase() !=
                                  "false")
                          ? Image.memory(
                              base64Decode(item["image_emp"] as String),
                              fit: BoxFit.cover,
                              height: 73.w,
                              width: 73.w,
                            )
                          : Image.asset(
                              'assets/png/police.png',
                              fit: BoxFit.cover,
                              height: 73.w,
                              width: 73.w,
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
                              vendor,
                              style: GoogleFonts.nunito(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(height: 5.w),
                          Text(
                            refNo,
                            style: GoogleFonts.nunito(
                              color: const Color(0xff333333).withOpacity(0.75),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: 5.w),
                          SizedBox(
                            width: 150.w,
                            child: Row(
                              children: [
                                Flexible(
                                  flex: 3,
                                  child: Text(
                                    project.isNotEmpty ? '$project ' : '',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                                if (work.isNotEmpty)
                                  Flexible(
                                    flex: 2,
                                    child: Text(
                                      '($work)',
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 10.sp,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
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
                        InfoContainer(
                            text:
                                materialType.isNotEmpty ? materialType : refNo),
                        SizedBox(height: 6.w),
                        InfoContainer(text: '$amount AED'),
                        SizedBox(height: 6.w),
                        InfoContainer(
                          text: date.isNotEmpty ? date : 'N/A',
                          icon: Icon(Icons.date_range,
                              size: 14.w, color: const Color(0xFF1A1A53)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


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