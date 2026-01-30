import 'dart:math' as math;

import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/ui/presentation/my_actions/data/my_actions_models.dart';
import 'package:el_race/ui/presentation/my_actions/data/my_actions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RfqScreen extends StatefulWidget {
  const RfqScreen({super.key});

  @override
  State<RfqScreen> createState() => _RfqScreenState();
}

class _RfqScreenState extends State<RfqScreen> {
  final MyActionsRepository _repo = MyActionsRepository();
  late final Future<List<MyActionItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchByType(MyActionsType.rfq);
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF9AA0A6);
    }
  }

  String _formatAmount(double? amount) {
    if (amount == null) return '';
    return NumberFormat.decimalPattern().format(amount);
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
            final sectionItems = items
                .map(
                  (e) => _RfqRequestItem(
                    requestNo: e.name,
                    title: e.project ?? '',
                    subtitle: e.vendor ?? '',
                    amount: _formatAmount(e.amountTotal),
                    statusColor: _statusColor(e.status),
                    employeeImage: e.employeeImage,
                  ),
                )
                .toList();

            final sections = <_RfqSection>[
              _RfqSection(
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
                          'assets/newapp/newicon/rfq_header.png',
                          width: 26.w,
                          height: 26.w,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'RFQ',
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB88700),
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
                          child: _RfqRequestCard(item: item),
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

class _RfqRequestCard extends StatelessWidget {
  final _RfqRequestItem item;

  const _RfqRequestCard({required this.item});

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
          _RfqAvatar(imageUrl: item.employeeImage),
          SizedBox(width: 10.w),
          _DividerLine(height: 52.h),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 10.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.requestNo,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0B2B7A),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0E0E0E),
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0B2B7A),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _DividerLine(height: 52.h),
          SizedBox(width: 12.w),
          Text(
            item.amount,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0B2B7A),
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(width: 12.w),
          Padding(
            padding: EdgeInsets.only(right: 14.w),
            child: _StatusBadge(color: item.statusColor),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  final double height;

  const _DividerLine({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: height,
      color: const Color(0xFFBDBDBD),
    );
  }
}

class _RfqAvatar extends StatelessWidget {
  final String imageUrl;

  const _RfqAvatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return Container(
      width: 54.w,
      height: 54.w,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFB10D0D), width: 2),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset('assets/png/rfq-icon.png',
                      fit: BoxFit.cover);
                },
              )
            : Image.asset(
                'assets/png/rfq-icon.png',
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Color color;

  const _StatusBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26.w,
      height: 26.w,
      child: CustomPaint(
        painter: _BurstPainter(color: color),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final Color color;

  const _BurstPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.78;
    const points = 16;

    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final isOuter = i.isEven;
      final radius = isOuter ? outerRadius : innerRadius;
      final angle = (i * math.pi) / points;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _RfqSection {
  final String title;
  final List<_RfqRequestItem> items;

  const _RfqSection({required this.title, required this.items});
}

class _RfqRequestItem {
  final String requestNo;
  final String title;
  final String subtitle;
  final String amount;
  final Color statusColor;
  final String employeeImage;

  const _RfqRequestItem({
    required this.requestNo,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.statusColor,
    required this.employeeImage,
  });
}
