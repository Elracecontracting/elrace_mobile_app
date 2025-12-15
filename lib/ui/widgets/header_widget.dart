import 'dart:convert';

import 'package:el_race/core/services/notification_storage_service.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/providers/profile_box_provider.dart';
import 'package:el_race/ui/presentation/Email Approval/Approval.dart';
import 'package:el_race/ui/presentation/Notification/notification_screen.dart';
import 'package:el_race/ui/presentation/signin/sign_in_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/utils/custom_navigate.dart';
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
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationCount();
  }

  Future<void> _loadUserData() async {
    if (!SharedPref.isUserAuthenticated()) return;
    final data = SharedPref.getLoginData();
    _imageBase64 = data.result?.data?.image_url ?? '';
  }

  Future<void> _loadNotificationCount() async {
    final count = await NotificationStorageService.getUnreadCount();
    if (mounted) {
      setState(() {
        _notificationCount = count;
      });
    }
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
                onTap: () {
                  bloc.isNotOpen = false;
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
                  height: SizeConfig().getHeight(60),
                  width: SizeConfig().getWidth(120),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig().getWidth(20), vertical: 0),
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
                                SlideRightPageRoute(
                                  child: const ApprovalsScreen(),
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
                          onTap: () async {
                            print('🔔 [HEADER] Notification bell tapped');
                            print('   - User authenticated: ${SharedPref.isUserAuthenticated()}');
                            print('   - isNotOpen: ${bloc.isNotOpen}');
                            
                            if (SharedPref.isUserAuthenticated()) {
                              if (!bloc.isNotOpen) {
                                print('   - ✅ Opening notification screen...');
                                bloc.isNotOpen = true; // Mark as open before navigation
                                await Navigator.push(
                                  context,
                                  SlideRightPageRoute(
                                    child: const NotificationScreen(),
                                  ),
                                );
                                print('   - ✅ Returned from notification screen');
                                bloc.isNotOpen = false; // Reset to allow reopening
                                // Refresh notification count after returning
                                _loadNotificationCount();
                              } else {
                                print('   - ⚠️ Screen already open, ignoring tap');
                              }
                            } else {
                              print('   - ❌ User not authenticated');
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
                                child: _notificationCount > 0
                                    ? Container(
                                        padding: const EdgeInsets.all(3),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          _notificationCount > 99
                                              ? '99+'
                                              : _notificationCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
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
