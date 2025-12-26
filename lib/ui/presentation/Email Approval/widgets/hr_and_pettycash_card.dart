import 'dart:convert';
import 'package:el_race/core/constants/app_images.dart';
import 'package:el_race/ui/presentation/Email%20Approval/Approval_confirmation.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_card_type_two.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class HrAndPettycashCard extends StatelessWidget {
  final List<dynamic> approvalItems;
  const HrAndPettycashCard({super.key, required this.approvalItems});

  @override
  Widget build(BuildContext context) {
    if (approvalItems.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('No items found'),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 5) +
            EdgeInsets.only(bottom: 100.w, top: 100.w),
        itemCount: approvalItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 1),
        itemBuilder: (context, index) {
          final item = approvalItems[index];
          String type = item["type"] ?? "";
          String id = item["id"]?.toString() ?? "";
          String employeeName = item["employee_name"] ??
              item["requester_name"] ??
              item["name"] ??
              "N/A";
          String empCode = item["emp_code"]?.toString() ??
              item["employee_code"]?.toString() ??
              "";
          String reqNo = item["request_no"] ?? item["ref_no"] ?? "N/A";
          String amount = item["amount_total"]?.toString() ??
              item["amount"]?.toString() ??
              "0";
          String date = item["date"] ?? item["request_date"] ?? "";

          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ApprovalConfirmationScreen(
                    requestId: id,
                    type: type,
                  );
                },
              );
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
