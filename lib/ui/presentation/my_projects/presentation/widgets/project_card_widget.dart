import 'package:el_race/resources/app_colors.dart';
import 'package:el_race/ui/presentation/my_projects/domain/entities/project_entity.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/bloc/project_list_event.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/screens/attachment_list.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/screens/project_list_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../bloc/project_list_bloc.dart';


class ProjectCardWidget extends StatelessWidget {
  final ProjectEntity item;
  const ProjectCardWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ProjectListBloc.get(context).add(GetProjectAttachmentsEvent(item.projectId.toString()));
        Util.pushPage(const AttachmentListScreen(), context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                width: 20.w,  
                height: 28.w,
                margin: EdgeInsets.only(left: 20.w,),
                decoration: BoxDecoration(
                  color: red,
                  boxShadow: [
                    BoxShadow(
                      color: red.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              Container(
                height: 37.w,
                width: 210.w,
                alignment: Alignment.centerLeft,
                margin:  EdgeInsets.only(left: 30.w),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  image: DecorationImage(image: AssetImage('assets/newapp/back_ground_card.png'))
                ),
                child: SizedBox(
                  width: 190.w,
                  child: Text(
                    item.name,
                    style: GoogleFonts.koulen(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/png/background.png"),
                fit: BoxFit.fill,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(36, 16, 16, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset("assets/newapp/my_projects.png",height: 26.w,width: 26.w,),
                            
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  item.name,
                                  style: GoogleFonts.koulen(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                    letterSpacing: 1.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Icon(Icons.more_horiz, size: 20, color: Colors.black),
                    ],
                  ),
                 
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Image.asset("assets/png/icons/tag.png",height: 20.w,width: 20.w,),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: Text(
                          "WORK ORDER",
                          style: GoogleFonts.koulen(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: red,
                            letterSpacing: 1.0,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                     
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset("assets/png/icons/hand.png",height: 30.w,width: 30.w,),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 170.w,
                            child: Text(
                              item.agreementId,
                              maxLines: 1,
                              style: GoogleFonts.koulen(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                letterSpacing: 1.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(right: 10,bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: greyText, width: 2),
                        ),
                        child: Text(
                          '+12',
                          style: GoogleFonts.koulen(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.green,
                          ),
                        )
                      ),
                    ],
                  ),
                 
                  Transform.translate(
                    offset: Offset(0, -15.w),
                    child: Row(
                      children: [
                        // SizedBox(
                        //   width: 200,
                        //   child: Text(
                        //     item.partnerId,
                        //     style: GoogleFonts.koulen(
                        //       fontSize: 12,
                        //       color: Colors.black,
                        //       letterSpacing: 1.0,
                        //     ),
                        //     overflow: TextOverflow.ellipsis,
                        //     maxLines: 2,
                        //     softWrap: false,
                        //   ),
                        // ),
                         Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                      'assets/png/profile_1.png',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                            ),
                          ),
                        const Spacer(),
                        Container(
                          width: 60.w,
                          height: 100.w,
                          margin: EdgeInsets.only(right: 10.w,),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            // image: DecorationImage(
                            //   image: AssetImage("assets/png/date_box_bg.png"),
                            //   fit: BoxFit.contain,
                            // ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 50.w,
                                height: 50,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(horizontal: 6,) + const EdgeInsets.only(top: 10),
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage("assets/png/date_box_bg.png"),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                child: Text(
                                  Util.isValidDateTime(item.date)?DateTime.parse(item.date).day.toString():'',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Util.isValidDateTime(item.date)
                                  ? DateFormat.MMMM().format(DateTime.parse(item.date))
                                  : '',
                                style: GoogleFonts.inter(
                                  fontSize: 9.w,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                Util.isValidDateTime(item.date)?DateTime.parse(item.date).year.toString():'',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        )
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
