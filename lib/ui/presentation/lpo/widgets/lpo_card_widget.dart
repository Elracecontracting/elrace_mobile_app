import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class LpoCardWidget extends StatelessWidget {
  const LpoCardWidget({
    super.key,
    this.name,
    this.vendorName,
    this.date,
    this.amount,
    this.lpoCount,
  });

  final String? name;
  final String? vendorName;
  final String? date;
  final String? amount;
  final String? lpoCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showAttachmentDialog(context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/png/background.png"),
                fit: BoxFit.fill,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(36, 16, 16, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                "assets/newapp/my_projects.png",
                                height: 26.w,
                                width: 26.w,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                name ?? 'item.name',
                                style: GoogleFonts.koulen(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  letterSpacing: 1.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // const Icon(Icons.more_horiz,
                      //     size: 20, color: Colors.black),
                    ],
                  ),
                  const SizedBox(height: 25),

                  Transform.translate(
                    offset: Offset(0, -15.w),
                    child: Row(

                      children: [
                        // SizedBox(
                        //   width: 200,
                        //   child: Text(
                        //     item.partnerId,
                        //     style: GoogleFonts.koulen(
                        //       fontSize: 12,
                        //       color: Colors.black,
                        //       letterSpacing: 1.0,
                        //     ),
                        //     overflow: TextOverflow.ellipsis,
                        //     maxLines: 2,
                        //     softWrap: false,
                        //   ),
                        // ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  "assets/png/icons/tag.png",
                                  height: 11.86.w,
                                  width: 11.2.w,
                                  color: black,
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    'LPO NO',
                                    //  (lpoCount ?? 'LPO NO').toString(),
                                    style: GoogleFonts.koulen(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: black,
                                    ),
                                  ),
                                ),
                                // const SizedBox(width: 8),
                                // Text(
                                //   (lpoCount ?? '').toString(),
                                //   style: GoogleFonts.koulen(
                                //     fontSize: 12,
                                //     fontWeight: FontWeight.w600,
                                //     color: black,
                                //   ),
                                // ),
                              ],
                            ),
                            //const SizedBox(height: 3),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      "assets/png/icons/hand.png",
                                      height: 12.8.w,
                                      width: 19.57.w,
                                      color: black,
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 170.w,
                                      child: Text(
                                        vendorName ?? 'Vendor Name',
                                        maxLines: 1,
                                        style: GoogleFonts.koulen(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: black,
                                          //letterSpacing: 1.0,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                // Container(
                                //     padding: const EdgeInsets.all(6),
                                //     margin: const EdgeInsets.only(right: 10, bottom: 20),
                                //     decoration: BoxDecoration(
                                //       color: Colors.transparent,
                                //       shape: BoxShape.circle,
                                //       border: Border.all(color: greyText, width: 2),
                                //     ),
                                //     child: Text(
                                //       '+12',
                                //       style: GoogleFonts.koulen(
                                //         fontSize: 20.sp,
                                //         fontWeight: FontWeight.w500,
                                //         color: AppColors.green,
                                //       ),
                                //     )),
                              ],
                            ),
                            Container(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/png/profile_1.png',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 60.w,
                          height: 100.w,
                          margin: EdgeInsets.only(
                            right: 10.w,
                          ),
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(11.9),
                                topRight: Radius.circular(11.9),
                                bottomLeft: Radius.circular(11.9),
                              )
                              // image: DecorationImage(
                              //   image: AssetImage("assets/png/date_box_bg.png"),
                              //   fit: BoxFit.contain,
                              // ),
                              ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 50.w,
                                height: 50,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ) +
                                    const EdgeInsets.only(top: 10),
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(
                                        "assets/png/date_box_bg.png"),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                child: Text(
                                  Util.isValidDateTime(date ?? 'item.date')
                                      ? DateTime.parse(date!).day.toString()
                                      : '',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Util.isValidDateTime(date ?? 'item.date')
                                    ? DateFormat.MMMM()
                                        .format(DateTime.parse(date!))
                                    : '',
                                style: GoogleFonts.inter(
                                  fontSize: 9.w,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                Util.isValidDateTime(date ?? 'item.date')
                                    ? DateTime.parse(date!).year.toString()
                                    : '',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-20.w, -17.h),
            child: Align(
              alignment: Alignment.centerRight,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    width: 20.w,
                    height: 27.w,
                    margin: EdgeInsets.only(
                      left: 40.w,
                    ),
                    decoration: BoxDecoration(
                      color: red,
                      boxShadow: [
                        BoxShadow(
                          color: red.withValues(alpha: 0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 37.w,
                    width: 210.w,
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.only(left: 30.w),
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage(
                                'assets/png/lpo_blue_container.png'))),
                    child: SizedBox(
                      width: 200.w,
                      child: Text(
                        ('AMOUNT: $amount'),
                        style: GoogleFonts.koulen(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


void showAttachmentDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: _buildDialogContent(context),
      );
    },
  );
}

Widget _buildDialogContent(BuildContext context) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: -0.8, // in radians (not degrees)
              child: const Icon(
                Icons.attachment,
                color: Colors.black,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "ATTACHMENTS",
              style: GoogleFonts.koulen(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                //letterSpacing: 1.2,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 🔸 LPO No
        Row(
          children: [
            const Icon(Icons.tag, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(
              "LPO NO",
              style: GoogleFonts.koulen(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 🔸 Vendor Name
        Row(
          children: [
            const Icon(Icons.handshake, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              "VENDOR NAME",
              style: GoogleFonts.koulen(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 🔸 Project Name
        Row(
          children: [
            const Icon(Icons.business_center, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            Text(
              "PROJECT NAME",
              style: GoogleFonts.koulen(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // 🔘 Button
        Center(
          child: SizedBox(
            width: 180,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF191F52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                // TODO: Add your view attachment logic here
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: -0.8, // in radians (not degrees)
                    child: const Icon(
                      Icons.attachment,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "VIEW ATTACHMENT",
                    style: GoogleFonts.koulen(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

