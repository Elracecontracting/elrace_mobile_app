import 'package:el_race/data/models/announcement_model.dart';
import 'package:el_race/data/services/announcements_api_service.dart';
import 'package:el_race/providers/announcements_provider.dart';
import 'package:el_race/ui/presentation/News%20Banner/news_detail_screen_api.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch news on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementsProvider>().fetchAnnouncements(
            category: AnnouncementCategory.news,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: Consumer<AnnouncementsProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Header section
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/png/news_logo.png',
                            height: 24.h,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.article,
                                size: 24.h,
                                color: appFontColor),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            translate('home.news'),
                            style: GoogleFonts.koulen(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w400,
                              color: appFontColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Content based on state
                if (provider.isLoading)
                  _buildLoadingState()
                else if (provider.hasError)
                  _buildErrorState(provider)
                else if (provider.isEmpty)
                  _buildEmptyState()
                else if (provider.hasData)
                  _buildNewsList(provider.announcements),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(appFontColor),
            ),
            SizedBox(height: 16.h),
            Text(
              'Loading news...',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(AnnouncementsProvider provider) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.w,
                color: Colors.red[400],
              ),
              SizedBox(height: 16.h),
              Text(
                'Error',
                style: GoogleFonts.koulen(
                  fontSize: 24.sp,
                  color: Colors.red[700],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                provider.errorMessage ?? 'An error occurred',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: () => provider.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appFontColor,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64.w,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No News Available',
              style: GoogleFonts.koulen(
                fontSize: 24.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'There are no news items to display at the moment.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build news list
  Widget _buildNewsList(List<AnnouncementModel> newsList) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final newsItem = newsList[index];
            return _buildNewsCard(newsItem);
          },
          childCount: newsList.length,
        ),
      ),
    );
  }

  /// Build individual news card
  Widget _buildNewsCard(AnnouncementModel newsItem) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreenAPI(newsItem: newsItem),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // News image if available
              if (newsItem.hasAttachment && newsItem.attachmentUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    newsItem.attachmentUrl!,
                    width: double.infinity,
                    height: 200.h,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 200.h,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50.w,
                        color: Colors.grey[600],
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: 200.h,
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
                SizedBox(height: 12.h),
              ],

              // Title
              Text(
                newsItem.name,
                style: GoogleFonts.koulen(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: appFontColor,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 12.h),

              // Description preview (first 150 characters)
              Text(
                _getDescriptionPreview(newsItem.description),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),

              // Bottom action row
              SizedBox(height: 12.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NewsDetailScreenAPI(newsItem: newsItem),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: appFontColor,
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                  child: Text(
                    'Read More',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get description preview (first 150 characters)
  String _getDescriptionPreview(String description) {
    if (description.length <= 150) {
      return description;
    }
    return '${description.substring(0, 150)}...';
  }
}
