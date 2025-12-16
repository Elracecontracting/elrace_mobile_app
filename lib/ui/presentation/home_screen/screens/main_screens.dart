import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:el_race/core/constants/app_images.dart';
import 'package:el_race/ui/presentation/call_screen/call_screen.dart';
import 'package:el_race/ui/presentation/camera/camera_screen.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const List<Widget> screens = [
    CallScreen(),
    HomeScreenPage(),
    SizedBox(),
  ];

  @override
  Widget build(BuildContext context) {
    final bloc = HomeBloc.get(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: const CustomBottomNavBar(),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) => screens[bloc.currentIndex],
      ),
      // bottomNavigationBar: ,
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final bool isMain;
  const CustomBottomNavBar({this.isMain = true});

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
              filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
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
          bloc.add(ChangeCurrentIndex(index: index));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            ),
            (route) => true,
          );
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
    // Request camera permission
    final status = await Permission.camera.request();

    if (status.isGranted) {
      try {
        // Get available cameras
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No camera found')),
            );
          }
          return;
        }

        // Open camera (you can create a custom camera screen later)
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraScreen(camera: cameras.first),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening camera: $e')),
          );
        }
      }
    } else if (status.isDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }
  }
}
