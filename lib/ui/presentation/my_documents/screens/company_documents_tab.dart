import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Company Documents Tab
class CompanyDocumentsTab extends StatelessWidget {
  const CompanyDocumentsTab({super.key});

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
