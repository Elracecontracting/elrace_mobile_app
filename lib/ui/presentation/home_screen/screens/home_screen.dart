import 'dart:async';
import 'dart:convert';

import 'package:el_race/core/biometric/face_recognition/face_recognition_di.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/bloc/face_recognition_bloc.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/screens/face_registration_screen.dart';
import 'package:el_race/core/biometric/face_recognition/data/services/facenet_service.dart';
import 'package:el_race/core/biometric/face_recognition/data/services/face_detector_service.dart';
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

    // Skip face recognition if test mode OR faceIdEnabled=false from backend config
    if (!AppConfigService.instance.shouldSkipFaceId) {
      // Pre-load face recognition models in background
      // This prevents lag when opening face registration for the first time
      _preloadFaceModels();

      // Check if face registration is pending
      _checkFaceRegistration();
    } else {
      print('🧪 Face ID disabled: Skipping face registration and model preloading');
      // Clear any pending face verification flags
      SharedPref().setPreferencesBoolean('pendingFaceVerification', false);
      SharedPref().setPreferencesBoolean('isFaceRegistrationInProgress', false);
    }
    // List of pages or widgets that you want to display for each navigation ite
  }

  /// Pre-load face recognition models in background
  /// This ensures smooth experience when opening face registration
  Future<void> _preloadFaceModels() async {
    try {
      print('🔄 Pre-loading face recognition models in background...');

      // Initialize FaceNet model (this is the slow part)
      final faceNetService = FaceNetService();
      await faceNetService.initialize();

      // Initialize Face Detector
      final faceDetectorService = FaceDetectorService();
      await faceDetectorService.initialize();

      print('✅ Face recognition models pre-loaded successfully');
    } catch (e) {
      print('⚠️ Pre-loading face models failed (will retry when needed): $e');
    }
  }

  Future<void> _checkFaceRegistration() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final isInProgress =
        SharedPref().getPreferenceBoolean('isFaceRegistrationInProgress');
    final isPending =
        SharedPref().getPreferenceBoolean('pendingFaceVerification');
    final isRegistered = SharedPref().getPreferenceBoolean('isFaceRegistered');

    print('🔍 Face Registration Check:');
    print('  - isInProgress: $isInProgress');
    print('  - isPending: $isPending');
    print('  - isRegistered: $isRegistered');

    // If registration is in progress or pending and not yet registered
    if (isInProgress || (isPending && !isRegistered)) {
      print('✅ Opening face registration screen...');
      // Get userId from SharedPref - MUST match UnifiedBiometricHelper priority order!
      final loginDataStr = SharedPref().getPreferenceString('loginResponse');
      if (loginDataStr.isNotEmpty) {
        try {
          final loginData = jsonDecode(loginDataStr);
          final data = loginData['result']?['data'] ?? loginData;

          // Priority order: emp_id > emp_profile_id > uid > username (same as UnifiedBiometricHelper)
          String? userId;

          final empId = data['emp_id']?.toString();
          final empProfileId = data['emp_profile_id']?.toString();
          final uid = data['uid']?.toString();
          final username = data['username']?.toString();

          print('🔍 Available user ID fields:');
          print('   - emp_id: $empId');
          print('   - emp_profile_id: $empProfileId');
          print('   - uid: $uid');
          print('   - username: $username');

          if (empId != null && empId.isNotEmpty && empId != 'null') {
            userId = empId;
            print('✅ Using emp_id: $userId');
          } else if (empProfileId != null &&
              empProfileId.isNotEmpty &&
              empProfileId != 'null') {
            userId = empProfileId;
            print('✅ Using emp_profile_id: $userId');
          } else if (uid != null && uid.isNotEmpty && uid != 'null') {
            userId = uid;
            print('✅ Using uid: $userId');
          } else if (username != null &&
              username.isNotEmpty &&
              username != 'null') {
            userId = username;
            print('✅ Using username: $userId');
          } else {
            userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
            print('⚠️ No user ID found, using fallback: $userId');
          }

          // Ensure userId is not null (use fallback if still null)
          final finalUserId = userId;
          print('📱 User ID for face registration: $finalUserId');

          // Set flag to indicate face registration is in progress
          SharedPref()
              .setPreferencesBoolean('isFaceRegistrationInProgress', true);

          // Navigate to face registration with BLoC provider
          // Use regular push - WillPopScope in FaceRegistrationScreen will prevent going back
          final success = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (_) => FaceRecognitionDI.get<FaceRecognitionBloc>(),
                child: FaceRegistrationScreen(
                  userId: finalUserId,
                  title: 'Register Your Face (Required)',
                  subtitle: 'Face registration is required to use the app',
                ),
              ),
            ),
          );

          if (success == true && mounted) {
            // Mark as registered and clear in-progress flag
            SharedPref().setPreferencesBoolean('isFaceRegistered', true);
            SharedPref()
                .setPreferencesBoolean('pendingFaceVerification', false);
            SharedPref()
                .setPreferencesBoolean('isFaceRegistrationInProgress', false);

            // Force rebuild to show home content
            setState(() {});
          }
        } catch (e) {
          print('❌ Error parsing login data: $e');
        }
      } else {
        print('⚠️ loginDataStr is empty!');
      }
    } else {
      print('⏭️ Skipping face registration (conditions not met)');
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
      // Check face registration status when app resumes
      _checkFaceRegistration();

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
