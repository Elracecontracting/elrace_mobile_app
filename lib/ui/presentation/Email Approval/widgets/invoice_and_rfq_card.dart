import 'dart:convert';
import 'package:el_race/core/services/approval_viewed_service.dart';
import 'package:el_race/ui/presentation/Email%20Approval/Approval_confirmation.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_card_type_two.dart';
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final safePadding =
        bottomPadding > viewPadding ? bottomPadding : viewPadding;
    final totalBottomPadding = safePadding > 0 ? safePadding + 20.h : 150.h;

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
          String vendor = item["vendor"] ?? item["client"] ?? "N/A";
          String refNo =
              item["ref_no"] ?? item["title"] ?? item["request_no"] ?? "N/A";
          String materialType = item["material_type"] ?? "";
          String project = (item["project"] ?? item["work_order"] ?? "")
              .toString()
              .replaceAll('false', '')
              .replaceAll('true', '');
          String work = item["work"] ?? "";
          String amount = item["amount_total"]?.toString() ?? "0";
          String date = (item["date"] ?? item["request_date"] ?? "")
              .toString()
              .replaceAll('false', '')
              .replaceAll('true', '');

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
                                SizedBox(
                                  width: 100.w,
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
                                Text(
                                  work.isNotEmpty ? '($work)' : '',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 10.sp,
                                  ),
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