import 'package:el_race/ui/presentation/my_projects/data/datasources/project_remote_datasource.dart';
import 'package:el_race/ui/presentation/my_projects/data/repositories/project_repository_impl.dart';
import 'package:el_race/ui/presentation/my_projects/domain/usecases/get_partner_projects_usecase.dart';
import 'package:el_race/ui/presentation/my_projects/domain/usecases/get_projects_by_partner_usecase.dart';
import 'package:el_race/ui/presentation/my_projects/domain/usecases/get_projects_usecase.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/bloc/partner_bloc.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/bloc/partner_event.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/bloc/partner_state.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/bloc/project_list_bloc.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/screens/project_list_screen.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';

class MyProject extends StatefulWidget {
  const MyProject({super.key});

  @override
  State<MyProject> createState() => _MyProjectState();
}

class _MyProjectState extends State<MyProject> {
  late PartnerBloc _partnerBloc;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _partnerBloc = PartnerBloc(
      getPartnerProjectsUseCase: GetPartnerProjectsUseCase(
        repository: ProjectRepositoryImpl(
          ProjectRemoteDataSource(),
        ),
      ),
    );
    // Load partners when the screen initializes
    _partnerBloc.add(const LoadPartnersEvent());
  }

  @override
  void dispose() {
    _partnerBloc.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _partnerBloc,
      child: Scaffold(
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
                    GestureDetector(
                      onTap: () {
                        // Implement search functionality
                        showSearch(
                          context: context,
                          delegate: PartnerSearchDelegate(_partnerBloc),
                        );
                      },
                      child: Image.asset(
                        'assets/png/search.png',
                        width: 38.w,
                        height: 38.h,
                      ),
                    ),
                    SizedBox(width: 23.w),
                  ],
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 10.h),
                child: BlocBuilder<PartnerBloc, PartnerState>(
                  builder: (context, state) {
                    if (state is PartnerLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    else if (state is PartnerError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: ${state.message}',
                              style: GoogleFonts.koulen(
                                fontSize: 16.sp,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: () {
                                _partnerBloc.add(
                                    const LoadPartnersEvent(refresh: true));
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    else if (state is PartnerLoaded || state is PartnerSearchLoaded) {
                      final partners = state is PartnerLoaded
                          ? state.partners
                          : (state as PartnerSearchLoaded).partners;

                      if (partners.isEmpty) {
                        return Center(
                          child: Text(
                            'No partners found',
                            style: GoogleFonts.koulen(
                              fontSize: 18.sp,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20.w,
                          mainAxisSpacing: 10.h,
                          childAspectRatio: 1,
                        ),
                        itemCount: partners.length,
                        itemBuilder: (context, index) {
                          final partner = partners[index];
                          return GestureDetector(
                            onTap: () {
                              final repository = ProjectRepositoryImpl(
                                ProjectRemoteDataSource(),
                              );

                              final projectListBloc = ProjectListBloc(
                                getProjectsUseCase: GetProjectsUseCase(
                                  repository: repository,
                                ),
                                getProjectAttachmentsUseCase:
                                    GetProjectAttachmentsUseCase(
                                  repository: repository,
                                ),
                                getProjectsByPartnerUseCase:
                                    GetProjectsByPartnerUseCase(
                                  repository: repository,
                                ),
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BlocProvider(
                                    create: (context) => projectListBloc,
                                    child: ProjectListScreen(
                                      bloc: projectListBloc,
                                      partnerId: partner.id, // Pass partner ID
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
                                padding: EdgeInsets.all(8.w),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    partner.icon != null
                                        ? Image.network(
                                            partner.icon!,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                Image.asset(
                                              "assets/png/police.png",
                                                  width: 70,
                                                  height: 70,
                                                  fit: BoxFit.contain,
                                            ),
                                          )
                                        : Image.asset(
                                            "assets/png/police.png",
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.contain,
                                          ),
                                    SizedBox(height: 5.h),
                                    Text(
                                      partner.name,
                                      style: GoogleFonts.koulen(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    SizedBox(height: 5.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.tag,size: 20,),
                                        Text(
                                          'work orders',
                                          style: GoogleFonts.koulen(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(width: 3.w),
                                        Container(
                                          width: 25.w,
                                          height:25.h,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              partner.workOrdersCount.toString(),
                                              style: GoogleFonts.montserrat(
                                                fontWeight: FontWeight.w700,
                                                fontSize:partner.workOrdersCount.toString().length>=3?10.sp:12.sp,
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
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Search delegate for partners
class PartnerSearchDelegate extends SearchDelegate<String> {
  final PartnerBloc partnerBloc;

  PartnerSearchDelegate(this.partnerBloc);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          partnerBloc.add(const LoadPartnersEvent());
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) {
      partnerBloc.add(SearchPartnersEvent(query));
    }
    return BlocBuilder<PartnerBloc, PartnerState>(
      bloc: partnerBloc,
      builder: (context, state) {
        if (state is PartnerLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PartnerSearchLoaded) {
          final partners = state.partners;
          return ListView.builder(
            itemCount: partners.length,
            itemBuilder: (context, index) {
              final partner = partners[index];
              return ListTile(
                title: Text(partner.name),
                subtitle: Text('${partner.workOrdersCount} work orders'),
                onTap: () {
                  close(context, partner.name);
                },
              );
            },
          );
        }
        return const Center(child: Text('Search for partners'));
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('Enter partner name to search'));
  }
}
