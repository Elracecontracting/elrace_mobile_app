import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/providers/profile_box_provider.dart';
import 'package:el_race/ui/presentation/Email Approval/Approval.dart';
import 'package:el_race/ui/presentation/Notification/notification_screen.dart';
import 'package:el_race/ui/presentation/signin/sign_in_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../presentation/home_screen/bloc/home_bloc.dart';
import '../presentation/home_screen/screens/home_screen.dart';

class HeaderWidget extends StatefulWidget implements PreferredSizeWidget {
  const HeaderWidget({super.key});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();

  @override
  Size get preferredSize => Size.fromHeight(SizeConfig().getHeight(70));
}

class _HeaderWidgetState extends State<HeaderWidget> {
  String _imageBase64 = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!SharedPref.isUserAuthenticated()) return;
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
    var bloc = HomeBloc.get(context);
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      elevation: 0,
      toolbarHeight: SizeConfig().getHeight(100),
      flexibleSpace: Container(
        padding: EdgeInsets.zero,
        width: ScreenUtil().screenWidth,
        height: SizeConfig().getHeight(115),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/png/header_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            PositionedDirectional(
              top: SizeConfig().getHeight(48.w),
              start: SizeConfig().getWidth(10),
              //left: SizeConfig().getWidth(15),
              child: GestureDetector(
                onTap: (){
                  bloc.isNotOpen=false;
                  bloc.add(const ChangeCurrentIndex(index: 1));
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(),
                    ),
                        (route) => true,
                  );
                },
                child: Image.asset(
                  'assets/png/logo.gif',
                  fit: BoxFit.cover,
                  height: SizeConfig().getHeight(100),
                  width: SizeConfig().getWidth(120),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig().getWidth(20), vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: SizeConfig().getWidth(200),
                    ),
                    Row(
                      children: [
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
                                top: -5,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    '7',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: SizeConfig().getWidth(10)),
                        GestureDetector(
                          onTap: () {
                            if (SharedPref.isUserAuthenticated()) {
                              if(!bloc.isNotOpen){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationScreen(),
                                  ),
                                );
                                bloc.isNotOpen=true;
                              }
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
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    '5',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: SizeConfig().getWidth(15)),
                        GestureDetector(
                          onTap: () {
                            if (!SharedPref.isUserAuthenticated()) {
                              Util.pushPage(const SignInScreen(), context);
                              return;
                            }
                            Provider.of<ProfileBoxProvider>(context,
                                    listen: false)
                                .toggleProfileBox();
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
