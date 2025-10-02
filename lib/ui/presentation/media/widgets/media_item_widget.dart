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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMediaIcon(),
            const SizedBox(height: 10),
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
        ),
      ),
    );
  }

  Widget _buildMediaIcon() {
    if (media.isImage) {
      return Container(
        width: double.infinity,
        height: 200.h,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: media.url.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: media.url.startsWith('assets/')
                    ? Image.asset(
                        media.url,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image,
                            size: 30.sp,
                            color: Colors.blue,
                          );
                        },
                      )
                    : Image.network(
                        media.url,
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
                      ),
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
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: media.url.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (media.url.endsWith('.gif') || media.url.endsWith('.mp4'))
                      media.url.startsWith('assets/')
                          ? Image.asset(
                              media.url,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.videocam,
                                  size: 30.sp,
                                  color: Colors.red,
                                );
                              },
                            )
                          : Image.network(
                              media.url,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.videocam,
                                  size: 30.sp,
                                  color: Colors.red,
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
                            )
                    else
                      Icon(
                        Icons.videocam,
                        size: 30.sp,
                        color: Colors.red,
                      ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
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