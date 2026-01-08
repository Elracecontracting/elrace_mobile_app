import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:el_race/data/models/global_search_item.dart';
import 'package:el_race/providers/global_search_provider.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/utils/global_search_navigation_helper.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/ui/presentation/lpo/widgets/lpo_card_widget.dart';
import 'package:el_race/ui/presentation/my_projects/domain/entities/project_entity.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/widgets/project_card_widget.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/bloc/project_list_bloc.dart';
import 'package:el_race/ui/presentation/my_projects/data/repositories/project_repository_impl.dart';
import 'package:el_race/ui/presentation/my_projects/data/datasources/project_remote_datasource.dart';
import 'package:el_race/ui/presentation/my_projects/domain/usecases/get_projects_usecase.dart';
import 'package:el_race/ui/presentation/my_projects/domain/usecases/get_projects_by_partner_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Global Search Screen Widget
///
/// Features:
/// - Debounced search (400ms)
/// - Category selection
/// - Loading, empty, and error states
/// - Keyword highlighting
/// - Navigation to detail screens
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'lpo';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final remoteDataSource = ProjectRemoteDataSource();
        final repository = ProjectRepositoryImpl(remoteDataSource);
        return ProjectListBloc(
          getProjectsUseCase: GetProjectsUseCase(repository: repository),
          getProjectAttachmentsUseCase:
              GetProjectAttachmentsUseCase(repository: repository),
          getProjectsByPartnerUseCase:
              GetProjectsByPartnerUseCase(repository: repository),
        );
      },
      child: ChangeNotifierProvider(
        create: (_) => GlobalSearchProvider(),
        child: Builder(
          builder: (context) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: const HeaderWidget(),
              body: Column(
                children: [
                  _buildSearchBar(),
                  _buildCategorySelector(),
                  Expanded(child: _buildSearchResults()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Search bar with clear button
  Widget _buildSearchBar() {
    return Consumer<GlobalSearchProvider>(
      builder: (context, provider, _) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              provider.search(
                category: _selectedCategory,
                keyword: value,
                limit: 20,
              );
            },
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: () {
                        _searchController.clear();
                        provider.clearResults();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
        );
      },
    );
  }

  /// Category selector chips
  Widget _buildCategorySelector() {
    final categories = [
      {'value': 'lpo', 'label': 'LPO', 'icon': Icons.description},
      {'value': 'petty_cash', 'label': 'Petty Cash', 'icon': Icons.receipt},
      {'value': 'projects', 'label': 'My Projects', 'icon': Icons.work},
    ];

    return Container(
      height: 50.h,
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['value'];

          return Consumer<GlobalSearchProvider>(
            builder: (context, provider, _) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                child: ChoiceChip(
                  label: Text(category['label'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = category['value'] as String;
                      });

                      // Re-trigger search if there's text
                      if (_searchController.text.trim().length >= 2) {
                        provider.search(
                          category: _selectedCategory,
                          keyword: _searchController.text,
                          limit: 20,
                        );
                      }
                    }
                  },
                  selectedColor: appFontColor,
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : appFontColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  showCheckmark: false,
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Build search results based on state
  Widget _buildSearchResults() {
    return Consumer<GlobalSearchProvider>(
      builder: (context, provider, _) {
        // Idle state
        if (provider.state == GlobalSearchState.idle) {
          return _buildEmptyState(
            icon: Icons.search,
            title: 'Start Searching',
            message: 'Enter at least 2 characters to search',
          );
        }

        // Loading state - Show skeleton loaders
        if (provider.isLoading) {
          return _buildSkeletonLoader();
        }

        // Error state
        if (provider.hasError) {
          return _buildErrorState(
            message: provider.errorMessage ?? 'An error occurred',
            onRetry: () => provider.retry(),
          );
        }

        // Empty state
        if (provider.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off,
            title: 'No Results Found',
            message: 'Try adjusting your search keywords',
          );
        }

        // Results
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          itemCount: provider.results.length,
          itemBuilder: (context, index) {
            return _buildResultItem(
              context,
              provider.results[index],
              provider.currentKeyword,
            );
          },
        );
      },
    );
  }

  /// Build skeleton loader for petty cash cards
  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: 5,
      itemBuilder: (context, index) {
        if (_selectedCategory == 'petty_cash') {
          return _buildPettyCashSkeleton();
        } else if (_selectedCategory == 'lpo') {
          return _buildLpoSkeleton();
        } else {
          return _buildGenericSkeleton();
        }
      },
    );
  }

  /// Petty Cash skeleton loader
  Widget _buildPettyCashSkeleton() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.h, horizontal: 5.w),
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 8, 15, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildShimmerBox(width: 60.w, height: 20.h),
            const SizedBox(width: 15),
            const SizedBox(
              height: 30,
              child: VerticalDivider(color: Colors.grey, thickness: 2),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildShimmerBox(width: 50.w, height: 15.h),
                  SizedBox(height: 4.h),
                  _buildShimmerBox(width: 70.w, height: 15.h),
                ],
              ),
            ),
            const SizedBox(
              height: 30,
              child: VerticalDivider(color: Colors.grey, thickness: 2),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildShimmerBox(width: 50.w, height: 15.h),
                  SizedBox(height: 4.h),
                  _buildShimmerBox(width: 70.w, height: 15.h),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildShimmerBox(width: 20.w, height: 20.h, isCircle: true),
          ],
        ),
      ),
    );
  }

  /// LPO skeleton loader
  Widget _buildLpoSkeleton() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.h, horizontal: 5.w),
      padding: EdgeInsets.all(12.w),
      height: 120.h,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmerBox(width: 60.w, height: 20.h),
              const Spacer(),
              _buildShimmerBox(width: 40.w, height: 40.h, isCircle: true),
            ],
          ),
          SizedBox(height: 8.h),
          _buildShimmerBox(width: 150.w, height: 15.h),
          SizedBox(height: 4.h),
          _buildShimmerBox(width: 200.w, height: 15.h),
          const Spacer(),
          Row(
            children: [
              _buildShimmerBox(width: 80.w, height: 15.h),
              const Spacer(),
              _buildShimmerBox(width: 60.w, height: 15.h),
            ],
          ),
        ],
      ),
    );
  }

  /// Generic skeleton loader
  Widget _buildGenericSkeleton() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.h, horizontal: 5.w),
      padding: EdgeInsets.all(12.w),
      height: 100.h,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          _buildShimmerBox(width: 48.w, height: 48.h),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildShimmerBox(width: 150.w, height: 15.h),
                SizedBox(height: 8.h),
                _buildShimmerBox(width: 200.w, height: 12.h),
                SizedBox(height: 8.h),
                _buildShimmerBox(width: 80.w, height: 12.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer box widget
  Widget _buildShimmerBox({
    required double width,
    required double height,
    bool isCircle = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: isCircle ? null : BorderRadius.circular(4.r),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }

  /// Build individual search result item
  Widget _buildResultItem(
      BuildContext context, GlobalSearchItem item, String keyword) {
    // Use specific widgets for each category
    if (item.category == 'lpo') {
      return InkWell(
        onTap: () => _navigateToDetail(item),
        child: _buildLpoCard(item),
      );
    } else if (item.category == 'projects') {
      return InkWell(
        onTap: () => _navigateToDetail(item),
        child: _buildProjectCard(context, item),
      );
    } else if (item.category == 'petty_cash') {
      return InkWell(
        onTap: () => _navigateToDetail(item),
        child: _buildPettyCashCard(item),
      );
    }

    // Fallback to generic card for other categories
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(item),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: _getCategoryColor(item.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  _getCategoryIcon(item.category),
                  color: _getCategoryColor(item.category),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with highlighting
                    _buildHighlightedText(
                      item.title,
                      keyword,
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: appFontColor,
                      ),
                    ),

                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        item.subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    SizedBox(height: 6.h),

                    // Category badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _getCategoryColor(item.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        item.displayCategory,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: _getCategoryColor(item.category),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build highlighted text with keyword emphasis
  Widget _buildHighlightedText(
    String text,
    String keyword, {
    required TextStyle style,
  }) {
    if (keyword.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    final spans = <TextSpan>[];

    int start = 0;
    int indexOfKeyword;

    while ((indexOfKeyword = lowerText.indexOf(lowerKeyword, start)) != -1) {
      // Add text before keyword
      if (indexOfKeyword > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfKeyword)));
      }

      // Add highlighted keyword
      spans.add(TextSpan(
        text: text.substring(indexOfKeyword, indexOfKeyword + keyword.length),
        style: style.copyWith(
          backgroundColor: Colors.yellow.withOpacity(0.3),
          fontWeight: FontWeight.w700,
        ),
      ));

      start = indexOfKeyword + keyword.length;
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80.sp, color: Colors.grey[300]),
            SizedBox(height: 16.h),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Error state widget with retry
  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80.sp, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'Oops!',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: appFontColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get category icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'petty_cash':
        return Icons.receipt;
      case 'projects':
        return Icons.work;
      case 'lpo':
        return Icons.description;
      case 'notes':
        return Icons.note;
      case 'documents':
        return Icons.folder;
      case 'tasks':
        return Icons.task;
      default:
        return Icons.search;
    }
  }

  /// Get category color
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'petty_cash':
        return Colors.green;
      case 'projects':
        return Colors.blue;
      case 'lpo':
        return Colors.orange;
      case 'notes':
        return Colors.purple;
      case 'documents':
        return Colors.teal;
      case 'tasks':
        return appFontColor;
      default:
        return Colors.grey;
    }
  }

  /// Navigate to detail screen based on category
  void _navigateToDetail(GlobalSearchItem item) {
    GlobalSearchNavigationHelper.navigateToDetail(context, item);
  }

  // Build LPO Card
  Widget _buildLpoCard(GlobalSearchItem item) {
    final data = item.additionalData ?? {};

    String? _pickVendor() {
      final partner = data['partner_id'];
      if (partner is List && partner.length > 1) return partner[1]?.toString();
      if (partner != null) return partner.toString();
      return data['vendor_name'] ??
          data['partner_name'] ??
          data['vendor'] ??
          data['supplier'] ??
          data['supplier_name'] ??
          item.subtitle;
    }

    String? _pickProject() {
      final xProject = data['x_project_id'];
      if (xProject is List && xProject.length > 1)
        return xProject[1]?.toString();
      if (xProject != null) return xProject.toString();
      final projectId = data['project_id'];
      if (projectId is List && projectId.length > 1)
        return projectId[1]?.toString();
      if (projectId != null) return projectId.toString();
      return data['project_name'] ??
          data['project'] ??
          data['project_description'] ??
          data['analytic_account_id']?[1] ??
          data['analytic_account_id']?.toString();
    }

    String? _pickAmount() {
      final amountCandidates = [
        data['amount_total'],
        data['total_amount'],
        data['amount_untaxed'],
        data['amount'],
        data['amount_total_signed'],
        data['amount'],
        data['balance_due'],
      ];
      final first = amountCandidates.firstWhere(
        (v) => v != null,
        orElse: () => null,
      );
      return first?.toString();
    }

    String? _pickDate() {
      return data['date_order'] ??
          data['order_date'] ??
          data['commitment_date'] ??
          data['expected_date'] ??
          data['date'] ??
          data['create_date'];
    }

    return LpoCardWidget(
      name: data['name'] ?? item.title,
      vendorName: _pickVendor(),
      projectName: _pickProject(),
      date: _pickDate(),
      amount: _pickAmount(),
      attachments: (data['attachments'] as List?) ?? const [],
      lpoCount: data['lpo_count'],
      clientPhoto: data['partner_photo'] ?? data['client_photo'],
      requestedByUserPhoto: data['requested_by_user_photo'],
      requestedBy: data['requested_by'],
      requesterManager: data['requester_manager'],
      state: data['state'] ?? data['status'],
    );
  }

  // Build Project Card
  Widget _buildProjectCard(BuildContext context, GlobalSearchItem item) {
    final data = item.additionalData ?? {};

    final project = ProjectEntity(
      projectId: item.id,
      partnerId: data['partner_id']?[0]?.toString() ??
          data['partner_id']?.toString() ??
          '',
      name: item.title,
      agreementId: data['agreement_id'] ??
          data['analytic_account_id']?[1] ??
          data['analytic_account_id']?.toString() ??
          '',
      woRefNo: data['wo_ref_no'] ?? item.title,
      woAmount: double.tryParse(data['wo_amount']?.toString() ??
              data['amount']?.toString() ??
              '0') ??
          0.0,
      projectStatus: data['project_status'] ?? data['stage_id']?[1] ?? 'Active',
      date: data['date'] ?? DateTime.now().toString(),
      dateStart:
          data['date_start'] ?? data['date'] ?? DateTime.now().toString(),
      projectManagerPhoto: data['project_manager_photo'],
      differenceDays:
          int.tryParse(data['difference_days']?.toString() ?? '0') ?? 0,
    );

    final bloc = context.read<ProjectListBloc>();
    return ProjectCardWidget(item: project, bloc: bloc);
  }

  // Build Petty Cash Card
  Widget _buildPettyCashCard(GlobalSearchItem item) {
    final data = item.additionalData ?? {};
    final status = (data['state'] ?? data['status'])?.toString().toUpperCase();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.h, horizontal: 5.w),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/png/item_bg_green.png'),
          fit: BoxFit.cover,
        ),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).toInt()),
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            // Title/Name section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title.isNotEmpty ? item.title : 'N/A',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: appFontColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (status != null && status.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12.w),
            // Check mark icon
            const CircleAvatar(
              radius: 12,
              backgroundImage: AssetImage('assets/png/tick-petty.png'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.orange;
      case 'approved':
      case 'done':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return appFontColor;
    }
  }

  String _formatPettyCashDate(String date) {
    if (date.isEmpty) return '--';
    try {
      final dt = DateTime.parse(date);
      return DateFormat('dd/MM/yy').format(dt);
    } catch (_) {
      return date;
    }
  }
}
