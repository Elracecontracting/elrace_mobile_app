import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Share Documents Tab
class ShareDocumentsTab extends StatelessWidget {
  const ShareDocumentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No Docs',
        style: GoogleFonts.aBeeZee(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: const Color(0xff949494),
        ),
      ),
    );
  }
}
