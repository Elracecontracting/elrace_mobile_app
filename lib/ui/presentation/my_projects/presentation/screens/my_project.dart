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
import 'package:intl/intl.dart';

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
  int? _selectedCompanyId;

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
        if (_selectedCompanyId != null &&
            !_projects.any((p) => p.projectId == _selectedCompanyId)) {
          _selectedCompanyId = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<UserProjectModel> get _filteredProjects {
    if (_selectedCompanyId == null) {
      return _projects;
    }
    return _projects
        .where((p) => p.projectId == _selectedCompanyId)
        .toList(growable: false);
  }

  Widget _buildCompanyFilterTabs() {
    const unfocusedStart = Color(0xFFD6D6D6);
    const unfocusedEnd = Color(0xFFADB2BD);
    const focusedStart = Color(0xB81B1F26);
    const focusedEnd = Color(0xFF717171);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: List.generate(_projects.length + 1, (index) {
          final bool isAllTab = index == 0;
          final UserProjectModel? company =
              isAllTab ? null : _projects[index - 1];
          final bool isSelected = isAllTab
              ? _selectedCompanyId == null
              : _selectedCompanyId == company!.projectId;

          return Padding(
            padding:
                EdgeInsetsDirectional.only(end: index == _projects.length ? 0 : 6.w),
            child: InkWell(
              borderRadius: BorderRadius.circular(22.r),
              onTap: () {
                setState(() {
                  _selectedCompanyId = isAllTab ? null : company!.projectId;
                });
              },
              child: Container(
                constraints: BoxConstraints(minWidth: 84.w, maxWidth: 210.w),
                height: 36.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22.r),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isSelected
                        ? const [focusedStart, focusedEnd]
                        : const [unfocusedStart, unfocusedEnd],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  isAllTab ? 'ALL' : company!.projectName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.koulen(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
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
                if (!_isLoading && _error == null && _projects.isNotEmpty) ...[
                  _buildCompanyFilterTabs(),
                  const SizedBox(height: 8),
                ],
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
                  : _filteredProjects.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(
                            child: Text('No projects found for this company'),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final project = _filteredProjects[index];

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
                                  id: '$id',
                                  name: name,
                                  photoUrl: photoUrl ?? '',
                                  projectsCount: totalProjects,
                                  amountAed: totalAmount,
                                ),
                              );
                            },
                            childCount: _filteredProjects.length,
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
  required String id,
  required String name,
  required String photoUrl,
  required int projectsCount,
  required double amountAed,
  String location = '',
}) {
  String? normalizedPhotoUrl = photoUrl.trim();
  if (normalizedPhotoUrl.isEmpty) normalizedPhotoUrl = null;
  if (normalizedPhotoUrl != null &&
      normalizedPhotoUrl.contains('erp.elrace.compublic')) {
    normalizedPhotoUrl = normalizedPhotoUrl.replaceAll(
        'erp.elrace.compublic', 'erp.elrace.com/public');
  }

  final formattedAmount = NumberFormat('#,##0.##', 'en').format(amountAed);
  const cardDataGray = Color(0xB8484848);

  return Container(
    margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22.r),
      border: Border.all(color: const Color(0xFF2C2F36), width: 1),
      gradient: const LinearGradient(
        colors: [Color(0xFFD6D6D6), Color(0xFFADB2BD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22.r),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/newapp/for_attachments.png',
                  width: 150.w,
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.centerRight,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 18.h,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          DateFormat('MM/dd/yyyy').format(DateTime.now()),
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: cardDataGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  id.isNotEmpty ? id : '-',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 10.h),
                Text(
                  name.trim().isNotEmpty ? name.trim() : '-',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(text: 'Work Order# '),
                            TextSpan(
                              text: '$projectsCount',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: cardDataGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                            children: [
                              const TextSpan(text: 'Amount# '),
                              TextSpan(
                                text: formattedAmount,
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: cardDataGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 16.w, color: red),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        location.trim().isNotEmpty ? location.trim() : '-',
                        style: GoogleFonts.inter(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: cardDataGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PositionedDirectional(
            start: 10.w,
            top: 10.h,
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: normalizedPhotoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        normalizedPhotoUrl,
                        fit: BoxFit.contain,
                        headers: {
                          'Accept': 'image/*',
                          'Authorization':
                              'Bearer ${SharedPref.getLoginData().result?.token ?? ''}',
                        },
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.business,
                          size: 18.w,
                          color: appFontColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.business,
                      size: 18.w,
                      color: appFontColor,
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}
