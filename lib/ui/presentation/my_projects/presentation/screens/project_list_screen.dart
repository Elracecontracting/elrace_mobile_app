import 'dart:ui';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/bloc/project_list_bloc.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/bloc/project_list_event.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/bloc/project_list_state.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/screens/attachment_list.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProjectListScreen extends StatefulWidget {
  final ProjectListBloc bloc;
  final int? partnerId;
  final String? partnerName;
  final String? partnerPhoto;

  const ProjectListScreen({
    super.key,
    required this.bloc,
    this.partnerId,
    this.partnerName,
    this.partnerPhoto,
  });

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

    // Load projects based on whether we have a partnerId or not
    if (widget.partnerId != null) {
      bloc.add(LoadProjectsByPartnerEvent(partnerId: widget.partnerId!));
    } else {
      bloc.add(LoadProjectsEvent());
    }
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
          Stack(
            alignment: Alignment.center,
            children: [
              // Center: Title
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 60.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(
                        builder: (context) {
                          print(
                              '🖼️ Partner Photo URL: ${widget.partnerPhoto}');
                          print('📝 Partner Name: ${widget.partnerName}');

                          if (widget.partnerPhoto != null &&
                              widget.partnerPhoto!.isNotEmpty) {
                            return ClipOval(
                              child: Image.network(
                                widget.partnerPhoto!,
                                height: 60.w,
                                width: 60.w,
                                fit: BoxFit.cover,
                                headers: {
                                  'Accept': 'image/*',
                                  'Authorization':
                                      'Bearer ${SharedPref.getLoginData().result?.token ?? ''}',
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    print(
                                        '✅ Partner photo loaded successfully');
                                    return child;
                                  }
                                  print('⏳ Loading partner photo...');
                                  return SizedBox(
                                    width: 30.w,
                                    height: 30.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                      '❌ Error loading partner photo: $error');
                                  print('❌ Stack trace: $stackTrace');
                                  return Icon(
                                    Icons.business,
                                    size: 30.w,
                                    color: appFontColor,
                                  );
                                },
                              ),
                            );
                          } else {
                            print('⚠️ No partner photo provided');
                            return Icon(
                              Icons.business,
                              size: 30.w,
                              color: appFontColor,
                            );
                          }
                        },
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          widget.partnerName != null
                              ? widget.partnerName!.toUpperCase()
                              : 'ABU DHABI POLICE',
                          style: GoogleFonts.koulen(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w500,
                            color: appFontColor,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Left: Back button
              Positioned(
                left: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
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
                    onRefresh: () async {
                      if (widget.partnerId != null) {
                        bloc.add(LoadProjectsByPartnerEvent(
                            partnerId: widget.partnerId!, refresh: true));
                      } else {
                        bloc.add(LoadProjectsEvent(refresh: true));
                      }
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.only(top: 10),
                      controller: _scrollController,
                      itemCount: list
                          .length, // ✅ Fixed: removed +1 to prevent index issues
                      itemBuilder: (context, index) {
                        if (index < list.length) {
                          final item = list[index];
                          return _buildProjectCard(item);
                        } else {
                          return const SizedBox(); // ✅ Fallback widget
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

  Widget _buildProjectCard(dynamic project) {
    final name = project.name ?? 'PROJECT NAME';
    final amount = project.woAmount ?? 0.0;
    final date = project.date ?? '';
    final agreementId = project.agreementId ?? '';
    final projectManagerPhoto = project.projectManagerPhoto;
    final differenceDays = project.differenceDays ?? 0;
    final projectId = project.projectId?.toString() ?? '0';

    final formattedAmount = _formatAmount(amount);
    final formattedDate = _formatDate(date);
    final statusCount = _formatDifferenceDays(differenceDays);

    return GestureDetector(
      onTap: () {
        // Load attachments and navigate
        bloc.add(GetProjectAttachmentsEvent(projectId));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttachmentListScreen(bloc: bloc),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21.r),
            gradient: const LinearGradient(
              colors: [Color(0xFFD6D6D6), Color(0xFFADB2BD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top: Title with gradient + status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF151544), Color(0xFF3535AA)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            stops: [0.7, 1.0],
                          ).createShader(bounds),
                          child: Text(
                            name.toUpperCase(),
                            style: GoogleFonts.koulen(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Status badge - raised slightly above the title
                    Transform.translate(
                      offset: Offset(0, -4.h),
                      child: Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          border: Border.all(
                              color: const Color(0xFF151544), width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          statusCount,
                          style: GoogleFonts.koulen(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: _getStatusColor(statusCount),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // Bottom: Amount + Avatar + Date (with glassmorphism effect)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        color: Colors.white.withOpacity(0.25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.4),
                            blurRadius: 6,
                            spreadRadius: -2,
                            offset: const Offset(-2, -2),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            spreadRadius: -2,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // LEFT: Amount
                          Flexible(
                            flex: 4,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/png/icons/Coin.png',
                                  width: 20.w,
                                  height: 20.w,
                                  color: const Color(0xFF151544),
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.attach_money,
                                    size: 20.w,
                                    color: const Color(0xFF151544),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    formattedAmount,
                                    style: GoogleFonts.koulen(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      letterSpacing: 0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 6.w),
                          // CENTER: Avatar (Project Manager Photo)
                          Container(
                            width: 34.w,
                            height: 34.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: projectManagerPhoto != null
                                ? ClipOval(
                                    child: Image.network(
                                      projectManagerPhoto,
                                      width: 34.w,
                                      height: 34.w,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Text(
                                        _getInitials(agreementId),
                                        style: GoogleFonts.koulen(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                          color: appFontColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    _getInitials(agreementId),
                                    style: GoogleFonts.koulen(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: appFontColor,
                                    ),
                                  ),
                          ),
                          SizedBox(width: 6.w),
                          // RIGHT: Date
                          Flexible(
                            flex: 3,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/png/calender.png',
                                  width: 20.w,
                                  height: 20.w,
                                  color: const Color(0xFF151544),
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.calendar_month,
                                    size: 20.w,
                                    color: const Color(0xFF151544),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    formattedDate,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en');
    return '${formatter.format(amount)} AED';
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _getInitials(String text) {
    if (text.isEmpty) return 'P';
    final words = text.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return text.characters.take(2).toString().toUpperCase();
  }

  Color _getStatusColor(String status) {
    // Green for positive, Red for negative
    if (status.startsWith('+')) {
      return const Color(0xFF009859); // Green for positive
    }
    return const Color(0xFFBA1719); // Red for negative
  }

  String _formatDifferenceDays(int days) {
    if (days > 0) {
      return '+$days';
    } else if (days < 0) {
      return '$days';
    }
    return '0';
  }
}
