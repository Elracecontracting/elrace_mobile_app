import 'dart:convert';
import 'package:el_race/core/constants/app_images.dart';
import 'package:el_race/core/services/approval_viewed_service.dart';
import 'package:el_race/core/services/approval_count_service.dart';
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

  Widget _buildHrCard({
    required dynamic item,
    required String reqNo,
    required String requestType,
    required String employeeName,
    required String empCode,
  }) {
    return Container(
      height: 112.w,
      width: 350.w,
      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 1.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE1E4E8),
            Color(0xFFB9C0CB),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFF5F666F), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: 50.w + 12.w + 2.w + 14.w),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        reqNo.toUpperCase(),
                        style: GoogleFonts.nunito(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0B2D5E),
                          letterSpacing: 0.5,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.w),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.9), width: 2),
                    ),
                    child: ClipOval(
                      child: _buildEmployeeImage(item["image_emp"], 50.w),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    width: 2.w,
                    height: 54.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          requestType.toUpperCase(),
                          style: GoogleFonts.nunito(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0E0E10),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1.5.w),
                        Text(
                          employeeName.toUpperCase(),
                          style: GoogleFonts.nunito(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0B2D5E),
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1.5.w),
                        Text(
                          empCode,
                          style: GoogleFonts.nunito(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6B717B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  // Helper method to check if image_emp is a URL or base64 data
  bool _isImageUrl(String imageData) {
    return imageData.startsWith('http://') || imageData.startsWith('https://');
  }

  // Helper widget to display employee image (URL or base64)
  Widget _buildEmployeeImage(dynamic imageEmp, double size) {
    if (imageEmp != null &&
        imageEmp is String &&
        imageEmp.isNotEmpty &&
        imageEmp.toLowerCase() != "false") {
      if (_isImageUrl(imageEmp)) {
        // It's a URL, use Image.network
        return Image.network(
          imageEmp,
          fit: BoxFit.cover,
          height: size,
          width: size,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              AppImages.personImage,
              fit: BoxFit.cover,
              height: size,
              width: size,
            );
          },
        );
      } else {
        // It's base64 data, decode it
        try {
          return Image.memory(
            base64Decode(imageEmp),
            fit: BoxFit.cover,
            height: size,
            width: size,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                AppImages.personImage,
                fit: BoxFit.cover,
                height: size,
                width: size,
              );
            },
          );
        } catch (e) {
          return Image.asset(
            AppImages.personImage,
            fit: BoxFit.cover,
            height: size,
            width: size,
          );
        }
      }
    }
    // Fallback to default image
    return Image.asset(
      AppImages.personImage,
      fit: BoxFit.cover,
      height: size,
      width: size,
    );
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
          final isHr = type.toString().toUpperCase() == 'HR';

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

            String requestType = _getSafeString(
              item["request_type_name"] ??
                item["request_type"] ??
                item["subject"] ??
                item["title"] ??
                item["type"],
              "N/A");

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
                  // Update approval count badge
                  ApprovalCountService.onCountChanged?.call();
                  // Refresh the list
                  onRefresh?.call();
                }
              }
            },
            child: isHr
                ? _buildHrCard(
                    item: item,
                    reqNo: reqNo,
                    requestType: requestType,
                    employeeName: employeeName,
                    empCode: empCode,
                  )
                : Container(
                    height: 105.w,
                    width: 350.w,
                    margin:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 1.w),
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
                            child: _buildEmployeeImage(item["image_emp"], 73.w),
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
                                    color:
                                        const Color(0xff333333).withOpacity(0.75),
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
                                    size: 14.w,
                                    color: const Color(0xFF1A1A53)),
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
