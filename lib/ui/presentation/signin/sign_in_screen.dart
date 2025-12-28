import 'dart:convert';
import 'dart:developer';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/instruction/views/instruction_view.dart';
import 'package:el_race/ui/presentation/signin/bloc/sign_in_bloc.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:el_race/utils/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:el_race/core/biometric/face_recognition_helper.dart';

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
  late SignInBloc signInBloc;

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

  /// Proceed to app after successful face verification
  void _proceedToApp(dynamic loginResponse) {
    Util.fetchHomeScreenData(context);

    SharedPref().setPreferencesString(
        'loginResponse', jsonEncode(loginResponse.toJson()));
    SharedPref().setPreferencesBoolean('isRegistered', true);

    Util.pushPageAndRemoveRoutes(
        InstructionView(loginResponseModel: loginResponse), context);
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
          Navigator.of(context, rootNavigator: true).maybePop();

          // Get user ID for face verification
          final userId = state.loginResponse.result?.data?.uid?.toString() ??
              state.loginResponse.result?.data?.username ??
              state.loginResponse.result?.data?.emp_id ??
              'user_unknown';

          // Check if user has face registered
          final hasFace = await FaceRecognitionHelper.hasFaceRegistered(userId);

          if (hasFace) {
            // User has face registered - verify it
            final faceVerified = await FaceRecognitionHelper.authenticate(
              context: context,
              userId: userId,
              title: 'التحقق من الهوية',
              subtitle: 'استخدم وجهك للتحقق من هويتك',
            );

            if (!faceVerified) {
              // Face verification failed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('فشل التحقق من الوجه. الرجاء المحاولة مرة أخرى.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
          } else {
            // User doesn't have face registered - register now
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('تسجيل الوجه'),
                content: const Text(
                  'لم يتم تسجيل وجهك بعد. هل تريد تسجيله الآن لتسهيل تسجيل الدخول مستقبلاً؟',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _proceedToApp(state.loginResponse);
                    },
                    child: const Text('لاحقاً'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final registered =
                          await FaceRecognitionHelper.registerFace(
                        context,
                        userId: userId,
                      );

                      if (registered) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تسجيل وجهك بنجاح!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }

                      _proceedToApp(state.loginResponse);
                    },
                    child: const Text('تسجيل الآن'),
                  ),
                ],
              ),
            );
            return;
          }

          // Face verification successful - proceed to app
          _proceedToApp(state.loginResponse);
        }
      },
      buildWhen: (previous, current) =>
          current is LoadingST ||
          current is InitialSignedInST ||
          current is ErrMsg,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Stack(
              children: [
                // Background images
                Align(
                  alignment: Alignment.topLeft,
                  child: Image.asset(
                    'assets/png/top_curve.png',
                    width: ScreenUtil().screenWidth,
                    fit: BoxFit.cover,
                    alignment: Alignment.topLeft,
                  ),
                ),
                // Background images
                Align(
                  alignment: Alignment.bottomRight,
                  child: Image.asset(
                    'assets/png/bottom_curve.png',
                    width: ScreenUtil().screenWidth * 0.65,
                    fit: BoxFit.fill,
                    alignment: Alignment.bottomRight,
                  ),
                ),

                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig().getWidth(15)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: SizeConfig().getHeight(110),
                        ),
                        Image.asset(
                          'assets/gif/el-race-logo.gif',
                          fit: BoxFit.cover,
                          height: SizeConfig().getHeight(180),
                        ),
                        // const SizedBox(3
                        //   width: 600,
                        //   child: Image.asset('$imagePrefixIcons/logo.png'),
                        // ),
                        Text(
                          'sign in to your Account',
                          style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.w400,
                              fontSize: SizeConfig().getTextSize(20)),
                        ),
                        SizedBox(height: SizeConfig().getHeight(20)),
                        textForms('Email ID', 'account.png', usernameController,
                            false),
                        SizedBox(height: SizeConfig().getHeight(40)),
                        textForms(
                            'Password', 'lock.png', passwordController, true),
                        SizedBox(height: SizeConfig().getHeight(6)),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: isChecked,
                                activeColor: const Color(0xff00264D),
                                materialTapTargetSize: MaterialTapTargetSize
                                    .shrinkWrap, // يقلل مساحة اللمس
                                visualDensity: const VisualDensity(
                                    horizontal: -4), // يقلل الحجم والمسافة
                                onChanged: (bool? value) {
                                  setState(() {
                                    isChecked = value!;
                                  });
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  'Remember Password',
                                  style: GoogleFonts.tajawal(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xff30309B),
                                      fontSize: 15),
                                ),
                              ),
                            ],
                          ),
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Continue as a Guest',
                                style: TextStyle(
                                  color: HexColor("#999999"),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                ),
                              ),
                              const SizedBox(
                                  height:
                                      4), // ← المسافة بين النص والخط (زيدها إذا بدك)
                              Container(
                                width:
                                    120, // ← عرض الخط (عدل حسب الطول اللي بدك ياه)
                                height: 0.8, // ← سماكة الخط
                                color: HexColor("#999999"), // ← نفس لون النص
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: SizeConfig().getHeight(70)),
                        Text(
                          'Contact with Support',
                          style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig().getTextSize(18)),
                        ),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // const Icon(Icons.person_add_alt, color: Colors.white),
            //SizedBox(width: SizeConfig().getWidth(8)),
            Text(
              'sign in',
              style: TextStyle(
                color: Colors.black,
                fontSize: SizeConfig().getTextSize(19),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: SizeConfig().getWidth(8)),
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
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF545454)),
        prefixIcon: Image.asset(
          '$imagePrefixIcons/$icon',
          color: const Color(0xFF545454),
        ),
      ),
    ),
  );
}
