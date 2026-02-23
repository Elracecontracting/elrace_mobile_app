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

  // ── Counters state (loaded on init – very fast) ──────────────────────────
  bool _isLoadingCounters = true;
  String _counterError = '';
  DelayedCountersResponse? _counters;

  // ── Details state (loaded lazily per category on tap) ────────────────────
  /// api-type → list of normalized card maps
  final Map<String, List<Map<String, dynamic>>> _detailsCache = {};
  final Map<String, bool> _loadingDetails = {};
  final Map<String, String> _detailErrors = {};

  // ── UI state ─────────────────────────────────────────────────────────────
  String _selectedCategory = 'ALL';
  final List<String> _categories = [
    'ALL',
    'HR',
    'RFQ',
    'INVOICE',
    'PETTY CASH',
  ];

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _apiType(String category) {
    switch (category) {
      case 'HR':
        return 'hr';
      case 'RFQ':
        return 'rfq';
      case 'INVOICE':
        return 'invoice';
      case 'PETTY CASH':
        return 'petty_cash';
      default:
        return category.toLowerCase();
    }
  }

  int _getCategoryCount(String category) {
    if (_counters == null) return 0;
    switch (category) {
      case 'ALL':
        return _counters!.totalCount;
      case 'HR':
        return _counters!.hrCount;
      case 'RFQ':
        return _counters!.rfqCount;
      case 'INVOICE':
        return _counters!.invoiceCount;
      case 'PETTY CASH':
        return _counters!.pettyCashCount;
      default:
        return 0;
    }
  }

  // ── Network calls ─────────────────────────────────────────────────────────

  /// Step 1 – called on init. Fast counters-only request.
  Future<void> _fetchCounters() async {
    setState(() {
      _isLoadingCounters = true;
      _counterError = '';
    });
    try {
      final counters = await _repository.fetchCounters();
      setState(() {
        _counters = counters;
        _isLoadingCounters = false;
      });
    } catch (e) {
      setState(() {
        _counterError = e.toString();
        _isLoadingCounters = false;
      });
    }
  }

  /// Step 2 – called when the user taps a specific category tab.
  /// Uses the cache so the API is only hit once per category per screen session.
  Future<void> _loadDetailsIfNeeded(String type) async {
    if (_detailsCache.containsKey(type)) return; // already cached
    if (_loadingDetails[type] == true) return; // already in-flight

    setState(() {
      _loadingDetails[type] = true;
      _detailErrors.remove(type);
    });

    try {
      final response = await _repository.fetchDetails(type);
      setState(() {
        _detailsCache[type] = response.toCardItems();
        _loadingDetails[type] = false;
      });
    } catch (e) {
      setState(() {
        _detailErrors[type] = e.toString();
        _loadingDetails[type] = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Only fetch counters on open – fast and lightweight.
    _fetchCounters();
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
                _buildCategoryTabs(),
                SizedBox(height: 12.w),
              ],
            ),
          ),
          _buildSliverContent(),
        ],
      ),
    );
  }

  // ── Category tabs ─────────────────────────────────────────────────────────

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 44.w,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          final count = _getCategoryCount(category);

          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = category);
              if (category != 'ALL') {
                _loadDetailsIfNeeded(_apiType(category));
              }
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
                      color:
                          isSelected ? Colors.white : const Color(0xFF666666),
                    ),
                  ),
                  // Tiny spinner while counters are still loading
                  if (_isLoadingCounters && category == 'ALL') ...[
                    SizedBox(width: 6.w),
                    SizedBox(
                      width: 12.w,
                      height: 12.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            isSelected ? Colors.white : const Color(0xFF0B2D5E),
                      ),
                    ),
                  ] else if (count > 0) ...[
                    SizedBox(width: 6.w),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
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
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFB91C1C),
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

  // ── Content area ──────────────────────────────────────────────────────────

  Widget _buildSliverContent() {
    if (_isLoadingCounters) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0B2D5E)),
        ),
      );
    }

    if (_counterError.isNotEmpty) {
      return _buildErrorSliver(_counterError, _fetchCounters);
    }

    if (_selectedCategory == 'ALL') {
      return _buildAllSummarySliver();
    }

    final type = _apiType(_selectedCategory);
    final isLoadingDetails = _loadingDetails[type] == true;
    final detailError = _detailErrors[type];
    final items = _detailsCache[type];

    if (isLoadingDetails) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0B2D5E)),
        ),
      );
    }

    if (detailError != null) {
      return _buildErrorSliver(detailError, () => _loadDetailsIfNeeded(type));
    }

    if (items == null) {
      // Guard – details not yet requested
      return SliverFillRemaining(
        child: Center(
          child: TextButton(
            onPressed: () => _loadDetailsIfNeeded(type),
            child: Text(
              'Load $_selectedCategory requests',
              style: GoogleFonts.nunito(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0B2D5E),
              ),
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) return _buildEmptySliver();

    return _buildItemsSliver(items);
  }

  /// ALL tab: summary cards with counts – tap to drill into a category
  Widget _buildAllSummarySliver() {
    if (_counters == null || _counters!.totalCount == 0) {
      return _buildEmptySliver();
    }

    final summaryItems = [
      {'label': 'HR', 'count': _counters!.hrCount, 'category': 'HR'},
      {'label': 'RFQ', 'count': _counters!.rfqCount, 'category': 'RFQ'},
      {
        'label': 'INVOICE',
        'count': _counters!.invoiceCount,
        'category': 'INVOICE'
      },
      {
        'label': 'PETTY CASH',
        'count': _counters!.pettyCashCount,
        'category': 'PETTY CASH'
      },
    ].where((e) => (e['count'] as int) > 0).toList();

    if (summaryItems.isEmpty) return _buildEmptySliver();

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
          16.w, 8.w, 16.w, kBottomNavigationBarHeight + 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final entry = summaryItems[index];
            final label = entry['label'] as String;
            final count = entry['count'] as int;
            final category = entry['category'] as String;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = category);
                _loadDetailsIfNeeded(_apiType(category));
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 12.w),
                padding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFE4E8EF)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.koulen(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2540),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 6.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB91C1C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '$count delayed',
                        style: GoogleFonts.nunito(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    const Icon(Icons.chevron_right,
                        color: Color(0xFF0B2D5E)),
                  ],
                ),
              ),
            );
          },
          childCount: summaryItems.length,
        ),
      ),
    );
  }

  Widget _buildItemsSliver(List<Map<String, dynamic>> items) {
    final totalBottomPadding =
        kBottomNavigationBarHeight + context.systemBottomInset + 16;

    return SliverPadding(
      padding: EdgeInsets.only(top: 8.w, bottom: totalBottomPadding),
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

  Widget _buildEmptySliver() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64.w, color: Colors.green[400]),
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

  Widget _buildErrorSliver(String error, VoidCallback onRetry) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.w, color: Colors.red[400]),
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
              onPressed: onRetry,
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
}

