import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/signin/sign_in_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:el_race/providers/profile_box_provider.dart';
import 'package:el_race/ui/presentation/Notification/notification_screen.dart';
import 'package:el_race/ui/presentation/Email Approval/Approval.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({super.key});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  String _imageBase64 = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if(!SharedPref.isUserAuthenticated())return;
    final data = SharedPref.getLoginData();
    _imageBase64 = data.result?.data?.image_url ?? '';
  }

  bool _isValidBase64(String str) {
    try {
      if (str.trim().isEmpty || str.length % 4 != 0) return false;
      base64Decode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        top: statusBarHeight, // ✅ Prevents overlap with status bar
        left: SizeConfig().getWidth(20),
        right: SizeConfig().getWidth(20),
      ),
      width: ScreenUtil().screenWidth,
      height: SizeConfig().getHeight(70) + statusBarHeight,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/png/header_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔹 Left: Logo
          Padding(
            padding: const EdgeInsets.only(left: 16), // Adjust value as needed
            child: Container(
              alignment: Alignment.centerLeft,
              height: SizeConfig().getHeight(60),
              width: SizeConfig().getWidth(110),
              child: Image.asset(
                'assets/png/logo.gif',
                fit: BoxFit.cover,
              ),
            ),
          ),


          // 🔹 Right: Icons (Approval, Bell, Profile)
          Row(
            children: [
              // Approval Icon
// Approval Icon with Badge and Click
              GestureDetector(
                onTap: () {
                  if (SharedPref.isUserAuthenticated()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ApprovalsScreen(),
                      ),
                    );
                  }
                },
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      child: Image.asset(
                        'assets/png/approval_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.brown,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '7',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: SizeConfig().getWidth(10)),

// Bell Icon with Badge and Click
              GestureDetector(
                onTap: () {
                  if (SharedPref.isUserAuthenticated()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  }
                },
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      child: Image.asset(
                        'assets/png/bell_image.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.brown,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '5',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: SizeConfig().getWidth(15)),


              // Profile Picture
              GestureDetector(
                onTap: () {
                  if(!SharedPref.isUserAuthenticated()){
                    Util.pushPage(const SignInScreen(), context);
                    return;
                  }
                  Provider.of<ProfileBoxProvider>(context, listen: false).toggleProfileBox();

                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: _isValidBase64(_imageBase64)
                        ? Image.memory(
                      base64Decode(_imageBase64),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                        : Image.asset(
                      'assets/png/profile_1.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
