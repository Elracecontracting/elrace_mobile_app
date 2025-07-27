import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/providers/profile_box_provider.dart';
import 'package:el_race/ui/presentation/signin/sign_in_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:provider/provider.dart';
import 'package:flutter_translate/flutter_translate.dart';

class ProfileBoxWithSlideAnimation extends StatelessWidget {
  const ProfileBoxWithSlideAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return  
    SharedPref.isUserAuthenticated()==false?
    const SizedBox.shrink():
    Consumer<ProfileBoxProvider>(
      builder: (context, profileBoxProvider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final drawerWidth = screenWidth * 0.75;
        

        final base64Image = SharedPref().getUserBase64Image();
        final hasValidImage = base64Image.isNotEmpty && Util.isValidBase64(base64Image);
        

        final loginData = SharedPref.getLoginData();

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: SharedPref().isArabic() ? null : (profileBoxProvider.isProfileVisible ? 0 : -drawerWidth),
          right: SharedPref().isArabic() ? (profileBoxProvider.isProfileVisible ? 0 : -drawerWidth) : null,
          top: 0,
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
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundImage: hasValidImage
                                ? MemoryImage(base64Decode(base64Image))
                                : const AssetImage('assets/png/profile_1.png') as ImageProvider,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text(
                        loginData.result?.data?.name?.split(' ').take(2).join(' ') ?? translate('profile.name_not_available'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loginData.result?.data?.job_id ?? translate('profile.job_id_not_available'),
                        style: GoogleFonts.inter(fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loginData.result?.data?.uid?.toString() ?? translate('profile.id_not_available'),
                        style: GoogleFonts.inter(fontSize: 10),
                      ),

                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                insetPadding: const EdgeInsets.all(15),
                                child: Container(
                                  width: double.infinity,
                                  height: MediaQuery.of(context).size.height * 0.3,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset('assets/png/certificate.png', fit: BoxFit.cover),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Image.asset(
                          'assets/png/cert_icon.png',
                          height: 30,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 15),
                            padding: const EdgeInsets.only(top: 50, bottom: 10),
                            color: Colors.white,
                            child: Column(
                              children: [
                                const SizedBox(height: 80),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async{
                                        if (profileBoxProvider.isProfileVisible) {
                                          profileBoxProvider.hideProfileBox();
                                        }
                                        await Util.saveAndChangeLocale(context,  'en');
                                         
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:  !SharedPref().isArabic()? appFontColor:Colors.white,
                                        minimumSize: const Size(100, 30),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      child: Text(translate('profile.english'), style: TextStyle(color:  !SharedPref().isArabic()? Colors.white:Colors.black, fontSize: 12)),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (profileBoxProvider.isProfileVisible) {
                                         profileBoxProvider.hideProfileBox();
                                        }
                                        await Util.saveAndChangeLocale(context,  'ar');
                                        
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: SharedPref().isArabic() ?appFontColor :Colors.grey.shade200,
                                        minimumSize: const Size(100, 30),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      child: Text(translate('profile.arabic'), style: TextStyle(color: SharedPref().isArabic() ? Colors.white: Colors.black, fontSize: 12)),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),
                                Container(
                                  height: 2,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha((0.15 * 255).toInt()),
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.notifications_off, color: Color(0xFF1A1A53), size: 20),
                                          const SizedBox(width: 8),
                                          Text(translate('profile.mute_notifications'), style: GoogleFonts.inter(fontSize: 12)),
                                        ],
                                      ),
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
                                Container(
                                  height: 2,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha((0.15 * 255).toInt()),
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.dark_mode, color: Color(0xFF1A1A53), size: 20),
                                      const SizedBox(width: 8),
                                      Text(translate('profile.dark_mode'), style: const TextStyle(fontSize: 12)),
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
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha((0.5 * 255).toInt()),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Image.asset('assets/png/qr.png', height: 120, width: 120),
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
                        child: Column(
                          children: [
                            Container(
                              height: 2,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha((0.15 * 255).toInt()), // Shadow color
                                    offset: const Offset(0, 2), // Shadow position (horizontal, vertical)
                                    blurRadius: 4,        // Softness of the shadow
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                SharedPref().clearPreferences();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                                );
                              },
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: Text(translate('profile.logout'), style: const TextStyle(color: Colors.red)),
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
        );
      },
    );
  }
}