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
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Container
          Container(
            width: 280,
            height: 39,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              image: const DecorationImage(
                image: AssetImage('assets/png/button_background.png'),
                fit: BoxFit.contain,
              ),
              color: Colors.white,
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
