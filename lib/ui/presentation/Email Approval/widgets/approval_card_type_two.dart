import 'dart:convert';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ApprovalCardTypeTwo extends StatelessWidget {
  final Map<dynamic, dynamic> item;
  final bool isExpanded;
  final VoidCallback onTap;

  const ApprovalCardTypeTwo({
    super.key,
    required this.item,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String name = item["name"] ?? '';
    String type = item["type"] ?? 'ALL';
    String empName = item["approver"] ?? '';
    String location = item["location"] ?? 'N/A';
    String status = item["status"] ?? 'pending';
    String date = item["date"] ?? '';
    
    List<String> nameParts = name.split(' ');
    List<String> requesterParts = empName.split(" - ");
    String requesterName = requesterParts.isNotEmpty ? requesterParts[0] : '';
    String requesterRole = requesterParts.length > 1 ? requesterParts[1] : '';

    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'approved':
          return Colors.green;
        case 'rejected':
          return Colors.red;
        case 'pending':
        default:
          return Colors.orange;
      }
    }

    return InkWell(
      onTap: onTap,
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
                  child: (item["image_emp"] != null &&
                          item["image_emp"] is String &&
                          (item["image_emp"] as String).isNotEmpty &&
                          (item["image_emp"] as String).toLowerCase() != "false")
                      ? Image.memory(
                          base64Decode(item["image_emp"] as String),
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/png/profile_1.png',
                          fit: BoxFit.cover,
                        ),
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
                        requesterName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(height: 5.w),
                    Text(
                      name,
                      style: TextStyle(color: greyText,fontSize: 13.sp),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 6.w, horizontal: 8.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const InfoContainer(text: 'Job Mission'),
                      SizedBox(height: 6.w),
                      InfoContainer(text: name),
                      SizedBox(height: 6.w),
                      InfoContainer(
                        text: date,
                        icon: Icon(Icons.date_range, size: 14.w, color: const Color(0xFF1A1A53)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 


class InfoContainer extends StatelessWidget {
  final String text;
  final Widget? icon;
  final double? fontSize;
  final double? width;

  const InfoContainer({
    super.key,
    required this.text,
    this.icon,
    this.fontSize,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: 27.w,
      width: width ?? 120.w,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1A1A53), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            SizedBox(width: 2.w),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: fontSize ?? 11.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A53),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}