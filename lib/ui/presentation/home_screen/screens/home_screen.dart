import 'dart:async';

import 'package:el_race/core/biometric/unified_biometric_helper.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/location_bloc/location_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/screens/main_home_content_widget.dart';
import 'package:el_race/ui/presentation/home_screen/screens/main_screens.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/timer_controller.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:el_race/core/services/app_config_service.dart';
import '../../tasks_dashboard/screens/tasks_dashboard_screen.dart';
import '../../tasks/data/task_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}

class HomeScreenPage extends StatefulWidget {
  const HomeScreenPage({
    super.key,
  });

  @override
  State<HomeScreenPage> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreenPage>
    with WidgetsBindingObserver {
  // bool isMuted = false; // default value
  bool isCheckedIn = false;
  final _locationBloc = LocationBloc();
  final Location _location = Location();

  // _loadMuteStatus() {
  //   setState(() {
  //     isMuted = SharedPref().getPreferenceBoolean('mute_notifications');
  //   });
  // }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // مراقبة حالة التطبيق
    Get.put(TimerController()); // only once!
    // _loadMuteStatus();
    // Future.delayed(const Duration(seconds: 5), () {
    //   showBabyGirlPopup(context);
    // });
    _checkLocationService(); // Check location service on initialization
    _locationBloc.add(GetCurrentLocationET());

    // After login: authenticate with biometric / PIN
    if (!AppConfigService.instance.shouldSkipFaceId) {
      _authenticateAfterLogin();
    }
    // List of pages or widgets that you want to display for each navigation ite
  }

  /// Authenticate user right after login using device biometrics or PIN.
  /// If the device has no biometrics and no PIN is set yet, setup PIN first,
  /// then verify immediately.
  Future<void> _authenticateAfterLogin() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Setup PIN if needed (no biometrics + no PIN)
    final needs = await UnifiedBiometricHelper.needsSetup();
    if (needs && mounted) {
      await UnifiedBiometricHelper.setupPin(context);
    }

    if (!mounted) return;

    // Now actually authenticate (Face ID / fingerprint / PIN)
    bool authenticated = false;
    while (!authenticated && mounted) {
      authenticated = await UnifiedBiometricHelper.authenticate(
        context: context,
        title: 'تحقق من الهوية',
        subtitle: 'يرجى التحقق من هويتك للمتابعة',
        reason: 'تحقق من هويتك بعد تسجيل الدخول',
      );

      if (!authenticated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب التحقق من هويتك للمتابعة'),
            duration: Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // إزالة المراقبة
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationService(); // إعادة التحقق عند العودة
      _locationBloc.add(GetCurrentLocationET()); // إعادة جلب اللوكيشن
    }
  }

  Future<void> _checkLocationService() async {
    // Check if location service is enabled
    bool isServiceEnabled = await _location.serviceEnabled();
    if (!isServiceEnabled) {
      // If not enabled, show popup
      _showLocationServiceDialog();
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(translate('location.enable_service')),
          content: Text(translate('location.please_enable')),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                bool serviceEnabled = await _location.requestService();
                if (!serviceEnabled) {
                  // If still not enabled, show the dialog again
                  _showLocationServiceDialog();
                }
              },
              child: Text(translate('common.ok')),
            ),
          ],
        );
      },
    );
  }

  void _navigateToTasksDashboard(BuildContext context, List<TaskModel> tasks) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TasksDashboardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width;
    // final drawerWidth = screenWidth * 0.75; // 75% of screen width
    return Scaffold(
      appBar: const HeaderWidget(),
      backgroundColor: lightGrey,
      extendBody:
          false, // Changed to false since bottomNavigationBar is commented out
      // bottomNavigationBar: CustomBottomNavbar(
      //   currentIndex: _selectedIndex,
      //   onItemTapped: _onItemTapped,
      // ),
      body: Stack(
        children: [
          // Main Content
          const MainHomeContentWidget(),
          // Bottom Nav Arrow
          // ArraowVisibalityBottomNav(),
          
          // زر حفظ عائم (Floating Save Button)
          BlocBuilder<HomeBloc, HomeState>(
            buildWhen: (previous, current) => current is ReorderModeChanged,
            builder: (context, state) {
              final bloc = HomeBloc.get(context);
              return bloc.isReorderMode
                  ? Positioned(
                      bottom: 120.h,
                      right: 20.w,
                      child: Material(
                        elevation: 12,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 56.w,
                          height: 56.w,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.6),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              bloc.add(const ToggleReorderModeEvent());
                            },
                            borderRadius: BorderRadius.circular(50),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 32.sp,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
