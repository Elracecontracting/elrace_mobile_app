import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/ui/presentation/my_actions/data/my_actions_models.dart';
import 'package:el_race/ui/presentation/my_actions/data/my_actions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PettyCashMyActionScreen extends StatefulWidget {
  const PettyCashMyActionScreen({super.key});

  @override
  State<PettyCashMyActionScreen> createState() =>
      _PettyCashMyActionScreenState();
}

class _PettyCashMyActionScreenState extends State<PettyCashMyActionScreen> {
  final MyActionsRepository _repo = MyActionsRepository();
  late final Future<List<MyActionItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchByType(MyActionsType.ptsh);
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
    final formatter = NumberFormat.decimalPattern();
    if (amount == amount.roundToDouble()) {
      return formatter.format(amount.toInt());
    }
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                      Icon(Icons.cloud_off, size: 60.w, color: const Color(0xFFB5B7C1)),
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
            final sectionItems = items
                .map(
                  (e) => _PettyCashRequestItem(
                    requestNo: e.name,
                    amount: _formatAmount(e.amountTotal),
                    employeeName: e.employeeName,
                    statusBadgeAsset: _statusBadgeAsset(e.status),
                    employeeImage: e.employeeImage,
                  ),
                )
                .toList();

            final sections = <_PettyCashSection>[
              _PettyCashSection(
                title: 'today',
                items: sectionItems,
              ),
            ];

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
                          'assets/newapp/newicon/petty_cach_header.png',
                          width: 26.w,
                          height: 26.w,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'PETTYCASH',
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF151544),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (sectionItems.isEmpty)
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
                  ...sections.expand((section) {
                    return [
                      _SectionHeader(title: section.title),
                      SizedBox(height: 10.h),
                      ...section.items.map(
                        (item) => Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 7.h),
                          child: _PettyCashRequestCard(item: item),
                        ),
                      ),
                      SizedBox(height: 14.h),
                    ];
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 18.w, top: 6.h),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF9AA0A6),
        ),
      ),
    );
  }
}

class _PettyCashRequestCard extends StatelessWidget {
  final _PettyCashRequestItem item;

  const _PettyCashRequestCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50.r),
        border: Border.all(color: const Color(0xFFBDBDBD), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 10.w),
          _Avatar(imageUrl: item.employeeImage),
          SizedBox(width: 10.w),
          Container(
            width: 1,
            height: 52.h,
            color: const Color(0xFFBDBDBD),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.requestNo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0B2B7A),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.amount.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    item.employeeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexendDeca(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF484848).withOpacity(0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 14.w),
            child: _StatusBadge(assetPath: item.statusBadgeAsset),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String imageUrl;

  const _Avatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return Container(
      width: 54.w,
      height: 54.w,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBDBDBD), width: 1),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset('assets/png/profile_1.png',
                      fit: BoxFit.cover);
                },
              )
            : Image.asset(
                'assets/png/profile_1.png',
                fit: BoxFit.cover,
              ),
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
      width: 34.w,
      fit: BoxFit.contain,
    );
  }
}

class _PettyCashSection {
  final String title;
  final List<_PettyCashRequestItem> items;

  const _PettyCashSection({required this.title, required this.items});
}

class _PettyCashRequestItem {
  final String requestNo;
  final String amount;
  final String employeeName;
  final String statusBadgeAsset;
  final String employeeImage;

  const _PettyCashRequestItem({
    required this.requestNo,
    required this.amount,
    required this.employeeName,
    required this.statusBadgeAsset,
    required this.employeeImage,
  });
}
