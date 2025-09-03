import 'package:el_race/ui/presentation/landing_screen/landing_screen.dart';
import 'package:el_race/ui/presentation/signin/bloc/sign_in_bloc.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:el_race/ui/presentation/signin/sign_in_screen.dart';
import 'package:el_race/ui/presentation/splash_screen/splash_screen.dart';
import 'package:el_race/utils/di.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:el_race/ui/presentation/home_screen/screens/home_screen.dart';

import '../ui/presentation/call_screen/bloc/contact_bloc.dart';
import '../ui/presentation/call_screen/call_screen.dart';

class OnGeneratedRoutes {
  Route<dynamic> generatedRoutes(RouteSettings settings) {
    final _signInBloc = sl.get<SignInBloc>();
    final _contactBloc = sl.get<ContactBloc>();
    switch (settings.name) {
      case '/':
        return CupertinoPageRoute(builder: (_) => const SplashScreen());
      case '/signIN':
        Future.delayed(const Duration(milliseconds: 500), () {
          _signInBloc.add(CheckSignedIn());
        });
        return CupertinoPageRoute(builder: (_) => const SignInScreen());
      case '/landing':
        return CupertinoPageRoute(
            builder: (_) => LandingScreen(
                  loginResponseModel: settings.arguments! as LoginResponseModel,
                ));
      case '/home':
        return CupertinoPageRoute(
          builder: (_) => const HomeScreen(), // Pass the argument),
        );
      case '/contact':
        Future.delayed(const Duration(milliseconds: 500), () {
          _contactBloc.add(GetEmployeeLisET());
        });
        return CupertinoPageRoute(builder: (_) => const CallScreen());
    }
    return MaterialPageRoute(
        builder: (_) => Scaffold(
            body:
                Center(child: Text('No route defined for ${settings.name}'))));
  }
}
