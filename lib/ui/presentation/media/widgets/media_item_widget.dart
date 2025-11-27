import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/media_model.dart';

class MediaItemWidget extends StatelessWidget {
  final MediaModel media;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MediaItemWidget({
    super.key,
    required this.media,
    this.onTap,
    this.onLongPress,
  });

  Widget _buildImageThumbnail() {
    String imageUrl = media.previewUrl;
    // Use a consistent inner padding and show a thin border around thumbnail
    final double pad = 12.w;
    final borderRadius = BorderRadius.circular(10.r);

    Widget buildAssetImage() {
      return Image.asset(
        imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.image,
            size: 30.sp,
            color: Colors.blue,
          );
        },
      );
    }

    Widget buildNetworkImage() {
      return Image.network(
        imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.image,
            size: 30.sp,
            color: Colors.blue,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }

    final Widget inner = imageUrl.startsWith('assets/')
        ? buildAssetImage()
        : buildNetworkImage();

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: appFontColor.withOpacity(0.12), width: 1),
          borderRadius: borderRadius,
        ),
        clipBehavior: Clip.hardEdge,
        child: ClipRRect(borderRadius: borderRadius, child: inner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: appFontColor.withOpacity(0.9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            ClipRRect(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14.r),
                  topRight: Radius.circular(14.r)),
              child: SizedBox(
                width: double.infinity,
                height: 170.h,
                child: _buildImageThumbnail(),
              ),
            ),

            // Content — use the same inner padding as thumbnail
            Padding(
              padding: EdgeInsets.only(
                  left: 18.w, right: 18.w, top: 12.w, bottom: 12.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          media.displayName,
                          style: GoogleFonts.koulen(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w600,
                            color: appFontColor,
                            letterSpacing: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (media.client != null &&
                            media.client!.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            media.client!,
                            style: GoogleFonts.koulen(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: appFontColor,
                              letterSpacing: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 20.sp,
                              color: const Color(0xFFB0B0B0),
                            ),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(media.dateCreated),
                                style: GoogleFonts.koulen(
                                  fontSize: 14.sp,
                                  color: const Color(0xffB0B0B0),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action icons (360 and share) — horizontal row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: SizedBox(
                          width: 25.w,
                          height: 25.h,
                          child: Image.asset(
                            'assets/png/icons/Frame (1).png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      SizedBox(width: 25.w),
                      GestureDetector(
                        onTap: () {},
                        child: SizedBox(
                          width: 25.w,
                          height: 25.h,
                          child: Image.asset(
                            'assets/png/icons/Capa_1.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // removed unused _buildMediaIcon to avoid unused declaration warnings
}
