import 'package:el_race/report_module/data/models/folder_model.dart';
import 'package:el_race/report_module/presentation/screens/report_listing/project_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class FolderTile extends StatelessWidget {
  final FolderModel folder;
  final ValueChanged<String> onMenuSelected;
  final VoidCallback? onTap;

  const FolderTile({
    super.key,
    required this.folder,
    required this.onMenuSelected,
    this.onTap,
  });

  Widget _buildLatestImagesRow() {
    if (folder.latestItemImages.isEmpty) {
      return Text(
        'No images',
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF9AA0A6),
        ),
      );
    }

    final displayCount =
        folder.latestItemImages.length > 5 ? 5 : folder.latestItemImages.length;
    final remaining = folder.reportCount > displayCount
        ? folder.reportCount - displayCount
        : 0;

    return Row(
      children: [
        ...List.generate(displayCount, (index) {
          return Align(
            widthFactor: 0.6,
            child: Container(
              padding: EdgeInsets.only(bottom:1.6.w),
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.6),
              ),
              child: ClipOval(
                child: Image.network(
                  folder.latestItemImages[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE5E7EB),
                    child: Icon(
                      Icons.image,
                      size: 14.w,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        if (remaining > 0)
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: Text(
              '+$remaining',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF27304E),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ProjectReportsScreen(folder: folder)));
          },
      child: Container(
        margin: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
        clipBehavior: Clip.hardEdge,
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: const Color(0xFFBEC1C8),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: Report name + report status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),
                  Text(
                    folder.name.isEmpty ? 'Report Name' : folder.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF27304E),
                    ),
                    maxLines: null,
                    overflow: TextOverflow.visible,
                  ),
                  Text(
                    folder.reportCount == 1
                        ? '1 report item'
                        : '${folder.reportCount} report items',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8A8D97),
                    ),
                    maxLines: null,
                    overflow: TextOverflow.visible,
                  ),
                  SizedBox(height: 5.h),
                  _buildLatestImagesRow(),
                ],
              ),
            ),
            // Right side: three dots + count chart
            SizedBox(
              width: 180.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Three dots at top-right
                  Padding(
                    padding: EdgeInsets.only(right: 2.w),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                      ),
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 16,
                        icon: Icon(
                          Icons.more_vert,
                          size: 20.w,
                          color: const Color(0xFF27304E),
                        ),
                        onSelected: onMenuSelected,
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 18.w,
                                  color: const Color(0xFF27304E),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Rename',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF27304E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 18.w,
                                  color: const Color(0xFFE81E25),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Delete',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFE81E25),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // Chart image with 100 inside
                  SizedBox(
                    width: 190.w,
                    height: 52.h,
                    child: ClipRect(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/png/r1.png',
                              fit: BoxFit.contain,
                              alignment: Alignment.centerRight,
                            ),
                          ),
                          Positioned(
                            right: 8.w,
                            bottom: 2.h,
                            child: Text(
                              folder.reportCount.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF27304E),
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
