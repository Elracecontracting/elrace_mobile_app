import 'dart:convert';
import 'dart:developer';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/auth/uaepass_auth_cubit.dart';
import 'package:el_race/ui/auth/auth_loading_screen.dart';
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
import 'package:el_race/core/biometric/face_recognition/face_recognition_di.dart';
import 'package:el_race/core/biometric/face_recognition/data/services/face_embedding_storage_service.dart';

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
  bool isPasswordVisible = false;
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

  // Register face and print embeddings
  Future<void> _printEmbeddings(String userId) async {
    // Wait a bit for registration to complete
    await Future.delayed(const Duration(seconds: 2));

    try {
      final storageService =
          FaceRecognitionDI.get<FaceEmbeddingStorageService>();
      final embeddings = await storageService.getEmbeddings(userId);

      if (embeddings.isNotEmpty) {
        final embedding = embeddings.first;
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ FACE REGISTERED SUCCESSFULLY!');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('👤 User ID: $userId');
        print('📅 Created At: ${embedding.createdAt}');
        print('🏷️  Label: ${embedding.label ?? "primary"}');
        print('📊 Embedding Dimensions: ${embedding.embedding.length}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔢 FACE EMBEDDING VALUES:');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        // Print embeddings in groups of 8 for readability
        for (int i = 0; i < embedding.embedding.length; i += 8) {
          final end = (i + 8 < embedding.embedding.length)
              ? i + 8
              : embedding.embedding.length;
          final group = embedding.embedding.sublist(i, end);
          final formatted = group.map((v) => v.toStringAsFixed(6)).join(', ');
          print('[$i-${end - 1}]: $formatted');
        }

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('💾 Full JSON:');
        print(jsonEncode(embedding.toJson()));
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      } else {
        print('⚠️ No embeddings found for user: $userId');
      }
    } catch (e) {
      print('⚠️ Error printing embeddings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uaepassCubit = context.read<UaepassAuthCubit>();
    final uaepassConfig = uaepassCubit.config;
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context, rootNavigator: true).maybePop();
            });
          }
        }
        if (state is InitialSignedInST) {
          Util.fetchHomeScreenData(context);

          // Debug: Log the FULL login response before saving
          print('DEBUG: ===== FULL LOGIN RESPONSE =====');
          final responseJson = state.loginResponse.toJson();
          print('DEBUG: Full JSON:');
          print(const JsonEncoder.withIndent('  ').convert(responseJson));
          print('DEBUG: ===================================');
          print('DEBUG: Specific fields:');
          print('DEBUG: name = ${state.loginResponse.result?.data?.name}');
          print(
              'DEBUG: emp_name = ${state.loginResponse.result?.data?.emp_name}');
          print(
              'DEBUG: username = ${state.loginResponse.result?.data?.username}');
          print(
              'DEBUG: partnerDisplayName = ${state.loginResponse.result?.data?.partnerDisplayName}');
          print('DEBUG: job_id = ${state.loginResponse.result?.data?.job_id}');
          print('DEBUG: emp_id = ${state.loginResponse.result?.data?.emp_id}');
          print(
              'DEBUG: emp_profile_id = ${state.loginResponse.result?.data?.emp_profile_id}');
          print('DEBUG: uid = ${state.loginResponse.result?.data?.uid}');
          print('DEBUG: ===================================');

          // Additional debug for Face Registration
          print('\n📱 ===== FACE REGISTRATION USER ID SELECTION =====');
          final userId = state.loginResponse.result?.data?.emp_id ??
              state.loginResponse.result?.data?.emp_profile_id ??
              state.loginResponse.result?.data?.uid?.toString() ??
              state.loginResponse.result?.data?.username;
          print('SELECTED USER ID FOR FACE REGISTRATION: $userId');
          print('==================================================\n');

          SharedPref().setPreferencesString(
              'loginResponse', jsonEncode(state.loginResponse.toJson()));
          SharedPref().setPreferencesBoolean('isRegistered', true);

          // ✅ Face Recognition with LOCAL storage only
          SharedPref().setPreferencesBoolean('pendingFaceVerification', true);
          SharedPref()
              .setPreferencesBoolean('isFaceRegistrationInProgress', false);

          // Navigate to HomeScreen - face registration will be triggered
          // Using pushAndRemoveUntil to remove all previous routes including login screen
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false, // Remove all previous routes
            );
          });
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
                          height: SizeConfig().getHeight(120),
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
                        passwordField(),
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
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AuthLoadingScreen(),
                              ),
                            );
                            uaepassCubit.startLogin();
                          },
                          child: Image.asset(
                            uaepassConfig.buttonAssetPath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, _, __) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: const Text('Sign in with UAE PASS'),
                            ),
                          ),
                        ),
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

  Widget passwordField() {
    return Container(
      height: SizeConfig().getHeight(55),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(52),
        color: white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).toInt()),
            blurRadius: 12,
          )
        ],
      ),
      child: TextFormField(
        obscureText: !isPasswordVisible,
        controller: passwordController,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Password',
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF545454)),
          prefixIcon: Image.asset(
            '$imagePrefixIcons/lock.png',
            color: const Color(0xFF545454),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFF545454),
            ),
            onPressed: () {
              setState(() {
                isPasswordVisible = !isPasswordVisible;
              });
            },
          ),
        ),
      ),
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
