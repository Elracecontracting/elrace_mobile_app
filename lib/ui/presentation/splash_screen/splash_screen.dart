import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/firebase_service.dart';
import 'package:el_race/ui/presentation/signin/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:el_race/ui/presentation/home_screen/screens/home_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/core/services/app_config_service.dart';
import 'package:el_race/core/security/device_security_service.dart';
import 'package:el_race/data/services/hive_service.dart';
import 'package:provider/provider.dart';
import 'package:el_race/ui/presentation/qr_survey/providers/qr_survey_data_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isSecurityCheckComplete = false;
  bool _isDeviceSecure = true;

  @override
  void initState() {
    super.initState();
    _performSecurityCheck();
    // Clear any QR data from previous sessions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<QrSurveyDataProvider>(context, listen: false);
      provider.clearData();
      print('🧹 SplashScreen - Cleared QR data on app start');
    });
  }

  /// Perform security check before allowing app usage
  Future<void> _performSecurityCheck() async {
    try {
      print('🔒 Starting security check...');
      final result =
          await DeviceSecurityService.instance.performSecurityCheck();

      if (mounted) {
        setState(() {
          _isDeviceSecure = result.isSecure;
          _isSecurityCheckComplete = true;
        });

        if (!result.isSecure) {
          print('❌ Device security check failed!');
          // Show security warning dialog
          DeviceSecurityService.showSecurityBlockDialog(context, result);
        } else {
          print('✅ Device security check passed!');
        }
      }
    } catch (e) {
      print('⚠️ Error during security check: $e');
      // On error, allow app to continue (fail-open for better UX)
      if (mounted) {
        setState(() {
          _isSecurityCheckComplete = true;
          _isDeviceSecure = true;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    // Splash screen duration: 6 seconds (wait for security check too)
    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted) return;

      // Don't navigate if device is not secure
      if (!_isDeviceSecure && _isSecurityCheckComplete) {
        print('🚫 Navigation blocked - device not secure');
        return;
      }

      // Wait for security check if not complete yet
      if (!_isSecurityCheckComplete) {
        print('⏳ Waiting for security check to complete...');
        _waitForSecurityCheckAndNavigate();
        return;
      }

      _navigateToNextScreen();
    });

    // Safety timeout - force navigation after 15 seconds if nothing happened
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        print('⚠️ Splash timeout reached - forcing navigation');
        if (_isDeviceSecure || !_isSecurityCheckComplete) {
          _navigateToNextScreen();
        }
      }
    });

    super.didChangeDependencies();
  }

  /// Wait for security check to complete then navigate
  Future<void> _waitForSecurityCheckAndNavigate() async {
    // Wait up to 5 more seconds for security check
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isSecurityCheckComplete) {
        if (_isDeviceSecure) {
          _navigateToNextScreen();
        }
        return;
      }
    }
    // Timeout - navigate anyway
    _navigateToNextScreen();
  }

  /// Logout user — clear all auth state
  Future<void> _performLogout() async {
    try {
      await SharedPref().setPreferencesBoolean('isRegistered', false);
      await SharedPref().removePreference('loginResponse');
      await HiveService.setUserLoggedIn(false);
      SharedPref().setPreferencesBoolean('pendingFaceVerification', false);
      SharedPref().setPreferencesBoolean('isFaceRegistrationInProgress', false);
      SharedPref().setPreferencesBoolean('isFaceRegistered', false);
      print('✅ Logout completed from splash screen');
    } catch (e) {
      print('⚠️ Error during logout: $e');
    }
  }

  /// Navigate to the appropriate screen after security check
  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    try {
      // Check authentication first
      final isAuthenticated = SharedPref.isUserAuthenticated();

      // Fetch home screen data (with error handling inside the function)
      // This won't throw - errors are handled internally
      Util.fetchHomeScreenData(context);

      if (isAuthenticated) {
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
            FirebaseService.markHomeReady();
            return;
          }

          // Face registration not completed — log the user out
          // They must re-login and complete face registration
          print('🚫 Face registration not completed — logging out user');
          await _performLogout();
          Util.pushPageAndRemoveRoutes(const SignInScreen(), context);
          return;
        } else {
          // User already registered or no pending verification
          Util.pushPageAndRemoveRoutes(const HomeScreen(), context);
          FirebaseService.markHomeReady();
        }
      } else {
        Util.pushPageAndRemoveRoutes(const SignInScreen(), context);
      }
    } catch (e) {
      print('❌ Error navigating from splash: $e');
      // Fallback based on authentication status, not to login screen blindly
      if (mounted) {
        if (SharedPref.isUserAuthenticated()) {
          Util.pushPageAndRemoveRoutes(const HomeScreen(), context);
          FirebaseService.markHomeReady();
        } else {
          Util.pushPageAndRemoveRoutes(const SignInScreen(), context);
        }
      }
    }
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
