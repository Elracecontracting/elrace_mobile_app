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
import 'package:el_race/ui/presentation/tasks/logic/tasks_provider.dart';
import 'package:el_race/ui/presentation/tasks_dashboard/screens/tasks_dashboard_screen.dart';
import 'package:el_race/utils/custom_navigate.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'dart:ui';
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
        // Filter out my_notes widget
        activeWidgets = widgets
            .where((w) => w.id != 'my_notes')
            .toList();
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
    final bloc = HomeBloc.get(context);
    final isReorderMode = bloc.isReorderMode;

    switch (widget.id) {
      case 'time_sheet':
        return _buildTimeSheetWidget(isReorderMode: isReorderMode);
      case 'petty_cash':
        return _buildPettyCashWidget(isReorderMode: isReorderMode);
      case 'lpo':
        return _buildLPOWidget(isReorderMode: isReorderMode);
      case 'documents':
        return _buildDocumentsWidget(isReorderMode: isReorderMode);
      case 'my_notes':
        return _buildMyNotesWidget(isReorderMode: isReorderMode);
      case 'todo_list':
        return _buildTodoListWidget(isReorderMode: isReorderMode);
      case 'projects':
        return _buildProjectsWidget(isReorderMode: isReorderMode);
      case 'my_request':
        return _buildMyRequestWidget(isReorderMode: isReorderMode);
      case 'media':
        return _buildMediaWidget(isReorderMode: isReorderMode);
      case 'my_report':
        return _buildMyReportWidget(isReorderMode: isReorderMode);
      case 'attendance':
        return _buildAttendanceWidget(isReorderMode: isReorderMode);
      case 'prayer':
        return const ParayerWidget();
      // QR widget removed from home screen - only available in sidebar
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTimeSheetWidget({bool isReorderMode = false}) {
    final loginData = SharedPref.getLoginData();
    final widgetData = loginData.result?.data?.defaultWidgets?.data;
    final timesheetCount =
        widgetData?['timesheet_widget']?['record_to_show']?.toString() ?? '0';

    return Stack(
      children: [
        GrayCardComponent(
          onClick: isReorderMode ? null : () => Util.pushPage(const TaskSheetPage(), context),
          cardTitle: 'Timesheet',
          upperCaseTitle: false,
          backgroundImagePath: 'assets/png/t-sheet.png',
          childWidget: const SizedBox.shrink(),
        ),
        Positioned(
          left: 16.w,
          bottom: 12.h,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Image.asset(
                'assets/png/time-sheet-icon.png',
                width: 44.w,
                height: 44.w,
              ),
              SizedBox(width: 6.w),
              Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Text(
                  timesheetCount,
                  style: GoogleFonts.koulen(
                    color: Colors.black,
                    fontSize: 22.w,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPettyCashWidget({bool isReorderMode = false}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23.r),
        child: Stack(
          children: [
            GrayCardComponent(
              onClick: isReorderMode ? null : () => Util.pushPage(const PettyCashScreen(), context),
              cardTitle: translate('home.petty_cash'),
              titleColor: Colors.white,
              backgroundImagePath:
                  'assets/newapp/petty_cach_widget_background.png',
              childWidget: const SizedBox.shrink(),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Transform.translate(
                    offset: Offset(-12.w, 30.h),
                    child: Opacity(
                      opacity: 0.28,
                      child: Image.asset(
                        'assets/newapp/d_for_petty_Cach.png',
                        height: 30.h,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLPOWidget({bool isReorderMode = false}) {
    final loginData = SharedPref.getLoginData();
    final widgetData = loginData.result?.data?.defaultWidgets?.data;
    final lpoTotal =
        widgetData?['lpo_widget']?['record_to_show']?['total']?.toString() ??
            '0';

    return GrayCardComponent(
      onClick: isReorderMode ? null : () => Util.pushPage(const LpoListScreen(), context),
      cardTitle: translate('home.lpo'),
      titleColor: Colors.white,
      backgroundImagePath: 'assets/newapp/Lpo_background_widget.png',
      topPadding: true,
      childWidget: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: SizeConfig().getWidth(190),
          height: SizeConfig().getHeight(115),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  translate('home.lpo').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16.w),
                Text(
                  lpoTotal,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildDocumentsWidget({bool isReorderMode = false}) {
    final loginData = SharedPref.getLoginData();
    final widgetData = loginData.result?.data?.defaultWidgets?.data;
    final docsCount =
        widgetData?['my_documents_widget']?['record_to_show']?.toString() ??
            '0';

    return Stack(
      children: [
        GrayCardComponent(
          onClick: isReorderMode ? null : () => Util.pushPage(const MyDocumentsScreen(), context),
          cardTitle: translate('home.documents'),
          titleColor: Colors.white,
          backgroundImagePath:
              'assets/newapp/my_document_widet_background_new.png',
          childWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 40.h),
                child: const SizedBox(),
              ),
            ],
          ),
        ),
        Positioned(
          right: 10.w,
          top: 10.w,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: 30.w,
                height: 30.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.26),
                      Colors.white.withOpacity(0.08),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  docsCount.toUpperCase(),
                  style: GoogleFonts.koulen(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.09,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyNotesWidget({bool isReorderMode = false}) {
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
          onClick: isReorderMode ? null : () => Navigator.push(
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

  Widget _buildTodoListWidget({bool isReorderMode = false}) {
    return Consumer<TasksProvider>(
      builder: (context, tasksProvider, child) {
        if (tasksProvider.status == TasksStatus.initial) {
          Future.microtask(() => tasksProvider.loadTasks());
        }

        final isLoading = tasksProvider.status == TasksStatus.loading ||
            tasksProvider.status == TasksStatus.initial;
        final hasError = tasksProvider.status == TasksStatus.error;
        final todoCount = hasError
            ? '!'
            : isLoading
                ? '...'
                : tasksProvider.tasks.length.toString();

        return Stack(
          children: [
            GrayCardComponent(
              cardTitle: "Task Managment",
              titleColor: Colors.white,
              backgroundImagePath:
                  'assets/newapp/task_managment_widget_backdround.png',
              onClick: isReorderMode ? null : () {
                if (hasError) {
                  // Show error message in a snackbar when tapped
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          tasksProvider.errorMessage ?? 'Failed to load tasks'),
                      action: SnackBarAction(
                        label: 'Retry',
                        onPressed: () => tasksProvider.loadTasks(),
                      ),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                } else {
                  // Navigate to new Tasks Dashboard
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TasksDashboardScreen(),
                    ),
                  );
                }
              },
              childWidget: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : hasError
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.white.withOpacity(0.5),
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to retry',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
            /*
            Positioned(
              right: 10.w,
              top: 10.w,
              child: CountWidget(
                count: todoCount,
                countColor: Colors.black,
                containerColor: hasError ? Colors.red.shade100 : Colors.white,
              ),
            ),
            */
          ],
        );
      },
    );
  }

  Widget _buildProjectsWidget({bool isReorderMode = false}) {
    final loginData = SharedPref.getLoginData();
    final widgetData = loginData.result?.data?.defaultWidgets?.data;
    final projectsData = widgetData?['my_projects_widget']?['record_to_show'];
    final totalProjects = projectsData?['total_projects']?.toString() ?? '0';
    final delayedProjects =
        projectsData?['delayed_projects']?.toString() ?? '0';

    return ClipRRect(
      borderRadius: BorderRadius.circular(23.r),
      child: Stack(
        children: [
          GrayCardComponent(
            cardTitle: translate('home.projects'),
            backgroundImagePath: 'assets/newapp/blue_widget_background.png',
            onClick: isReorderMode ? null : () => Util.pushPage(const MyProject(), context),
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
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.centerRight,
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Transform.translate(
                      offset: Offset(50.w, 40.h),
                      child: Opacity(
                        opacity: 0.16,
                        child: Image.asset(
                          'assets/newapp/Ellipse 106.png',
                          height: 260.h,
                          fit: BoxFit.contain,
                          color: const Color(0xFF9ED3FF),
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(10.w, 5.h),
                      child: Opacity(
                        opacity: 0.16,
                        child: Image.asset(
                          'assets/newapp/Ellipse 105.png',
                          height: 230.h,
                          fit: BoxFit.contain,
                          color: const Color(0xFF9ED3FF),
                          colorBlendMode: BlendMode.srcIn,
                        ),
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

  Widget _buildMyRequestWidget({bool isReorderMode = false}) {
    final loginData = SharedPref.getLoginData();
    final widgetData = loginData.result?.data?.defaultWidgets?.data;
    final requestData = widgetData?['my_request_widget']?['record_to_show'];
    final totalRequests =
        requestData?['total_requests_count']?.toString() ?? '0';
    final waitingApproval =
        requestData?['waiting_for_approval_count']?.toString() ?? '0';

    return ClipRRect(
      borderRadius: BorderRadius.circular(23.r),
      child: Stack(
        children: [
          GrayCardComponent(
            cardTitle: translate('home.my_request'),
            backgroundImagePath: 'assets/newapp/blue_widget_background.png',
            onClick: isReorderMode ? null : () => Util.pushPage(const MyRequestsPage(), context),
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
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.centerRight,
                child: Opacity(
                  opacity: 0.16,
                  child: Image.asset(
                    'assets/newapp/R.png',
                    height: 220.h,
                    fit: BoxFit.contain,
                    color: const Color(0xFF9ED3FF),
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaWidget({bool isReorderMode = false}) {
    final loginData = SharedPref.getLoginData();
    final widgetData = loginData.result?.data?.defaultWidgets?.data;
    final mediaData = widgetData?['media_widget']?['record_to_show'];
    final mediaCount = mediaData?['media_count']?.toString() ?? '0';
    // final filesCount = mediaData?['files']?.toString() ?? '0';

    return Stack(
      children: [
        GrayCardComponent(
          // Keep base component untouched; hide its title for this card only.
          cardTitle: '',
          backgroundImagePath: 'assets/newapp/media_widget_background.png',
          onClick: isReorderMode ? null : () => Util.pushPage(const MediaListScreen(), context),
          childWidget: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              child: Padding(
                padding: EdgeInsets.only(top: 80.h),
                child: SizedBox(
                  width: SizeConfig().getWidth(190),
                  height: SizeConfig().getHeight(80),
                  child: const Column(
                    children: [
                      /*
                      CustomBulletPoint(
                        text: translate('home.videos'),
                        textColor: Colors.black,
                        countColor: Colors.black,
                        count: mediaCount,
                        containerColor: Colors.white,
                      ),
                      */
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 36.w,
          top: 16,
          child: Text(
            translate('home.media').toUpperCase(),
            style: GoogleFonts.koulen(
              color: Colors.white,
              fontSize: 24.w,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.9,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyReportWidget({bool isReorderMode = false}) {
    final loginData = SharedPref.getLoginData();
    final widgetData = loginData.result?.data?.defaultWidgets?.data;
    final reportsCount =
        widgetData?['my_reports_widget']?['record_to_show']?.toString() ?? '0';

    return GrayCardComponent(
      mainIcon: 'assets/png/my_documents.png',
      cardTitle: translate('home.my_report'),
      titleColor: Colors.white,
      backgroundImagePath: 'assets/newapp/my_report_widget_background.png',
      onClick: isReorderMode ? null : () => Util.pushPage(const ReportAppHomeScreen(), context),
      topPadding: true,
      childWidget: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 85.h),
            child: SizedBox(
              child: Column(
                children: [
                  CustomBulletPoint(
                    text: translate('home.No_Of_Reports'),
                    textColor: Colors.white,
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

  Widget _buildAttendanceWidget({bool isReorderMode = false}) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (cxt, state) {
        var bloc = HomeBloc.get(cxt);
        final monthAbbrev = bloc.monthName.length >= 3
            ? bloc.monthName.substring(0, 3).toUpperCase()
            : bloc.monthName.toUpperCase();

        return ClipRRect(
          borderRadius: BorderRadius.circular(23.r),
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              GrayCardComponent(
                cardTitle: translate('home.attendance'),
                backgroundImagePath: 'assets/newapp/blue_widget_background.png',
                onClick: isReorderMode ? null : () => Util.pushPage(const AttendancePage(), context),
                childWidget: const SizedBox.shrink(),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Opacity(
                      opacity: 1,
                      child: Image(
                        image: AssetImage(
                          'assets/newapp/finger-print_svgrepo.com.png',
                        ),
                        fit: BoxFit.contain,
                        color: Color(0xFFFFFFFF),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12.w,
                top: 10.h,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.26),
                            Colors.white.withOpacity(0.08),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 16.sp,
                            color: const Color(0xFF151544),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            monthAbbrev,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF151544),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
                      }),

                // إضافة مساحة إضافية في الأسفل عندما يكون في وضع التعديل
                if (bloc.isReorderMode) SizedBox(height: 100.h),
              ],
            ),
          ),
        );
      },
    );
  }
}
