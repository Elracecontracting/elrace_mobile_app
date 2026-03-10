import 'package:el_race/utils/safe_insets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AllApprovalsOverview extends StatelessWidget {
  final int invoiceCount;
  final int pettyCashCount;
  final int rfqCount;
  final int hrCount;
  final int delayedCount;
  final VoidCallback? onDelayedTap;

  const AllApprovalsOverview({
    super.key,
    required this.invoiceCount,
    required this.pettyCashCount,
    required this.rfqCount,
    required this.hrCount,
    required this.delayedCount,
    this.onDelayedTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalBottomPadding =
        kBottomNavigationBarHeight + context.systemBottomInset + 100.h;

    return Expanded(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          left: 18.w,
          right: 18.w,
          top: 120.w,
          bottom: totalBottomPadding,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Invoice',
                    value: invoiceCount,
                    borderColor: const Color(0xFF2ECC71),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _StatCard(
                    title: 'Petty cash',
                    value: pettyCashCount,
                    borderColor: const Color(0xFF2ECC71),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.w),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'RFQ',
                    value: rfqCount,
                    borderColor: const Color(0xFFF39C12),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _StatCard(
                    title: 'HR',
                    value: hrCount,
                    borderColor: const Color(0xFFE74C3C),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.w),
            _DelayedRequestCard(value: delayedCount, onTap: onDelayedTap),
            SizedBox(height: 30.w),
            _BarChart(
              values: {
                'HR': hrCount,
                'RFQ': rfqCount,
                'Invoice': invoiceCount,
                'Pettycash': pettyCashCount,
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final Color borderColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150.w,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: borderColor, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              value.toString(),
              style: GoogleFonts.inter(
                fontSize: 48.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFBDBDBD),
                height: 1.0,
              ),
            ),
          ),
          SizedBox(height: 6.w),
        ],
      ),
    );
  }
}

class _DelayedRequestCard extends StatelessWidget {
  final int value;
  final VoidCallback? onTap;

  const _DelayedRequestCard({required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.w),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFEDEDED)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Delayed Requests',
                      style: GoogleFonts.inter(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8E8E8E),
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      color: const Color(0xFF8E8E8E),
                      size: 28.sp,
                    ),
                ],
              ),
              SizedBox(height: 10.w),
              Row(
                children: [
                  Container(
                    width: 6.w,
                    height: 26.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    value.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 54.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final Map<String, int> values;

  const _BarChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final maxValue = values.values.fold<int>(0, (m, v) => v > m ? v : m);
    final maxHeight = 220.w;
    final minBarHeight = 12.w; // الحد الأدنى للعمود إذا كانت القيمة > 0
    final zeroBarHeight = 6.w; // إظهار عمود صغير حتى لو كانت القيمة 0

    return SizedBox(
      height: maxHeight + 36.w,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: values.entries.map((entry) {
          // حساب النسبة بناءً على القيمة القصوى
          final ratio = maxValue == 0 ? 0.0 : entry.value / maxValue;
          // طول العمود يتناسب مع الرقم - حتى القيمة 0 لها طول صغير مرئي
          final double barHeight = entry.value == 0
              ? zeroBarHeight
              : (maxHeight * ratio).clamp(minBarHeight, maxHeight);

          return SizedBox(
            width: 68.w,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 38.w,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBDBDBD),
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                ),
                SizedBox(height: 12.w),
                Text(
                  entry.key,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
