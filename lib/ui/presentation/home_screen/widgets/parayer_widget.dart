import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ParayerWidget extends StatefulWidget {
  const ParayerWidget({super.key});
  @override
  State<ParayerWidget> createState() => _ParayerWidgetState();
}

class _ParayerWidgetState extends State<ParayerWidget> {
  PrayerTimes? _pt;
  Prayer? _next;
  DateTime? _nextTime;
  Timer? _ticker;

  String? _error; // <— keep the reason
  bool _loading = true; // <— explicit loading flag

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1) Try last known position for instant UI (may be null)
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _setPrayerTimesFor(Coordinates(last.latitude, last.longitude));
      }

      // 2) Ensure services + permissions
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled.');
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }

      // 3) Fresh position with a timeout (prevents hanging forever)
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      _setPrayerTimesFor(Coordinates(pos.latitude, pos.longitude));
    } catch (e) {
      // 4) If we still don't have _pt (no last known), fallback to Cairo
      _error = e.toString();
      if (_pt == null) {
        _setPrayerTimesFor(Coordinates(30.0444, 31.2357)); // Cairo fallback
      } else {
        // we already showed last-known times; just mark error
        setState(() {});
      }
    } finally {
      setState(() => _loading = false);
      _startTicker();
    }
  }

  void _setPrayerTimesFor(Coordinates coords) {
    final params = CalculationMethod.egyptian.getParameters()
      ..madhab = Madhab.hanafi;

    final pt = PrayerTimes.today(coords, params);
    final n = pt.nextPrayer();
    final nt = pt.timeForPrayer(n);
    setState(() {
      _pt = pt;
      _next = n;
      _nextTime = nt;
    });
  }

  void _startTicker() {
    _ticker?.cancel();
    if (_pt == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final n = _pt!.nextPrayer();
      final nt = _pt!.timeForPrayer(n);
      if (n != _next || nt != _nextTime) {
        setState(() {
          _next = n;
          _nextTime = nt;
        });
      } else {
        setState(() {}); // just update countdown
      }
    });
  }

  String _fmt(DateTime dt) => DateFormat('hh:mm a').format(dt);
  String _hhmmssUntil(DateTime? t) {
    if (t == null) return '--:--:--';
    final diff = t.difference(DateTime.now());
    final d = diff.isNegative ? Duration.zero : diff;
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    // Loader state
    if (_loading && _pt == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // We always try to render something (_pt is set either by last-known or fallback)
    final pt = _pt!;
    return Opacity(
      opacity: !SharedPref.isUserAuthenticated() ? .5 : 1,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: AssetImage('assets/png/prayer_time_background.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text('Prayer times',
                        style: GoogleFonts.koulen(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        )),
                    const Spacer(),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.error_outline,
                            color: Colors.yellow.shade200, size: 18),
                      ),
                    InkWell(
                      onTap: _init, // refresh / retry
                      child: Image.asset('assets/png/Vector.png',
                          color: Colors.white),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style:
                        GoogleFonts.kanit(fontSize: 12, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: Geolocator.openLocationSettings,
                        child: const Text('Open Location Settings'),
                      ),
                      TextButton(
                        onPressed: Geolocator.openAppSettings,
                        child: const Text('Open App Settings'),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 0.h), // Reduced from 20.h
                Stack(children: [
                  Column(
                    children: [
                      SizedBox(height: 65.h),
                      SvgPicture.asset(
                        'assets/png/prayer_curve.svg',
                        height: 85.h,
                        fit: BoxFit.fill,
                      ),
                    ],
                  ), // Reduced from 160.h
                  Positioned(
                      bottom: 65.h, // Reduced from 85.h
                      left: 0,
                      child: _label('Fajr', _fmt(pt.fajr))),
                  Positioned(
                      bottom: 24.h, // Reduced from 55.h
                      left: 26.w,
                      child: SvgPicture.asset('assets/png/fajr_icon.svg')),
                  Positioned(
                      bottom: 80.h, // Reduced from 110.h
                      left: 60.w,
                      child: _label('Dhuhr', _fmt(pt.dhuhr))),
                  Positioned(
                      bottom: 70.h, // Reduced from 110.h
                      right: 0.w,
                      left: 0.w,
                      child: SvgPicture.asset('assets/png/dhuhr_icon.svg')),
                  Positioned(
                      bottom: 80.h, // Reduced from 110.h
                      right: 50.w,
                      child: _label('Maghrib', _fmt(pt.maghrib))),
                  Positioned(
                      bottom: 60.h, // Reduced from 85.h
                      right: 0,
                      child: _label('Isha', _fmt(pt.isha))),
                  Positioned(
                      bottom: 28.h, // Reduced from 55.h
                      right: 25.w,
                      child: SvgPicture.asset('assets/png/ishaa_icon.svg')),
                  Positioned(
                    top: 12.h,
                    left: 0,
                    right: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6.3),
                            border: Border.all(color: Colors.white),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6.3),
                            child: ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [Color(0xffFFFFFF), Color(0xff999999)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(b),
                              child: Text(
                                'Asr',
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
                          _fmt(pt.asr),
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
                    bottom: 18.h, // Reduced from 50.h
                    right: 0,
                    left: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'till ${(_next ?? Prayer.fajr).name.toUpperCase()}',
                          style: GoogleFonts.kanit(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _hhmmssUntil(_nextTime),
                          style: GoogleFonts.kanit(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ),
          Positioned(
            right: 10.w,
            bottom: 5.h, // Reduced from 15.h
            child: Image.asset(
              'assets/png/pray_decoration.png',
              width: 160.w, // Reduced from 200.w
              height: 200.h, // Reduced from 250.h
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String name, String time) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(name,
              style: GoogleFonts.kanit(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              )),
          Text(time,
              style: GoogleFonts.kanit(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              )),
        ],
      );
}
