import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LabelWidget extends StatelessWidget {
  final String name;
  final String time;
  const LabelWidget({super.key, required this.name, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
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
}