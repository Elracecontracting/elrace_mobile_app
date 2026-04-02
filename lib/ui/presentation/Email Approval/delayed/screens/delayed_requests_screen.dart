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
  final ScrollController _scrollController = ScrollController();

  static const int _pageSize = 20;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int? _nextPage = 2;
  String _error = '';
  List<Map<String, dynamic>> _items = [];

  Future<void> _fetchDelayedRequests() async {
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _currentPage = 1;
      _nextPage = 2;
      _error = '';
      _items = [];
    });

    try {
      final firstPage = await _repository
          .fetchAllPage(page: 1, pageSize: _pageSize)
          .timeout(const Duration(seconds: 30));

      final normalized = firstPage.data.toCardItems();
      final merged = _mergeUniqueByTypeAndId([], normalized);

      if (!mounted) return;
      setState(() {
        _items = merged;
        _isLoading = false;
        _currentPage = firstPage.currentPage;
        _nextPage = firstPage.nextPage;
        _hasMore = firstPage.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _hasMore = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    final pageToLoad = _nextPage ?? (_currentPage + 1);
    if (pageToLoad <= _currentPage) return;

    setState(() => _isLoadingMore = true);
    try {
      final page = await _repository
          .fetchAllPage(page: pageToLoad, pageSize: _pageSize)
          .timeout(const Duration(seconds: 30));

      final newItems = page.data.toCardItems();
      if (!mounted) return;

      setState(() {
        _items = _mergeUniqueByTypeAndId(_items, newItems);
        _currentPage = page.currentPage;
        _nextPage = page.nextPage;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('⚠️ Failed loading delayed approvals page $pageToLoad: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  List<Map<String, dynamic>> _mergeUniqueByTypeAndId(
    List<Map<String, dynamic>> base,
    List<Map<String, dynamic>> incoming,
  ) {
    final result = List<Map<String, dynamic>>.from(base);
    final seen = <String>{
      for (final item in base)
        '${(item['type'] ?? '').toString()}_${(item['id'] ?? item['reqNo'] ?? '').toString()}'
    };

    for (final item in incoming) {
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
    _scrollController.addListener(_onScroll);
    _fetchDelayedRequests();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
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
            if (index >= items.length) {
              if (_isLoadingMore) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0B2D5E)),
                  ),
                );
              }
              return const SizedBox.shrink();
            }

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
          childCount: items.length + ((_hasMore || _isLoadingMore) ? 1 : 0),
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
