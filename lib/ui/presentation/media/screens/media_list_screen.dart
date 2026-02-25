import 'dart:async';

import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/media_bloc.dart';
import '../data/media_model.dart';
import '../data/content_model.dart';
import '../widgets/media_item_widget.dart';
import '../widgets/content_item_widget.dart';
import 'yoyo_video_player_screen.dart';

class MediaListScreen extends StatefulWidget {
  const MediaListScreen({super.key});

  @override
  State<MediaListScreen> createState() => _MediaListScreenState();
}

enum _MediaFilterTab {
  videos,
  photos,
  view360,
}

class _MediaListScreenState extends State<MediaListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final bool _showSearch = false;
  _MediaFilterTab _activeTab = _MediaFilterTab.videos;
  final GlobalKey _videosTabKey = GlobalKey();
  final GlobalKey _photosTabKey = GlobalKey();
  final GlobalKey _view360TabKey = GlobalKey();

  void _setActiveTab(_MediaFilterTab tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);

    // Fetch appropriate data based on tab
    if (tab == _MediaFilterTab.videos) {
      context.read<MediaBloc>().add(const FetchMediaList());
    } else {
      context.read<MediaBloc>().add(const FetchContents());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? ctx;
      switch (tab) {
        case _MediaFilterTab.videos:
          ctx = _videosTabKey.currentContext;
          break;
        case _MediaFilterTab.photos:
          ctx = _photosTabKey.currentContext;
          break;
        case _MediaFilterTab.view360:
          ctx = _view360TabKey.currentContext;
          break;
      }
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    context.read<MediaBloc>().add(const FetchMediaList());
    _searchController.addListener(() {
      final text = _searchController.text.trim();
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        context.read<MediaBloc>().add(SearchMedia(text));
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: BlocConsumer<MediaBloc, MediaState>(
        listener: (context, state) {
          if (state is MediaError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: GoogleFonts.poppins(),
                ),
              ),
            );
          }
          if (state is MediaActionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: GoogleFonts.poppins(),
                ),
              ),
            );
          }
          if (state is MediaActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Media action completed successfully',
                  style: GoogleFonts.poppins(),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 6.h, bottom: 8.h),
                  child: _buildHeader(),
                ),
              ),
              if (state is MediaLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        if (state is MediaLoaded &&
                            _activeTab == _MediaFilterTab.videos)
                          (() {
                            final q =
                                _searchController.text.trim().toLowerCase();

                            final list = state.mediaList.where((m) {
                              if (!m.isVideo) return false;
                              if (q.isEmpty) return true;

                              final name = m.name.toLowerCase();
                              final typeLabel = m.isImage ? 'image' : 'video';
                              final id = m.id.toLowerCase();
                              final url = (m.url).toLowerCase();
                              final s3 = (m.xWebUrl ?? '').toLowerCase();
                              final ext = m.fileExtension.toLowerCase();
                              return name.contains(q) ||
                                  typeLabel.contains(q) ||
                                  id.contains(q) ||
                                  url.contains(q) ||
                                  s3.contains(q) ||
                                  ext.contains(q);
                            }).toList();

                            return list.isEmpty
                                ? _buildEmptyState()
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: list.length,
                                    itemBuilder: (context, index) {
                                      final media = list[index];
                                      return MediaItemWidget(
                                        media: media,
                                        onTap: () {
                                          if (media.isVideo) {
                                            print(media.previewUrl);
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    YoYoVideoPlayerScreen(
                                                        media: media),
                                              ),
                                            );
                                          } else {
                                            _showMediaDetails(context, media);
                                          }
                                        },
                                        onLongPress: () {
                                          _showDeleteConfirmation(
                                              context, media.id);
                                        },
                                      );
                                    },
                                    separatorBuilder:
                                        (BuildContext context, int index) =>
                                            SizedBox(height: 6.w),
                                  );
                          })()
                        else if (state is ContentsLoaded)
                          _buildContentsList(state.contents)
                        else if (state is MediaError)
                          _buildErrorState(state.message),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/png/camera.png', width: 24.w, height: 24.w),
            const SizedBox(width: 8),
            if (!_showSearch)
              Text(
                translate('home.media'),
                style: GoogleFonts.koulen(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w400,
                  color: appFontColor,
                  letterSpacing: 1.5,
                ),
                overflow: TextOverflow.ellipsis,
              )
            else
              Expanded(child: _buildInlineSearchField()),
          ],
        ),
        SizedBox(height: 10.h),
        _buildFilterTabs(),
        SizedBox(height: 14.h),
      ],
    );
  }

  Widget _buildFilterTabs() {
    const unfocusedStart = Color(0xFFD6D6D6);
    const unfocusedEnd = Color(0xFFADB2BD);
    // Provided as #1B1F26B8 (RRGGBBAA) -> Flutter uses AARRGGBB.
    const focusedStart = Color(0xB81B1F26);
    const focusedEnd = Color(0xFF717171);

    final screenWidth = MediaQuery.sizeOf(context).width;
    // Make tabs slightly smaller so a portion of the next tab is visible.
    final contentWidth =
        screenWidth - 24.w; // header has 12.w horizontal padding
    final tabWidth = contentWidth * 0.40;
    final effectiveTabWidth = tabWidth < 120.w ? 120.w : tabWidth;

    Widget buildTab({
      required _MediaFilterTab tab,
      required Widget child,
      required Key tabKey,
    }) {
      final bool isActive = _activeTab == tab;

      return InkWell(
        borderRadius: BorderRadius.circular(22.r),
        onTap: () {
          _setActiveTab(tab);
        },
        child: Container(
          key: tabKey,
          width: effectiveTabWidth,
          height: 44.h,
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isActive
                  ? const [focusedStart, focusedEnd]
                  : const [unfocusedStart, unfocusedEnd],
            ),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      );
    }

    Text label(String text) {
      return Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 1.0,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          buildTab(
              tab: _MediaFilterTab.videos,
              tabKey: _videosTabKey,
              child: label('VIDEOS')),
          SizedBox(width: 10.w),
          buildTab(
              tab: _MediaFilterTab.photos,
              tabKey: _photosTabKey,
              child: label('PHOTOS')),
          SizedBox(width: 10.w),
          buildTab(
              tab: _MediaFilterTab.view360,
              tabKey: _view360TabKey,
              child: Image.asset(
                'assets/newapp/newicon/360 degrees.png',
                width: 50.w,
                height: 50.w,
                fit: BoxFit.contain,
              )),
        ],
      ),
    );
  }

  // The search field is kept for future use but may be hidden in some screens.
  // ignore: unused_element
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/png/bg_atten.png'),
          fit: BoxFit.none,
        ),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(29.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.2 * 255).toInt()),
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Find media',
          hintStyle: GoogleFonts.poppins(
            fontSize: 12.sp,
            color: appFontColor,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.menu, size: 18, color: appFontColor),
          ),
          suffixIcon: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.search, size: 18, color: appFontColor),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildInlineSearchField() {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/png/bg_atten.png'),
          fit: BoxFit.none,
        ),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(29.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.2 * 255).toInt()),
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Find media',
          hintStyle: GoogleFonts.poppins(
            fontSize: 12.sp,
            color: appFontColor,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.search, size: 18, color: appFontColor),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildFilterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFilterButton('All', () {
          context.read<MediaBloc>().add(const FetchMediaList());
        }),
        _buildFilterButton('Images', () {
          context
              .read<MediaBloc>()
              .add(const FetchMediaByType(MediaType.image));
        }),
        _buildFilterButton('Videos', () {
          context
              .read<MediaBloc>()
              .add(const FetchMediaByType(MediaType.video));
        }),
      ],
    );
  }

  Widget _buildFilterButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: appFontColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildContentsList(ContentsResponse contents) {
    final q = _searchController.text.trim().toLowerCase();

    List<ContentModel> list;
    if (_activeTab == _MediaFilterTab.photos) {
      list = contents.photos;
    } else if (_activeTab == _MediaFilterTab.view360) {
      list = contents.view360;
    } else {
      list = [];
    }

    // Apply search filter
    if (q.isNotEmpty) {
      list = list.where((c) {
        final name = c.fileName.toLowerCase();
        final project = c.projectName.toLowerCase();
        return name.contains(q) || project.contains(q);
      }).toList();
    }

    if (list.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final content = list[index];
        return ContentItemWidget(
          content: content,
          onTap: () => _handleContentTap(context, content),
        );
      },
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(height: 6.w),
    );
  }

  void _handleContentTap(BuildContext context, ContentModel content) async {
    if (content.is360View) {
      // Open 360 view in browser or webview
      final url = Uri.parse(content.previewUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } else {
      // Show photo in full screen or dialog
      _showPhotoPreview(context, content);
    }
  }

  void _showPhotoPreview(BuildContext context, ContentModel content) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  content.previewUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200.w,
                      height: 200.h,
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 200.w,
                    height: 200.h,
                    color: Colors.black54,
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.white, size: 48),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      content.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (content.projectName.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        content.projectName,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.white70,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(50.w),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.perm_media_outlined,
              size: 64.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              'No media files yet',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your media collection will appear here',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: EdgeInsets.all(50.w),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: Colors.red,
            ),
            SizedBox(height: 16.h),
            Text(
              'Error loading media',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                // Retry based on current tab
                if (_activeTab == _MediaFilterTab.videos) {
                  context.read<MediaBloc>().add(const FetchMediaList());
                } else {
                  context.read<MediaBloc>().add(const FetchContents());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appFontColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaDetails(BuildContext context, MediaModel media) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          media.name,
          style: GoogleFonts.poppins(
            letterSpacing: 1.0,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type: ${media.isImage ? 'Image' : 'Video'}',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey[600],
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Created: ${media.dateCreated.day}/${media.dateCreated.month}/${media.dateCreated.year}',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey[600],
                letterSpacing: 1.0,
              ),
            ),
            if (media.size != null) ...[
              SizedBox(height: 8.h),
              Text(
                'Size: ${media.size!.toStringAsFixed(1)} MB',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  letterSpacing: 1.0,
                ),
              ),
            ],
            if (media.isVideo && media.duration != null) ...[
              SizedBox(height: 8.h),
              Text(
                'Duration: ${media.duration} seconds',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String mediaId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Media',
          style: GoogleFonts.poppins(
            letterSpacing: 1.0,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this media file?',
          style: GoogleFonts.poppins(
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                letterSpacing: 1.0,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<MediaBloc>().add(DeleteMedia(mediaId));
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
