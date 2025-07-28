import 'dart:async';
import 'package:el_race/ui/presentation/home_screen/screens/main_home_content_widget.dart';
import 'package:el_race/ui/presentation/home_screen/screens/main_screens.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/profile_box_with_slide_animation.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/timer_controller.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/visibilty_icon.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:el_race/providers/profile_box_provider.dart'; // Import the provider
import 'package:el_race/ui/presentation/home_screen/bloc/location_bloc/location_bloc.dart';
import 'package:location/location.dart';

class HomeScreen extends StatelessWidget{
  const HomeScreen();
  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}


class HomeScreenPage extends StatefulWidget {
  const HomeScreenPage({super.key,});

  @override
  State<HomeScreenPage> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreenPage> {
  // bool isMuted = false; // default value
  bool isCheckedIn = false;
  final _locationBloc = LocationBloc();
  final Location _location = Location();

  // _loadMuteStatus() {
  //   setState(() {
  //     isMuted = SharedPref().getPreferenceBoolean('mute_notifications');
  //   });
  // }

  @override
  void initState() {
    super.initState();
    Get.put(TimerController()); // only once!
    // _loadMuteStatus();
    // Future.delayed(const Duration(seconds: 5), () {
    //   showBabyGirlPopup(context);
    // });
    _checkLocationService(); // Check location service on initialization
    _locationBloc.add(GetCurrentLocationET());
    // List of pages or widgets that you want to display for each navigation ite
  }

  Future<void> _checkLocationService() async {
    // Check if location service is enabled
    bool isServiceEnabled = await _location.serviceEnabled();
    if (!isServiceEnabled) {
      // If not enabled, show popup
      _showLocationServiceDialog();
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enable Location Service"),
          content: const Text("Please enable location services to proceed."),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                bool serviceEnabled = await _location.requestService();
                if (!serviceEnabled) {
                  // If still not enabled, show the dialog again
                  _showLocationServiceDialog();
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width;
    // final drawerWidth = screenWidth * 0.75; // 75% of screen width
    return Scaffold(
      backgroundColor: lightGrey,
      // bottomNavigationBar: CustomBottomNavbar(
      //   currentIndex: _selectedIndex,
      //   onItemTapped: _onItemTapped,
      // ),
      body: GestureDetector(
        onTap: () {
          final profileBoxProvider = Provider.of<ProfileBoxProvider>(context, listen: false);
          if (profileBoxProvider.isProfileVisible) {
            profileBoxProvider.hideProfileBox(); // Close the profile box
          }
        },
        child: const  Stack(
          children: [
            // Main Content
            MainHomeContentWidget(),
    
            // Profile Box with Slide Animation
           ProfileBoxWithSlideAnimation(),     


            ArraowVisibalityBottomNav(),
          ],
        ),
      ),
    );
  }
}

