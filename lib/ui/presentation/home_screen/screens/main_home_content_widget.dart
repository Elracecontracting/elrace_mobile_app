import 'package:carousel_slider/carousel_slider.dart';
import 'package:el_race/ui/presentation/News%20Banner/banner.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/widget_container.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../provider/slider_provider.dart';

class MainHomeContentWidget extends StatelessWidget {
  const MainHomeContentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final sliderProvider = Provider.of<SliderProvider>(context);
    return RefreshIndicator(
      onRefresh: () async => await Util.fetchHomeScreenData(context),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: SizeConfig().getHeight(10)),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CarouselSlider.builder(
                      itemCount: sliderProvider.sliderImages.length,
                      itemBuilder: (BuildContext context, int itemIndex,
                          int pageViewIndex) {
                        return GestureDetector(
                          onTap: () => Util.pushPage(
                                NewsPage(), context),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: SizeConfig().getWidth(7)),
                            child: Container(
                              height: 160.w,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: itemIndex.isEven
                                      ? [buttonLight, Colors.white, buttonDark]
                                      : [lightGrey, darkGrey],
                                ),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.asset(
                                      sliderProvider.sliderImages[itemIndex],
                                      fit: BoxFit.cover,
                                      height: 190,
                                      width: double.infinity,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 30,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        image: const DecorationImage(
                                          image: AssetImage(
                                              'assets/png/news-liner-bg.png'),
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 1),
                                      child: Text(
                                        sliderProvider.titles[itemIndex %
                                            sliderProvider.titles.length],
                                        style: TextStyle(
                                          color: appFontColor,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              offset: const Offset(0, 1),
                                              blurRadius: 6,
                                              color: Colors.black.withAlpha(
                                                  (0.4 * 255).toInt()),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: 190,
                        autoPlay: true,
                        aspectRatio: 16 / 9,
                        viewportFraction: 1.0,
                        onPageChanged: (index, reason) {
                          sliderProvider.setCurrentIndex(index);
                        },
                        initialPage: sliderProvider.currentIndex,
                      ),
                    ),

                    // Dots Indicator
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(sliderProvider.titles.length,
                            (index) {
                          final isActive = sliderProvider.currentIndex == index;
                          return GestureDetector(
                            onTap: () => sliderProvider.setCurrentIndex(index),
                            child: Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? const Color(0xFF1A1A53)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: const Color(0xFF1A1A53),
                                  width: 1,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                     )
                    ),
                  ],
                ),
                //
                // // "See All" Button
                // Padding(
                //   padding: const EdgeInsets.only(top: 12.0, right: 16),
                //   child: Align(
                //     alignment: Alignment.centerRight,
                //     child: GestureDetector(
                //       onTap: () => Util.pushPage(
                //           const ProjectAnnouncementPage(), context),
                //       child: Text(
                //         translate('home.see_all'),
                //         style: GoogleFonts.inter(
                //           fontSize: 16,
                //           color: Colors.grey[700],
                //           fontWeight: FontWeight.w500,
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
            SizedBox(height: 15.w),
            const WidgetContainer(),
            SizedBox(height: 120.h),
          ],
        ),
      ),
    );
  }
}
