import 'dart:io';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../utils/di.dart';
import '../data/media_model.dart';
import '../repository/i_media_repository.dart';

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
                        // Always share as link directly
                        await _shareMediaAsLink(context);
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

  // Share media with thumbnail and video URL
  Future<void> _shareMediaAsLink(BuildContext context) async {
    try {
      print('🚀 Starting share process for media: ${media.id} - ${media.name}');

      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preparing share...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      String? shareableUrl;

      // 1. Try to call prepare_share API to get the shareable URL
      try {
        print('📞 Getting media repository...');
        final mediaRepository = sl.get<IMediaRepository>();
        print('✅ Got repository, calling prepareShare...');

        shareableUrl = await mediaRepository.prepareShare(media.id);
        print('📥 Received shareableUrl from API: $shareableUrl');
      } catch (e) {
        print('⚠️ API call failed: $e');
      }

      // 2. If API failed, use x_web_url as fallback
      if (shareableUrl == null || shareableUrl.isEmpty) {
        print('🔄 API failed, using x_web_url as fallback');
        shareableUrl = media.xWebUrl ?? media.streamingUrl;
        print('📤 Using fallback URL: $shareableUrl');
      }

      // Trim whitespace and encode URL to handle spaces
      shareableUrl = shareableUrl?.trim() ?? '';

      // Parse and properly encode the URL to replace spaces with %20
      try {
        final uri = Uri.parse(shareableUrl);
        // Reconstruct URL with properly encoded path
        shareableUrl = uri
            .replace(
              path: uri.pathSegments
                  .map((segment) => Uri.encodeComponent(segment))
                  .join('/'),
            )
            .toString();
      } catch (e) {
        print('⚠️ Could not parse URL for encoding: $e');
        // Fallback: simple space replacement
        shareableUrl = shareableUrl?.replaceAll(' ', '%20') ?? '';
      }

      if (shareableUrl.isEmpty) {
        throw Exception('No URL available to share');
      }

      print('📤 Final shareable URL (encoded): $shareableUrl');

      // 3. Download the thumbnail image if available
      XFile? thumbnailFile;
      if (media.thumbnail != null && media.thumbnail!.isNotEmpty) {
        try {
          print('📥 Downloading thumbnail from: ${media.thumbnail}');

          final response = await http.get(Uri.parse(media.thumbnail!));
          if (response.statusCode == 200) {
            // Get temporary directory
            final tempDir = await getTemporaryDirectory();
            final fileName =
                'share_thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final filePath = '${tempDir.path}/$fileName';

            // Save the thumbnail to a temporary file
            final file = File(filePath);
            await file.writeAsBytes(response.bodyBytes);

            thumbnailFile = XFile(filePath);
            print('✅ Thumbnail saved to: $filePath');
          } else {
            print('⚠️ Failed to download thumbnail: ${response.statusCode}');
          }
        } catch (e) {
          print('⚠️ Error downloading thumbnail: $e');
          // Continue without thumbnail if download fails
        }
      }

      // 4. Share the thumbnail image + video URL
      if (thumbnailFile != null) {
        // Share with both thumbnail and URL
        print('📤 Sharing thumbnail + URL');
        await Share.shareXFiles(
          [thumbnailFile],
          text: shareableUrl,
        );
      } else {
        // Share only the URL if thumbnail download failed
        print('📤 Sharing URL only');
        await Share.share(shareableUrl);
      }

      print('✅ Share completed successfully');
    } catch (e, stackTrace) {
      print('❌ Error sharing media: $e');
      print('Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: ${e.toString()}')),
        );
      }
    }
  }

  // removed unused _buildMediaIcon to avoid unused declaration warnings
}
