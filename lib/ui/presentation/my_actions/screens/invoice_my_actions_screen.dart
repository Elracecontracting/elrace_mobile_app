import 'package:el_race/ui/presentation/my_actions/data/my_actions_models.dart';
import 'package:el_race/ui/presentation/my_actions/data/my_actions_repository.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InvoiceMyActionsScreen extends StatefulWidget {
  const InvoiceMyActionsScreen({super.key});

  @override
  State<InvoiceMyActionsScreen> createState() => _InvoiceMyActionsScreenState();
}

class _InvoiceMyActionsScreenState extends State<InvoiceMyActionsScreen> {
  final MyActionsRepository _repo = MyActionsRepository();
  late final Future<List<MyActionItem>> _future;
  final DateFormat _updatedDateFormat = DateFormat('MM/dd/yyyy');

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchByType(MyActionsType.invoice);
  }

  String _statusBadgeAsset(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return 'assets/newapp/approvedBadge.png';
      case 'pending':
        return 'assets/newapp/warningBadge.png';
      case 'rejected':
        return 'assets/newapp/rejectBadge.png';
      default:
        return 'assets/newapp/warningBadge.png';
    }
  }

  String _formatAmount(double? amount) {
    if (amount == null) return '';
    return '${NumberFormat.decimalPattern().format(amount)} M';
  }

  DateTime? _parseDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) {
      return null;
    }
    final normalized = rawDate.trim().replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized) ?? DateTime.tryParse(rawDate.trim());
  }

  String _formatUpdatedDate(DateTime? dateTime) {
    if (dateTime == null) return '--/--/----';
    return _updatedDateFormat.format(dateTime);
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
            final cards = items.map((item) {
              final updatedDate = _parseDate(item.date);
              final title = (item.project?.trim().isNotEmpty == true)
                  ? item.project!.trim()
                  : (item.vendor ?? '');
              return _InvoiceRequestItem(
                requestNo: (item.reference?.trim().isNotEmpty == true)
                    ? item.reference!.trim()
                    : item.name,
                title: title,
                workOrder: item.vendor ?? '',
                employeeName: item.employeeName,
                amount: _formatAmount(item.amountTotal),
                statusBadgeAsset: _statusBadgeAsset(item.status),
                lastUpdated: _formatUpdatedDate(updatedDate),
                updatedDate: updatedDate,
              );
            }).toList();

            cards.sort((a, b) {
              final aDate = a.updatedDate ?? DateTime(1970, 1, 1);
              final bDate = b.updatedDate ?? DateTime(1970, 1, 1);
              return bDate.compareTo(aDate);
            });

            return ListView(
              padding: EdgeInsets.only(top: 8.h, bottom: 80.h),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/newapp/newicon/invoice_header.png',
                          width: 26.w,
                          height: 26.w,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'INVOICE',
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
                if (cards.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 24.h),
                    child: Center(
                      child: Text(
                        'No actions available.',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5A5A5A),
                        ),
                      ),
                    ),
                  )
                else
                  ...cards.map(
                    (item) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
                      child: _InvoiceRequestCard(item: item),
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

class _InvoiceRequestCard extends StatelessWidget {
  final _InvoiceRequestItem item;

  const _InvoiceRequestCard({required this.item});

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
          Positioned(
            top: 0,
            left: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30.r)),
              child: _StatusBadge(assetPath: item.statusBadgeAsset),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    item.requestNo,
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
                Text(
                  item.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111111),
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.workOrder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF777777),
                  ),
                ),
                Text(
                  item.employeeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF777777),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    SizedBox(width: 86.w),
                    Expanded(
                      child: Center(
                        child: Text(
                          item.amount,
                          style: GoogleFonts.inter(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF073A85),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 92.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Last Updated',
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB8B8B8),
                            ),
                          ),
                          Text(
                            item.lastUpdated,
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB8B8B8),
                            ),
                          ),
                        ],
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
}

class _StatusBadge extends StatelessWidget {
  final String assetPath;

  const _StatusBadge({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: 73.w,
      height: 41.h,
      fit: BoxFit.contain,
    );
  }
}

class _InvoiceRequestItem {
  final String requestNo;
  final String title;
  final String workOrder;
  final String employeeName;
  final String amount;
  final String statusBadgeAsset;
  final String lastUpdated;
  final DateTime? updatedDate;

  const _InvoiceRequestItem({
    required this.requestNo,
    required this.title,
    required this.workOrder,
    required this.employeeName,
    required this.amount,
    required this.statusBadgeAsset,
    required this.lastUpdated,
    required this.updatedDate,
  });
}