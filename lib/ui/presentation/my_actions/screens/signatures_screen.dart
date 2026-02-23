import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/ui/presentation/my_actions/data/my_actions_models.dart';
import 'package:el_race/ui/presentation/my_actions/data/my_actions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SignaturesScreen extends StatefulWidget {
  const SignaturesScreen({super.key});

  @override
  State<SignaturesScreen> createState() => _SignaturesScreenState();
}

class _SignaturesScreenState extends State<SignaturesScreen> {
  final MyActionsRepository _repo = MyActionsRepository();
  late final Future<List<MyActionItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchByType(MyActionsType.signatures);
  }

  String _statusBadgeAsset(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
      case 'signed':
        return 'assets/newapp/approvedBadge.png';
      case 'pending':
      case 'waiting':
        return 'assets/newapp/warningBadge.png';
      case 'rejected':
        return 'assets/newapp/rejectBadge.png';
      default:
        return 'assets/newapp/warningBadge.png';
    }
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

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_document,
                      size: 80.w,
                      color: const Color(0xFFB5B7C1),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No signatures found',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9AA0A6),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: EdgeInsets.only(top: 8.h, bottom: 80.h),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.draw,
                          size: 26.w,
                          color: const Color(0xFF151544),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Signatures',
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
                ...items.map(
                  (item) => _SignatureCard(
                    name: item.name,
                    employeeName: item.employeeName,
                    statusBadgeAsset: _statusBadgeAsset(item.status),
                    employeeImage: item.employeeImage,
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

class _SignatureCard extends StatelessWidget {
  final String name;
  final String employeeName;
  final String statusBadgeAsset;
  final String employeeImage;

  const _SignatureCard({
    required this.name,
    required this.employeeName,
    required this.statusBadgeAsset,
    required this.employeeImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFE9EAEE),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EAEE),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: employeeImage.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      employeeImage,
                      width: 48.w,
                      height: 48.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 24.w,
                        color: const Color(0xFF9AA0A6),
                      ),
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 24.w,
                    color: const Color(0xFF9AA0A6),
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  employeeName,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF484848).withOpacity(0.72),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Image.asset(
            statusBadgeAsset,
            width: 34.w,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
