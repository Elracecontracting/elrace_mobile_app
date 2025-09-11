import 'package:el_race/ui/presentation/my_projects/data/datasources/project_remote_datasource.dart';
import 'package:el_race/ui/presentation/my_projects/data/repositories/project_repository_impl.dart';
import 'package:el_race/ui/presentation/my_projects/domain/usecases/get_projects_usecase.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/bloc/project_list_bloc.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/screens/project_list_screen.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';

class MyProject extends StatelessWidget {
  final List<Map<String, dynamic>> projects = [
    {
      'icon': "assets/png/police.png",
      'title': 'ABU DHABI POLICE',
      'number': 'work orders no',
    },
    {
      'icon': "assets/png/police.png",
      'title': 'ABU DHABI POLICE',
      'number': 'work orders no',
    },
    {
      'icon': "assets/png/police.png",
      'title': 'ABU DHABI POLICE',
      'number': 'work orders no',
    },
    {
      'icon': "assets/png/police.png",
      'title': 'ABU DHABI POLICE',
      'number': 'work orders no',
    },
    {
      'icon': "assets/png/police.png",
      'title': 'ABU DHABI POLICE',
      'number': 'work orders no',
    },
    {
      'icon': "assets/png/police.png",
      'title': 'ABU DHABI POLICE',
      'number': 'work orders no',
    },
    {
      'icon': "assets/png/police.png",
      'title': 'ABU DHABI POLICE',
      'number': 'work orders no',
    },
    {
      'icon': "assets/png/police.png",
      'title': 'ABU DHABI POLICE',
      'number': 'work orders no',
    },
  ];
  MyProject({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              Row(
                children: [
                  Image.asset(
                    "assets/newapp/my_projects.png",
                    height: 30.w,
                    width: 30.w,
                  ),
                  Text(
                    translate('home.projects'),
                    style: GoogleFonts.koulen(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w500,
                      color: appFontColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Image.asset(
                    'assets/png/search.png',
                    width: 38.w,
                    height: 38.h,
                  ),
                  SizedBox(width: 23.w),
                ],
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 10.h),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20.w,
                  mainAxisSpacing: 15.h,
                  childAspectRatio: 1.3,
                ),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final item = projects[index];
                  return GestureDetector(
                    onTap: () {
                      final projectListBloc = ProjectListBloc(
                        getProjectsUseCase: GetProjectsUseCase(
                          repository: ProjectRepositoryImpl(
                            ProjectRemoteDataSource(),
                          ),
                        ),
                        getProjectAttachmentsUseCase:
                            GetProjectAttachmentsUseCase(
                          repository: ProjectRepositoryImpl(
                            ProjectRemoteDataSource(),
                          ),
                        ),
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => projectListBloc,
                            child: ProjectListScreen(
                              bloc: projectListBloc,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xffD6D6D6),
                            Color(0xffADB2BD),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(10.w),
                        child: Column(
                          children: [
                            Image.asset(
                              item['icon'],
                              width: 60.w,
                              height: 60.h,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              item['title'],
                              style: GoogleFonts.koulen(
                                fontSize: 20.66,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '# ',
                                  style: GoogleFonts.koulen(
                                    fontSize: 12.19,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  item['number'],
                                  style: GoogleFonts.koulen(
                                    fontSize: 12.19,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Container(
                                  width: 20.08.w,
                                  height: 20.08.h,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '5',
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.24,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
