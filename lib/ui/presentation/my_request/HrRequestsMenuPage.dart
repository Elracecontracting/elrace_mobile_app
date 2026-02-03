import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/my_request/RequestEffectiveDate.dart';
import 'package:el_race/ui/presentation/my_request/RequestJobMissionPage.dart';
import 'package:el_race/ui/presentation/my_request/RequestLeavePageNew.dart';
import 'package:el_race/ui/presentation/my_request/RequestPermission.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class HrRequestsMenuPage extends StatelessWidget {
  const HrRequestsMenuPage({super.key});

  Widget _pillButton({
    required BuildContext context,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 0.75.sw,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE1E5EA), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.koulen(
              fontSize: 18.sp,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.2,
              color: const Color(0xFF151544),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final login = SharedPref.getLoginData();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 30.h),
            child: Column(
              children: [
                Text(
                  'HR REQUESTS',
                  style: GoogleFonts.koulen(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2.0,
                    color: const Color(0xFF151544),
                  ),
                ),
                SizedBox(height: 18.h),
                _pillButton(
                  context: context,
                  label: 'Sick Leave',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestLeavePageNew(
                          loginResponseModel: login,
                          leaveType: 'SICK',
                        ),
                      ),
                    );
                  },
                ),
                _pillButton(
                  context: context,
                  label: 'Short Leave',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestLeavePageNew(
                          loginResponseModel: login,
                          leaveType: 'SHORT',
                        ),
                      ),
                    );
                  },
                ),
                _pillButton(
                  context: context,
                  label: 'Annual Leave',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestLeavePageNew(
                          loginResponseModel: login,
                          leaveType: 'ANNUAL',
                        ),
                      ),
                    );
                  },
                ),
                _pillButton(
                  context: context,
                  label: 'Effective Date',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EffectiveDatePage(
                          loginResponseModel: login,
                        ),
                      ),
                    );
                  },
                ),
                _pillButton(
                  context: context,
                  label: 'Temporary Permission',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestPermission(
                          loginResponseModel: login,
                        ),
                      ),
                    );
                  },
                ),
                _pillButton(
                  context: context,
                  label: 'Job Mission',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestJobMissionPage(
                          loginResponseModel: login,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
