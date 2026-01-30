import 'dart:async';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/my_projects/data/datasources/project_remote_datasource.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/user_project_model.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/user_projects_response.dart';
import 'package:el_race/ui/presentation/my_projects/data/repositories/project_repository_impl.dart';
import 'package:el_race/ui/presentation/my_projects/domain/usecases/get_projects_by_partner_usecase.dart';
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

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final ShaderCallback? shaderCallback;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.shaderCallback,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _needsScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollNeeded();
    });
  }

  void _checkIfScrollNeeded() {
    if (!mounted) return;
    if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0) {
      setState(() {
        _needsScrolling = true;
      });
      _startScrolling();
    }
  }

  void _startScrolling() async {
    if (!mounted || !_needsScrolling) return;

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    while (mounted && _needsScrolling) {
      // Scroll to end slowly
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(
            milliseconds: (widget.text.length * 120).clamp(4000, 15000)),
        curve: Curves.linear,
      );

      if (!mounted) break;
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) break;

      // Jump back to start instantly (no animation)
      _scrollController.jumpTo(0);

      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      widget.text,
      style: widget.style,
      textAlign: widget.textAlign,
    );

    final scrollableText = SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: textWidget,
    );

    if (widget.shaderCallback != null) {
      return ShaderMask(
        shaderCallback: widget.shaderCallback!,
        child: scrollableText,
      );
    }

    return scrollableText;
  }
}

class MyProject extends StatefulWidget {
  const MyProject({super.key});

  @override
  State<MyProject> createState() => _MyProjectState();
}

class _MyProjectState extends State<MyProject> {
  bool _isLoading = false;
  String? _error;
  List<UserProjectModel> _projects = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProjects();
  }

  Future<void> _fetchUserProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final UserProjectsResponse response =
          await ProjectRemoteDataSource().fetchClientsList();

      setState(() {
        _projects = response.projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 🔹 Projects Title Section (Scrollable)
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 5),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/newapp/my_projects.png",
                        height: 24.w,
                        width: 24.w,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        translate('home.projects'),
                        style: GoogleFonts.koulen(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w500,
                          color: appFontColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),

          // 🔹 Loading or Error or List
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error != null
                  ? SliverFillRemaining(
                      child: Center(
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    )
                  : _projects.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(
                            child: Text('No projects found'),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final project = _projects[index];

                              final id = project.projectId;
                              final name = project.projectName;
                              final totalProjects = project.totalProjects;
                              final totalAmount = project.totalProjectsAmount;
                              final photoUrl = project.photoUrl;

                              return GestureDetector(
                                onTap: () {
                                  final repo = ProjectRepositoryImpl(
                                      ProjectRemoteDataSource());
                                  final bloc = ProjectListBloc(
                                    getProjectsUseCase: GetProjectsUseCase(
                                      repository: repo,
                                    ),
                                    getProjectAttachmentsUseCase:
                                        GetProjectAttachmentsUseCase(
                                            repository: repo),
                                    getProjectsByPartnerUseCase:
                                        GetProjectsByPartnerUseCase(
                                            repository: repo),
                                  );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: bloc,
                                        child: ProjectListScreen(
                                          bloc: bloc,
                                          partnerId: id,
                                          partnerName: name,
                                          partnerPhoto: photoUrl ?? '',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: buildProjectCard(
                                  name: name,
                                  photoUrl: photoUrl ?? '',
                                  wo: '$totalProjects',
                                  amount: totalAmount > 0
                                      ? '${(totalAmount / 1000000).toStringAsFixed(2)}M'
                                      : '0',
                                  leftLabel: 'PROJECTS',
                                  rightLabel: 'AMOUNT (AED)',
                                ),
                              );
                            },
                            childCount: _projects.length,
                          ),
                        ),
          // Bottom padding
          SliverPadding(padding: EdgeInsets.only(bottom: 100.h)),
        ],
      ),
    );
  }
}

//
// ------------- CARD — EXACT MATCH TO REFERENCE ----------------
//

Widget buildProjectCard({
  required String name,
  required String photoUrl,
  required String wo,
  required String amount,
  String leftLabel = 'W.O',
  String rightLabel = 'AMOUNT',
}) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
    padding: const EdgeInsets.all(1),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22.r),
      gradient: const LinearGradient(
        colors: [Color(0xFF151544), Color(0xFF3535AA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Container(
      height: 120.h,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21.r),
        gradient: const LinearGradient(
          colors: [Color(0xFFD6D6D6), Color(0xFFADB2BD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // avatar
          Container(
            width: 75.w,
            height: 75.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      headers: {
                        'Accept': 'image/*',
                        'Authorization':
                            'Bearer ${SharedPref.getLoginData().result?.token ?? ''}',
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: appFontColor,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          name.isNotEmpty ? name[0] : 'C',
                          style: GoogleFonts.koulen(
                            fontSize: 28.sp,
                            color: appFontColor,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        name.isNotEmpty ? name[0] : 'C',
                        style: GoogleFonts.koulen(
                          fontSize: 28.sp,
                          color: appFontColor,
                        ),
                      ),
                    ),
            ),
          ),

          SizedBox(width: 16.w),

          // divider
          Container(width: 2.5.w, height: 60.h, color: Colors.white),

          SizedBox(width: 16.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MarqueeText(
                  text: name.toUpperCase(),
                  style: GoogleFonts.koulen(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF151544), Color(0xFF3535AA)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0.7, 1.0],
                  ).createShader(bounds),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    _pillData(leftLabel, wo),
                    SizedBox(width: 12.w),
                    _pillData(rightLabel, amount),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    ),
  );
}

Widget _pillData(String label, String value) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.koulen(
            fontSize: 12.sp,
            color: Colors.black87,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 3.h),
        Container(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: GoogleFonts.koulen(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: 0.8,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    ),
  );
}
