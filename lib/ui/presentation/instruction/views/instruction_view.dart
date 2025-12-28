import 'package:el_race/resources/app_colors.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:el_race/ui/widgets/custom_button.dart';
import 'package:el_race/utils/extensions/size_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:el_race/core/biometric/face_recognition_helper.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/home_screen/screens/home_screen.dart';
import 'package:el_race/utils/Util.dart';

import '../view_model/instruction_view_model.dart';

class InstructionView extends StatelessWidget {
  final InstructionViewController controller = InstructionViewController();
  final LoginResponseModel loginResponseModel;

  InstructionView({required this.loginResponseModel, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.appBarColor,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              Icon(
                Icons.camera_alt_outlined,
                color: AppColors.loaderColors,
                size: 0.1.sh,
              ),
              SizedBox(height: 0.02.sh),
              Text(
                translate('instruction.selfie_time'),
                style: TextStyle(
                  fontSize: 0.05.sh,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  shadows: [
                    Shadow(
                      color: Colors.black.withAlpha((0.15 * 255).toInt()),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 0.01.sh),
              Text(
                translate('instruction.get_ready'),
                style: TextStyle(
                  fontSize: 0.025.sh,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 0.05.sh),

              // Instruction list with icons
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: controller.instructions.map((tip) {
                  final icon =
                      controller.instructionIcons[tip] ?? Icons.info_rounded;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          icon,
                          color: AppColors.loaderColors,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tip,
                            style: TextStyle(
                              fontSize: 0.020.sh,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 0.07.sh),

              // Action Button
              CustomButton(
                text: translate('instruction.lets_go'),
                onTap: () async {
                  // Get user ID from login data
                  final loginData = SharedPref.getLoginData();
                  final userId = loginData.result?.data?.uid?.toString() ??
                      loginData.result?.data?.username ??
                      'user_${DateTime.now().millisecondsSinceEpoch}';

                  // Register face using Face Recognition - MANDATORY
                  final success = await FaceRecognitionHelper.registerFace(
                    context,
                    userId: userId,
                    title: 'Register Your Face (Required)',
                    subtitle:
                        'Face registration is required to use the app. Please complete this step.',
                  );

                  if (success) {
                    // Mark face as registered
                    SharedPref()
                        .setPreferencesBoolean('isFaceRegistered', true);
                    SharedPref().setPreferencesBoolean(
                        'pendingFaceVerification', false);

                    // Navigate to home screen
                    if (context.mounted) {
                      Util.pushPageAndRemoveRoutes(const HomeScreen(), context);
                    }
                  } else {
                    // Registration failed or cancelled - show error and stay on same screen
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Face registration is required. Please try again.'),
                          duration: Duration(seconds: 3),
                          backgroundColor: Colors.red,
                        ),
                      );
                      // Stay on instruction screen - don't navigate
                      // User must complete face registration to continue
                    }
                  }
                },
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
