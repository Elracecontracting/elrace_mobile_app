import 'package:flutter/material.dart';
import '../../widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart'; // Import global colors
import 'package:flutter_translate/flutter_translate.dart';

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
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  translate('news_banner.announcements'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appFontColor),
                ),
                const SizedBox(width: 40), // Spacer for alignment
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Project Announcement Section
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
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
                          Container(
                            width: 26, // Thickness of the red line
                            color: const Color(0xFFBA1719), // Red color
                            height: 72, // Ensures it matches the height of the content
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(5, 15, 0, 10),
                              decoration: const BoxDecoration(
                                color: appFontColor,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    translate('news_banner.project_completion'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    translate('news_banner.date'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),


                    // Enclosing Image and Text Section
                    Container(
                      padding: const EdgeInsets.all(14),
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
                          // Image Section
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/png/slider.png', // Replace with your asset image path
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Content Section
                          Text(
                            translate('news_banner.announce_completion'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            translate('news_banner.facility_commitment'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            translate('news_banner.sustainability'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                        ],
                      ),
                    ),
                  ],

                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
