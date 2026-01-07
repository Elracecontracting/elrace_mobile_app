import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

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
    final double pad = 6.w;
    final borderRadius = BorderRadius.circular(8.r);

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: appFontColor.withOpacity(0.9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          ClipRRect(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11.r),
                topRight: Radius.circular(11.r)),
            child: SizedBox(
              width: double.infinity,
              height: 130.h,
              child: _buildImageThumbnail(),
            ),
          ),

          // Content — use the same inner padding as thumbnail
          Padding(
            padding:
                EdgeInsets.only(left: 12.w, right: 12.w, top: 8.w, bottom: 8.w),
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
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: appFontColor,
                          letterSpacing: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (media.client != null && media.client!.isNotEmpty) ...[
                        SizedBox(height: 3.h),
                        Text(
                          media.client!,
                          style: GoogleFonts.koulen(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: appFontColor,
                            letterSpacing: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14.sp,
                            color: const Color(0xFFB0B0B0),
                          ),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(media.dateCreated),
                              style: GoogleFonts.koulen(
                                fontSize: 12.sp,
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

                // Action icons (view and share) — horizontal row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onTap,
                      child: Icon(
                        Icons.visibility_outlined,
                        size: 26.sp,
                        color: appFontColor,
                      ),
                    ),
                    SizedBox(width: 15.w),
                    GestureDetector(
                      onTap: () async {
                        // Share media with other apps
                        String shareText = media.displayName;

                        // Add client name if available
                        if (media.client != null && media.client!.isNotEmpty) {
                          shareText += '\n${media.client}';
                        }

                        // Add URL
                        shareText += '\n${media.url}';

                        // Print to console for debugging
                        print('📤 Sharing media:');
                        print('Name: ${media.displayName}');
                        print('Client: ${media.client}');
                        print('URL: ${media.url}');
                        print('Thumbnail: ${media.thumbnail}');
                        print('Full text: $shareText');

                        // Share with thumbnail if available
                        if (media.thumbnail != null &&
                            media.thumbnail!.isNotEmpty) {
                          try {
                            // Try to share with image
                            await Share.share(
                              shareText,
                              subject: media.displayName,
                            );
                          } catch (e) {
                            print('❌ Error sharing with thumbnail: $e');
                            // Fallback to text only
                            Share.share(
                              shareText,
                              subject: media.displayName,
                            );
                          }
                        } else {
                          // Share text only
                          Share.share(
                            shareText,
                            subject: media.displayName,
                          );
                        }
                      },
                      child: SizedBox(
                        width: 26.w,
                        height: 26.h,
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
    );
  }

  // removed unused _buildMediaIcon to avoid unused declaration warnings
}
