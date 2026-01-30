import 'package:el_race/ui/presentation/Email%20Approval/delayed/data/delayed_approvals_repository.dart';
import 'package:el_race/ui/presentation/Email%20Approval/delayed/models/delayed_approval_model.dart';
import 'package:el_race/ui/presentation/Email%20Approval/delayed/widgets/delayed_request_card.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/safe_insets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class DelayedRequestsScreen extends StatefulWidget {
  const DelayedRequestsScreen({super.key});

  @override
  State<DelayedRequestsScreen> createState() => _DelayedRequestsScreenState();
}

class _DelayedRequestsScreenState extends State<DelayedRequestsScreen> {
  final DelayedApprovalsRepository _repository = DelayedApprovalsRepository();

  bool _isLoading = true;
  String _error = '';
  DelayedApprovalsResponse? _data;

  // Category filter
  String _selectedCategory = 'ALL';
  final List<String> _categories = ['ALL', 'HR', 'RFQ', 'INVOICE', 'PETTY CASH'];

  @override
  void initState() {
    super.initState();
    _fetchDelayedApprovals();
  }

  Future<void> _fetchDelayedApprovals() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final data = await _repository.fetchDelayedApprovals();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredItems() {
    if (_data == null) return [];

    List<Map<String, dynamic>> items = [];

    // HR items
    if (_selectedCategory == 'ALL' || _selectedCategory == 'HR') {
      for (final item in _data!.hrItems) {
        items.add({
          'type': 'HR',
          'id': item.id,
          'reqNo': item.name,
          'requestType': item.requestType,
          'employeeName': item.validatorName,
          'empCode': item.validatorEmpId,
          'employeeImageUrl': item.validatorImage,
          'daysDelayed': item.daysDelayed,
        });
      }
    }

    // RFQ items
    if (_selectedCategory == 'ALL' || _selectedCategory == 'RFQ') {
      for (final item in _data!.rfqItems) {
        items.add({
          'type': 'RFQ',
          'id': item.id,
          'reqNo': item.name,
          'requestType': item.project,
          'employeeName': item.reviewerName,
          'empCode': item.reviewerEmpId,
          'employeeImageUrl': item.reviewerImage,
          'daysDelayed': item.daysDelayed,
        });
      }
    }

    // Invoice items
    if (_selectedCategory == 'ALL' || _selectedCategory == 'INVOICE') {
      for (final item in _data!.invoiceItems) {
        items.add({
          'type': 'INVOICE',
          'id': item.id,
          'reqNo': item.name,
          'requestType': item.project,
          'employeeName': item.reviewerName,
          'empCode': item.reviewerEmpId,
          'employeeImageUrl': item.reviewerImage,
          'daysDelayed': item.daysDelayed,
        });
      }
    }

    // Petty Cash items
    if (_selectedCategory == 'ALL' || _selectedCategory == 'PETTY CASH') {
      for (final item in _data!.pettyCashItems) {
        items.add({
          'type': 'PETTY CASH',
          'id': item.id,
          'reqNo': item.name,
          'requestType': item.project,
          'employeeName': item.reviewerName,
          'empCode': item.reviewerEmpId,
          'employeeImageUrl': item.reviewerImage,
          'daysDelayed': item.daysDelayed,
        });
      }
    }

    return items;
  }

  int _getCategoryCount(String category) {
    if (_data == null) return 0;

    switch (category) {
      case 'ALL':
        return _data!.totalCount;
      case 'HR':
        return _data!.hrItems.length;
      case 'RFQ':
        return _data!.rfqItems.length;
      case 'INVOICE':
        return _data!.invoiceItems.length;
      case 'PETTY CASH':
        return _data!.pettyCashItems.length;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: false,
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            automaticallyImplyLeading: false,
            flexibleSpace: HeaderWidget(),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: 12.w),
                // Title
                Center(
                  child: Text(
                    'DELAYED REQUESTS',
                    style: GoogleFonts.koulen(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 16.w),
                // Category tabs
                _buildCategoryTabs(),
                SizedBox(height: 12.w),
              ],
            ),
          ),
          // Content
          _buildSliverContent(),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 44.w,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          final count = _getCategoryCount(category);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0B2D5E)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0B2D5E)
                      : const Color(0xFFE0E0E0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category,
                    style: GoogleFonts.nunito(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF666666),
                    ),
                  ),
                  if (count > 0) ...[
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFFB91C1C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        count.toString(),
                        style: GoogleFonts.nunito(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverContent() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0B2D5E),
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48.w,
                color: Colors.red[400],
              ),
              SizedBox(height: 16.w),
              Text(
                'Failed to load delayed requests',
                style: GoogleFonts.nunito(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8.w),
              TextButton(
                onPressed: _fetchDelayedApprovals,
                child: Text(
                  'Retry',
                  style: GoogleFonts.nunito(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B2D5E),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = _getFilteredItems();

    if (items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64.w,
                color: Colors.green[400],
              ),
              SizedBox(height: 16.w),
              Text(
                'No delayed requests',
                style: GoogleFonts.nunito(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8.w),
              Text(
                'All requests are on track!',
                style: GoogleFonts.nunito(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalBottomPadding =
        kBottomNavigationBarHeight + context.systemBottomInset + 16;

    return SliverPadding(
      padding: EdgeInsets.only(
        top: 8.w,
        bottom: totalBottomPadding,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return DelayedRequestCard(
              reqNo: item['reqNo'] ?? '',
              requestType: item['requestType'] ?? '',
              employeeName: item['employeeName'] ?? '',
              empCode: item['empCode'] ?? '',
              employeeImageUrl: item['employeeImageUrl'] ?? '',
              daysDelayed: item['daysDelayed'] ?? 0,
              onTap: () {
                // TODO: Navigate to detail screen if needed
              },
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}
