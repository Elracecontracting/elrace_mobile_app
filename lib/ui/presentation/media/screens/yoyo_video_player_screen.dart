import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lecle_yoyo_player/lecle_yoyo_player.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/media_model.dart';
import '../../../widgets/header_widget.dart';

class YoYoVideoPlayerScreen extends StatefulWidget {
  final MediaModel media;

  const YoYoVideoPlayerScreen({
    super.key,
    required this.media,
  });

  @override
  State<YoYoVideoPlayerScreen> createState() => _YoYoVideoPlayerScreenState();
}

class _YoYoVideoPlayerScreenState extends State<YoYoVideoPlayerScreen> {
  bool fullscreen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: fullscreen ? null : const HeaderWidget(),
      body: Column(
        children: [
          // Video title (only show when not in fullscreen)
          if (!fullscreen)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  const BackButton(color: Colors.white,),
                  Expanded(
                    child: Text(
                      widget.media.name,
                      style: GoogleFonts.koulen(
                        fontSize: 18.sp,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Download button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: IconButton(
                      onPressed: () async {
                        try {
                          final downloadUrl = widget.media.downloadUrl;
                          if (downloadUrl.isNotEmpty) {
                            await launchUrl(Uri.parse(downloadUrl));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Download URL not available')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to open download link')),
                          );
                        }
                      },
                      icon: Icon(
                        Icons.download,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // YoYo Video Player
          Expanded(
            child: YoYoPlayer(
              aspectRatio: 16 / 9,
              url: widget.media.streamingUrl,
              videoStyle: const VideoStyle(
                qualityStyle: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                forwardAndBackwardBtSize: 30.0,
                playButtonIconSize: 40.0,
                playIcon: Icon(
                  Icons.play_circle_filled,
                  size: 40.0,
                  color: Colors.white,
                ),
                pauseIcon: Icon(
                  Icons.pause_circle_filled,
                  size: 40.0,
                  color: Colors.white,
                ),
                videoQualityPadding: EdgeInsets.all(5.0),
              ),
              videoLoadingStyle: VideoLoadingStyle(
                loading: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "Loading video...",
                        style: GoogleFonts.koulen(
                          fontSize: 16.sp,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              allowCacheFile: true,
              onCacheFileCompleted: (files) {
                print('Cached file length ::: ${files?.length}');
                if (files != null && files.isNotEmpty) {
                  for (var file in files) {
                    print('File path ::: ${file.path}');
                  }
                }
              },
              onCacheFileFailed: (error) {
                print('Cache file error ::: $error');
              },
              onFullScreen: (value) {
                setState(() {
                  if (fullscreen != value) {
                    fullscreen = value;
                  }
                });
              },
            ),
          ),
          
          // Video details (only show when not in fullscreen)
          if (!fullscreen)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.media.size != null)
                    Text(
                      'Size: ${widget.media.size!.toStringAsFixed(1)} MB',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                  if (widget.media.duration != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Duration: ${widget.media.duration} seconds',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Text(
                    'Created: ${widget.media.dateCreated.day}/${widget.media.dateCreated.month}/${widget.media.dateCreated.year}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 