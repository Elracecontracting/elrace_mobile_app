import 'package:el_race/ui/presentation/my_actions/data/my_actions_models.dart';
import 'package:el_race/ui/presentation/my_actions/data/my_actions_repository.dart';
import 'package:el_race/ui/presentation/my_documents/screens/attachment_viewer_screen.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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

  String _formatDisplayDate(String? rawDate) {
    final input = (rawDate ?? '').trim();
    if (input.isEmpty) return '';

    final parsed = DateTime.tryParse(input);
    if (parsed == null) return input;

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    final hour24 = parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final isPm = hour24 >= 12;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final period = isPm ? 'Pm' : 'Am';

    return '$day/$month/$year  At $hour12:$minute $period';
  }

  Future<void> _openReportLink(
    BuildContext context,
    _ReportRequestItem item,
  ) async {
    final uri = Uri.tryParse(item.reportLink);
    if (uri == null || item.reportLink.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file URL available')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttachmentViewerScreen(
          publicUrl: item.reportLink,
          title:
              item.reportName.trim().isEmpty ? 'Attachment' : item.reportName,
        ),
      ),
    );
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
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5A5A5A),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'This feature is currently unavailable.\nPlease try again later.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
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
                displayDate: _formatDisplayDate(item.date),
                reportLink: item.reportLink?.trim().isNotEmpty == true
                    ? item.reportLink!
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
                          style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
                      child: _ReportRequestCard(
                        item: item,
                        onTap: item.reportLink.isNotEmpty
                            ? () => _openReportLink(context, item)
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
  final VoidCallback? onTap;

  const _ReportRequestCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        height: 102.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: const Color(0xFFA9A9A9), width: 1),
        ),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Row(
          children: [
            Image.asset(
              'assets/newapp/pdf.png',
              width: 70.w,
              height: 70.w,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.reportName.trim().isEmpty
                        ? 'File Name'
                        : item.reportName,
                    maxLines: null,
                    overflow: TextOverflow.visible,
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111111),
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    item.displayDate.isEmpty ? '-' : item.displayDate,
                    maxLines: null,
                    overflow: TextOverflow.visible,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF232323),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ──────────────────────── Data model ──────────────────────── */

class _ReportRequestItem {
  final int reportId;
  final String reportName;
  final String displayDate;
  final String reportLink;

  const _ReportRequestItem({
    required this.reportId,
    required this.reportName,
    required this.displayDate,
    required this.reportLink,
  });
}
