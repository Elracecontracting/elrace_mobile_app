import 'package:el_race/ui/presentation/my_projects/presentation/bloc/project_list_bloc.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/bloc/project_list_event.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/bloc/project_list_state.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/widgets/project_card_widget.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ProjectListScreen extends StatefulWidget {
  final ProjectListBloc bloc;

  const ProjectListScreen({super.key, required this.bloc});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final _scrollController = ScrollController();
  late ProjectListBloc bloc;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    bloc = widget.bloc;
    bloc.add(LoadProjectsEvent());
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      bloc.add(LoadMoreProjectsEvent());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: Column(
        children: [
          // 🔹 Always-visible header
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
                    ' My Projects',
                    style: GoogleFonts.koulen(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w500,
                      color: appFontColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 40),
            ],
          ),

          // 🔹 Expanded so list or loading takes remaining space
          Expanded(
            child: BlocBuilder<ProjectListBloc, ProjectListState>(
              builder: (ctx, state) {
                if (state is ProjectListLoading &&
                    bloc.visibleProjects.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!(state is ProjectListLoading) &&
                    bloc.visibleProjects.isEmpty) {
                  return const Center(child: Text('No data available'));
                } else if (state is ProjectListLoaded ||
                    bloc.visibleProjects.isNotEmpty) {
                  var list = bloc.visibleProjects;
                  return RefreshIndicator(
                    onRefresh: () async =>
                        bloc.add(LoadProjectsEvent(refresh: true)),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(top: 10),
                      controller: _scrollController,
                      itemCount: list.length + 1, // ✅ Removed header from list
                      itemBuilder: (context, index) {
                        if (index < list.length) {
                          final item = list[index];
                          return ProjectCardWidget(item: item, bloc: bloc);
                        } else {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                    ),
                  );
                } else if (state is ProjectListError) {
                  return Center(child: Text(state.message));
                } else {
                  return const SizedBox();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
