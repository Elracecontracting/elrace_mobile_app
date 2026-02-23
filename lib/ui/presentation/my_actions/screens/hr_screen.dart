import 'package:el_race/ui/presentation/my_actions/data/my_actions_models.dart';
import 'package:el_race/ui/presentation/my_actions/data/my_actions_repository.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HrScreen extends StatefulWidget {
  const HrScreen({super.key});

  @override
  State<HrScreen> createState() => _HrScreenState();
}

class _HrScreenState extends State<HrScreen> {
  final MyActionsRepository _repo = MyActionsRepository();
  late final Future<List<MyActionItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchByType(MyActionsType.hr);
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

  String _statusText(String status) {
    final value = status.trim().toUpperCase();
    return value.isEmpty ? 'UNKNOWN' : value;
  }

  String _formatDate(String? dateRaw) {
    if (dateRaw == null || dateRaw.trim().isEmpty) return '--/--/----';
    final parsed = DateTime.tryParse(dateRaw);
    if (parsed == null) return dateRaw;
    return DateFormat('MM/dd/yyyy').format(parsed);
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
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final items = snapshot.data ?? const <MyActionItem>[];

            return ListView(
              padding: EdgeInsets.only(top: 10.h, bottom: 80.h),
              children: [
                _ActionsHeader(
                  iconAsset: 'assets/png/my-req-frame.png',
                  title: 'MY REQUESTS',
                ),
                SizedBox(height: 12.h),
                if (items.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 30.h),
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
                  ...items.map(
                    (item) => Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                      child: _HrRequestCard(
                        requestNo: item.reference?.trim().isNotEmpty == true
                            ? item.reference!
                            : item.name,
                        title: item.requestType?.trim().isNotEmpty == true
                            ? item.requestType!
                            : 'REQUEST',
                        employeeName:
                            item.employeeName.trim().isEmpty ? '-' : item.employeeName,
                        requestId: '${item.id}',
                        updatedAt: _formatDate(item.date),
                        statusBadgeAsset: _statusBadgeAsset(item.status),
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

class _ActionsHeader extends StatelessWidget {
  final String iconAsset;
  final String title;

  const _ActionsHeader({
    required this.iconAsset,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconAsset,
            width: 30.w,
            height: 30.w,
            fit: BoxFit.contain,
            color: const Color(0xFFD21B2E),
            colorBlendMode: BlendMode.srcIn,
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF171A2E),
            ),
          ),
        ],
      ),
    );
  }
}

class _HrRequestCard extends StatelessWidget {
  final String requestNo;
  final String title;
  final String employeeName;
  final String requestId;
  final String updatedAt;
  final String statusBadgeAsset;

  const _HrRequestCard({
    required this.requestNo,
    required this.title,
    required this.employeeName,
    required this.requestId,
    required this.updatedAt,
    required this.statusBadgeAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: const Color(0xFF8E8E8E), width: 1),
      ),
      child: Stack(
        children: [
          _StatusRibbon(assetPath: statusBadgeAsset),
          Padding(
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    requestNo.trim().isEmpty ? 'REQ/-' : requestNo,
                    style: GoogleFonts.inter(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D3E7F),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  employeeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF484848).withOpacity(0.72),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  requestId,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF686868),
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Last Updated',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB1B1B1),
                        ),
                      ),
                      Text(
                        updatedAt,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB1B1B1),
                        ),
                      ),
                    ],
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

class _StatusRibbon extends StatelessWidget {
  final String assetPath;

  const _StatusRibbon({
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      child: Image.asset(
        assetPath,
        width: 84.w,
        fit: BoxFit.contain,
      ),
    );
  }
}