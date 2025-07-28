import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/my_request/bloc/requests_bloc.dart';
import 'package:el_race/ui/presentation/my_request/bloc/requests_event.dart';
import 'package:el_race/ui/presentation/signin/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:el_race/ui/presentation/home_screen/screens/home_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';

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
      if(SharedPref.isUserAuthenticated()){
        Util.pushPageAndRemoveRoutes(const HomeScreen(), context);
      }else{
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
