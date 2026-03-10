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

  // true only during the fast counters fetch; false once we know the categories
  bool _isLoading = true;
  // number of category detail requests still in-flight
  int _pendingCategories = 0;
  String _error = '';
  List<Map<String, dynamic>> _items = [];

  Future<void> _fetchDelayedRequests() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _items = [];
      _pendingCategories = 0;
    });

    try {
      // Step 1 – fast counters endpoint (~0.5 s) tells us which categories
      // have data so we don't waste a round-trip on empty ones.
      final counters = await _repository
          .fetchCounters()
          .timeout(const Duration(seconds: 15));

      final types = <String>[];
      if (counters.hrCount > 0) types.add('hr');
      if (counters.rfqCount > 0) types.add('rfq');
      if (counters.invoiceCount > 0) types.add('invoice');
      if (counters.pettyCashCount > 0) types.add('petty_cash');

      if (!mounted) return;
      setState(() {
        _isLoading = false; // hide full-screen spinner after counters
        _pendingCategories = types.length;
      });

      if (types.isEmpty) return;

      // Step 2 – fire one fetchDetails() per non-empty category in parallel.
      // HR (7 records) will appear almost immediately; Invoice (66) follows.
      await Future.wait(types.map((type) async {
        try {
          final resp = await _repository
              .fetchDetails(type)
              .timeout(const Duration(seconds: 30));
          final newItems = resp.toCardItems();
          if (!mounted) return;
          setState(() {
            final combined = [..._items, ...newItems];
            combined.sort((a, b) => (b['daysDelayed'] as int)
                .compareTo(a['daysDelayed'] as int));
            _items = combined;
            _pendingCategories = (_pendingCategories - 1).clamp(0, 99);
          });
        } catch (e) {
          debugPrint('⚠️ Failed to fetch $type delayed details: $e');
          if (!mounted) return;
          setState(() {
            _pendingCategories = (_pendingCategories - 1).clamp(0, 99);
          });
        }
      }));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _pendingCategories = 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDelayedRequests();
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
                SizedBox(height: 18.w),
                Center(
                  child: Text(
                    'DELAYED REQUESTS',
                    style: GoogleFonts.koulen(
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
    // Full-screen spinner: only during initial counters fetch
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

    // Still waiting for the first category to return data
    if (_items.isEmpty && _pendingCategories > 0) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0B2D5E)),
        ),
      );
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

