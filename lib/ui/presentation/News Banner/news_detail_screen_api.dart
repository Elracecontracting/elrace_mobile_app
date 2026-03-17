import 'package:el_race/data/models/announcement_model.dart';
import 'package:el_race/data/models/announcement_details_model.dart';
import 'package:el_race/data/services/announcements_api_service.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// News detail screen that displays full announcement details from API
class NewsDetailScreenAPI extends StatefulWidget {
  final AnnouncementModel newsItem;

  const NewsDetailScreenAPI({
    super.key,
    required this.newsItem,
  });

  @override
  State<NewsDetailScreenAPI> createState() => _NewsDetailScreenAPIState();
}

class _NewsDetailScreenAPIState extends State<NewsDetailScreenAPI> {
  final AnnouncementsApiService _apiService = AnnouncementsApiService();

  AnnouncementDetailsModel? _details;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final details = await _apiService.fetchAnnouncementDetails(
        announcementId: widget.newsItem.id,
      );

      if (!mounted) return;
      setState(() {
        _details = details;
      });
    } catch (_) {
      // Fallback to list item data if details endpoint fails.
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingDetails = false;
      });
    }
  }

  String get _title {
    final detailsTitle = _details?.title.trim() ?? '';
    if (detailsTitle.isNotEmpty) return detailsTitle;
    return widget.newsItem.name;
  }

  String get _content {
    final detailsText = _details?.announcementText.trim() ?? '';
    if (detailsText.isNotEmpty) return detailsText;
    return widget.newsItem.description;
  }

  String? get _imageUrl {
    final detailsAttachment = _details?.attachmentUrl?.trim() ?? '';
    if (detailsAttachment.isNotEmpty) return detailsAttachment;
    return widget.newsItem.attachmentUrl;
  }

  bool get _hasAttachment {
    if (_details != null) return _details!.hasAttachment;
    return widget.newsItem.hasAttachment;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderWidget(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoadingDetails) const LinearProgressIndicator(minHeight: 2),

            // News image if available
            if (_hasAttachment && _imageUrl != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    _imageUrl!,
                    width: double.infinity,
                    height: 250.h,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 250.h,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        size: 60.w,
                        color: Colors.grey[600],
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: 250.h,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // News title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                _title,
                textAlign: TextAlign.left,
                style: GoogleFonts.koulen(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w600,
                  color: appFontColor,
                  letterSpacing: 1.2,
                  height: 1.3,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Full description with padding
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _content,
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      color: const Color(0xFF374151),
                      height: 1.8,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
