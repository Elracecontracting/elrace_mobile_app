import 'dart:developer';
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../utils/di.dart';
import '../../../../../utils/string_utils.dart';
import '../../widgets/header_widget.dart';
import 'bloc/contact_bloc.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key,});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _contactBloc = sl.get<ContactBloc>();
  int? expandedIndex;

  @override
  void initState() {
    _contactBloc.add(GetEmployeeLisET());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ContactBloc, ContactState>(
      listenWhen: (p, c) => c is ContactLoadingState,
      listener: (context, state) {
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
        backgroundColor: Colors.white,
        appBar: const HeaderWidget(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 100.w,top: 10.w),
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    searchWidget(),
                    const SizedBox(
                      height: 30,
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      itemCount: _contactBloc.empList.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        var emp = _contactBloc.empList[index];
                        bool isExpanded = expandedIndex == index;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: ContactTile(
                            color: const [darkGrey,darkGrey],
                            textColor: white,
                            gradientAlignment: index.isOdd,
                            image: emp.profilePhotoUrl.toString(),
                            name: emp.name!,
                            job: emp.jobId.toString(),
                            emp: emp.id.toString(),
                            num: emp.mobilePhone.toString(),
                            isExpanded: isExpanded,
                            onTapExpand: () {
                              setState(() {
                                expandedIndex = isExpanded ? null : index;
                              });
                            },
                            onTapCall: () => _makePhoneCall('tel:${emp.mobilePhone}'),
                            onTapWhatsApp: () => _openWhatsApp(emp.mobilePhone.toString()),
                            onTapEmail: () => _sendEmail(emp.name!),
                          ),
                        );
                      },
                      separatorBuilder:
                          (BuildContext context, int index) {
                        return const SizedBox(
                          height: 20,
                        );
                      },
                    ),
                  ],
                ),
              ],
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

  Future<void> _openWhatsApp(String phoneNumber) async {
    String url = "https://wa.me/$phoneNumber";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  Future<void> _sendEmail(String name) async {
    String url = "mailto:?subject=Hello $name";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch email';
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

class ContactTile extends StatelessWidget {
  final List<Color> color;
  final Color textColor;
  final bool gradientAlignment;
  final String image;
  final String name;
  final String job;
  final String emp;
  final String num;
  final bool isExpanded;
  final VoidCallback onTapExpand;
  final VoidCallback onTapCall;
  final VoidCallback onTapWhatsApp;
  final VoidCallback onTapEmail;

  const ContactTile({
    super.key,
    required this.color,
    required this.textColor,
    required this.gradientAlignment,
    required this.image,
    required this.name,
    required this.job,
    required this.emp,
    required this.num,
    required this.isExpanded,
    required this.onTapExpand,
    required this.onTapCall,
    required this.onTapWhatsApp,
    required this.onTapEmail,
  });

  @override
  Widget build(BuildContext context) {
    List<String> nameParts = name.split(' ');
    String image = 'https://t3.ftcdn.net/jpg/02/99/04/20/360_F_299042079_vGBD7wIlSeNl7vOevWHiL93G4koMM967.jpg';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: onTapExpand,
        child: Container(
          height: 85.w,
          width: 350.w,
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            gradient: LinearGradient(
                colors: color,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.all(7.w),
                  height: isExpanded ? 56.w : 80.w,
                  width: isExpanded ? 56.w : 80.w,
                  padding: EdgeInsets.all(9.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    image: DecorationImage(
                      image: NetworkImage(image),
                      fit: BoxFit.cover,
                    ),
                    shape: BoxShape.circle,
                    // gradient: const LinearGradient(colors: [darkPeach, lightPeach]),
                    border: isExpanded ? Border.all(
                      color: Colors.white,
                      width: 2,
                    ) : null,
                  ),
                ),
                if(!isExpanded)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nameParts.length > 1 ? nameParts[1] : name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: 2.w),
                          SizedBox(
                            width: 140.w,
                            child: Text(
                              job,
                              style: const TextStyle(color: greyText,fontSize: 12,fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(height: 2.w),
                          Text(
                            emp,
                            style: const TextStyle(color: greyText),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          )
                        ],
                      ),
                    ),
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
                      ),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: isExpanded
                      ? Container(
                        width: 250.w,
                        padding: EdgeInsets.symmetric(vertical: 6.w,horizontal: 10.w),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF1A1A53),width: 1),
                            borderRadius: BorderRadius.circular(25),
                          ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            key: const ValueKey('icons'),
                            children: [
                              GestureDetector(
                                onTap: onTapCall,
                                child: Container(
                                  padding: EdgeInsets.all(6.w),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Image.asset(
                                    '$imagePrefixPng/call.png',
                                    width: 35.w,
                                    height: 35.w,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: onTapWhatsApp,
                                child: Container(
                                  padding: EdgeInsets.all(6.w),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Image.asset(
                                    '$imagePrefixPng/whatsapp.png',
                                   width: 35.w,
                                    height: 35.w,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: onTapEmail,
                                child: Container(
                                  padding: EdgeInsets.all(6.w),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Image.asset(
                                    '$imagePrefixPng/email.png',
                                    width: 35.w,
                                    height: 35.w,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      )
                      : Container(
                          key: const ValueKey('button'),
                          height: 40,
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF1A1A53),width: 1),
                              borderRadius: BorderRadius.circular(25),),
                          child: const Center(
                            child: Text(
                              'Contact me',
                              style: TextStyle(
                                  color: Color(0xFF1A1A53),
                                  fontSize: 12),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
