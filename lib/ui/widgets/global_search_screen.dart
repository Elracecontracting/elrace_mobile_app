import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:el_race/data/models/global_search_item.dart';
import 'package:el_race/providers/global_search_provider.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/utils/global_search_navigation_helper.dart';
import 'package:el_race/ui/widgets/header_widget.dart';

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
    return ChangeNotifierProvider(
      create: (_) => GlobalSearchProvider(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const HeaderWidget(),
        body: Column(
          children: [
            _buildSearchBar(),
            _buildCategorySelector(),
            Expanded(child: _buildSearchResults()),
          ],
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

        // Loading state
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(appFontColor),
            ),
          );
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
              provider.results[index],
              provider.currentKeyword,
            );
          },
        );
      },
    );
  }

  /// Build individual search result item
  Widget _buildResultItem(GlobalSearchItem item, String keyword) {
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
}
