import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/signin/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:el_race/ui/presentation/home_screen/screens/home_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/core/services/app_config_service.dart';
import 'package:provider/provider.dart';
import 'package:el_race/ui/presentation/qr_survey/providers/qr_survey_data_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Clear any QR data from previous sessions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<QrSurveyDataProvider>(context, listen: false);
      provider.clearData();
      print('🧹 SplashScreen - Cleared QR data on app start');
    });
  }

  @override
  void didChangeDependencies() {
    // Splash screen duration: 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted) return;

      try {
        Util.fetchHomeScreenData(context);
        if (SharedPref.isUserAuthenticated()) {
          // Check if face registration is in progress or pending
          final isRegistrationInProgress =
              SharedPref().getPreferenceBoolean('isFaceRegistrationInProgress');
          final isPendingFaceVerification =
              SharedPref().getPreferenceBoolean('pendingFaceVerification');
          final isFaceRegistered =
              SharedPref().getPreferenceBoolean('isFaceRegistered');

          // If registration was in progress, user must complete it
          if (isRegistrationInProgress ||
              (isPendingFaceVerification && !isFaceRegistered)) {
            // In Test Mode, skip face registration
            if (AppConfigService.instance.isTestMode) {
              SharedPref()
                  .setPreferencesBoolean('pendingFaceVerification', false);
              SharedPref()
                  .setPreferencesBoolean('isFaceRegistrationInProgress', false);
              Util.pushPageAndRemoveRoutes(const HomeScreen(), context);
              return;
            }

            // User needs to register face - go to home, it will be triggered from there
            Util.pushPageAndRemoveRoutes(const HomeScreen(), context);
          } else {
            // User already registered or no pending verification
            Util.pushPageAndRemoveRoutes(const HomeScreen(), context);
          }
        } else {
          Util.pushPageAndRemoveRoutes(const SignInScreen(), context);
        }
      } catch (e) {
        print('❌ Error navigating from splash: $e');
        // Fallback to login screen on error
        if (mounted) {
          Util.pushPageAndRemoveRoutes(const SignInScreen(), context);
        }
      }
    });

    // Safety timeout - force navigation after 10 seconds if nothing happened
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        print('⚠️ Splash timeout reached - forcing navigation');
        try {
          if (SharedPref.isUserAuthenticated()) {
            Util.pushPageAndRemoveRoutes(const HomeScreen(), context);
          } else {
            Util.pushPageAndRemoveRoutes(const SignInScreen(), context);
          }
        } catch (e) {
          print('❌ Error in safety timeout: $e');
        }
      }
    });

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Image.asset(
        'assets/mp4/intro.gif',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
