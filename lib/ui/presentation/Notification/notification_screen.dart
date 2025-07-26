import 'package:el_race/ui/widgets/back_icon.dart';
import 'package:el_race/utils/Util.dart';
import 'package:flutter/material.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import '../../widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/ui/presentation/Attendace_list/attendance_page.dart';
import 'package:flutter_translate/flutter_translate.dart';


class NotificationScreen extends StatefulWidget {
  final LoginResponseModel loginResponseModel;

  const NotificationScreen({super.key, required this.loginResponseModel});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int currentIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.85); // 👈 show next card hint
  final List<Map<String, dynamic>> notifications = [
    {
      'icon': 'assets/png/hr_icon.png',
      'message': 'Your request from Jan 15 to Jan 20 has been approved.',
      'time': '5 minutes ago',
    },
    {
      'icon': 'assets/png/construction_icon.png',
      'message': 'Your request from Jan 15 to Jan 20 has been approved.',
      'time': '10 minutes ago',
    },
    {
      'icon': 'assets/png/calendar_icon.png',
      'message': 'Your request from Jan 15 to Jan 20 has been approved.',
      'time': '20 minutes ago',
    },
    {
      'icon': 'assets/png/supplier_icon.png',
      'message': 'Your request from Jan 15 to Jan 20 has been approved.',
      'time': '1 day ago',
    },
    {
      'icon': 'assets/png/hr_icon.png',
      'message': 'Your request from Jan 22 to Jan 27 has been approved.',
      'time': '2 days ago',
    },
    {
      'icon': 'assets/png/construction_icon.png',
      'message': 'Your request from Feb 1 to Feb 5 has been approved.',
      'time': '3 days ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if(mounted)showBabyGirlPopup(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeaderWidget(),

          const SizedBox(height: 16),

          Stack(
            alignment: Alignment.center,
            children: [
              const BackIcon(),
              Text(
               translate('notification_screen.center'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: appFontColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(
                    height: 150,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: 3,
                      onPageChanged: (index) => setState(() => currentIndex = index),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3), // optional spacing between cards
                          child: Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE6E6E6), Color(0xFF2D2F81)],
                                begin: Alignment.center,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha((0.1 * 255).toInt()),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          translate('notification_screen.circulars'),
                                          style: const TextStyle(
                                            color: Color(0xFF1A237E),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.arrow_forward,
                                            size: 16,
                                            color: Color(0xFF2D2F81),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      translate('notification_screen.stay_updated'),
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                                
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (dotIndex) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotIndex == currentIndex ? Colors.black : Colors.grey[400],
                        ),
                      );
                    }),
                  ),
            
                  const SizedBox(height: 30),
            
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
                            onTap: () => Util.pushPage(const AttendancePage(), context),
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
                                    color: Colors.black.withAlpha((0.08 * 255).toInt()),
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
                                      item['icon']??'',
                                      width: 29,
                                      height: 29,
                                      color: appFontColor,
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          item['message']??'',
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
                              item['time']??'',
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