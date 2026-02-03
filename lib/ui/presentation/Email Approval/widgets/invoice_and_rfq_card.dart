import 'dart:convert';
import 'package:el_race/core/services/approval_viewed_service.dart';
import 'package:el_race/core/services/approval_count_service.dart';
import 'package:el_race/ui/presentation/Email%20Approval/Approval_confirmation.dart';
import 'package:el_race/ui/presentation/Email%20Approval/screens/invoice_details_screen.dart';
import 'package:el_race/ui/presentation/Email%20Approval/screens/rfq_details_screen.dart';
import 'package:el_race/utils/safe_insets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InvoiceAndRfqCard extends StatelessWidget {
  final List<dynamic> approvalItems;
  final VoidCallback? onRefresh;
  const InvoiceAndRfqCard(
      {super.key, required this.approvalItems, this.onRefresh});

  String _formatAmountForCard(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    final value = double.tryParse(cleaned);
    if (value == null) return raw;
    if (value % 1 == 0) {
      return NumberFormat('#,##0', 'en_US').format(value);
    }
    return NumberFormat('#,##0.##', 'en_US').format(value);
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
              'assets/png/police.png',
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
                'assets/png/police.png',
                fit: BoxFit.cover,
                height: size,
                width: size,
              );
            },
          );
        } catch (e) {
          return Image.asset(
            'assets/png/police.png',
            fit: BoxFit.cover,
            height: size,
            width: size,
          );
        }
      }
    }
    // Fallback to default image
    return Image.asset(
      'assets/png/police.png',
      fit: BoxFit.cover,
      height: size,
      width: size,
    );
  }

  Widget _buildRfqCard({
    required dynamic item,
    required String refNo,
    required String vendor,
    required String subtitle,
    required String amount,
  }) {
    final amountText = _formatAmountForCard(amount);

    return Container(
      height: 125.w,
      width: 350.w,
      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 1.w),
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
        border: Border.all(color: const Color(0xFF5F666F), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: 54.w + 12.w + 2.w + 14.w),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        refNo.toUpperCase(),
                        style: GoogleFonts.nunito(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0B2D5E),
                          letterSpacing: 0.4,
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
            SizedBox(
              height: 54.w,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 54.w,
                    height: 54.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.95), width: 2),
                    ),
                    child: ClipOval(
                      child: _buildEmployeeImage(item["image_emp"], 54.w),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    width: 2.w,
                    height: 54.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.toUpperCase(),
                          style: GoogleFonts.nunito(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0E0E10),
                            letterSpacing: 0.2,
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.w),
                        Text(
                          subtitle.toUpperCase(),
                          style: GoogleFonts.nunito(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF6B717B),
                            letterSpacing: 0.2,
                            height: 1.0,
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
            SizedBox(height: 4.w),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  amountText,
                  style: GoogleFonts.nunito(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0B2D5E),
                    letterSpacing: 0.3,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
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
          String type = item["type"] ?? "";
          String id = item["id"]?.toString() ?? "";
          final isRfq = type.toString().toUpperCase() == 'RFQ';

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

          // Check multiple amount fields
          String amount = _getSafeString(
              item["total_amount"] ??
                  item["amount_total"] ??
                  item["amount"] ??
                  item["total"],
              fallback: "0");

          final subtitle = _getSafeString(
            item["partner_name"] ??
                item["requester_name"] ??
                item["emp_name"] ??
                item["project"] ??
                item["project_title"] ??
                item["project"],
            fallback: "",
          );

          final location = _getSafeString(
            item["location"] ??
                item["work_location"] ??
                item["site"] ??
                item["address"],
            fallback: "",
          );

          return GestureDetector(
            onTap: () async {
              // Mark item as viewed
              print('🔵 Marking as viewed - Type: $type, ID: $id');
              await ApprovalViewedService.markAsViewed(
                type,
                id,
              );

              if (context.mounted) {
                final upperType = type.toString().toUpperCase();
                final result = upperType == 'INVOICE'
                    ? await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InvoiceDetailsScreen(
                            requestId: id,
                            type: type,
                          ),
                        ),
                      )
                    : upperType == 'RFQ'
                        ? await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RfqDetailsScreen(
                                requestId: id,
                                type: type,
                              ),
                            ),
                          )
                        : await showDialog(
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
            child: isRfq
                ? _buildRfqCard(
                    item: item,
                    refNo: refNo,
                    vendor: vendor,
                    subtitle: subtitle,
                    amount: amount,
                  )
                : _buildRfqCard(
                    item: item,
                    refNo: refNo,
                    vendor: _getSafeString(
                      item["project_title"] ?? item["project"] ?? item["name"],
                    ),
                    subtitle: _getSafeString(
                      item["client_name"] ?? item["client"] ?? item["partner_name"],
                      fallback: 'N/A',
                    ),
                    amount: amount,
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
