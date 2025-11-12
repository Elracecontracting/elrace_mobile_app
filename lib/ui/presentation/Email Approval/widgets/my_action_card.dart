import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/approval_bloc.dart';
import '../bloc/approval_event.dart';
import '../bloc/approval_state.dart';

class MyActionCard extends StatelessWidget {
  final List<dynamic> approvalItems;
  const MyActionCard({super.key, required this.approvalItems});

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
      child: BlocBuilder<ApprovalBloc, ApprovalState>(
        builder: (context, state) {
          final expandedItems = state.expandedItems;
          
          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10) + EdgeInsets.only(bottom: 100.w),
            itemCount: approvalItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = approvalItems[index];
              String reqNo = item["request_no"] ?? item["req_no"] ?? "N/A";
              String title = item["name"] ?? item["title"] ?? "N/A";
              String dateStr = (item["date"] ?? item["request_date"] ?? "").toString().replaceAll('false', '').replaceAll('true', '');
              String status = item["status"] ?? "pending";
              
              DateTime? parsedDate;
              try {
                parsedDate = DateTime.tryParse(dateStr);
              } catch (e) {
                parsedDate = DateTime.now();
              }
              
              return GestureDetector(
                onTap: () {
                  context.read<ApprovalBloc>().add(ToggleItemExpansion(index));
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    expandedItems.contains(index)
                        ? Container(
                            key: ValueKey("expanded_$index"),
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
                                  status.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: status.toLowerCase() == 'approved' || status.toLowerCase() == 'accept'
                                        ? Colors.green
                                        : status.toLowerCase() == 'rejected' || status.toLowerCase() == 'reject'
                                            ? Colors.redAccent
                                            : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 23.sp,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                          )
                        : Container(
                            height: 60.w,
                            alignment: Alignment.center,
                            key: ValueKey("collapsed_$index"),
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            margin: EdgeInsets.only(left: 4.w, top: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border(
                                left: BorderSide(
                                  color: status.toLowerCase() == 'approved' || status.toLowerCase() == 'accept'
                                      ? const Color(0xff009859)
                                      : status.toLowerCase() == 'rejected' || status.toLowerCase() == 'reject'
                                          ? Colors.red
                                          : Colors.orange,
                                  width: 6,
                                ),
                              ),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xffD6D6D6),
                                  Color(0xffADB2BD),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 1),
                                Text(
                                  parsedDate != null 
                                      ? DateFormat('dd MMM yy').format(parsedDate).toUpperCase()
                                      : 'N/A',
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
                                      reqNo,
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
                                    title,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    maxLines: 2,
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
          );
        },
      ),
    );
  }
}