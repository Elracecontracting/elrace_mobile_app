import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/prayer_time_gridview.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/prayer_time_listview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ParayerWidget extends StatelessWidget {
  const ParayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return  Opacity(
      opacity: !SharedPref.isUserAuthenticated() ? .5 : 1,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: const DecorationImage(
            image: AssetImage('assets/png/gray_card.png'), // ✅ Update to your image path
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  'Prayer times',
                  style: GoogleFonts.koulen(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xff151544),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: InkWell(
                      onTap: () {},
                      child: const Icon(
                        Icons.volume_up,
                        color: Color(0xff151544),
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 15),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrayerTimeListView(),
                
                PrayerTimeGridView(),
              ],
            ),

          ],
        ),
      ),
    );
  }
}