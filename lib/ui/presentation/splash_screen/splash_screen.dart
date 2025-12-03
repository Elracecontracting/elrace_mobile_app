import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/signin/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:el_race/ui/presentation/home_screen/screens/home_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/ui/presentation/authenticate_face/views/authenticate_face_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void didChangeDependencies() {
    Future.delayed(const Duration(seconds: 6), () {
      Util.fetchHomeScreenData(context);
      if (SharedPref.isUserAuthenticated()) {
        // Check if there's a pending face verification
        final isPendingFaceVerification =
            SharedPref().getPreferenceBoolean('pendingFaceVerification');

        if (isPendingFaceVerification) {
          // Must complete face verification first
          Util.pushPageAndRemoveRoutes(
            AuthenticateFaceView(
              loginResponseModel: SharedPref.getLoginData(),
              isLeftToRight: true,
              onCheckInStatusChanged: (bool checkedIn) {
                // Face verification completed successfully
                SharedPref()
                    .setPreferencesBoolean('pendingFaceVerification', false);
              },
            ),
            context,
          );
        } else {
          Util.pushPageAndRemoveRoutes(const HomeScreen(), context);
        }
      } else {
        Util.pushPageAndRemoveRoutes(const SignInScreen(), context);
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
