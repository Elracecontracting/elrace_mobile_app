import 'package:el_race/ui/widgets/back_icon.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({
    super.key,
  });

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  int currentIndex = 0;
  final List<Map<String, dynamic>> documents = [
    {
      'icon': 'assets/png/emitates_id.png',
      'title': 'EMIRATES ID',
      'name': 'Marwan Ahmed Mohmamed',
    },
    {
      'icon': 'assets/png/emitates_id.png',
      'title': 'EMIRATES ID',
      'name': 'Marwan Ahmed Mohmamed',
    },
    {
      'icon': 'assets/png/profile_image.png',
      'title': 'EMIRATES ID',
      'name': 'Marwan Ahmed Mohmamed',
    },
    {
      'icon': 'assets/png/emitates_id.png',
      'title': 'EMIRATES ID',
      'name': 'Marwan Ahmed Mohmamed',
    },
    {
      'icon': 'assets/png/driving_license.png',
      'title': 'EMIRATES ID',
      'name': 'Marwan Ahmed Mohmamed',
    },
    {
      'icon': 'assets/png/passport.png',
      'title': 'EMIRATES ID',
      'name': 'Marwan Ahmed Mohmamed',
    },
  ];

  // @override
  // void initState() {
  //   super.initState();
  //   Future.delayed(const Duration(seconds: 5), () {
  //     if (mounted) showBabyGirlPopup(context);
  //   });
  // }

  final List<Map<String, dynamic>> notificationType = [
    {
      'icon': 'assets/png/folder.png',
      'title': 'MY DOCUMENTS',
    },
    {
      'icon': 'assets/png/family.png',
      'title': 'FAMILY DOCUMENTS',
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
                "MY DOCUMENTS",
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

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final item = documents[index];
                      return Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.18),
                            border: Border.all(
                              color: const Color(0xffD9D9D9),
                            )),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(item['icon']),
                            Text(
                              item['title'],
                              style: GoogleFonts.koulen(
                                fontSize: 11.35,
                                fontWeight: FontWeight.w400,
                                letterSpacing: .10,
                                color: const Color(0xff949494),
                              ),
                            ),
                            Text(
                              item['name'],
                              style: GoogleFonts.aBeeZee(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: .10,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      );
                    },
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 30,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

//   void showBabyGirlPopup(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       barrierColor: Colors.black.withAlpha((0.5 * 255).toInt()),
//       builder: (BuildContext context) {
//         return Dialog(
//           backgroundColor: Colors.white.withAlpha((0.95 * 255).toInt()),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(28),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   "🎉 Congratulations ✨",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w800,
//                     color: Colors.black,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   "Congratulations to",
//                   style: TextStyle(fontSize: 13, color: Colors.black),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 5),
//                 const Text(
//                   "Eng. Hassan Abuebied",
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 14),
//                 const Text(
//                   "on the arrival of his baby girl! 🎀✨ Wishing her a life filled with love, joy, and endless blessings. May she bring happiness and prosperity to the family! 💖👶🏼",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 13,
//                     height: 1.5,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Image.asset(
//                   'assets/png/Baby_girl.png',
//                   height: 80,
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
}
