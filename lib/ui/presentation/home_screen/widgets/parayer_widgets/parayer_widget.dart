import 'package:adhan/adhan.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/parayer_widgets/label_widget.dart';
import 'package:el_race/utils/dimens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ParayerWidget extends StatefulWidget {
  const ParayerWidget({super.key});
  @override
  State<ParayerWidget> createState() => _ParayerWidgetState();
}

class _ParayerWidgetState extends State<ParayerWidget>
    with WidgetsBindingObserver {
  String _prayerKey(Prayer p) {
    switch (p) {
      case Prayer.fajr:
        return 'home.Fajr';
      case Prayer.dhuhr:
        return 'home.Dhuhr';
      case Prayer.asr:
        return 'home.Asr';
      case Prayer.maghrib:
        return 'home.Maghrib';
      case Prayer.isha:
        return 'home.Isha';
      default:
        return 'home.Fajr';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Dispatch events to BLoC
    context.read<HomeBloc>().add(const LoadPrayerMuteStateEvent());
    context.read<HomeBloc>().add(const InitPrayerTimesEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeBloc>().add(const InitPrayerTimesEvent());
    }
  }

  String _fmt(DateTime dt) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('hh:mm a', locale).format(dt);
  }

  String _hhmmssUntil(DateTime? t) {
    if (t == null) return '--:--:--';
    final diff = t.difference(DateTime.now());
    final d = diff.isNegative ? Duration.zero : diff;
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  // Get prayer time based on Prayer enum
  DateTime? _getPrayerTime(PrayerTimes? pt, Prayer? prayer) {
    if (pt == null || prayer == null) return null;
    switch (prayer) {
      case Prayer.fajr:
        return pt.fajr;
      case Prayer.dhuhr:
        return pt.dhuhr;
      case Prayer.asr:
        return pt.asr;
      case Prayer.maghrib:
        return pt.maghrib;
      case Prayer.isha:
        return pt.isha;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (previous, current) =>
          current is PrayerTimesLoading ||
          current is PrayerTimesLoaded ||
          current is PrayerTimesError ||
          current is PrayerMuteStateChanged,
      builder: (context, state) {
        PrayerTimes? pt;
        Prayer? nextPrayer;
        DateTime? nextTime;
        String? error;
        bool isSoundMuted = false;

        if (state is PrayerTimesLoaded) {
          pt = state.prayerTimes;
          nextPrayer = state.nextPrayer;
          nextTime = state.nextTime;
          error = state.error;
          isSoundMuted = state.isSoundMuted;
        } else if (state is PrayerTimesError) {
          pt = state.prayerTimes;
          error = state.error;
          isSoundMuted = state.isSoundMuted;
        } else if (state is PrayerMuteStateChanged) {
          isSoundMuted = state.isMuted;
        }

        // If no prayer times yet, show loading
        // if (pt == null) {
        //   return const SizedBox.shrink();
        // }

        return Opacity(
          opacity: !SharedPref.isUserAuthenticated() ? .5 : 1,
          child: SizedBox(
            width: double.infinity,
            height: AppDimen.homeWidgetCardHeight.w + 13.w,
            child: Stack(
              children: [
                Container(
                    width: double.infinity,
                    height: AppDimen.homeWidgetCardHeight.w + 13.w,
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      image: const DecorationImage(
                        image:
                            AssetImage('assets/png/prayer_time_background.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Stack(alignment: Alignment.centerRight, children: [
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Image.asset(
                          'assets/png/pray_decoration.png',
                          width: 200.w,
                          height: 200.w,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 30.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(translate('home.prayer_times'),
                                    style: GoogleFonts.koulen(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                    )),
                                const Spacer(),
                                if (error != null)
                                  Padding(
                                    padding: EdgeInsets.only(right: 6.w),
                                    child: Icon(Icons.error_outline,
                                        color: Colors.yellow.shade200,
                                        size: 16.sp),
                                  ),
                                SizedBox(width: 8.w),
                                InkWell(
                                  onTap: () {
                                    context
                                        .read<HomeBloc>()
                                        .add(const InitPrayerTimesEvent());
                                    context.read<HomeBloc>().add(
                                        const TogglePrayerMuteStateEvent());
                                  },
                                  child: isSoundMuted
                                      ? Icon(Icons.volume_mute,
                                          color: Colors.white, size: 30.w)
                                      : Image.asset('assets/png/Vector.png',
                                          color: Colors.white,
                                          width: 26.w,
                                          height: 20.w),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            SizedBox(
                              height: 140.h,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: SvgPicture.asset(
                                      'assets/png/prayer_curve.svg',
                                      height: 80.h,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  Positioned(
                                      bottom: 40.h,
                                      left: -1.w,
                                      child: LabelWidget(
                                          name: translate('home.Fajr'),
                                          time: _fmt(
                                              pt?.fajr ?? DateTime.now()))),
                                  Positioned(
                                      top: 70.h,
                                      left: 50.w,
                                      child: SvgPicture.asset(
                                          'assets/png/fajr_icon.svg')),
                                  Positioned(
                                      bottom: 85.w,
                                      left: 60.w,
                                      child: LabelWidget(
                                          name: translate('home.Dhuhr'),
                                          time: _fmt(
                                              pt?.dhuhr ?? DateTime.now()))),
                                  Positioned(
                                    bottom: 70.w,
                                    right: 0.w,
                                    left: 0.w,
                                    child: Center(
                                      child: Container(
                                        width: 70.w,
                                        height: 35.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFFE082)
                                                  .withOpacity(0.95),
                                              blurRadius: 1,
                                              spreadRadius: 1,
                                            ),
                                            BoxShadow(
                                              color: const Color(0xFFFFC107)
                                                  .withOpacity(0.55),
                                              blurRadius: 5,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: SvgPicture.asset(
                                            'assets/png/dhuhr_icon.svg',
                                            width: 36.w,
                                            height: 36.w,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                      bottom: 85.w,
                                      right: 50.w,
                                      child: LabelWidget(
                                          name: translate('home.Maghrib'),
                                          time: _fmt(
                                              pt?.maghrib ?? DateTime.now()))),
                                  Positioned(
                                      bottom: 35.h,
                                      right: 0.w,
                                      child: LabelWidget(
                                          name: translate('home.Isha'),
                                          time: _fmt(
                                              pt?.isha ?? DateTime.now()))),
                                  Positioned(
                                      top: 75.h,
                                      right: 50.w,
                                      child: SvgPicture.asset(
                                          'assets/png/ishaa_icon.svg')),
                                  Positioned(
                                    top: 1.h,
                                    left: 0,
                                    right: 0,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(6.3),
                                            border:
                                                Border.all(color: Colors.white),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6.3),
                                            child: ShaderMask(
                                              shaderCallback: (b) =>
                                                  const LinearGradient(
                                                colors: [
                                                  Color(0xffFFFFFF),
                                                  Color(0xff999999)
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ).createShader(b),
                                              child: Text(
                                                translate(_prayerKey(
                                                    nextPrayer ?? Prayer.fajr)),
                                                style: GoogleFonts.kanit(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _fmt(_getPrayerTime(pt, nextPrayer) ??
                                              DateTime.now()),
                                          style: GoogleFonts.kanit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 18.h,
                                    right: 0,
                                    left: 0,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Builder(builder: (context) {
                                          final Prayer prayerToUse =
                                              nextPrayer ?? Prayer.fajr;
                                          final nextPrayerName = translate(
                                              _prayerKey(prayerToUse));

                                          return Text(
                                            translate('home.till_prayer',
                                                args: {
                                                  'prayer': nextPrayerName
                                                }),
                                            style: GoogleFonts.kanit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white,
                                            ),
                                          );
                                        }),
                                        Text(
                                          _hhmmssUntil(nextTime),
                                          style: GoogleFonts.kanit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ])),
              ],
            ),
          ),
        );
      },
    );
  }
}
