import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/providers/profile_box_provider.dart';
import 'package:el_race/ui/presentation/signin/sign_in_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:provider/provider.dart';

class ProfileBoxWithSlideAnimation extends StatelessWidget {
  const ProfileBoxWithSlideAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return SharedPref.isUserAuthenticated() == false
        ? const SizedBox.shrink()
        : Consumer<ProfileBoxProvider>(
            builder: (context, profileBoxProvider, child) {
              final isAuthenticated = SharedPref.isUserAuthenticated();
              if (isAuthenticated == false) return const SizedBox.shrink();

              final screenWidth = MediaQuery.of(context).size.width;
              final drawerWidth = screenWidth * 0.75;

              final base64Image = SharedPref().getUserBase64Image();
              final hasValidImage =
                  base64Image.isNotEmpty && Util.isValidBase64(base64Image);

              final loginData = SharedPref.getLoginData();

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: SharedPref().isArabic()
                    ? null
                    : (profileBoxProvider.isProfileVisible ? 0 : -drawerWidth),
                right: SharedPref().isArabic()
                    ? (profileBoxProvider.isProfileVisible ? 0 : -drawerWidth)
                    : null,
                top: 0,
                child: Material(
                  color: Colors.grey[300],
                  child: SafeArea(
                    child: Container(
                      width: drawerWidth,
                      padding: EdgeInsets.zero,
                      child: SingleChildScrollView(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 106.13,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.black, width: 2),
                                    ),
                                    child: CircleAvatar(
                                      radius: 35,
                                      backgroundImage: hasValidImage
                                          ? MemoryImage(base64Decode(base64Image))
                                          : const AssetImage(
                                                  'assets/png/profile_1.png')
                                              as ImageProvider,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 12.4,
                                  ),
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24)),
                                    child: Image.asset(
                                        'assets/png/name_tag_icon.png'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                loginData.result?.data?.name
                                        ?.split(' ')
                                        .take(2)
                                        .join(' ') ??
                                    translate('profile.name_not_available'),
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700, fontSize: 11.26),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                loginData.result?.data?.job_id ??
                                    translate('profile.job_id_not_available'),
                                style: GoogleFonts.inter(
                                    fontSize: 11.26, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                loginData.result?.data?.emp_id?.toString() ??
                                    translate('profile.id_not_available'),
                                style: GoogleFonts.inter(
                                    fontSize: 11.26, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return Dialog(
                                        insetPadding: const EdgeInsets.all(15),
                                        child: Container(
                                          width: double.infinity,
                                          height:
                                              MediaQuery.of(context).size.height *
                                                  0.3,
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.asset(
                                                'assets/png/certificate.png',
                                                fit: BoxFit.cover),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Image.asset(
                                  'assets/png/cert_icon.png',
                                  height: 26.52,
                                  width: 26.52,
                                  //fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 15),
                                    padding: const EdgeInsets.only(
                                        top: 75, bottom: 10),
                                    color: Colors.grey.shade100,
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 80),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(
                                                    (0.15 * 255).toInt()),
                                                offset: const Offset(0, 1.68),
                                                // blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                                child: Container(
                                                  width: 94.13,
                                                  height: 25.03,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: !SharedPref()
                                                              .isArabic()
                                                          ? [
                                                              const Color(
                                                                  0xFF151544),
                                                              const Color(
                                                                  0xFF3535AA)
                                                            ] // لو مش عربي
                                                          : [
                                                              Colors.white,
                                                              Colors.grey[300]!
                                                            ], // لو عربي
                                                      begin: Alignment.centerLeft,
                                                      end: Alignment.centerRight,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.3),
                                                  ),
                                                  child: ElevatedButton(
                                                    onPressed: () async {
                                                      if (profileBoxProvider
                                                          .isProfileVisible) {
                                                        profileBoxProvider
                                                            .hideProfileBox();
                                                      }
                                                      await Util
                                                          .saveAndChangeLocale(
                                                              context, 'en');
                                                    },
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      //  backgroundColor: !SharedPref().isArabic()
                                                      //       ? appFontColor
                                                      //       : Colors.white,
                                                      minimumSize:
                                                          const Size(100, 30),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20.3)),
                                                    ),
                                                    child: Text(
                                                        translate(
                                                            'profile.english'),
                                                        style: TextStyle(
                                                            color: !SharedPref()
                                                                    .isArabic()
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontSize: 12)),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Container(
                                                width: 94.13,
                                                height: 25.03,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20.3),
                                                ),
                                                child: ElevatedButton(
                                                  onPressed: () async {
                                                    if (profileBoxProvider
                                                        .isProfileVisible) {
                                                      profileBoxProvider
                                                          .hideProfileBox();
                                                    }
                                                    await Util
                                                        .saveAndChangeLocale(
                                                            context, 'ar');
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: SharedPref()
                                                            .isArabic()
                                                        ? appFontColor
                                                        : Colors.grey.shade200,
                                                    minimumSize:
                                                        const Size(100, 30),
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                20.3)),
                                                  ),
                                                  child: Text(
                                                      translate('profile.arabic'),
                                                      style: TextStyle(
                                                          color: SharedPref()
                                                                  .isArabic()
                                                              ? Colors.white
                                                              : Colors.black,
                                                          fontSize: 12)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                  
                                        const SizedBox(height: 6),
                                        // Container(
                                        //   height: 2,
                                        //   width: double.infinity,
                                        //   decoration: BoxDecoration(
                                        //     color: Colors.grey.shade300,
                                        //     // boxShadow: [
                                        //     //   BoxShadow(
                                        //     //     color: Colors.black.withAlpha(
                                        //     //         (0.15 * 255).toInt()),
                                        //     //     offset: const Offset(0, 2),
                                        //     //     blurRadius: 4,
                                        //     //   ),
                                        //     // ],
                                        //   ),
                                        // ),
                  
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 12),
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(
                                                    (0.15 * 255).toInt()),
                                                offset: const Offset(0, 1.68),
                                                //blurRadius: 4,
                                              )
                                            ],
                                            color: Colors.white,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Image.asset(
                                                  'assets/png/notification_filled_icon.png'),
                                              const SizedBox(width: 20),
                                              Text(
                                                  translate(
                                                      'profile.mute_notifications'),
                                                  style: GoogleFonts.inter(
                                                      fontSize: 12)),
                                              const Spacer(),
                                              SizedBox(
                                                height: 10.57,
                                                child: Transform.scale(
                                                  scale: 0.7, // تصغير الحجم
                                                  child: const Switch(
                                                    value: false,
                                                    onChanged: null,
                                                    activeColor:
                                                        appFontColor, // لون الزر لما يكون ON
                                                    activeTrackColor: Color(
                                                        0xffD9D9D9), // لون الخلفية لما يكون ON
                                                    inactiveThumbColor: Color(
                                                        0xff3E3C3C), // لون الزر لما يكون OFF
                                                    inactiveTrackColor: Color(
                                                        0xffD9D9D9), // لون الخلفية لما يكون OFF
                                                  ),
                                                ),
                                              )
                                              // Switch.adaptive(
                                              //   value: isMuted,
                                              //   onChanged: (val) => _updateMuteStatus(val),
                                              //   activeColor: const Color(0xFF1A1A53),
                                              //   activeTrackColor: Colors.grey.shade400,
                                              // ),
                                            ],
                                          ),
                                        ),
                                        // 🔹 Divider with shadow
                                        // Container(
                                        //   height: 2,
                                        //   width: double.infinity,
                                        //   decoration: BoxDecoration(
                                        //     color: Colors.grey.shade300,
                                        // boxShadow: [
                                        //   BoxShadow(
                                        //     color: Colors.black.withAlpha(
                                        //         (0.15 * 255).toInt()),
                                        //     offset: const Offset(0, 2),
                                        //     blurRadius: 4,
                                        //   ),
                                        // ],
                                        //   ),
                                        // ),
                                        const SizedBox(
                                          height: 12,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 12),
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withAlpha(
                                                      (0.15 * 255).toInt()),
                                                  offset: const Offset(0, 1.68),
                                                  // blurRadius: 4,
                                                )
                                              ]),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                child: Image.asset(
                                                    'assets/png/dark_mode_icon.png'),
                                              ),
                                              const SizedBox(width: 22),
                                              Text(
                                                  translate(
                                                      'profile.dark_mode'),
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: -10,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        //padding: const EdgeInsets.all(13),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(27),
                                          // boxShadow: [
                                          //   BoxShadow(
                                          //     color: Colors.black
                                          //         .withAlpha((0.5 * 255).toInt()),
                                          //     blurRadius: 6,
                                          //     offset: const Offset(0, 3),
                                          //   ),
                                          // ],
                                        ),
                                        child: Image.asset(
                                            'assets/png/qr_code.png',
                                            height: 176,
                                            width: 176),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: const BorderRadius.only(
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Image.asset('assets/png/log_out_icon.png'),
                                    const SizedBox(
                                      width: 26,
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        SharedPref().clearPreferences();
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const SignInScreen()),
                                        );
                                      },
                                      child: Text(translate('profile.logout'),
                                          style: const TextStyle(
                                              color: Color(0xffBA1719))),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }
}
