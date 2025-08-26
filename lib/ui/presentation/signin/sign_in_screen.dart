import 'dart:convert';
import 'dart:developer';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/instruction/views/instruction_view.dart';
import 'package:el_race/ui/presentation/signin/bloc/sign_in_bloc.dart';
import 'package:el_race/ui/presentation/splash_screen/splash_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/di.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/utils/string_utils.dart';

import '../home_screen/screens/home_screen.dart';


class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isChecked = false;
  late SignInBloc signInBloc ;
  
  @override
  void didChangeDependencies() {
    signInBloc = SignInBloc.get(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignInBloc, SignInState>(
      listener: (context, state) async {
        log('Listener state: $state');
    
        if (state is ErrMsg) {
          Navigator.of(context, rootNavigator: true).maybePop();
          await Future.delayed(const Duration(milliseconds: 100));
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('Error'),
              content: Text(state.msg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
    
        if (state is LoadingST) {
          if (state.isLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
          } else {
            Navigator.of(context, rootNavigator: true).maybePop();
          }
        }
        if (state is InitialSignedInST) {
          Util.fetchHomeScreenData(context);
        
          SharedPref().setPreferencesString('loginResponse', jsonEncode(state.loginResponse.toJson()));
          SharedPref().setPreferencesBoolean('isRegistered', true); 
    
          // final name = state.loginResponse.result?.data?.username?.toLowerCase() ?? "";
          
          // if (name == "jawad@elrace.com" || name == "aziz@elrace.com") {
          //   Util.pushPageAndRemoveRoutes(const SplashScreen(), context);
          // } else {
            Util.pushPageAndRemoveRoutes(InstructionView(loginResponseModel: state.loginResponse), context);
          // }
        }
    
      },
      buildWhen: (previous, current) => current is LoadingST || current is InitialSignedInST || current is ErrMsg,
      builder: (context, state) {
         return Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Stack(
              children: [
                // Background images
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/png/top_curve.png',
                        width: ScreenUtil().screenWidth),
                    Image.asset('assets/png/bottom_curve.png',
                        width: ScreenUtil().screenWidth, fit: BoxFit.fill),
                  ],
                ),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig().getWidth(15)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: SizeConfig().getHeight(110),),
                        Image.asset(
                          'assets/png/logo.gif',
                          fit: BoxFit.cover,
                          height: SizeConfig().getHeight(180),
                        ),
                        // const SizedBox(3
                        //   width: 600,
                        //   child: Image.asset('$imagePrefixIcons/logo.png'),
                        // ),
                        Text(
                          'sign in to your Account',
                          style:GoogleFonts.tajawal(fontSize: SizeConfig().getTextSize(20)),
                        ),
                        SizedBox(height: SizeConfig().getHeight(20)),
                        textForms('Email ID', 'account.png', usernameController,
                            false),
                        SizedBox(height: SizeConfig().getHeight(40)),
                        textForms(
                            'Password', 'lock.png', passwordController, true),
                        SizedBox(height: SizeConfig().getHeight(6)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Checkbox(
                              value: isChecked,
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked = value!;
                                });
                              },
                            ),
                            const Text(
                              'Remember Password',
                              style: TextStyle(color: Color(0xff30309B)),
                            ),
                            SizedBox(
                              width: SizeConfig().getHeight(30),
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig().getHeight(30)),
                        loginButton(() {
                          // if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //     const SnackBar(content: Text('Please enter both email and password.')),
                          //   );
                          //   return;
                          // }

                          signInBloc.add(SignInET(
                            email: usernameController.text,
                            password: passwordController.text,
                            deviceId: '776655',
                          ));
                        }),
                        const SizedBox(
                          height: 7,
                        ),
                        InkWell(
                          onTap: () => Util.pushPageAndRemoveRoutes(
                              const HomeScreen(), context),
                          child: const Text(
                            'Continue as a Guest',
                            style: const TextStyle(
                                decoration: TextDecoration.underline,
                                fontSize: 13.0),
                          ),
                        ),
                        SizedBox(height: SizeConfig().getHeight(70)),
                        Text('Contact with Support',
                            style: TextStyle(
                                fontSize: SizeConfig().getTextSize(18))),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget loginButton(Function() onTapped) {
  return GestureDetector(
    onTap: onTapped,
    child: Container(
      width: SizeConfig().getWidth(145),
      height: SizeConfig().getHeight(40),
      decoration: BoxDecoration(
        // gradient:
        //     const LinearGradient(colors: [Colors.purple, Colors.blueAccent]),
        gradient: const LinearGradient(
            colors: [Color(0xffD6D6D6), Color(0xffADB2BD)]),
        borderRadius: BorderRadius.circular(54),
        // boxShadow: [
        //   BoxShadow(
        //       color: Colors.black.withAlpha((0.2 * 255).toInt()),
        //       blurRadius: 8,
        //       offset: const Offset(0, 4)),
        // ],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // const Icon(Icons.person_add_alt, color: Colors.white),
            SizedBox(width: SizeConfig().getWidth(8)),
            Text(
              'sign in ',
              style: TextStyle(
                color: Colors.black,
                fontSize: SizeConfig().getTextSize(19),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: SizeConfig().getWidth(10)),
            const Icon(Icons.arrow_forward, color: Colors.black),
          ],
        ),
      ),
    ),
  );
}

Widget textForms(
    String title, String icon, TextEditingController controller, bool obscure) {
  return Container(
    height: SizeConfig().getHeight(55),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(52),
      color: white,
      boxShadow: [
        BoxShadow(
          // spreadRadius: 4,
          color: Colors.black.withAlpha((0.2 * 255).toInt()),
          blurRadius: 12,
        )
      ],
    ),
    child: TextFormField(
      obscureText: obscure,
      controller: controller,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: title,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        hintStyle: TextStyle(
            fontSize: 16, color: Colors.black.withAlpha((0.5 * 255).toInt())),
        prefixIcon: Image.asset('$imagePrefixIcons/$icon'),
      ),
    ),
  );
}