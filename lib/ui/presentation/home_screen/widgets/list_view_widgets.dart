import 'package:el_race/report_module/presentation/screens/report_listing/report_app_home_screen.dart';
import 'package:el_race/ui/presentation/Attendace_list/attendance_page.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashScreen.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/card_tile.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/custom_bullet_point.dart';
import 'package:el_race/ui/presentation/my_request/MyRequestsPage.dart';
import 'package:el_race/ui/presentation/task_sheet/task_sheet_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:el_race/utils/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../../my_request/bloc/requests_bloc.dart';
import '../../my_request/bloc/requests_state.dart';

class ListViewWidgets extends StatelessWidget {

  const ListViewWidgets({super.key,});

  @override
  Widget build(BuildContext context) {
    // Fetch requests count (if you want to trigger it here)
    return Column(
      children: [
        BlocBuilder<HomeBloc, HomeState>(
          builder: (cxt, state) {
            var bloc= HomeBloc.get(cxt);
            return GrayCardComponent(
              mainIcon: 'assets/png/icons/finger-print_icon.png',
              cardTitle: translate('home.attendance'),
              backgroundImagePath: 'assets/png/attendace_new_bg.png',
              onClick: () => Util.pushPage(const AttendancePage(), context),
              childWidget: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A53),
                ),
                child: SizedBox(
                  width: SizeConfig().getWidth(190),
                  height: SizeConfig().getHeight(47),
                  child: CustomBulletPoint(
                    bulletColor: const Color(0xFF1A1A53),
                    text: translate('home.your_monthly_attendance'),
                    textColor: const Color(0xFF1A1A53),
                    countColor: const Color(0xFFBA1719),
                    count: bloc.attendedDays.toString(),
                  ),
              ),
            ),);
          },
        ),



        const SizedBox(
          height: 10,
        ),

        GrayCardComponent(
          onClick: () => Util.pushPage(const TaskSheetPage(), context),
          mainIcon: 'assets/png/icons/timesheet_icon.png',
          cardTitle: translate('home.time_sheet'),
          backgroundImagePath: 'assets/png/timesheet_new_bg.png', // ✅ Add this
          childWidget: DefaultTextStyle(
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 10, // Set desired font size
              color: Color(0xFF1A1A53), // Ensure text color contrasts the background
            ),
            child: SizedBox(
              width: SizeConfig().getWidth(190),
              height: SizeConfig().getHeight(47),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0), // Add vertical padding
                    child: CustomBulletPoint(
                      bulletColor: Colors.yellow,
                      text: translate('home.waiting_approve'),
                      textColor: const Color(0xFF1A1A53),
                      countColor: const Color(0xFFBA1719),
                      count: "08",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),



        const SizedBox(
          height: 10,
        ),



        GrayCardComponent(
          mainIcon: 'assets/png/icons/myrequest_icon.png',
          cardTitle: translate('home.my_request'),
          backgroundImagePath: 'assets/png/icons/my_request_new_bg.png', 
          onClick: () => Util.pushPage(const MyRequestsPage(), context),
          childWidget: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 10, // Set desired font size
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A53), // Ensure text color contrasts the background
            ),
            child: SizedBox(
              width: SizeConfig().getWidth(180),
              height: SizeConfig().getHeight(67),
              child: BlocBuilder<RequestsBloc, RequestsState>(
                builder: (cxt, state) {
                  var bloc = RequestsBloc.get(cxt);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3.0),
                        child: CustomBulletPoint(
                          bulletColor: const Color(0xFF1A1A53),
                          text: translate('home.all_request'),
                          textColor: const Color(0xFF1A1A53),
                          countColor: const Color(0xFFBA1719),
                          count: bloc.getRequestsCount.toString(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 3.0),
                        child: CustomBulletPoint(
                          bulletColor: Colors.yellow,
                          text: translate('home.waiting_approve'),
                          textColor: const Color(0xFF1A1A53),
                          countColor: const Color(0xFFBA1719),
                          count: "08",
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),


        const SizedBox(
          height: 10,
        ),


        GrayCardComponent(
          mainIcon: 'assets/png/icons/pettycash_icon.png',
          cardTitle: translate('home.petty_cash'),
          backgroundImagePath: 'assets/png/pettycash_new_bg.png', // ✅ Add this
          onClick: () => Util.pushPage(const PettyCashScreen(), context),
          childWidget: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 10, // Set desired font size
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A53), // Ensure text color contrasts the background
            ),
            child: SizedBox(
              width: SizeConfig().getWidth(180),
              height: SizeConfig().getHeight(67),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3.0), // Add padding below the first item
                    child: CustomBulletPoint(
                      bulletColor: const Color(0xFF1A1A53),
                      text: translate('home.waiting_approve'),
                      textColor: const Color(0xFF1A1A53),
                      countColor: const Color(0xFFBA1719),
                      count: "12",
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 3.0), // Add padding above the second item
                    child: CustomBulletPoint(
                      bulletColor: Colors.yellow,
                      text: translate('home.rejected'),
                      textColor: const Color(0xFF1A1A53),
                      countColor: const Color(0xFFBA1719),
                      count: "08",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),


        const SizedBox(
          height: 10,
        ),


        GrayCardComponent(
          mainIcon: 'assets/png/my_documents.png',
          cardTitle: translate('home.my_report'),
          backgroundImagePath: 'assets/png/notes_new_bg.png', // ✅ Add this
          onClick: () => Util.pushPage(const ReportAppHomeScreen(), context),
          childWidget: Container(
            width: SizeConfig().getWidth(200),
            height: SizeConfig().getHeight(67),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: SizeConfig().getWidth(55),
                  height: SizeConfig().getHeight(42.11),
                  child: Image.asset('$imagePrefixIcons/id_card.png'),
                ),
                SizedBox(width: SizeConfig().getWidth(20)),
                SizedBox(
                  width: SizeConfig().getWidth(55),
                  height: SizeConfig().getHeight(44.40),
                  child: Image.asset('$imagePrefixIcons/licnc.png'),
                ),
                SizedBox(width: SizeConfig().getWidth(20)),
              ],
            ),
          ),
          // itemIndex: index,
        ),
        const SizedBox(
          height: 20,
        ),
        //
        // GrayCardComponent(
        //   mainIcon: 'assets/png/my_notes.png',
        //   cardTitle: 'MY NOTES',
        //   isGrayCard: false,
        //   childWidget: DefaultTextStyle(
        //     style: const TextStyle(
        //       fontSize: 10, // Set desired font size
        //       fontWeight: FontWeight.w500,
        //       color: Color(0xFF1A1A53), // Ensure text color contrasts the background
        //     ),
        //     child: SizedBox(
        //       width: SizeConfig().getWidth(100),
        //       height: SizeConfig().getHeight(67),
        //       child: Column(
        //         mainAxisAlignment: MainAxisAlignment.center,
        //         children: const [
        //           CustomBulletPoint(
        //             bulletColor: Color(0xFF1A1A53),
        //             text: 'Saved',
        //             textColor: Color(0xFF1A1A53),
        //             countColor: Color(0xFFBA1719),
        //             count: "12",
        //           ),
        //           CustomBulletPoint(
        //             bulletColor: Color(0xFFBA1719),
        //             text: 'Draft ',
        //             textColor: Color(0xFF1A1A53),
        //             countColor: Color(0xFFBA1719),
        //             count: "08",
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        // ),

        const SizedBox(
          height: 10,
        ),

      ],
    );
  }
}