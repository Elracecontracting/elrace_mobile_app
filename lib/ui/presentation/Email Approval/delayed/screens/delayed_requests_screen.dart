import 'package:el_race/ui/presentation/Email%20Approval/delayed/data/delayed_approvals_repository.dart';
import 'package:el_race/ui/presentation/Email%20Approval/delayed/widgets/delayed_request_card.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
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
  static List<Map<String, dynamic>> _cachedItems = const [];
  static const int _batchSize = 200;

  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _items = [];

  Future<void> _fetchDelayedRequests() async {
    final hasCached = _cachedItems.isNotEmpty;
    if (mounted) {
      setState(() {
        _isLoading = !hasCached;
        _error = '';
        if (hasCached) {
          _items = List<Map<String, dynamic>>.from(_cachedItems);
        }
      });
    }

    try {
      final normalized = await _fetchAllItemsFromApi();
      normalized.sort(
        (a, b) => ((b['daysDelayed'] ?? 0) as num)
            .compareTo((a['daysDelayed'] ?? 0) as num),
      );

      if (!mounted) return;
      setState(() {
        _items = normalized;
        _cachedItems = List<Map<String, dynamic>>.from(normalized);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllItemsFromApi() async {
    final first = await _repository
        .fetchAllPage(page: 1, pageSize: _batchSize)
        .timeout(const Duration(seconds: 30));

    final combined = <Map<String, dynamic>>[
      ...first.data.toCardItems(),
    ];

    var nextPage = first.nextPage;
    var hasMore = first.hasMore;
    var safety = 0;

    while (hasMore && nextPage != null && safety < 20) {
      safety++;
      final page = await _repository
          .fetchAllPage(page: nextPage, pageSize: _batchSize)
          .timeout(const Duration(seconds: 30));

      final pageItems = page.data.toCardItems();
      if (pageItems.isEmpty) {
        break;
      }

      combined.addAll(pageItems);

      final previousNext = nextPage;
      nextPage = page.nextPage;
      hasMore = page.hasMore && nextPage != null && nextPage != previousNext;
    }

    return _dedupeByTypeAndId(combined);
  }

  List<Map<String, dynamic>> _dedupeByTypeAndId(
      List<Map<String, dynamic>> items) {
    final result = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final item in items) {
      final key =
          '${(item['type'] ?? '').toString()}_${(item['id'] ?? item['reqNo'] ?? '').toString()}';
      if (seen.add(key)) {
        result.add(item);
      }
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    _fetchDelayedRequests();
  }

  @override
  void dispose() => super.dispose();

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
                SizedBox(height: 18.w),
                Center(
                  child: Text(
                    'DELAYED REQUESTS',
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                SizedBox(height: 20.w),
              ],
            ),
          ),
          _buildSliverContent(),
        ],
      ),
    );
  }

  Widget _buildSliverContent() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0B2D5E)),
        ),
      );
    }

    if (_error.isNotEmpty && _items.isEmpty) {
      return _buildErrorSliver(_error, _fetchDelayedRequests);
    }

    if (_items.isEmpty) {
      return _buildEmptySliver();
    }

    return _buildItemsSliver(_items);
  }

  Widget _buildItemsSliver(List<Map<String, dynamic>> items) {
    final totalBottomPadding = kBottomNavigationBarHeight + 12.w;

    return SliverPadding(
      padding: EdgeInsets.only(top: 2.w, bottom: totalBottomPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return DelayedRequestCard(
              reqNo: item['reqNo'] ?? '',
              requestType: item['requestType'] ?? '',
              employeeName: item['employeeName'] ?? '',
              empCode: item['empCode'] ?? '',
              requestDate: item['requestDate'] ?? '',
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
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8.w),
            Text(
              'All requests are on track!',
              style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
