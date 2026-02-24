import 'dart:convert';
import 'package:el_race/core/constants/app_images.dart';
import 'package:el_race/core/services/approval_viewed_service.dart';
import 'package:el_race/core/services/approval_count_service.dart';
import 'package:el_race/ui/presentation/Email%20Approval/Approval_confirmation.dart';
import 'package:el_race/ui/presentation/Email%20Approval/screens/hr_details_screen.dart';
import 'package:el_race/ui/presentation/Email%20Approval/screens/pettycash_details_screen.dart';
import 'package:el_race/utils/safe_insets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HrAndPettycashCard extends StatelessWidget {
  final List<dynamic> approvalItems;
  final VoidCallback? onRefresh;
  final String categoryType;
  const HrAndPettycashCard(
      {super.key, required this.approvalItems, this.onRefresh, this.categoryType = ''});

  String _formatAmountForCard(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    final value = double.tryParse(cleaned);
    if (value == null) return raw;
    if (value % 1 == 0) {
      return NumberFormat('#,##0', 'en_US').format(value);
    }
    return NumberFormat('#,##0.##', 'en_US').format(value);
  }

  Widget _buildHrCard({
    required dynamic item,
    required String reqNo,
    required String requestType,
    required String employeeName,
    required String empCode,
    required String date,
  }) {
    return Container(
      width: 350.w,
      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE1E4E8),
            Color(0xFFB9C0CB),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFF7B828B), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.95),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _buildEmployeeImage(
                      item["requester_image"] ??
                          item["employee_image"] ??
                          item["emp_image"] ??
                          item["image_emp"],
                      44.w),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Center(
                  child: Text(
                    reqNo.toUpperCase(),
                    style: GoogleFonts.nunito(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0B387A),
                      letterSpacing: 0.4,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(width: 54.w),
            ],
          ),
          SizedBox(height: 10.w),
          Text(
            requestType.toUpperCase(),
            style: GoogleFonts.nunito(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F1114),
              letterSpacing: 0.2,
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.w),
          Text(
            employeeName,
            style: GoogleFonts.nunito(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5B616A),
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.5.w),
          Text(
            empCode,
            style: GoogleFonts.nunito(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF6B717B),
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.w),
          Text(
            date,
            style: GoogleFonts.nunito(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF707780),
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPettyCashCard({
    required dynamic item,
    required String refNo,
    required String title,
    required String subtitle,
    required String date,
    required String amount,
  }) {
    final amountText = _formatAmountForCard(amount);

    return Container(
      width: 350.w,
      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE1E4E8),
            Color(0xFFB9C0CB),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFF7B828B), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.95),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _buildEmployeeImage(
                      item["requester_image"] ??
                          item["employee_image"] ??
                          item["emp_image"] ??
                          item["image_emp"],
                      44.w),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Center(
                  child: Text(
                    refNo.toUpperCase(),
                    style: GoogleFonts.nunito(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0B387A),
                      letterSpacing: 0.4,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(width: 54.w),
            ],
          ),
          SizedBox(height: 10.w),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.nunito(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F1114),
              letterSpacing: 0.2,
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 3.w),
          Text(
            subtitle.toUpperCase(),
            style: GoogleFonts.nunito(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF737A83),
              letterSpacing: 0.4,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.w),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  date,
                  style: GoogleFonts.nunito(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF707780),
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                amountText,
                style: GoogleFonts.nunito(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0B387A),
                  letterSpacing: 0.2,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
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
        kBottomNavigationBarHeight + context.systemBottomInset + 100.h;

    return Expanded(
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 5) +
            EdgeInsets.only(bottom: totalBottomPadding, top: 120.w),
        itemCount: approvalItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 1),
        itemBuilder: (context, index) {
          final item = approvalItems[index];
          String category = (item["category"]?.toString().isNotEmpty == true)
              ? item["category"].toString()
              : (item["type"]?.toString().isNotEmpty == true)
                  ? item["type"].toString()
                  : categoryType;
          String type = item["type"] ?? "";
          String id = item["id"]?.toString() ?? "";
          final isHr = category.toString().toUpperCase() == 'HR';

          // Debug: Print all available fields for HR items
          if (kDebugMode && isHr && index == 0) {
            print('🔍 HR Item Fields: ${item.keys.toList()}');
            print('📋 HR Item Data: $item');
          }

          // Use _getSafeString to handle false/true values properly
          String employeeName = _getSafeString(
              item["employee_name"] ??
                  item["requester_name"] ??
                  item["emp_name"],
              "N/A");

          String empCode = _getSafeString(
              item["emp_code"] ??
                  item["employee_code"] ??
                  item["requester_code"] ??
                  item["emp_id"]?.toString() ??
                  item["employee_id"]?.toString() ??
                  item["requester_id"]?.toString() ??
                  item["requester_emp_id"]?.toString() ??
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
              item["type"] ??
                  item["request_type"] ??
                  item["holiday_status_name"] ??
                  item["request_type_name"] ??
                  item["holiday_status_id"] ??
                  item["leave_type"] ??
                  item["subject"] ??
                  item["title"],
              "HR Request");

            String date = _getSafeString(
              item["date"] ??
                item["request_date"] ??
                item["created_date"] ??
                item["submission_date"],
              "");

          String pettySubtitle = _getSafeString(
              item["project_title"] ??
                  item["project_name"] ??
                  item["project"] ??
                  item["client_name"] ??
                  item["client"] ??
                  item["partner_name"] ??
                  item["location"],
              "N/A");

          return GestureDetector(
            onTap: () async {
              // Mark item as viewed
              print('🔵 Marking as viewed - Category: $category, ID: $id');
              await ApprovalViewedService.markAsViewed(
                category,
                id,
              );

              if (context.mounted) {
                final upperCategory = category.toString().toUpperCase();
                final result = upperCategory == 'HR'
                    ? await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HrDetailsScreen(
                            requestId: id,
                            type: category,
                          ),
                        ),
                      )
                    : upperCategory == 'PETTY CASH'
                        ? await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PettyCashDetailsScreen(
                                requestId: id,
                                type: category,
                                initialData: Map<String, dynamic>.from(item as Map),
                              ),
                            ),
                          )
                        : await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return ApprovalConfirmationScreen(
                                requestId: id,
                                type: category,
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
                    date: date.isNotEmpty ? date : 'N/A',
                  )
                : _buildPettyCashCard(
                    item: item,
                    refNo: reqNo,
                    title: employeeName,
                    subtitle: pettySubtitle,
                    date: date.isNotEmpty ? date : 'N/A',
                    amount: amount,
                  ),
          );
        },
      ),
    );
  }
}
