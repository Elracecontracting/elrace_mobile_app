import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/report_module/presentation/screens/report_listing/report_app_home_screen.dart';
import 'package:el_race/ui/presentation/Attendace_list/attendance_page.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashList.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashScreen.dart';
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
  DateTime now = DateTime.now();
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
      // QR widget removed from home screen - only available in sidebar
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
                left: 190.w,
              ),
              child: Image.asset(
                'assets/png/time_sheet.png',
                width: SizeConfig().getWidth(140),
                height: SizeConfig().getHeight(130),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 100.h),
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
      child: GrayCardComponent(
        onClick: () => Util.pushPage(const PettyCashScreen(), context),
        cardTitle: translate('home.petty_cash'),
        backgroundImagePath: 'assets/newapp/petty_cash_background.png',
        childWidget: const SizedBox.shrink(),
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
              padding: EdgeInsets.only(top: 80.h),
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
          onClick: () => Util.pushPage(const MyDocumentsScreen(), context),
          cardTitle: translate('home.documents'),
          backgroundImagePath: 'assets/png/gray_card.png',
          // childWidget: const SizedBox.shrink(),
          childWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 90.w),
                child: SizedBox(
                  width: SizeConfig()
                      .getWidth(MediaQuery.of(context).size.width - 50),
                  height: SizeConfig().getHeight(50),
                  child: Center(
                      child: Image.asset('assets/newapp/simple_cards.png')),
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
        Positioned(
          right: 10.w,
          top: 10.w,
          child: const CountWidget(
            count: '2',
            countColor: Colors.black,
            containerColor: Colors.white,
          ),
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
          childWidget: const SizedBox.shrink(),
        ),
        Positioned(
          right: 6,
          top: 30,
          child: Opacity(
            opacity: 0.20,
            child: Image.asset('assets/png/notes_icon.png'),
          ),
        ),
        Positioned(
          right: 10.w,
          top: 10.w,
          child: const CountWidget(
            count: '2',
            countColor: Colors.black,
            containerColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsWidget() {
    return GrayCardComponent(
      cardTitle: translate('home.projects'),
      backgroundImagePath: 'assets/newapp/projects_background.png',
      onClick: () => Util.pushPage(const MyProject(), context),
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
    );
  }

  Widget _buildMyRequestWidget() {
    return GrayCardComponent(
      cardTitle: translate('home.my_request'),
      backgroundImagePath: 'assets/newapp/requests_background.png',
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
    );
  }

  Widget _buildMediaWidget() {
    return GrayCardComponent(
      cardTitle: translate('home.media'),
      backgroundImagePath: 'assets/newapp/media_background.png',
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
    );
  }

  Widget _buildMyReportWidget() {
    return GrayCardComponent(
      mainIcon: 'assets/png/my_documents.png',
      cardTitle: translate('home.my_report'),
      backgroundImagePath: 'assets/newapp/reports_background.png',
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
            padding: EdgeInsets.only(top: 85.h),
            child: SizedBox(
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

  Widget _buildAttendanceWidget() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (cxt, state) {
        var bloc = HomeBloc.get(cxt);
        return Stack(
          alignment: Alignment.centerRight,
          children: [
            GrayCardComponent(
              cardTitle: translate('home.attendance'),
              backgroundImagePath: 'assets/png/attendace_new_bg.png',
              onClick: () => Util.pushPage(const AttendancePage(), context),
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
                      // width: SizeConfig().getWidth(190),
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
                    width: 2,
                  ),
                  Text(
                    '${bloc.monthName}',
                    style: GoogleFonts.aBeeZee(
                      color: Colors.white,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
            _buildAttendanceWidget(),

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
