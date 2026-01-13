import 'dart:convert';
import 'package:el_race/core/constants/app_images.dart';
import 'package:el_race/core/services/approval_viewed_service.dart';
import 'package:el_race/ui/presentation/Email%20Approval/Approval_confirmation.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_card_type_two.dart';
import 'package:el_race/utils/safe_insets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class HrAndPettycashCard extends StatelessWidget {
  final List<dynamic> approvalItems;
  final VoidCallback? onRefresh;
  const HrAndPettycashCard(
      {super.key, required this.approvalItems, this.onRefresh});

  // Helper method to safely extract string values and handle false/true values
  String _getSafeString(dynamic value, String fallback) {
    if (value == null || value == false || value == true) return fallback;
    String strValue = value.toString().trim();
    if (strValue.isEmpty ||
        strValue.toLowerCase() == 'false' ||
        strValue.toLowerCase() == 'true' ||
        strValue.toLowerCase() == 'null') {
      return fallback;
    }
    return strValue;
  }

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

          // Use _getSafeString to handle false/true values properly
          String employeeName = _getSafeString(
              item["employee_name"] ??
                  item["requester_name"] ??
                  item["emp_name"],
              "N/A");

          String empCode = _getSafeString(
              item["emp_code"] ??
                  item["employee_code"] ??
                  item["emp_id"]?.toString() ??
                  item["code"],
              "");

          String reqNo = _getSafeString(
              item["name"] ??
                  item["request_no"] ??
                  item["ref_no"] ??
                  item["reference_no"] ??
                  item["req_no"],
              "N/A");

          String amount = _getSafeString(
              item["amount_total"] ??
                  item["amount"] ??
                  item["total_amount"] ??
                  item["total"],
              "0");

          String date = _getSafeString(
              item["date"] ??
                  item["request_date"] ??
                  item["created_date"] ??
                  item["submission_date"],
              "");

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
                              AppImages.personImage,
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
                              employeeName,
                              style: GoogleFonts.nunito(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(height: 5.w),
                          Text(
                            empCode,
                            style: GoogleFonts.nunito(
                              color: const Color(0xff333333).withOpacity(0.75),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
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
                        InfoContainer(text: reqNo),
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
