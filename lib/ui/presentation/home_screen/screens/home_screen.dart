import 'dart:async';
import 'dart:convert';

import 'package:el_race/core/biometric/face_recognition/face_recognition_di.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/bloc/face_recognition_bloc.dart';
import 'package:el_race/core/biometric/face_recognition/presentation/screens/face_registration_screen.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/location_bloc/location_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/screens/main_home_content_widget.dart';
import 'package:el_race/ui/presentation/home_screen/screens/main_screens.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/timer_controller.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';

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
    // Check if face registration is pending
    _checkFaceRegistration();
    // List of pages or widgets that you want to display for each navigation ite
  }

  Future<void> _checkFaceRegistration() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final isPending =
        SharedPref().getPreferenceBoolean('pendingFaceVerification');
    final isRegistered = SharedPref().getPreferenceBoolean('isFaceRegistered');

    if (isPending && !isRegistered) {
      // Get userId from SharedPref
      final loginDataStr = SharedPref().getPreferenceString('loginResponse');
      if (loginDataStr.isNotEmpty) {
        try {
          final loginData = jsonDecode(loginDataStr);
          final userId = (loginData['result']?['data']?['uid'] ??
                  loginData['result']?['data']?['username'] ??
                  'user_${DateTime.now().millisecondsSinceEpoch}')
              .toString();

          // Navigate to face registration with BLoC provider
          final success = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (_) => FaceRecognitionDI.get<FaceRecognitionBloc>(),
                child: FaceRegistrationScreen(
                  userId: userId,
                  title: 'Register Your Face (Required)',
                  subtitle: 'Face registration is required to use the app',
                ),
              ),
            ),
          );

          if (success == true) {
            // Mark as registered
            SharedPref().setPreferencesBoolean('isFaceRegistered', true);
            SharedPref()
                .setPreferencesBoolean('pendingFaceVerification', false);
          }
        } catch (e) {
          print('Error parsing login data: $e');
        }
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

  @override
  Widget build(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width;
    // final drawerWidth = screenWidth * 0.75; // 75% of screen width
    return const Scaffold(
      appBar: HeaderWidget(),
      backgroundColor: lightGrey,
      extendBody: true,
      // bottomNavigationBar: CustomBottomNavbar(
      //   currentIndex: _selectedIndex,
      //   onItemTapped: _onItemTapped,
      // ),
      body: const Stack(
        children: [
          // Main Content
          MainHomeContentWidget(),
          // Bottom Nav Arrow
          // ArraowVisibalityBottomNav(),
        ],
      ),
    );
  }
}
