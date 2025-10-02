import 'package:el_race/utils/color_utils.dart'; // Import global colors
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/header_widget.dart';

class ProjectAnnouncementPage extends StatelessWidget {
  const ProjectAnnouncementPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Default Header Widget
          const HeaderWidget(),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,size: 32,),
                  onPressed: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    const SizedBox(width: 30),
                    Image.asset('assets/png/news_logo.png'),
                    const SizedBox(width: 8),
                    Text(
                      translate('NEWS'),
                      style: GoogleFonts.koulen(
                          fontSize: 25,
                          fontWeight: FontWeight.w400,
                          color: appFontColor),
                    ),   
                  ],
                ),
                const SizedBox(width: 100),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Project Announcement Section
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Section
                  Container(
                    width: double.infinity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Red Vertical Line
                        // Container(
                        //   width: 26, // Thickness of the red line
                        //   color: const Color(0xFFBA1719), // Red color
                        //   height:
                        //       72, // Ensures it matches the height of the content
                        // ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(5, 15, 0, 10),
                            decoration: const BoxDecoration(
                              color: Color(0xffADB2BD),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    translate('ALAIN CLUB'),
                                    style: GoogleFonts.koulen(
                                      color: appFontColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                                // const SizedBox(height: 8),
                                // Text(
                                //   translate('news_banner.date'),
                                //   style: const TextStyle(
                                //     color: Colors.white,
                                //     fontSize: 8,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Enclosing Image and Text Section
                  Container(
                    //padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha((0.2 * 255).toInt()),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ClipRRect(
                        //  borderRadius: BorderRadius.circular(12),
                        //   child:
                        Image.asset(
                          'assets/png/carousal4.png', // Replace with your asset image path
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                        ),
                        //),

                        const SizedBox(height: 16),

                        // Content Section
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Column(
                            children: [
                              Text(
                                translate('news_banner.announce_completion'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15,
                                  color: Colors.black,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                translate('news_banner.facility_commitment'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                translate('news_banner.sustainability'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}