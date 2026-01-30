import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../data/content_model.dart';

class ContentItemWidget extends StatelessWidget {
  final ContentModel content;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ContentItemWidget({
    super.key,
    required this.content,
    this.onTap,
    this.onLongPress,
  });

  Widget _buildThumbnail() {
    final String imageUrl = content.previewUrl;
    final borderRadius = BorderRadius.circular(18.r);
    const borderColor = Color(0xB8484848);

    Widget placeholder() {
      return Container(
        color: Colors.black.withOpacity(0.04),
        alignment: Alignment.center,
        child: Icon(
          content.is360View ? Icons.threesixty : Icons.image_outlined,
          size: 44.sp,
          color: appFontColor.withOpacity(0.55),
        ),
      );
    }

    Widget buildNetworkImage() {
      // Check if URL is a web link (like vercel) vs image
      final isWebUrl = imageUrl.contains('vercel.app') || 
                       imageUrl.contains('.html') ||
                       !_isImageUrl(imageUrl);
      
      if (isWebUrl) {
        return placeholder();
      }

      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => placeholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 22.w,
              height: 22.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: buildNetworkImage(),
      ),
    );
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp') ||
        lower.contains('/image/');
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(22.r);
    const borderColor = Color(0xB8484848);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE6E6E6),
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 10.h, right: 14.w, left: 14.w),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    content.is360View ? '360° VIEW' : 'PHOTO',
                    style: GoogleFonts.koulen(
                      fontSize: 11.sp,
                      color: const Color(0xFF6E6E6E),
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 170.h,
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildThumbnail()),
                      if (content.is360View)
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.threesixty,
                                size: 40.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 16.w,
                  right: 12.w,
                  bottom: 14.h,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content.displayName,
                            style: GoogleFonts.koulen(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                              color: appFontColor,
                              letterSpacing: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (content.projectName.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              content.projectName,
                              style: GoogleFonts.koulen(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: appFontColor.withOpacity(0.75),
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _shareContent(context),
                      icon: Icon(
                        Icons.share_outlined,
                        size: 22.sp,
                        color: appFontColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareContent(BuildContext context) async {
    try {
      final shareText = content.is360View
          ? '${content.fileName}\n360° View: ${content.previewUrl}'
          : '${content.fileName}\n${content.previewUrl}';
      
      await SharePlus.instance.share(
        ShareParams(text: shareText),
      );
    } catch (e) {
      debugPrint('Error sharing content: $e');
    }
  }
}
