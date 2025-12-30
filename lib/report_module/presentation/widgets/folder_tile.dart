import 'package:el_race/report_module/core/constants/colors.dart';
import 'package:el_race/report_module/core/constants/text_styles.dart';
import 'package:el_race/report_module/data/models/folder_model.dart';
import 'package:el_race/report_module/presentation/screens/report_listing/folder_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class FolderTile extends StatelessWidget {
  final FolderModel folder;
  final VoidCallback onMoreClicked;
  const FolderTile(
      {super.key, required this.folder, required this.onMoreClicked});

  @override
  Widget build(BuildContext context) {
    final String day = DateFormat.d().format(folder.createdAt);
    final String month = DateFormat.MMMM().format(folder.createdAt);
    final String year = DateFormat.y().format(folder.createdAt);
    final String formattedDate =
        DateFormat("dd MMM yyyy, HH:mma").format(folder.createdAt);

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FolderReportScreen(folder: folder)));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 180.h,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/png/background.png"),
                fit: BoxFit.fill,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 16.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/png/my_documents.png",
                            height: 22.h,
                            width: 22.w,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              folder.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.koulen(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      if (folder.description.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(right: 12.w),
                          child: Text(
                            folder.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: CustomTextStyle.reportHeader.copyWith(
                              fontWeight: FontWeight.normal,
                              color: CustomColors.black,
                            ),
                          ),
                        ),
                      SizedBox(height: 12.h),
                      Text(
                        formattedDate,
                        style: CustomTextStyle.smallGrey.copyWith(
                          color: CustomColors.black,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: CustomColors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 4.h, horizontal: 12.w),
                            child: Text(
                              "Project",
                              style: CustomTextStyle.smallWhite,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 6.w,
                  top: 6.h,
                  child: InkWell(
                      onTap: onMoreClicked,
                      child: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.black,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
