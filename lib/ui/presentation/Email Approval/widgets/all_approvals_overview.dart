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
    final totalCount = invoiceCount + pettyCashCount + rfqCount + hrCount;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CategoryRingsRow(
              rfqCount: rfqCount,
              hrCount: hrCount,
              totalCount: totalCount,
              pettyCashCount: pettyCashCount,
              invoiceCount: invoiceCount,
            ),
            SizedBox(height: 20.h),
            _RorCard(
              hrCount: hrCount,
              rfqCount: rfqCount,
              pettyCashCount: pettyCashCount,
              invoiceCount: invoiceCount,
            ),
            SizedBox(height: 14.h),
            _DelayedRequestCard(value: delayedCount, onTap: onDelayedTap),
          ],
        ),
      ),
    );
  }
}

class _CategoryRingsRow extends StatelessWidget {
  final int rfqCount;
  final int hrCount;
  final int totalCount;
  final int pettyCashCount;
  final int invoiceCount;

  const _CategoryRingsRow({
    required this.rfqCount,
    required this.hrCount,
    required this.totalCount,
    required this.pettyCashCount,
    required this.invoiceCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84.h,
      child: Center(
        child: SizedBox(
          width: 310.w,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 7.h,
                child: _CountRing(
                  label: 'RFQ',
                  value: rfqCount,
                  borderColor: const Color(0xFFF0A21E),
                ),
              ),
              Positioned(
                left: 56.w,
                top: 7.h,
                child: _CountRing(
                  label: 'HR',
                  value: hrCount,
                  borderColor: const Color(0xFFD4334D),
                ),
              ),
              Positioned(
                left: 238.w,
                top: 7.h,
                child: _CountRing(
                  label: 'Invoice',
                  value: invoiceCount,
                  borderColor: const Color(0xFF2CBF6F),
                ),
              ),
              Positioned(
                left: 182.w,
                top: 7.h,
                child: _CountRing(
                  label: 'Pettycash',
                  value: pettyCashCount,
                  borderColor: const Color(0xFF25B5B3),
                ),
              ),
              Positioned(
                left: 112.w,
                top: 2.h,
                child: _CountRing(
                  label: 'Total',
                  value: totalCount,
                  borderColor: const Color(0xFF4BA0D9),
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountRing extends StatelessWidget {
  final String label;
  final int value;
  final Color borderColor;
  final bool isPrimary;

  const _CountRing({
    required this.label,
    required this.value,
    required this.borderColor,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isPrimary ? 84.w : 72.w,
      height: isPrimary ? 84.w : 72.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: borderColor,
          width: isPrimary ? 2.6 : 2.1,
        ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: const Color(0xFF4BA0D9).withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: GoogleFonts.inter(
              fontSize: isPrimary ? 18.sp : 15.5.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF444444),
              height: 1,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isPrimary ? 11.sp : 9.2.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8E8E8E),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RorCard extends StatelessWidget {
  final int hrCount;
  final int rfqCount;
  final int pettyCashCount;
  final int invoiceCount;

  const _RorCard({
    required this.hrCount,
    required this.rfqCount,
    required this.pettyCashCount,
    required this.invoiceCount,
  });

  @override
  Widget build(BuildContext context) {
    final chartValues = <int>[hrCount, rfqCount, pettyCashCount, invoiceCount];
    final maxValue = chartValues.fold<int>(0, (m, v) => v > m ? v : m);
    final highlightedIndex = chartValues.indexOf(maxValue);
    final ror = _calculateRorPercentage();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFCFCFCF), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF1F4),
                  borderRadius: BorderRadius.circular(5.r),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 18.sp,
                  color: const Color(0xFF596274),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'ROR',
                style: GoogleFonts.inter(
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                  height: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 7.h),
          Text(
            'Here, you can review your Response Rate regarding the actions\n'
            'taken on the requests.',
            style: GoogleFonts.inter(
              fontSize: 10.4.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF676767),
              height: 1.25,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: SizedBox(
                  height: 220.h,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RorNeedle(
                        label: 'HR',
                        value: hrCount,
                        maxValue: maxValue,
                        highlight: highlightedIndex == 0,
                      ),
                      _RorNeedle(
                        label: 'RFQ',
                        value: rfqCount,
                        maxValue: maxValue,
                        highlight: highlightedIndex == 1,
                      ),
                      _RorNeedle(
                        label: 'Petty cash',
                        value: pettyCashCount,
                        maxValue: maxValue,
                        highlight: highlightedIndex == 2,
                      ),
                      _RorNeedle(
                        label: 'invoice',
                        value: invoiceCount,
                        maxValue: maxValue,
                        highlight: highlightedIndex == 3,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              SizedBox(
                width: 72.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$ror%',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111111),
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'The percentage of\nROR in the past\nweek.',
                      style: GoogleFonts.inter(
                        fontSize: 8.2.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF616161),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateRorPercentage() {
    final total = hrCount + rfqCount + pettyCashCount + invoiceCount;
    if (total <= 0) return 0;
    final weightedDone =
        (hrCount + rfqCount + invoiceCount) + (pettyCashCount * 0.7).round();
    final ratio = (weightedDone / total) * 100;
    return ratio.clamp(0, 100).round();
  }
}

class _RorNeedle extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final bool highlight;

  const _RorNeedle({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0.0 : value / maxValue;
    final lineHeight = (18.h + (ratio * 122.h)).clamp(18.h, 140.h);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _ValueBubble(value: value),
        SizedBox(height: 5.h),
        Stack(
          alignment: Alignment.topCenter,
          children: [
            if (highlight)
              Container(
                width: 34.w,
                height: lineHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE2E9).withOpacity(0.55),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20.r),
                    bottomRight: Radius.circular(20.r),
                  ),
                ),
              )
            else
              Container(
                width: 1.4,
                height: lineHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8D8D8),
                  borderRadius: BorderRadius.circular(28.r),
                ),
              ),
            Container(
              width: 1.2,
              height: lineHeight,
              color: const Color(0xFFC9CFD8),
            ),
            if (highlight)
              Positioned(
                bottom: 0,
                child: Container(
                  width: 34.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EBF1).withOpacity(0.9),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20.r),
                      bottomRight: Radius.circular(20.r),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 6.5.w,
                height: 6.5.w,
                decoration: const BoxDecoration(
                  color: Color(0xFF79A8D8),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: 58.w,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF171717),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ValueBubble extends StatelessWidget {
  final int value;

  const _ValueBubble({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 24.w),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2749),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        value.toString(),
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 8.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
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
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFD),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFD44B4B), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Delayed Request',
                    style: GoogleFonts.inter(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                      height: 1,
                    ),
                  ),
                  if (onTap != null) ...[
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.chevron_right,
                      color: const Color(0xFF1A1A1A),
                      size: 23.sp,
                    ),
                  ],
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 7.w,
                    height: 30.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC81616),
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    value.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 30.sp,
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
