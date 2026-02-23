import 'package:el_race/ui/presentation/my_actions/data/my_actions_models.dart';
import 'package:el_race/ui/presentation/my_actions/data/my_actions_repository.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final MyActionsRepository _repo = MyActionsRepository();
  late final Future<List<MyActionItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchByType(MyActionsType.reports);
  }

  /// Map status strings to badge assets.
  String _statusBadgeAsset(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
      case 'approve':
      case 'done':
      case 'paid':
        return 'assets/newapp/approvedBadge.png';
      case 'pending':
      case 'submit':
      case 'draft':
        return 'assets/newapp/warningBadge.png';
      case 'rejected':
      case 'cancel':
        return 'assets/newapp/rejectBadge.png';
      default:
        return 'assets/newapp/warningBadge.png';
    }
  }

  Future<void> _openReportLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: const HeaderWidget(),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<MyActionItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off,
                          size: 60.w, color: const Color(0xFFB5B7C1)),
                      SizedBox(height: 16.h),
                      Text(
                        'Service not available',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5A5A5A),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'This feature is currently unavailable.\nPlease try again later.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: const Color(0xFF9AA0A6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final items = snapshot.data ?? const <MyActionItem>[];

            // Map API items to display items
            final reportItems = items.map((item) {
              return _ReportRequestItem(
                reportId: item.id,
                reportName: item.name.trim().isNotEmpty
                    ? item.name
                    : 'Report #${item.id}',
                project: item.project?.trim().isNotEmpty == true
                    ? item.project!
                    : '',
                statusBadgeAsset: _statusBadgeAsset(item.status),
                statusText: item.status.trim().isNotEmpty
                    ? item.status[0].toUpperCase() +
                        item.status.substring(1).toLowerCase()
                    : '',
                reportLink: item.reportLink?.trim().isNotEmpty == true
                    ? item.reportLink!
                    : '',
                clientImage: item.clientImage?.trim().isNotEmpty == true
                    ? item.clientImage!
                    : '',
              );
            }).toList();

            return ListView(
              padding: EdgeInsets.only(top: 8.h, bottom: 80.h),
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/png/my-reports-frame.png',
                          width: 26.w,
                          height: 26.w,
                          fit: BoxFit.contain,
                          color: const Color(0xFFD21B2E),
                          colorBlendMode: BlendMode.srcIn,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'MY REPORTS',
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF101C36),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (reportItems.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 24.h),
                    child: Center(
                      child: Text(
                        'No reports found.',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5A5A5A),
                        ),
                      ),
                    ),
                  )
                else
                  ...reportItems.map(
                    (item) => Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 7.h),
                      child: _ReportRequestCard(
                        item: item,
                        onOpenLink: item.reportLink.isNotEmpty
                            ? () => _openReportLink(item.reportLink)
                            : null,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/* ───────────────────────────── Card ───────────────────────────── */

class _ReportRequestCard extends StatelessWidget {
  final _ReportRequestItem item;
  final VoidCallback? onOpenLink;

  const _ReportRequestCard({required this.item, this.onOpenLink});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 152.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: const Color(0xFF9F9F9F), width: 1),
      ),
      child: Stack(
        children: [
          // Status ribbon (top-left corner)
          Positioned(
            top: 0,
            left: 0,
            child: ClipRRect(
              borderRadius:
                  BorderRadius.only(topLeft: Radius.circular(30.r)),
              child: Image.asset(
                item.statusBadgeAsset,
                width: 73.w,
                height: 41.h,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report ID (centered, blue)
                Center(
                  child: Text(
                    'Report #${item.reportId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A3887),
                    ),
                  ),
                ),
                SizedBox(height: 6.h),

                // Report name (left-aligned, bold)
                Text(
                  item.reportName.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111111),
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 2.h),

                // Project name (if available)
                if (item.project.isNotEmpty)
                  Text(
                    item.project,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF777777),
                    ),
                  ),

                const Spacer(),

                // Bottom row: status left + report link icon right
                Row(
                  children: [
                    // Status text
                    if (item.statusText.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: _statusBgColor(item.statusText),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          item.statusText,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: _statusTextColor(item.statusText),
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Download / view link button
                    if (onOpenLink != null)
                      GestureDetector(
                        onTap: onOpenLink,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A3887),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.picture_as_pdf_rounded,
                                size: 14.w,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'View PDF',
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        'No file',
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB8B8B8),
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

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFFE8F5E9);
      case 'pending':
      case 'draft':
        return const Color(0xFFFFF3E0);
      case 'rejected':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _statusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'pending':
      case 'draft':
        return const Color(0xFFE65100);
      case 'rejected':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF616161);
    }
  }
}

/* ──────────────────────── Data model ──────────────────────── */

class _ReportRequestItem {
  final int reportId;
  final String reportName;
  final String project;
  final String statusBadgeAsset;
  final String statusText;
  final String reportLink;
  final String clientImage;

  const _ReportRequestItem({
    required this.reportId,
    required this.reportName,
    required this.project,
    required this.statusBadgeAsset,
    required this.statusText,
    required this.reportLink,
    required this.clientImage,
  });
}
