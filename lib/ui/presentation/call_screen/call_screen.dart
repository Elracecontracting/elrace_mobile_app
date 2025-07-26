import 'dart:developer';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../utils/di.dart';
import '../../../../../utils/string_utils.dart';
import '../../widgets/header_widget.dart';
import 'bloc/contact_bloc.dart';

class CallScreen extends StatefulWidget {
  final LoginResponseModel loginResponseModel;

  const CallScreen({super.key, required this.loginResponseModel});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _contactBloc = sl.get<ContactBloc>();

  @override
  void initState() {

    Future.delayed(const Duration(milliseconds: 500), () {
      _contactBloc.add(GetEmployeeLisET());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _contactBloc,
      child: BlocListener<ContactBloc, ContactState>(
        bloc: _contactBloc,
        listenWhen: (p, c) => c is ContactLoadingState,
        listener: (context, state) {
          log('state $state');
          if (state is ContactLoadingState) {
            if (state.isLoading == true) {
              showDialog(
                  context: context,
                  builder: (context) => Dialog(
                        child: SizedBox(
                          height: SizeConfig().getHeight(80),
                          width: SizeConfig().getHeight(80),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ));
            } else {
              Navigator.pop(context);
            }
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const HeaderWidget(),

                  const SizedBox(
                    height: 20,
                  ),
                  Column(
                    children: [
                      searchWidget(),
                      const SizedBox(
                        height: 30,
                      ),
                      BlocBuilder<ContactBloc, ContactState>(
                        bloc: _contactBloc,
                        buildWhen: (p, c) =>
                            c != p && c is ContactLoadingState ||
                            c is EmployeeListLoaded,
                        builder: (context, state) {
                          if (state is EmployeeListLoaded) {
                            return ListView.separated(
                              shrinkWrap: true,
                              itemCount: state.empList.length,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                var emp = state.empList[index];

                                return contactTile(
                                    index.isEven
                                        ? [
                                            const Color(0xFFCDCDFF),
                                            Colors.white,
                                            const Color(0xFF9999D4),
                                            const Color(0xAA150030)
                                          ]
                                        : [lightGrey, darkGrey],
                                    white,
                                    index.isOdd,
                                    emp.profilePhotoUrl.toString(),
                                    emp.name!,
                                    emp.jobId.toString(),
                                    emp.id.toString(),
                                    emp.mobilePhone.toString(), () {
                                  _makePhoneCall('tel:${emp.mobilePhone}');
                                });
                              },
                              separatorBuilder:
                                  (BuildContext context, int index) {
                                return const SizedBox(
                                  height: 20,
                                );
                              },
                            );
                          }

                          return const SizedBox();
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }
}

Widget searchWidget() {
  return Container(
    height: 40,
    width: 250,
    decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(color: darkGrey, offset: Offset(2, 4), blurRadius: 12)
        ],
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffE5E4E2), Color(0xffD3D3D3)])),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        style: const TextStyle(
          color: Color(0xFF1A1A53),
          fontSize: 15,
          fontFamily: 'Koulen',
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'SEARCH CONTACT',
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            hintStyle: const TextStyle(
                fontSize: 12,
                fontFamily: 'Koulen',
                fontWeight: FontWeight.w400,
                color: Color(0xFF1A1A53)),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                '$imagePrefixPng/search_icon.png',
                width: 10,
                height: 10,
              ),
            ),
            suffixIcon: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  "assets/png/mic_icon.png",
                  width: 14,
                  height: 14,
                ))),
      ),
    ),
  );
}

Widget contactTile(
    List<Color> color,
    Color textColor,
    bool gradientAlignment,
    String image,
    String name,
    String job,
    String emp,
    String num,
    Function() onTap) {
  List<String> nameParts = name.split(' ');
  log('image $image');
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Container(
      height: 80,
      width: 350,
      // color: Colors.transparent,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        // borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
            colors: color,
            // begin: Alignment(1.00, 0.00),
            // end: Alignment(-1, 0),
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        shadows: [
          BoxShadow(
              color: Colors.black.withAlpha((0.4 * 255).toInt()),
              offset: const Offset(0, 6),
              blurRadius: 5)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 60,
                width: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: white,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                            LinearGradient(colors: [darkPeach, lightPeach])),
                    child: Center(
                      child: Image.network(
                          image) /*Image.asset('$imagePrefixIcons/user.png')*/,
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: SizeConfig().getWidth(170),
                  child: Text(
                    nameParts[1],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(
                  height: 1,
                ),
                Text(
                  job,
                  style: TextStyle(color: greyText),
                ),
                const SizedBox(
                  height: 1,
                ),
                Text(
                  emp,
                  style: TextStyle(color: greyText),
                )
              ],
            ),
            GestureDetector(
              onTap: () {
                onTap();
              },
              child: Container(
                height: SizeConfig().getHeight(40),
                width: SizeConfig().getWidth(100),
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha((0.4 * 255).toInt()),
                          offset: const Offset(0, 6),
                          blurRadius: 5)
                    ],
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                        colors: [shadowBlueDark, shadowBlueLight])),
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      child: Text(
                        'Contact me',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: SizeConfig().getTextSize(12)),
                      ),
                    )),
              ),
            )
          ],
        ),
      ),
    ),
  );
}
