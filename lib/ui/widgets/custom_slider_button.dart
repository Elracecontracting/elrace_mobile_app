import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomSliderButton extends StatefulWidget {
  final Future<void> Function() onSlideComplete;
  final dynamic loginResponseModel;

  const CustomSliderButton({
    Key? key, // ✅ Use Flutter's built-in key
    required this.onSlideComplete,
    required this.loginResponseModel,
  }) : super(key: key);

  @override
  CustomSliderButtonState createState() => CustomSliderButtonState();
}
class CustomSliderButtonState2 extends State<CustomSliderButton> {
  double _position = 5.0;
  bool _isCompleted = false;

  void resetSlider() {
    setState(() {
      _position = 5.0;
      _isCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 احسب نسبة السحب (0 → 1)
    double progress = (_position - 5) / (230 - 5);
    progress = progress.clamp(0.0, 1.0);

    // 🔹 اللون يتحول من أبيض إلى أخضر تدريجيًا
    Color dynamicColor = Color.lerp(Colors.white, Colors.green, progress)!;


    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ✅ الخلفية تتغيّر حسب التقدم
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 280,
            height: 39,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [
                  dynamicColor.withOpacity(0.9),
                  dynamicColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: dynamicColor.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),

          // 🔘 زرّ السحب (الدائرة)
          Positioned(
            left: _position,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _position = (details.localPosition.dx + 5).clamp(5, 230);
                });
              },
              onHorizontalDragEnd: (details) async {
                if (_position > 168) {
                  setState(() {
                    _position = 230;
                    _isCompleted = true;
                  });

                  await widget.onSlideComplete();
                } else {
                  setState(() => _position = 5);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: dynamicColor, // 👈 اللون يتغير أثناء السحب
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),

          // 📝 نص "SUBMIT"
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "SUBMIT",
                style: GoogleFonts.koulen(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 2.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class CustomSliderButtonState extends State<CustomSliderButton> {
  double _position = 5.0;
  bool _isCompleted = false;

  void resetSlider() {
    setState(() {
      _position = 5.0;
      _isCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 احسب نسبة السحب (0 → 1)
    double progress = (_position - 5) / (230 - 5);
    progress = progress.clamp(0.0, 1.0);

    // 🔹 اللون يتحول من أبيض إلى أخضر تدريجيًا
    Color dynamicColor = Color.lerp(Colors.white, Colors.green, progress)!;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Container
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 280,
            height: 39,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(width: 2,color: Colors.grey),
              gradient: LinearGradient(
                colors: [
                  dynamicColor.withOpacity(0.9),
                  dynamicColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha((0.5 * 255).toInt()),
                  spreadRadius: 0,
                  blurRadius: 0,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
          // Container(
          //   width: 280,
          //   height: 39,
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(30),
          //     image: const DecorationImage(
          //       image: AssetImage('assets/png/button_background.png'),
          //       fit: BoxFit.contain,
          //     ),
          //     color: Colors.white,
          //     boxShadow: [
          //       BoxShadow(
          //         color: Colors.grey.withAlpha((0.5 * 255).toInt()),
          //         spreadRadius: 0,
          //         blurRadius: 0,
          //         offset: const Offset(0, 0),
          //       ),
          //     ],
          //   ),
          // ),

          // Draggable Circle Button
          Positioned(
            left: _position,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _position = (details.localPosition.dx + 5).clamp(5, 230);
                });
              },
              onHorizontalDragEnd: (details) {
                if (_position > 168) {
                  setState(() {
                    _position = 230;
                    _isCompleted = true;
                  });

                  Future.delayed(const Duration(milliseconds: 0), () async {
                    await widget.onSlideComplete();
                  });

                } else {
                  setState(() => _position = 5);
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade900,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),

          // Submit Text
           Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "SUBMIT",
                style: GoogleFonts.koulen(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: appFontColor,
                  letterSpacing: 2.2, // Optional: for visual spacing
                ),
              ),

            ),
          ),
        ],
      ),
    );
  }
}
