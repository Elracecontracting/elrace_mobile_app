import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/report_module/presentation/screens/report_listing/report_app_home_screen.dart';
import 'package:el_race/ui/presentation/Attendace_list/attendance_page.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashList.dart';
import 'package:el_race/ui/presentation/home_screen/data/widget_model.dart';
import 'package:el_race/ui/presentation/home_screen/services/widget_service.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/card_tile.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/custom_bullet_point.dart';
import 'package:el_race/ui/presentation/lpo/screens/lpo_screen.dart';
import 'package:el_race/ui/presentation/media/screens/media_list_screen.dart';
import 'package:el_race/ui/presentation/my_documents/screens/my_documents_screen.dart';
import 'package:el_race/ui/presentation/my_notes/screens/my_notes_screen.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/screens/my_project.dart';
import 'package:el_race/ui/presentation/my_request/MyRequestsPage.dart';
import 'package:el_race/ui/presentation/qr_code/qr_code_screen.dart';
import 'package:el_race/ui/presentation/task_sheet/task_sheet_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/home_bloc.dart';

class ListViewWidgets extends StatefulWidget {
  const ListViewWidgets({
    super.key,
  });

  @override
  State<ListViewWidgets> createState() => _ListViewWidgetsState();
}

class _ListViewWidgetsState extends State<ListViewWidgets> {
  List<WidgetModel> activeWidgets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveWidgets();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadActiveWidgets();
  }

  Future<void> _loadActiveWidgets() async {
    final widgets = await WidgetService.getActiveWidgets();
    if (mounted) {
      setState(() {
        activeWidgets = widgets;
        isLoading = false;
      });
    }
  }

  Widget _buildCustomWidget(WidgetModel widget) {
    switch (widget.id) {
      case 'time_sheet':
        return _buildTimeSheetWidget();
      case 'petty_cash':
        return _buildPettyCashWidget();
      case 'lpo':
        return _buildLPOWidget();
      case 'documents':
        return _buildDocumentsWidget();
      case 'my_notes':
        return _buildMyNotesWidget();
      case 'projects':
        return _buildProjectsWidget();
      case 'my_request':
        return _buildMyRequestWidget();
      case 'media':
        return _buildMediaWidget();
      case 'my_report':
        return _buildMyReportWidget();
      case 'qr_code':
        return _buildQrCodeWidget();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTimeSheetWidget() {
    return GrayCardComponent(
      onClick: () => Util.pushPage(const TaskSheetPage(), context),
      mainIcon: 'assets/png/time_sheet.png',
      cardTitle: translate('home.time_sheet'),
      backgroundImagePath: 'assets/png/gray_card.png', // ✅ Add this
      topPadding: true,
      topPaddingValue: 40,
      childWidget: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: 210.w,
              ),
              child: Image.asset(
                'assets/png/time_sheet.png',
                width: SizeConfig().getWidth(140),
                height: SizeConfig().getHeight(140),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 66),
              child: SizedBox(
                width: SizeConfig().getWidth(190),
                height: SizeConfig().getHeight(85),
                child: Column(
                  children: [
                    CustomBulletPoint(
                      // bulletColor: Color(0xFF009859),
                      text: translate('home.No_of_Labors'),
                      textColor: Colors.black,
                      countColor: Colors.black,
                      count: '15',
                      containerColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // childWidget: Padding(
      //   padding: EdgeInsets.only(
      //     left: 210.w,
      //   ),
      //   child: Image.asset(
      //     'assets/png/time_sheet.png',
      //     width: SizeConfig().getWidth(140),
      //     height: SizeConfig().getHeight(140),
      //   ),
      // ),
    );
  }

  Widget _buildPettyCashWidget() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          GrayCardComponent(
            onClick: () => Util.pushPage(const PettyCashList(), context),
            cardTitle: translate('home.petty_cash'),
            backgroundImagePath: 'assets/png/pettycash_new_bg.png',
            childWidget: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildLPOWidget() {
    return GrayCardComponent(
      onClick: () => Util.pushPage(const LpoListScreen(), context),
      mainIcon: 'assets/png/time_sheet.png',
      cardTitle: translate('home.lpo'),
      backgroundImagePath: 'assets/png/gray_card.png', // ✅ Add this
      topPadding: true,
      topPaddingValue: 40,
      childWidget: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: 210.w,
              ),
              child: Image.asset(
                'assets/png/lpo.png',
                width: SizeConfig().getWidth(140),
                height: SizeConfig().getHeight(140),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 66),
              child: SizedBox(
                width: SizeConfig().getWidth(190),
                height: SizeConfig().getHeight(85),
                child: Column(
                  children: [
                    CustomBulletPoint(
                      // bulletColor: Color(0xFF009859),
                      text: translate('home.No_of_LPO'),
                      textColor: Colors.black,
                      countColor: Colors.black,
                      count: '15',
                      containerColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // childWidget: Padding(
      //   padding: EdgeInsets.only(
      //     left: 210.w,
      //   ),
      //   child: Image.asset(
      //     'assets/png/lpo.png',
      //     width: SizeConfig().getWidth(140),
      //     height: SizeConfig().getHeight(140),
      //   ),
      // ),
    );
  }

  Widget _buildDocumentsWidget() {
    return Stack(
      children: [
        GrayCardComponent(
          onClick: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const MyDocumentsScreen()),
            );
          },
          cardTitle: translate('home.documents'),
          backgroundImagePath: 'assets/png/gray_card.png',
          childWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              DefaultTextStyle(
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: Color(0xFF1A1A53),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 52),
                  child: SizedBox(
                    width: SizeConfig().getWidth(270),
                    height: SizeConfig().getHeight(50),
                    child: Image.asset('assets/newapp/simple_cards.png'),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 6,
          top: 30,
          child: Image.asset('assets/png/icons/doc_icon.png'),
        ),
      ],
    );
  }

  Widget _buildMyNotesWidget() {
    return Stack(
      children: [
        GrayCardComponent(
          cardTitle: translate('home.my_notes'),
          backgroundImagePath: 'assets/png/blue_card.png',
          onClick: () => Util.pushPage(const MyNotesScreen(), context),
          topPadding: true,
          childWidget: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 66),
                  child: SizedBox(
                    width: SizeConfig().getWidth(190),
                    height: SizeConfig().getHeight(85),
                    child: Column(
                      children: [
                        CustomBulletPoint(
                          // bulletColor: Color(0xFF009859),
                          text: translate('home.my_notes'),
                          textColor: Colors.black,
                          countColor: Colors.black,
                          count: '15',
                          containerColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // childWidget: DefaultTextStyle(
          //   style: const TextStyle(
          //     fontSize: 10,
          //     fontWeight: FontWeight.w500,
          //     color: Colors.black,
          //   ),
          //   child: Row(
          //     children: [
          //       SizedBox(
          //         width: SizeConfig().getWidth(40),
          //         height: SizeConfig().getHeight(150),
          //         child: Image.asset(
          //           'assets/png/not_icon.png',
          //           color: const Color(0xff1A1A53),
          //           fit: BoxFit.contain,
          //         ),
          //       ),
          //       const SizedBox(width: 10),
          //       const CountWidget(
          //         count: '200',
          //         countColor: Colors.white,
          //         width: 30,
          //         containerColor: Color(0xff1A1A53),
          //       ),
          //     ],
          //   ),
          // ),
        ),
        Positioned(
          right: 6,
          top: 30,
          child: Opacity(
            opacity: 0.20,
            child: Image.asset('assets/png/notes_icon.png'),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsWidget() {
    return Stack(
      children: [
        GrayCardComponent(
          cardTitle: translate('home.projects'),
          backgroundImagePath: 'assets/png/gray_card.png',
          onClick: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => MyProject()));
          },
          childWidget: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: SizedBox(
                  width: SizeConfig().getWidth(190),
                  height: SizeConfig().getHeight(85),
                  child: Column(
                    children: [
                      CustomBulletPoint(
                        // bulletColor: Color(0xFF009859),
                        text: translate('home.In_progress'),
                        textColor: Colors.black,
                        countColor: Colors.black,
                        count: '15',
                        containerColor: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      CustomBulletPoint(
                        // bulletColor: Color(0xFFBA1719),
                        text: translate('home.Delay'),
                        textColor: Colors.black,
                        countColor: Colors.black,
                        count: '2',
                        containerColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 30,
          child: Opacity(
            opacity: .12,
            child: Image.asset('assets/newapp/my_projects.png'),
          ),
        ),
      ],
    );
  }

  Widget _buildMyRequestWidget() {
    return Stack(
      children: [
        GrayCardComponent(
          cardTitle: translate('home.my_request'),
          backgroundImagePath: 'assets/png/gray_card.png',
          onClick: () => Util.pushPage(const MyRequestsPage(), context),
          childWidget: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: SizedBox(
                  width: SizeConfig().getWidth(190),
                  height: SizeConfig().getHeight(80),
                  child: Column(
                    children: [
                      CustomBulletPoint(
                        //bulletColor: const Color(0xFF009859),
                        text: translate('home.Approved'),
                        textColor: Colors.black,
                        countColor: Colors.black,
                        containerColor: Colors.white,
                        count: '5',
                      ),
                      CustomBulletPoint(
                        // bulletColor: const Color(0xFFBA1719),
                        text: translate('home.rejected'),
                        textColor: Colors.black,
                        countColor: Colors.black,
                        containerColor: Colors.white,
                        count: '5',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: -40,
          child: Image.asset('assets/png/my_request.png'),
        ),
      ],
    );
  }

  Widget _buildMediaWidget() {
    return Stack(
      children: [
        GrayCardComponent(
          cardTitle: translate('home.media'),
          backgroundImagePath: 'assets/png/gray_card.png',
          onClick: () => Util.pushPage(const MediaListScreen(), context),
          childWidget: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: SizedBox(
                  width: SizeConfig().getWidth(190),
                  height: SizeConfig().getHeight(80),
                  child: Column(
                    children: [
                      CustomBulletPoint(
                        // bulletColor: const Color(0xFF009859),
                        text: translate('home.videos'),
                        textColor: Colors.black,
                        countColor: Colors.black,
                        count: '7', containerColor: Colors.white,
                      ),
                      CustomBulletPoint(
                        // bulletColor: const Color(0xFFBA1719),
                        text: translate('home.photos'),
                        textColor: Colors.black,
                        countColor: Colors.black,
                        count: '20',
                        containerColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 30,
          child: Opacity(
            opacity: .20,
            child: Image.asset('assets/png/icons/media_icon.png'),
          ),
        ),
      ],
    );
  }

  Widget _buildMyReportWidget() {
    return GrayCardComponent(
      mainIcon: 'assets/png/my_documents.png',
      cardTitle: translate('home.my_report'),
      backgroundImagePath: 'assets/png/notes_new_bg.png',
      onClick: () => Util.pushPage(const ReportAppHomeScreen(), context),
      topPadding: true,
      childWidget: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 61),
            child: SizedBox(
              width: SizeConfig().getWidth(190),
              height: SizeConfig().getHeight(80),
              child: Column(
                children: [
                  CustomBulletPoint(
                    // bulletColor: const Color(0xFF009859),
                    text: translate('home.No_Of_Reports'),
                    textColor: Colors.black,
                    countColor: Colors.white,
                    count: '7', containerColor: const Color(0xff1A1A53),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // childWidget: Container(
      //   width: SizeConfig().getWidth(200),
      //   height: SizeConfig().getHeight(67),
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     crossAxisAlignment: CrossAxisAlignment.center,
      //     children: [
      //       SizedBox(
      //         width: SizeConfig().getWidth(55),
      //         height: SizeConfig().getHeight(42.11),
      //         child: Image.asset('$imagePrefixIcons/id_card.png'),
      //       ),
      //       SizedBox(width: SizeConfig().getWidth(20)),
      //       SizedBox(
      //         width: SizeConfig().getWidth(55),
      //         height: SizeConfig().getHeight(44.40),
      //         child: Image.asset('$imagePrefixIcons/licnc.png'),
      //       ),
      //       SizedBox(width: SizeConfig().getWidth(20)),
      //     ],
      //   ),
      // ),
    );
  }

  Widget _buildQrCodeWidget() {
    return GrayCardComponent(
      mainIcon: 'assets/png/qr_code.png', // You'll need to add this icon
      cardTitle: 'My QR Code',
      backgroundImagePath: 'assets/png/gray_card.png',
      onClick: () => Util.pushPage(const QrCodeScreen(), context),
      topPadding: true,
      topPaddingValue: 40,
      childWidget: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: 210.w,
              ),
              child: Icon(
                Icons.qr_code_2,
                size: 140.w,
                color: Colors.deepPurple.shade600,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 66),
              child: SizedBox(
                width: SizeConfig().getWidth(190),
                height: SizeConfig().getHeight(85),
                child: Column(
                  children: [
                    CustomBulletPoint(
                      text: 'Employee Profile',
                      textColor: Colors.black,
                      countColor: Colors.black,
                      count: 'QR',
                      containerColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: !SharedPref.isUserAuthenticated() ? .5 : 1,
      child: IgnorePointer(
        ignoring: !SharedPref.isUserAuthenticated(),
        child: Column(
          children: [
            // Always show attendance widget
            BlocBuilder<HomeBloc, HomeState>(
              builder: (cxt, state) {
                var bloc = HomeBloc.get(cxt);
                return Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    GrayCardComponent(
                      cardTitle: translate('home.attendance'),
                      backgroundImagePath: 'assets/png/attendace_new_bg.png',
                      onClick: () =>
                          Util.pushPage(const AttendancePage(), context),
                      childWidget: Directionality(
                        textDirection: TextDirection.ltr,
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 80),
                            child: SizedBox(
                              width: SizeConfig().getWidth(190),
                              height: SizeConfig().getHeight(85),
                              child: Column(
                                children: [
                                  CustomBulletPoint(
                                    isAttendance: true,
                                    //bulletColor: const Color(0xFF009859),
                                    text: translate('home.attendance'),
                                    textColor: Colors.black,
                                    countColor: Colors.white,
                                    count: bloc.attendedDays.toString(),
                                    containerColor: const Color(0xff1A1A53),
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  CustomBulletPoint(
                                    isAttendance: true,
                                    // bulletColor: Color(0xFFBA1719),
                                    text: translate('home.absent'),
                                    textColor: Colors.black,
                                    countColor: Colors.white,
                                    count: '2',
                                    containerColor: const Color(0xff1A1A53),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 30.w,
                      top: 10.w,
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/png/date_attendance.png',
                            width: 20.w,
                            height: 20.w,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Text(
                            'March',
                            style: GoogleFonts.aBeeZee(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 10),

            // Show active widgets from edit widgets
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ...activeWidgets.map((widget) {
                return Column(
                  children: [
                    _buildCustomWidget(widget),
                    const SizedBox(height: 10),
                  ],
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}


// import 'package:el_race/core/utils/shared_pref.dart';
// import 'package:el_race/report_module/presentation/screens/report_listing/report_app_home_screen.dart';
// import 'package:el_race/ui/presentation/Attendace_list/attendance_page.dart';
// import 'package:el_race/ui/presentation/PettyCash/PettyCashScreen.dart';
// import 'package:el_race/ui/presentation/home_screen/widgets/card_tile.dart';

// import 'package:el_race/ui/presentation/home_screen/widgets/custom_bullet_point.dart';
// import 'package:el_race/ui/presentation/my_projects/presentation/screens/project_list_screen.dart';
// import 'package:el_race/ui/presentation/my_request/MyRequestsPage.dart';
// import 'package:el_race/ui/presentation/task_sheet/task_sheet_screen.dart';
// import 'package:el_race/utils/Util.dart';
// import 'package:el_race/utils/orientation_helper.dart';
// import 'package:el_race/utils/string_utils.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_translate/flutter_translate.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../bloc/home_bloc.dart';
// import '../../my_request/bloc/requests_bloc.dart';
// import '../../my_request/bloc/requests_state.dart';

// class ListViewWidgets extends StatelessWidget {

//   const ListViewWidgets({super.key,});

//   @override
//   Widget build(BuildContext context) {
//     return Opacity(
//       opacity: !SharedPref.isUserAuthenticated()? 0.5 : 1,
//       child: IgnorePointer(
//         ignoring: !SharedPref.isUserAuthenticated(),
//         child: Column(
//           children: [
//             BlocBuilder<HomeBloc, HomeState>(
//               builder: (cxt, state) {
//                 var bloc= HomeBloc.get(cxt);
//                 return GrayCardComponent(
//                   mainIcon: 'assets/png/icons/finger-print_icon.png',
//                   cardTitle: translate('home.attendance'),
//                   backgroundImagePath: 'assets/png/attendace_new_bg.png',
//                   onClick: () => Util.pushPage(const AttendancePage(), context),
//                   childWidget: DefaultTextStyle(
//                     style: const TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w500,
//                       color: Color(0xFF1A1A53),
//                     ),
//                     child: SizedBox(
//                       width: SizeConfig().getWidth(190),
//                       height: SizeConfig().getHeight(47),
//                       child: CustomBulletPoint(
//                         bulletColor: const Color(0xFF1A1A53),
//                         text: translate('home.your_monthly_attendance'),
//                         textColor: const Color(0xFF1A1A53),
//                         countColor: const Color(0xFFBA1719),
//                         count: bloc.attendedDays.toString(),
//                       ),
//                   ),
//                 ),);
//               },
//             ),

//             const SizedBox(
//               height: 10,
//             ),

//             GrayCardComponent(
//               onClick: () => Util.pushPage(const ComingSoonScreen(), context),
//               mainIcon: 'assets/newapp/documents.png',
//               cardTitle: translate('home.documents'),
//               backgroundImagePath: 'assets/png/timesheet_new_bg.png', // ✅ Add this
//               childWidget: DefaultTextStyle(
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w500,
//                   fontSize: 10, // Set desired font size
//                   color: Color(0xFF1A1A53), // Ensure text color contrasts the background
//                 ),
//                 child: SizedBox(
//                   width: SizeConfig().getWidth(190),
//                   height: SizeConfig().getHeight(47),
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Image.asset('assets/newapp/simple_cards.png'),
//                   ),
//                 ),
//               ),
//             ),
        
        
        
//             const SizedBox(
//               height: 10,
//             ),

//             GrayCardComponent(
//               onClick: () => Util.pushPage(const ProjectListScreen(), context),
//               mainIcon: 'assets/newapp/my_projects.png',
//               cardTitle: translate('home.projects'),
//               backgroundImagePath: 'assets/png/timesheet_new_bg.png', // ✅ Add this
//               childWidget: DefaultTextStyle(
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w500,
//                   fontSize: 10, // Set desired font size
//                   color: Color(0xFF1A1A53), // Ensure text color contrasts the background
//                 ),
//                 child: SizedBox(
//                   width: SizeConfig().getWidth(190),
//                   height: SizeConfig().getHeight(70),
//                   child: const Column(
//                     children: [
//                        CustomBulletPoint(
//                         bulletColor: Colors.yellow,
//                         text: 'HR',
//                         textColor: const Color(0xFF1A1A53),
//                         countColor: const Color(0xFF1A1A53),
//                         count: '12',
//                       ),
//                       CustomBulletPoint(
//                         bulletColor: const Color(0xFFBA1719),
//                         text: 'Purchase',
//                         textColor: const Color(0xFF1A1A53),
//                         countColor: const Color(0xFF1A1A53),
//                         count: '08',
//                       ),
//                       CustomBulletPoint(
//                         bulletColor: Colors.green,
//                         text: 'Accountant',
//                         textColor: const Color(0xFF1A1A53),
//                         countColor: const Color(0xFF1A1A53),
//                         count: '08',
//                       ),
//                     ],
//                   )
//                 ),
//               ),
//             ),
        
        
        
//             const SizedBox(
//               height: 10,
//             ),
        
//             GrayCardComponent(
//               onClick: () => Util.pushPage(const TaskSheetPage(), context),
//               mainIcon: 'assets/png/icons/timesheet_icon.png',
//               cardTitle: translate('home.time_sheet'),
//               backgroundImagePath: 'assets/png/timesheet_new_bg.png', // ✅ Add this
//               childWidget: DefaultTextStyle(
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w500,
//                   fontSize: 10, // Set desired font size
//                   color: Color(0xFF1A1A53), // Ensure text color contrasts the background
//                 ),
//                 child: SizedBox(
//                   width: SizeConfig().getWidth(190),
//                   height: SizeConfig().getHeight(47),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 8.0), // Add vertical padding
//                         child: CustomBulletPoint(
//                           bulletColor: Colors.yellow,
//                           text: translate('home.waiting_approve'),
//                           textColor: const Color(0xFF1A1A53),
//                           countColor: const Color(0xFFBA1719),
//                           count: "08",
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
        
        
        
//             const SizedBox(
//               height: 10,
//             ),
        
        
        
//             GrayCardComponent(
//               mainIcon: 'assets/png/icons/myrequest_icon.png',
//               cardTitle: translate('home.my_request'),
//               backgroundImagePath: 'assets/png/icons/my_request_new_bg.png', 
//               onClick: () => Util.pushPage(const MyRequestsPage(), context),
//               childWidget: DefaultTextStyle(
//                 style: const TextStyle(
//                   fontSize: 10, // Set desired font size
//                   fontWeight: FontWeight.w500,
//                   color: Color(0xFF1A1A53), // Ensure text color contrasts the background
//                 ),
//                 child: SizedBox(
//                   width: SizeConfig().getWidth(180),
//                   height: SizeConfig().getHeight(67),
//                   child: BlocBuilder<RequestsBloc, RequestsState>(
//                     builder: (cxt, state) {
//                       var bloc = RequestsBloc.get(cxt);
//                       return Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.only(bottom: 3.0),
//                             child: CustomBulletPoint(
//                               bulletColor: const Color(0xFF1A1A53),
//                               text: translate('home.all_request'),
//                               textColor: const Color(0xFF1A1A53),
//                               countColor: const Color(0xFFBA1719),
//                               count: bloc.getRequestsCount.toString(),
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.only(top: 3.0),
//                             child: CustomBulletPoint(
//                               bulletColor: Colors.yellow,
//                               text: translate('home.waiting_approve'),
//                               textColor: const Color(0xFF1A1A53),
//                               countColor: const Color(0xFFBA1719),
//                               count: "08",
//                             ),
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ),
        
        
//             const SizedBox(
//               height: 10,
//             ),
        
        
//             GrayCardComponent(
//               mainIcon: 'assets/png/icons/pettycash_icon.png',
//               cardTitle: translate('home.petty_cash'),
//               backgroundImagePath: 'assets/png/pettycash_new_bg.png', // ✅ Add this
//               onClick: () => Util.pushPage(const PettyCashScreen(), context),
//               childWidget: DefaultTextStyle(
//                 style: const TextStyle(
//                   fontSize: 10, // Set desired font size
//                   fontWeight: FontWeight.w500,
//                   color: Color(0xFF1A1A53), // Ensure text color contrasts the background
//                 ),
//                 child: SizedBox(
//                   width: SizeConfig().getWidth(180),
//                   height: SizeConfig().getHeight(67),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.only(bottom: 3.0), // Add padding below the first item
//                         child: CustomBulletPoint(
//                           bulletColor: const Color(0xFF1A1A53),
//                           text: translate('home.waiting_approve'),
//                           textColor: const Color(0xFF1A1A53),
//                           countColor: const Color(0xFFBA1719),
//                           count: "12",
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.only(top: 3.0), // Add padding above the second item
//                         child: CustomBulletPoint(
//                           bulletColor: Colors.yellow,
//                           text: translate('home.rejected'),
//                           textColor: const Color(0xFF1A1A53),
//                           countColor: const Color(0xFFBA1719),
//                           count: "08",
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
        
        
//             const SizedBox(
//               height: 10,
//             ),
        
        
//             GrayCardComponent(
//               mainIcon: 'assets/png/my_documents.png',
//               cardTitle: translate('home.my_report'),
//               backgroundImagePath: 'assets/png/notes_new_bg.png', // ✅ Add this
//               onClick: () => Util.pushPage(const ReportAppHomeScreen(), context),
//               childWidget: Container(
//                 width: SizeConfig().getWidth(200),
//                 height: SizeConfig().getHeight(67),
        
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     SizedBox(
//                       width: SizeConfig().getWidth(55),
//                       height: SizeConfig().getHeight(42.11),
//                       child: Image.asset('$imagePrefixIcons/id_card.png'),
//                     ),
//                     SizedBox(width: SizeConfig().getWidth(20)),
//                     SizedBox(
//                       width: SizeConfig().getWidth(55),
//                       height: SizeConfig().getHeight(44.40),
//                       child: Image.asset('$imagePrefixIcons/licnc.png'),
//                     ),
//                     SizedBox(width: SizeConfig().getWidth(20)),
//                   ],
//                 ),
//               ),
//               // itemIndex: index,
//             ),
//             const SizedBox(
//               height: 20,
//             ),
//             //
//             GrayCardComponent(
//               onClick: () => Util.pushPage(const ComingSoonScreen(), context),
//               backgroundImagePath: 'assets/png/notes_new_bg.png', // ✅ Add this
//               mainIcon: 'assets/png/my_notes.png',
//               cardTitle: 'MY NOTES',
//               childWidget: DefaultTextStyle(
//                 style: const TextStyle(
//                   fontSize: 10, // Set desired font size
//                   fontWeight: FontWeight.w500,
//                   color: Color(0xFF1A1A53), // Ensure text color contrasts the background
//                 ),
//                 child: SizedBox(
//                   width: SizeConfig().getWidth(100),
//                   height: SizeConfig().getHeight(67),
//                   child: const Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       CustomBulletPoint(
//                         bulletColor: Color(0xFF1A1A53),
//                         text: 'Saved',
//                         textColor: Color(0xFF1A1A53),
//                         countColor: Color(0xFFBA1719),
//                         count: "12",
//                       ),
//                       CustomBulletPoint(
//                         bulletColor: Color(0xFFBA1719),
//                         text: 'Draft ',
//                         textColor: Color(0xFF1A1A53),
//                         countColor: Color(0xFFBA1719),
//                         count: "08",
//                       ),
//                     ],
//                   ),
//                 ),
//               ), 
//             ),
        
//             const SizedBox(
//               height: 10,
//             ),
        
//           ],
//         ),
//       ),
//     );
//   }
// }