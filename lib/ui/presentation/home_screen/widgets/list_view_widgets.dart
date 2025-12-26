import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/report_module/presentation/screens/report_listing/report_app_home_screen.dart';
import 'package:el_race/ui/presentation/Attendace_list/attendance_page.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashScreen.dart';
import 'package:el_race/ui/presentation/home_screen/data/widget_model.dart';
import 'package:el_race/ui/presentation/home_screen/services/widget_service.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/card_tile.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/custom_bullet_point.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/tilting_card.dart';
import 'package:el_race/ui/presentation/lpo/screens/lpo_screen.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/parayer_widgets/parayer_widget.dart';
import 'package:el_race/ui/presentation/media/screens/media_list_screen.dart';
import 'package:el_race/ui/presentation/my_documents/screens/my_documents_screen.dart';
import 'package:el_race/ui/presentation/my_notes/screens/my_notes_screen.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/screens/my_project.dart';
import 'package:el_race/ui/presentation/my_request/MyRequestsPage.dart';
import 'package:el_race/ui/presentation/task_sheet/task_sheet_screen.dart';
import 'package:el_race/ui/presentation/todo_list/providers/todo_provider.dart';
import 'package:el_race/ui/presentation/todo_list/screens/todo_list_screen.dart';
import 'package:el_race/utils/custom_navigate.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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

  void _reorderWidgets(int oldIndex, int newIndex) {
    // Provide strong haptic feedback for reordering
    HapticFeedback.mediumImpact();

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final widget = activeWidgets.removeAt(oldIndex);
      activeWidgets.insert(newIndex, widget);
      // حفظ الترتيب الجديد
      WidgetService.saveActiveWidgets(activeWidgets);
    });
    // Stronger confirmation vibration if available
    _vibrateConfirm();
  }

  void _vibrateConfirm() async {
    try {
      // Use strong haptic impact as confirmation
      HapticFeedback.heavyImpact();
    } catch (_) {
      HapticFeedback.vibrate();
    }
  }

  void _vibrateEnterReorder() async {
    try {
      // Stronger pulse when entering reorder mode
      HapticFeedback.heavyImpact();
    } catch (_) {
      HapticFeedback.vibrate();
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
      case 'todo_list':
        return _buildTodoListWidget();
      case 'projects':
        return _buildProjectsWidget();
      case 'my_request':
        return _buildMyRequestWidget();
      case 'media':
        return _buildMediaWidget();
      case 'my_report':
        return _buildMyReportWidget();
      case 'attendance':
        return _buildAttendanceWidget();
      case 'prayer':
        return const ParayerWidget();
      // QR widget removed from home screen - only available in sidebar
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTimeSheetWidget() {
    final loginData = SharedPref.getLoginData();
    final widgetData = loginData.result?.data?.defaultWidgets?.data;
    final timesheetCount =
        widgetData?['timesheet_widget']?['record_to_show']?.toString() ?? '0';

    return GrayCardComponent(
        onClick: () => Util.pushPage(const TaskSheetPage(), context),
        mainIcon: 'assets/png/time_sheet.png',
        cardTitle: translate('home.time_sheet'),
        backgroundImagePath: 'assets/png/gray_card.png',
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
                        text: translate('home.No_of_Labors'),
                        textColor: Colors.black,
                        countColor: Colors.black,
                        count: timesheetCount,
                        containerColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
        ));
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
    final loginData = SharedPref.getLoginData();
    final widgetData = loginData.result?.data?.defaultWidgets?.data;
    final lpoTotal =
        widgetData?['lpo_widget']?['record_to_show']?['total']?.toString() ??
            '0';

    return GrayCardComponent(
      onClick: () => Util.pushPage(const LpoListScreen(), context),
      mainIcon: 'assets/png/time_sheet.png',
      cardTitle: translate('home.lpo'),
      backgroundImagePath: 'assets/png/gray_card.png',
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
                      text: translate('home.No_of_LPO'),
                      textColor: Colors.black,
                      countColor: Colors.black,
                      count: lpoTotal,
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
    final loginData = SharedPref.getLoginData();
    final widgetData = loginData.result?.data?.defaultWidgets?.data;
    final docsCount =
        widgetData?['my_documents_widget']?['record_to_show']?.toString() ??
            '0';

    return Stack(
      children: [
        GrayCardComponent(
          onClick: () => Util.pushPage(const MyDocumentsScreen(), context),
          cardTitle: translate('home.documents'),
          backgroundImagePath: 'assets/png/gray_card.png',
          childWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 50.h),
                child: SizedBox(
                  width: SizeConfig()
                      .getWidth(MediaQuery.of(context).size.width - 100),
                  height: SizeConfig().getHeight(50),
                  child: Center(
                      child: Image.asset('assets/newapp/simple_cards.png')),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 6.w,
          top: 30.h,
          child: Image.asset('assets/png/icons/doc_icon.png'),
        ),
        Positioned(
          right: 10.w,
          top: 10.w,
          child: CountWidget(
            count: docsCount,
            countColor: Colors.black,
            containerColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMyNotesWidget() {
    final loginData = SharedPref.getLoginData();
    final widgetData = loginData.result?.data?.defaultWidgets?.data;
    final notesData = widgetData?['my_notes_widget']?['record_to_show'];
    final totalNotes =
        ((notesData?['saved_count'] ?? 0) + (notesData?['draft_count'] ?? 0))
            .toString();

    return Stack(
      children: [
        GrayCardComponent(
          cardTitle: translate('home.my_notes'),
          backgroundImagePath: 'assets/png/blue_card.png',
          onClick: () => Navigator.push(
            context,
            SlideRightPageRoute(child: const MyNotesScreen()),
          ),
          childWidget: const SizedBox.shrink(),
        ),
        Positioned(
          right: 6.w,
          top: 30.h,
          child: Opacity(
            opacity: 0.20,
            child: Image.asset('assets/png/notes_icon.png'),
          ),
        ),
        Positioned(
          right: 10.w,
          top: 10.w,
          child: CountWidget(
            count: totalNotes,
            countColor: Colors.black,
            containerColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTodoListWidget() {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final todoCount = todoProvider.totalCount.toString();
        return Stack(
          children: [
            GrayCardComponent(
              cardTitle: translate('home.todo_list'),
              backgroundImagePath: 'assets/png/blue_card.png',
              onClick: () => Util.pushPage(const TodoListScreen(), context),
              childWidget: const SizedBox.shrink(),
            ),
            Positioned(
              right: 6.w,
              top: 30.h,
              child: Opacity(
                opacity: 0.20,
                child: Image.asset(
                  'assets/png/notes_icon.png',
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.check_box_outlined,
                    size: 80.w,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10.w,
              top: 10.w,
              child: CountWidget(
                count: todoCount,
                countColor: Colors.black,
                containerColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProjectsWidget() {
    final loginData = SharedPref.getLoginData();
    final widgetData = loginData.result?.data?.defaultWidgets?.data;
    final projectsData = widgetData?['my_projects_widget']?['record_to_show'];
    final totalProjects = projectsData?['total_projects']?.toString() ?? '0';
    final delayedProjects =
        projectsData?['delayed_projects']?.toString() ?? '0';

    return GrayCardComponent(
      cardTitle: translate('home.projects'),
      backgroundImagePath: 'assets/newapp/projects_background.png',
      onClick: () => Util.pushPage(const MyProject(), context),
      childWidget: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 80.h),
            child: SizedBox(
              width: SizeConfig().getWidth(190),
              height: SizeConfig().getHeight(85),
              child: Column(
                children: [
                  CustomBulletPoint(
                    text: translate('home.In_progress'),
                    textColor: Colors.black,
                    countColor: Colors.black,
                    count: totalProjects,
                    containerColor: Colors.white,
                  ),
                  SizedBox(height: 4.h),
                  CustomBulletPoint(
                    text: translate('home.Delay'),
                    textColor: Colors.black,
                    countColor: Colors.black,
                    count: delayedProjects,
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
    final loginData = SharedPref.getLoginData();
    final widgetData = loginData.result?.data?.defaultWidgets?.data;
    final requestData = widgetData?['my_request_widget']?['record_to_show'];
    final totalRequests =
        requestData?['total_requests_count']?.toString() ?? '0';
    final waitingApproval =
        requestData?['waiting_for_approval_count']?.toString() ?? '0';

    return GrayCardComponent(
      cardTitle: translate('home.my_request'),
      backgroundImagePath: 'assets/newapp/requests_background.png',
      onClick: () => Util.pushPage(const MyRequestsPage(), context),
      childWidget: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 80.h),
            child: SizedBox(
              width: SizeConfig().getWidth(190),
              height: SizeConfig().getHeight(80),
              child: Column(
                children: [
                  CustomBulletPoint(
                    text: translate('home.total'),
                    textColor: Colors.black,
                    countColor: Colors.black,
                    containerColor: Colors.white,
                    count: totalRequests,
                  ),
                  CustomBulletPoint(
                    text: translate('home.waiting'),
                    textColor: Colors.black,
                    countColor: Colors.black,
                    containerColor: Colors.white,
                    count: waitingApproval,
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
    final loginData = SharedPref.getLoginData();
    final widgetData = loginData.result?.data?.defaultWidgets?.data;
    final mediaData = widgetData?['media_widget']?['record_to_show'];
    final mediaCount = mediaData?['media_count']?.toString() ?? '0';
    final filesCount = mediaData?['files']?.toString() ?? '0';

    return GrayCardComponent(
      cardTitle: translate('home.media'),
      backgroundImagePath: 'assets/newapp/media_background.png',
      onClick: () => Util.pushPage(const MediaListScreen(), context),
      childWidget: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 80.h),
            child: SizedBox(
              width: SizeConfig().getWidth(190),
              height: SizeConfig().getHeight(80),
              child: Column(
                children: [
                  CustomBulletPoint(
                    text: translate('home.videos'),
                    textColor: Colors.black,
                    countColor: Colors.black,
                    count: mediaCount,
                    containerColor: Colors.white,
                  ),
                  CustomBulletPoint(
                    text: translate('home.photos'),
                    textColor: Colors.black,
                    countColor: Colors.black,
                    count: filesCount,
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
    final loginData = SharedPref.getLoginData();
    final widgetData = loginData.result?.data?.defaultWidgets?.data;
    final reportsCount =
        widgetData?['my_reports_widget']?['record_to_show']?.toString() ?? '0';

    return GrayCardComponent(
      mainIcon: 'assets/png/my_documents.png',
      cardTitle: translate('home.my_report'),
      backgroundImagePath: 'assets/newapp/reports_background.png',
      onClick: () => Util.pushPage(const ReportAppHomeScreen(), context),
      topPadding: true,
      childWidget: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 85.h),
            child: SizedBox(
              child: Column(
                children: [
                  CustomBulletPoint(
                    text: translate('home.No_Of_Reports'),
                    textColor: Colors.black,
                    countColor: Colors.white,
                    count: reportsCount,
                    containerColor: const Color(0xff1A1A53),
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
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: 80.h),
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
                          SizedBox(
                            height: 4.h,
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
    final bloc = HomeBloc.get(context);

    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (previous, current) => current is ReorderModeChanged,
      builder: (context, state) {
        return Opacity(
          opacity: !SharedPref.isUserAuthenticated() ? .5 : 1,
          child: IgnorePointer(
            ignoring: !SharedPref.isUserAuthenticated(),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Show active widgets from edit widgets
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (bloc.isReorderMode)
                  // عرض ReorderableListView عند تفعيل وضع إعادة الترتيب
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeWidgets.length,
                    onReorder: _reorderWidgets,
                    proxyDecorator: (child, index, animation) {
                      // Custom decorator to remove white frame and improve visual feedback
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final double elevation = Tween<double>(
                            begin: 0.0,
                            end: 8.0,
                          ).evaluate(animation);
                          final double scale = Tween<double>(
                            begin: 1.0,
                            end: 1.05,
                          ).evaluate(animation);

                          return Transform.scale(
                            scale: scale,
                            child: Material(
                              elevation: elevation + 6,
                              color: Colors.transparent,
                              shadowColor: Colors.black.withOpacity(0.35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final widget = activeWidgets[index];
                      return TiltingCard(
                        key: ValueKey(widget.id),
                        child: Column(
                          children: [
                            _buildCustomWidget(widget),
                            const SizedBox(height: 10),
                          ],
                        ),
                      );
                    },
                  )
                else
                  // عرض ListView العادي مع إمكانية Long Press
                  ...activeWidgets.map((widget) {
                    return InkWell(
                      onLongPress: () {
                        // Provide strong haptic feedback when entering reorder mode
                        _vibrateEnterReorder();
                        // تفعيل وضع إعادة الترتيب عند الضغط الطويل
                        bloc.add(const ToggleReorderModeEvent());
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      child: Column(
                        children: [
                          _buildCustomWidget(widget),
                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  }).toList(),

                // زر إغلاق وضع إعادة الترتيب
                if (bloc.isReorderMode)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        bloc.add(const ToggleReorderModeEvent());
                      },
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        translate('common.close'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
