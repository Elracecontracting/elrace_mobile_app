import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.image,
            size: 30.sp,
            color: Colors.blue,
          );
        },
      );
    } else {
      return Image.network(
        imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
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
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMediaIcon(),
          const SizedBox(height: 10),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.name,
                    style: GoogleFonts.koulen(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      color: appFontColor,
                      letterSpacing: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  if (media.isVideo && media.duration != null) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 14.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${media.duration} seconds',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                  Text(
                    media.dateCreated.toString(),
                    style: GoogleFonts.koulen(
                      fontSize: 12.sp,
                      color: const Color(0xffB0B0B0),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildMediaIcon() {
    if (media.isImage) {
      return Container(
        width: double.infinity,
        height: 200.h,
        decoration: BoxDecoration(
          color: Colors.blue..withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: media.previewUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: _buildImageThumbnail(),
              )
            : Icon(
                Icons.image,
                size: 30.sp,
                color: Colors.blue,
              ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: 200.h,
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: const AssetImage("assets/png/video_preview.png"),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(36.r),
        ),
        child: media.previewUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
              )
            : Icon(
                Icons.videocam,
                size: 30.sp,
                color: Colors.red,
              ),
      );
    }
  }
}
