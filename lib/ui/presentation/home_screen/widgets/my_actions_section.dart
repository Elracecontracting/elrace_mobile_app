import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:el_race/ui/presentation/my_actions/screens/hr_screen.dart';
import 'package:el_race/ui/presentation/my_actions/screens/rfq_screen.dart';
import 'package:el_race/ui/presentation/my_actions/screens/petty_cash_my_action_screen.dart';
import 'package:el_race/ui/presentation/my_actions/screens/invoice_my_actions_screen.dart';
import 'package:el_race/utils/custom_navigate.dart';

class MyActionsSection extends StatelessWidget {
  const MyActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            translate('home.my_actions'),
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF000F42),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MyActionTile(
                iconAsset: 'assets/newapp/newicon/hr.png',
                label: 'HR',
                onTap: () {
                  Navigator.push(
                    context,
                    SlideRightPageRoute(
                      child: const HrScreen(),
                      settings: const RouteSettings(name: '/hr'),
                    ),
                  );
                },
              ),
              _MyActionTile(
                iconAsset: 'assets/newapp/newicon/rfq.png',
                label: 'RFQ',
                onTap: () {
                  Navigator.push(
                    context,
                    SlideRightPageRoute(
                      child: const RfqScreen(),
                      settings: const RouteSettings(name: '/rfq'),
                    ),
                  );
                },
              ),
              _MyActionTile(
                iconAsset: 'assets/newapp/newicon/Cash.png',
                label: 'Petty Cash',
                onTap: () {
                  Navigator.push(
                    context,
                    SlideRightPageRoute(
                      child: const PettyCashMyActionScreen(),
                      settings:
                          const RouteSettings(name: '/petty_cash_my_actions'),
                    ),
                  );
                },
              ),
              _MyActionTile(
                iconAsset: 'assets/newapp/newicon/Invoice.png',
                label: 'invoice',
                onTap: () {
                  Navigator.push(
                    context,
                    SlideRightPageRoute(
                      child: const InvoiceMyActionsScreen(),
                      settings:
                          const RouteSettings(name: '/invoice_my_actions'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MyActionTile extends StatelessWidget {
  final String iconAsset;
  final String label;
  final VoidCallback? onTap;

  const _MyActionTile({
    required this.iconAsset,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18.r);

    return InkWell(
      borderRadius: borderRadius,
      onTap: onTap,
      child: SizedBox(
        width: 78.w,
        child: Column(
          children: [
            Container(
              width: 68.w,
              height: 68.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EAEE),
                borderRadius: borderRadius,
                border: Border.all(
                  color: const Color(0xFFB5B7C1),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                iconAsset,
                width: 34.w,
                height: 34.w,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9AA0A6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
