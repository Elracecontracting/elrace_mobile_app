import 'package:el_race/utils/color_utils.dart'; // Import global colors
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/header_widget.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:el_race/ui/presentation/News%20Banner/banner.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/widget_container.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../home_screen/provider/slider_provider.dart';
import '../home_screen/screens/main_screens.dart';
import '../home_screen/widgets/visibilty_icon.dart';

class ProjectAnnouncementPage extends StatelessWidget {
  final news;
  const ProjectAnnouncementPage({
    required this.news,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      extendBody: true, // 👈 مهم جدًا
      floatingActionButton: const ArraowVisibalityBottomNav(),
      bottomNavigationBar:  const CustomBottomNavBar(isMain: false,),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 32,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    const SizedBox(width: 30),
                    Image.asset('assets/png/news_logo.png'),
                    const SizedBox(width: 8),
                    Text(
                      translate('home.news'),
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
                                    news['titles'],
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
                         "${ news['image']}", // Replace with your asset image path
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
                                "${ news['des']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15,
                                  color: Colors.black,
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
class NewsPage extends StatelessWidget {
  final  sliderList = [
    {
      "image": 'assets/png/slider_2.png',
      "titles":"abu dhabi dialysis center",
      "des":'''We are proud to announce the successful completion of a state-of-the-art healthcare facility, designed to elevate patient care and meet the growing healthcare needs of our community. This landmark project reflects our commitment to delivering excellence and innovation in the field of healthcare infrastructure.
The facility is equipped with cutting-edge medical technology, modern treatment rooms, and comfortable spaces that prioritize the well-being of patients and healthcare professionals alike. With a focus on accessibility, it ensures that advanced medical services are available to all residents, enhancing the overall quality of care in the region.
This project embodies our dedication to creating spaces that serve as pillars of support for the community, fostering health and wellness for everyone. By combining functionality with innovative design, we aim to set a new standard for healthcare facilities in the area.
We extend our gratitude to our skilled team, trusted partners, and the community for their collaboration and encouragement throughout this journey. Together, we have built more than a facility – we have created a space that will have a lasting, positive impact on people’s lives.
''',
      "des2":'''We are proud to announce the successful completion of a state-of-the-art healthcare facility, designed to elevate patient care and meet the growing healthcare needs of our community. This landmark project reflects our commitment to delivering excellence and innovation in the field of healthcare infrastructure.''',
    },
    {
      "image": 'assets/png/slider_3.png',
      "titles":"um kalthom school",
      "des":'''Al Race is thrilled to announce the successful completion of Umm Kulthum School, a cutting-edge educational facility designed to empower and inspire the next generation of learners. The school has officially opened its doors to students and staff, symbolizing a major step forward for the community’s educational growth.
This state-of-the-art building combines innovative design with functionality, providing students with an ideal environment for academic and personal development. The facility features modern classrooms, advanced laboratories, spacious recreational areas, and sustainable design elements, ensuring a well-rounded experience for students and staff alike.
We extend our heartfelt gratitude to everyone who contributed to this achievement – our dedicated workforce, supportive partners, and the community whose encouragement has been invaluable. This project is more than just a building; it represents a shared vision for the future, where quality education is accessible in a space that inspires learning and creativity.
''',
      "des2":'''Al Race is thrilled to announce the successful completion of Umm Kulthum School, a cutting-edge educational facility designed to empower and inspire the next generation of learners. The school has officially opened its doors to students and staff, symbolizing a major step forward for the community’s educational growth.''',
    },
    {
      "image":'assets/png/slider_4.png',
      "titles":" horse stables project",
      "des":'''The company is proud to announce the successful completion of the modern horse stables project located in Falaj Hazza Police Station. This project reflects our unwavering commitment to fine craftsmanship and innovation in equestrian infrastructure.
Designed to provide the utmost comfort and care for the horses, the stables feature advanced ventilation systems, spacious stalls, and state-of-the-art feeding and watering facilities. The layout has been meticulously planned to ensure ease of access for caretakers and to promote the well-being of the horses.
Sustainability and durability were at the forefront of this project. Eco-friendly materials and energy-efficient systems have been incorporated, making the stables not only functional but also environmentally conscious. The design combines traditional aesthetics with modern technology, honoring the heritage of equestrian culture while meeting contemporary standards.
''',
      "des2":'''The company is proud to announce the successful completion of the modern horse stables project located in Falaj Hazza Police Station. This project reflects our unwavering commitment to fine craftsmanship and innovation in equestrian infrastructure.''',
    },
    {
      "image": 'assets/png/slider.png',
      "titles":"alain club ",
      "des":'''We are pleased to announce the completion of our latest construction project. After months of hard work and dedication, our team has successfully realized this vision by developing a fully integrated sports building for Al Ain Club.
This state-of-the-art facility reflects our commitment to excellence and innovation in construction, blending modern architectural design with functionality to support athletes and the community. Equipped with cutting-edge technology and premium materials, the building includes training areas, administrative offices, locker rooms, and recreational spaces that meet international standards.
The sports building was designed with sustainability in mind, incorporating energy-efficient systems and eco-friendly practices to reduce environmental impact. From the foundation to the finishing touches, every detail was meticulously planned and executed to ensure durability and exceptional quality.
As a company, we take pride in contributing to Al Ain Club’s legacy by providing an environment that fosters talent, encourages teamwork, and inspires greatness. This project not only strengthens our partnership with the sports industry but also demonstrates our ability to deliver large-scale projects that leave a lasting impression.''',
      "des2":'''We are pleased to announce the completion of our latest construction project. After months of hard work and dedication, our team has successfully realized this vision by developing a fully integrated sports building for Al Ain Club.''',
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      extendBody: true, // 👈 مهم جدًا
      floatingActionButton: const ArraowVisibalityBottomNav(),
      bottomNavigationBar:  const CustomBottomNavBar(isMain: false,),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 32,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    const SizedBox(width: 30),
                    Image.asset('assets/png/news_logo.png'),
                    const SizedBox(width: 8),
                    Text(
                      translate('home.news'),
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
          Expanded(
            child: ListView.builder(
            //  padding: EdgeInsets.symmetric(horizontal: 10.w),
              itemCount: sliderList.length,
              itemBuilder: (context, index) {
                var item =sliderList[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 5.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    // borderRadius: BorderRadius.circular(14),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.black.withOpacity(0.1),
                    //     blurRadius: 6,
                    //     offset: const Offset(0, 3),
                    //   )
                    // ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Title
                      Container(
                        padding: const EdgeInsets.fromLTRB(5, 15, 0, 10),
                        decoration: const BoxDecoration(
                          color: Color(0xffADB2BD),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                "${item['titles']}".toUpperCase(),
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

                      // 🔹 Image
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(0)),
                        child: Image.asset(
                         "${ item['image']}",
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 180.h,
                        ),
                      ),

                      // 🔹 Description
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(text: "${item['des2']}  "),
                              TextSpan(
                                text: 'See All',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF191F52),
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // 🟢 هنا ضع ما تريده يحدث عند الضغط على "See All"
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProjectAnnouncementPage(
                                          news: item,
                                        ),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),

                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class NewsPage2 extends StatelessWidget {
  const NewsPage2({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);

    final List<Map<String, String>> projects = [
      {
        'title': 'ALAIN CLUB',
        'image': 'assets/images/alain_club.jpg',
        'desc':
        'We are pleased to announce the completion of our latest construction project. After months of hard work and dedication, our team has successfully realized this...'
      },
      {
        'title': 'HORSE STABLES PROJECT',
        'image': 'assets/images/horse_stables.jpg',
        'desc':
        'We are pleased to announce the completion of our latest construction project. After months of hard work and dedication, our team has successfully realized this...'
      },
      {
        'title': 'UM KALTHOM SCHOOL',
        'image': 'assets/images/um_kalthom.jpg',
        'desc':
        'Al Race is thrilled to announce the successful completion of Umm Kulthum School, a cutting-edge educational facility designed to empower and inspire...'
      },
      {
        'title': 'ABU DHABI DIALYSIS CENTER',
        'image': 'assets/images/dialysis_center.jpg',
        'desc':
        'We are proud to announce the successful completion of a state-of-the-art healthcare facility, designed to elevate patient care and enhance the healthcare...'
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                  Text(
                    'NEWS',
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF191F52),
                    ),
                  ),
                  const Icon(Icons.menu, color: Colors.transparent),
                ],
              ),
            ),

            // 🔹 News List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final item = projects[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 20.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Title
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE5E5E5),
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(14)),
                          ),
                          child: Text(
                            item['title']!,
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF191F52),
                            ),
                          ),
                        ),

                        // 🔹 Image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(0)),
                          child: Image.asset(
                            item['image']!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 180.h,
                          ),
                        ),

                        // 🔹 Description
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 10.h),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: Colors.black,
                              ),
                              children: [
                                TextSpan(text: item['desc']),
                                TextSpan(
                                  text: '  See All',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF191F52),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 🔹 Bottom Navigation Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 10.h),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.phone, size: 28, color: Color(0xFF191F52)),
                  Icon(Icons.home, size: 28, color: Color(0xFF191F52)),
                  Icon(Icons.newspaper, size: 28, color: Color(0xFF191F52)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

