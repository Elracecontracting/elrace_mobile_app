import 'dart:async';

import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/media_bloc.dart';
import '../data/media_model.dart';
import '../widgets/media_item_widget.dart';
import 'yoyo_video_player_screen.dart';

class MediaListScreen extends StatefulWidget {
  const MediaListScreen({super.key});

  @override
  State<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends State<MediaListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _showSearch = false;
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
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is MediaActionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is MediaActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Media action completed successfully')),
            );
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 10.h, bottom: 16.h),
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
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        if (state is MediaLoaded)
                          (() {
                            final q =
                                _searchController.text.trim().toLowerCase();
                            final list = q.isEmpty
                                ? state.mediaList
                                : state.mediaList.where((m) {
                                    final name = m.name.toLowerCase();
                                    final typeLabel =
                                        m.isImage ? 'image' : 'video';
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
                                            SizedBox(height: 12.w),
                                  );
                          })()
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
    return Row(
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
          hintStyle: TextStyle(fontSize: 12.sp, color: appFontColor),
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
          hintStyle: TextStyle(fontSize: 12.sp, color: appFontColor),
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
        style: GoogleFonts.koulen(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
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
              style: GoogleFonts.koulen(
                fontSize: 18.sp,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your media collection will appear here',
              style: GoogleFonts.koulen(
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
              style: GoogleFonts.koulen(
                fontSize: 18.sp,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: GoogleFonts.koulen(
                fontSize: 14.sp,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                context.read<MediaBloc>().add(const FetchMediaList());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appFontColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.koulen(
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
          style: GoogleFonts.koulen(
            letterSpacing: 1.0,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type: ${media.isImage ? 'Image' : 'Video'}',
              style: GoogleFonts.koulen(
                fontSize: 14.sp,
                color: Colors.grey[600],
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Created: ${media.dateCreated.day}/${media.dateCreated.month}/${media.dateCreated.year}',
              style: GoogleFonts.koulen(
                fontSize: 14.sp,
                color: Colors.grey[600],
                letterSpacing: 1.0,
              ),
            ),
            if (media.size != null) ...[
              SizedBox(height: 8.h),
              Text(
                'Size: ${media.size!.toStringAsFixed(1)} MB',
                style: GoogleFonts.koulen(
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
                style: GoogleFonts.koulen(
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
              style: GoogleFonts.koulen(
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
          style: GoogleFonts.koulen(
            letterSpacing: 1.0,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this media file?',
          style: GoogleFonts.koulen(
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.koulen(
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
              style: GoogleFonts.koulen(
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
