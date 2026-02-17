import 'dart:math' as math;
import 'dart:ui';

import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/ui/presentation/my_actions/data/my_actions_models.dart';
import 'package:el_race/ui/presentation/my_actions/data/my_actions_repository.dart';
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
  String _searchQuery = '';
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchByType(MyActionsType.reports);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
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
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: Colors.red,
                    ),
                  ),
                ),
              );
            }

            final items = snapshot.data ?? const <MyActionItem>[];

            final filteredItems = items.where((item) {
              if (_searchQuery.trim().isEmpty) {
                return true;
              }
              final query = _searchQuery.trim().toLowerCase();
              return item.name.toLowerCase().contains(query) ||
                  item.employeeName.toLowerCase().contains(query);
            }).toList();

            return Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (scrollNotification is ScrollUpdateNotification ||
                        scrollNotification is ScrollEndNotification) {
                      final isScrolled = scrollNotification.metrics.pixels > 10;
                      if (isScrolled != _isScrolled && mounted) {
                        setState(() {
                          _isScrolled = isScrolled;
                        });
                      }
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: SizedBox(height: 130.h)),
                      SliverToBoxAdapter(child: _buildProjectsHeader()),
                      SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                      if (filteredItems.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(items.isEmpty),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = filteredItems[index];
                              return _ReportCard(
                                name: item.name.trim().isEmpty
                                    ? 'Project Name'
                                    : item.name,
                                companyName: item.employeeName.trim().isEmpty
                                    ? 'Company Name'
                                    : item.employeeName,
                                seed: item.id == 0 ? index + 1 : item.id,
                              );
                            },
                            childCount: filteredItems.length,
                          ),
                        ),
                      SliverToBoxAdapter(child: SizedBox(height: 18.h)),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildGlassHeader(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _isScrolled ? 15.0 : 8.0,
          sigmaY: _isScrolled ? 15.0 : 8.0,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.fromLTRB(0, 12.h, 0, 16.h),
          decoration: BoxDecoration(
            color: _isScrolled
                ? Colors.white.withOpacity(0.55)
                : Colors.white.withOpacity(0.30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/png/my-reports-frame.png',
                    width: 22.w,
                    height: 22.w,
                    fit: BoxFit.contain,
                    color: const Color(0xFF151A36),
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'My Reports',
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF151A36),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: Container(
                  height: 52.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(28.r),
                    border: Border.all(
                      color: const Color(0xFFB9BBC3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            color: const Color(0xFF22263A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search',
                            border: InputBorder.none,
                            hintStyle: GoogleFonts.inter(
                              fontSize: 16.sp,
                              color: const Color(0xFFA3A6B1),
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.search,
                        size: 22.w,
                        color: const Color(0xFFA3A6B1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsHeader() {
    return Padding(
      padding: EdgeInsets.only(left: 20.w, right: 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Projects Reports',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF878B98),
                letterSpacing: 0.4,
              ),
            ),
          ),
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: const Color(0xFF27304E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14.r),
                bottomLeft: Radius.circular(14.r),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 26.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isItemsEmpty) {
    return Center(
      child: Text(
        isItemsEmpty ? 'No reports found' : 'No results found',
        style: GoogleFonts.inter(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF9AA0A6),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String name;
  final String companyName;
  final int seed;

  const _ReportCard({
    required this.name,
    required this.companyName,
    required this.seed,
  });

  @override
  Widget build(BuildContext context) {
    final points = _sparklinePoints(seed);

    return Container(
      margin: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
      padding: EdgeInsets.fromLTRB(18.w, 14.h, 12.w, 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: const Color(0xFFA7AAB4),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.h),
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF27304E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  companyName,
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF777A86),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            width: 132.w,
            height: 94.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Image.asset(
                  'assets/png/r1.png',
                  width: 16.w,
                  height: 16.w,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.more_vert,
                    size: 16.w,
                    color: const Color(0xFF27304E),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 130.w,
                  height: 52.h,
                  child: CustomPaint(
                    painter: _ReportChartPainter(points),
                  ),
                ),
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: Text(
                    '0022',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF27304E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Offset> _sparklinePoints(int baseSeed) {
    final random = math.Random(baseSeed.abs() + 21);
    final values = <double>[];

    double current = 0.12 + random.nextDouble() * 0.08;
    for (int i = 0; i < 24; i++) {
      final drift = (random.nextDouble() - 0.3) * 0.18;
      current = (current + drift).clamp(0.08, 0.92);
      if (i > 18) {
        current = (current + 0.05).clamp(0.1, 0.96);
      }
      values.add(current);
    }

    return values
        .asMap()
        .entries
        .map((entry) => Offset(entry.key.toDouble(), entry.value))
        .toList();
  }
}

class _ReportChartPainter extends CustomPainter {
  final List<Offset> points;

  const _ReportChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final paint = Paint()
      ..color = const Color(0xFF6E758A)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final px = (i / (points.length - 1)) * size.width;
      final py = size.height - (points[i].dy * size.height);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ReportChartPainter oldDelegate) {
    if (identical(oldDelegate.points, points)) {
      return false;
    }
    if (oldDelegate.points.length != points.length) {
      return true;
    }
    for (int i = 0; i < points.length; i++) {
      if (oldDelegate.points[i] != points[i]) {
        return true;
      }
    }
    return false;
  }
}
