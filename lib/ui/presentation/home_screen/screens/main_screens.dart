import 'dart:ui' as ui;

import 'package:el_race/core/constants/app_images.dart';
import 'package:el_race/ui/presentation/call_screen/call_screen.dart';
import 'package:el_race/ui/presentation/camera/camera_selection_screen.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/screens/home_screen.dart';
import 'package:el_race/ui/presentation/qr_survey/screens/qr_survey_content_wrapper.dart';
import 'package:el_race/ui/chat/chat_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_translate/flutter_translate.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const List<Widget> screens = [
    CallScreen(),
    HomeScreenPage(),
    SizedBox(),
    QrSurveyContentWrapper(), // QR Survey screen (no icon in bottom nav)
  ];

  Future<bool> _onWillPop() async {
    // Show confirmation dialog
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          translate('common.exit_app_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(translate('common.exit_app_message')),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              translate('common.cancel'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              translate('common.exit'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bloc = HomeBloc.get(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If not on home tab, go back to home tab instead of exiting
        if (bloc.currentIndex != 1) {
          bloc.add(const ChangeCurrentIndex(index: 1));
          return;
        }

        final shouldPop = await _onWillPop();
        if (shouldPop) {
          // Close the app properly instead of navigating to a black screen
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true,
        bottomNavigationBar: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            final currentIndex = HomeBloc.get(context).currentIndex;
            return currentIndex == 0
                ? const SizedBox.shrink()
                : const CustomBottomNavBar();
          },
        ),
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) =>
              screens[HomeBloc.get(context).currentIndex],
        ),
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final bool isMain;
  const CustomBottomNavBar({super.key, this.isMain = true});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(builder: (ctx, state) {
      var bloc = HomeBloc.get(ctx);
      if (bloc.enableBottomNav == false) return const SizedBox.shrink();
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, bottom: 20.0, top: 10.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(70.r),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                height: 60.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(70.r),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Chat button
                    _buildNavItem(
                      context,
                      index: 3,
                      isMain: isMain,
                      icon: AppImages.chatIconNew,
                    ),
                    _buildNavItem(
                      context,
                      index: 0,
                      isMain: isMain,
                      icon: AppImages.callIcon,
                    ),
                    _buildNavItem(
                      context,
                      index: 2,
                      isMain: isMain,
                      icon: AppImages.chatIcon,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem(BuildContext context,
      {required int index,
      dynamic icon,
      required bool isMain,
      bool isIconData = false}) {
    final bloc = HomeBloc.get(context);
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () async {
        if (isMain) {
          if (index == 2) {
            // Open camera
            await _openCamera(context);
            return;
          }
          if (index == 3) {
            // Open chat
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatListScreen()),
            );
            return;
          }
          bloc.add(ChangeCurrentIndex(index: index));
        } else {
          // Check if already on MainScreen/HomeScreen
          final currentRoute = ModalRoute.of(context);
          final isOnMainScreen = currentRoute?.settings.name == '/' ||
              currentRoute?.settings.arguments is MainScreen;

          if (!isOnMainScreen) {
            bloc.add(ChangeCurrentIndex(index: index));
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const MainScreen(),
              ),
              (route) => false, // Remove all previous routes
            );
          } else {
            // Already on main screen, just change index
            bloc.add(ChangeCurrentIndex(index: index));
          }
        }
      },
      icon: SizedBox(
        height: 60.h,
        child: Center(
          child: isIconData
              ? Icon(icon as IconData,
                  size: 30,
                  color: bloc.currentIndex == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.6))
              : Image.asset(
                  icon as String,
                  width: 30.w,
                ),
        ),
      ),
    );
  }

  Future<void> _openCamera(BuildContext context) async {
    // Open the Camera Selection Screen in fullscreen
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CameraSelectionScreen(),
          fullscreenDialog: true,
        ),
      );
    }
  }
}
