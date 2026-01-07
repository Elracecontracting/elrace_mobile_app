import 'dart:ui' as ui;

import 'package:el_race/core/constants/app_images.dart';
import 'package:el_race/ui/presentation/call_screen/call_screen.dart';
import 'package:el_race/ui/presentation/camera/camera_selection_screen.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/screens/home_screen.dart';
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
  DateTime? _lastBackPressTime;

  static const List<Widget> screens = [
    CallScreen(),
    HomeScreenPage(),
    SizedBox(),
  ];

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
        _lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2);

    if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
      _lastBackPressTime = now;

      // Show toast message
      Fluttertoast.showToast(
        msg: translate('common.press_back_again_to_exit'),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      return false; // Don't exit
    }

    return true; // Exit the app
  }

  @override
  Widget build(BuildContext context) {
    final bloc = HomeBloc.get(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop) {
          // Close the app properly instead of navigating to a black screen
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        bottomNavigationBar: const CustomBottomNavBar(),
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) => screens[bloc.currentIndex],
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
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(70.r),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(
                height: 60.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(70.r),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.28), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      context,
                      index: 0,
                      isMain: isMain,
                      icon: AppImages.callIcon,
                    ),
                    _buildNavItem(
                      context,
                      isMain: isMain,
                      index: 1,
                      icon: AppImages.homeIcon,
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
      {required int index, required String icon, required bool isMain}) {
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
          child: Image.asset(
            icon,
            width: 30.w,
          ),
        ),
      ),
    );
  }

  Future<void> _openCamera(BuildContext context) async {
    // Open the Camera Selection Screen
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CameraSelectionScreen(),
        ),
      );
    }
  }
}
