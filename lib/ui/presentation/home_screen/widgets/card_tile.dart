import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../utils/color_utils.dart';
import '../../../../../../utils/dimens.dart';
import '../../../../../../utils/orientation_helper.dart';

class CardTile extends StatelessWidget {
  final int itemIndex;
  const CardTile({super.key, required this.itemIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: 345,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: itemIndex.isOdd
                ? [buttonLight, Colors.white, buttonDark]
                : [lightGrey, darkGrey],
          )),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: SizeConfig().getWidth(40),
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: itemIndex.isOdd
                          ? [
                              buttonLight,
                              buttonDark.withAlpha((0.2 * 255).toInt())
                            ]
                          : [lightGrey, darkGrey],
                    )),
                child: const SizedBox(
                  height: 160,
                ),
              ),
              /*  SizedBox(
              height: 160,
              child: Row(
                children: [
                  Image.asset('assets/png/spike1.png'),
                  Image.asset('assets/png/spike2.png'),
                ],
              ),
            ),*/
              Container(
                width: SizeConfig().getWidth(40),
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      colors: itemIndex.isOdd
                          ? [
                              buttonLight,
                              buttonDark.withAlpha((0.2 * 255).toInt())
                            ]
                          : [lightGrey, darkGrey],
                    )),
                child: const SizedBox(
                  height: 160,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                vertical: SizeConfig().getHeight(20),
                horizontal: SizeConfig().getWidth(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 23,
                      width: 45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: white,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white,
                            Colors.black
                                .withAlpha((0.3 * 255).toInt()), // Shadow color
                          ],
                          center: Alignment.center,
                          radius: 3,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.arrow_right,
                          color: shadowBlueDark,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      color: shadowBlueDark,
                      child: Icon(
                        size: SizeConfig().getTextSize(24),
                        Icons.access_time_filled_rounded,
                        color: white,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      'My Title',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: SizeConfig().getTextSize(18),
                        color: shadowBlueDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GrayCardComponent extends StatelessWidget {
  const GrayCardComponent({
    super.key,
    this.mainIcon,
    this.onClick,
    required this.cardTitle,
    required this.backgroundImagePath,
    required this.childWidget,
    this.topPadding = false,
    this.topPaddingValue = 60,
  });
  final double? topPaddingValue;
  final bool topPadding;
  final String? mainIcon;
  final String backgroundImagePath;
  final VoidCallback? onClick;
  final String cardTitle;
  final Widget childWidget;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onClick,
      child: SizedBox(
        width: double.infinity,
        height: AppDimen.homeWidgetCardHeight.w,
        child: Container(
          width: double.infinity,
          height: AppDimen.homeWidgetCardHeight.w,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(backgroundImagePath),
              fit: BoxFit.fill,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 36.w,
                top: 16,
                child: SizedBox(
                  height: SizeConfig().getHeight(43),
                  child: Row(
                    children: [
                      // SizedBox(
                      //   width: SizeConfig().getWidth(40.26),
                      //   height: SizeConfig().getHeight(40.31),
                      //   child: Image.asset(
                      //     mainIcon,
                      //     width: SizeConfig().getWidth(40),
                      //     height: SizeConfig().getHeight(40),
                      //   ),
                      // ),
                      // const SizedBox(width: 10),
                      Text(
                        cardTitle.toUpperCase(),
                        style: GoogleFonts.koulen(
                          color: const Color(0xFF151544),
                          fontSize: 24.w,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: topPadding ? topPaddingValue : 30.h,
                left: 37.w,
                child: DefaultTextStyle(
                  style: GoogleFonts.nunito(
                    fontSize: 12.w,
                    color: Colors.black,
                  ),
                  child: Column(
                    children: [childWidget],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
