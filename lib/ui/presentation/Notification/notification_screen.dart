import 'package:el_race/ui/presentation/Attendace_list/attendance_page.dart';
import 'package:el_race/ui/widgets/back_icon.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/header_widget.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int currentIndex = 0;
  final PageController _pageController =
      PageController(viewportFraction: 0.85); // 👈 show next card hint
  final List<Map<String, dynamic>> notifications = [
    {
      'icon': 'assets/png/notification_icon.png',
      'message': 'Your request from Jan 15 to Jan 20 has been approved.',
      'time': '5 minutes ago',
    },
    {
      'icon': 'assets/png/notification_icon.png',
      'message': 'Your request from Jan 15 to Jan 20 has been approved.',
      'time': '10 minutes ago',
    },
    {
      'icon': 'assets/png/notification_icon.png',
      'message': 'Your request from Jan 15 to Jan 20 has been approved.',
      'time': '20 minutes ago',
    },
    {
      'icon': 'assets/png/notification_icon.png',
      'message': 'Your request from Jan 15 to Jan 20 has been approved.',
      'time': '1 day ago',
    },
    {
      'icon': 'assets/png/notification_icon.png',
      'message': 'Your request from Jan 22 to Jan 27 has been approved.',
      'time': '2 days ago',
    },
    {
      'icon': 'assets/png/notification_icon.png',
      'message': 'Your request from Feb 1 to Feb 5 has been approved.',
      'time': '3 days ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) showBabyGirlPopup(context);
    });
  }

  final List<Map<String, dynamic>> notificationType = [
    {
      'icon': 'assets/png/notification_icon.png',
      'title': 'notifications',
    },
    {
      'icon': 'assets/png/announcement.png',
      'title': 'announcements',
    },
    {
      'icon': 'assets/png/urgent_icon.png',
      'title': 'circular',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderWidget(),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const BackIcon(),
              Text(
                translate('notification_screen.center'),
                style: GoogleFonts.koulen(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w600,
                  color: appFontColor,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(
                    height: 55.w,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      controller: _pageController,
                      itemCount: notificationType.length,
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        String notificationIcon =
                            notificationType[index]['icon'];
                        String notificationTitle =
                            notificationType[index]['title'];
                        return InkWell(
                          onTap: () => setState(() => currentIndex = index),
                          child: Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: index == currentIndex
                                  ? appFontColor
                                  : greyText2,
                              // gradient: const LinearGradient(
                              //   colors: [Color(0xFFE6E6E6), ],
                              //   begin: Alignment.center,
                              //   end: Alignment.centerRight,
                              // ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withAlpha((0.1 * 255).toInt()),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            // child: Stack(
                            //   children: [
                            //     Column(
                            //       crossAxisAlignment: CrossAxisAlignment.start,
                            //       children: [
                            //         // Row(
                            //         //   mainAxisAlignment:
                            //         //       MainAxisAlignment.spaceBetween,
                            //         //   children: [
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  notificationIcon,
                                  height: 25.w,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  notificationTitle.toUpperCase(),
                                  style: GoogleFonts.koulen(
                                    color: index == currentIndex
                                        ? Colors.white
                                        : const Color(0xFF1A237E),
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.7,
                                  ),
                                ),
                              ],
                            ),
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //       horizontal: 8, vertical: 4),
                            //   decoration: BoxDecoration(
                            //     color: Colors.white,
                            //     borderRadius:
                            //         BorderRadius.circular(10),
                            //   ),
                            //   child: const Icon(
                            //     Icons.arrow_forward,
                            //     size: 16,
                            //     color: Color(0xFF2D2F81),
                            //   ),
                            // ),
                            //   ],
                            // ),
                            // const SizedBox(height: 6),
                            // Text(
                            //   translate(
                            //       'notification_screen.stay_updated'),
                            //   style: const TextStyle(
                            //     color: Colors.black87,
                            //     fontSize: 11,
                            //     fontWeight: FontWeight.bold,
                            //     height: 1.4,
                            //   ),
                            // ),
                            //       ],
                            //     ),
                            //   ],
                            // ),
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(
                        width: 10,
                      ),
                    ),
                  ),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: List.generate(3, (dotIndex) {
                  //     return Container(
                  //       margin: const EdgeInsets.symmetric(horizontal: 4),
                  //       width: 8,
                  //       height: 8,
                  //       decoration: BoxDecoration(
                  //         shape: BoxShape.circle,
                  //         color: dotIndex == currentIndex ? Colors.black : Colors.grey[400],
                  //       ),
                  //     );
                  //   }),
                  // ),

                  const SizedBox(height: 20),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                Util.pushPage(const AttendancePage(), context),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                image: const DecorationImage(
                                  image: AssetImage('assets/png/bg_petty.png'),
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withAlpha((0.08 * 255).toInt()),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      item['icon'] ?? '',
                                      width: 29,
                                      height: 29,
                                      color: appFontColor,
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          item['message'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 6, bottom: 10),
                            child: Text(
                              item['time'] ?? '',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void showBabyGirlPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha((0.5 * 255).toInt()),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white.withAlpha((0.95 * 255).toInt()),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "🎉 Congratulations ✨",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Congratulations to",
                  style: TextStyle(fontSize: 13, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                const Text(
                  "Eng. Hassan Abuebied",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                const Text(
                  "on the arrival of his baby girl! 🎀✨ Wishing her a life filled with love, joy, and endless blessings. May she bring happiness and prosperity to the family! 💖👶🏼",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Image.asset(
                  'assets/png/Baby_girl.png',
                  height: 80,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
