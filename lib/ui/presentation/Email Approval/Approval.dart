import 'dart:convert';
import 'dart:ui';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/Email%20Approval/delayed/data/delayed_approvals_repository.dart';
import 'package:el_race/ui/presentation/Email%20Approval/delayed/screens/delayed_requests_screen.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/all_approvals_overview.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/hr_and_pettycash_card.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/invoice_and_rfq_card.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import '../../widgets/header_widget.dart';
import '../home_screen/screens/main_screens.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  String selectedCategoryKey = _CategoryKeys.all;
  TextEditingController searchController = TextEditingController();
  final ScrollController _tabScrollController = ScrollController();
  List<dynamic> hrItems = [];
  List<dynamic> rfqItems = [];
  List<dynamic> invoiceItems = [];
  List<dynamic> pettyCashItems = [];
  List<dynamic> allItems = [];
  List<dynamic> approvalItems = [];
  String error = '';

  // Per-category loading/loaded/error state — no full-screen blocking loader
  final Map<String, bool> _categoryLoading = {};
  final Map<String, bool> _categoryLoaded = {};
  Map<String, String> categoryErrors = {};

  // Delayed requests count from API
  int delayedCount = 0;
  bool _delayedLoading = false;
  final DelayedApprovalsRepository _delayedRepo = DelayedApprovalsRepository();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    selectedCategoryKey = categoryKeys.first;
    searchController.addListener(_onSearchChanged);
    // Show the screen immediately — load all categories in background in parallel.
    // Delayed count is also fired in background.
    _loadAllCategoriesInBackground();
    _fetchDelayedCount();
  }

  @override
  void dispose() {
    searchController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedTab(int index) {
    if (_tabScrollController.hasClients) {
      // Calculate the position based on tab width + padding
      final double tabWidth =
          90 + 9; // 90w for width + 5 right padding + 4 margin
      final double screenWidth = MediaQuery.of(context).size.width;
      final double targetPosition =
          (index * tabWidth) - (screenWidth / 2) + (tabWidth / 2);

      _tabScrollController.animateTo(
        targetPosition.clamp(
            0.0, _tabScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSearchChanged() {
    setState(() {
      approvalItems = _getFilteredItems();
    });
  }

  List<dynamic> _getFilteredItems() {
    final allFiltered = _getApprovalListForSelectedCategory();
    if (searchController.text.isEmpty) {
      return allFiltered;
    }

    final searchLower = searchController.text.toLowerCase();
    return allFiltered.where((item) {
      final name = item["name"]?.toString().toLowerCase() ?? "";
      final requestNo = item["request_no"]?.toString().toLowerCase() ?? "";
      final reqNo = item["req_no"]?.toString().toLowerCase() ?? "";
      final title = item["title"]?.toString().toLowerCase() ?? "";
      final employeeName =
          item["employee_name"]?.toString().toLowerCase() ?? "";
      final vendor = item["vendor"]?.toString().toLowerCase() ?? "";

      return name.contains(searchLower) ||
          requestNo.contains(searchLower) ||
          reqNo.contains(searchLower) ||
          title.contains(searchLower) ||
          employeeName.contains(searchLower) ||
          vendor.contains(searchLower);
    }).toList();
  }

  Future<List<dynamic>> _fetchCategoryData(String groupType) async {
    final token = SharedPref.getLoginData().result?.token;

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final url = Uri.parse("https://erp.elrace.com/api/my_approvals_grouped");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {"group_type": groupType},
    });

    final request = http.Request('GET', url)
      ..headers.addAll(headers)
      ..body = body;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('[$groupType] status=${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      const Map<String, String> responseKeys = {
        "hr": "human_resources",
        "rfq": "rfq",
        "invoice": "invoices",
        "petty_cash": "petty_cash",
      };
      final actualKey = responseKeys[groupType] ?? groupType;
      return data['result']['data'][actualKey] ?? [];
    } else {
      throw Exception("Failed to fetch $groupType: ${response.statusCode}");
    }
  }

  /// Loads a single category in the background and updates state when done.
  Future<void> _loadCategory(String categoryKey) async {
    if (_categoryLoading[categoryKey] == true) return; // already in-flight
    if (_categoryLoaded[categoryKey] == true) return;  // already done

    setState(() => _categoryLoading[categoryKey] = true);

    try {
      final items = await _fetchCategoryData(categoryKey);
      if (!mounted) return;
      setState(() {
        switch (categoryKey) {
          case 'hr':
            hrItems = items.map((i) => {...i, 'category': 'HR'}).toList();
          case 'rfq':
            rfqItems = items.map((i) => {...i, 'category': 'RFQ'}).toList();
          case 'invoice':
            invoiceItems = items.map((i) => {...i, 'category': 'INVOICE'}).toList();
          case 'petty_cash':
            pettyCashItems = items.map((i) => {...i, 'category': 'PETTY CASH'}).toList();
        }
        allItems = [...hrItems, ...rfqItems, ...invoiceItems, ...pettyCashItems];
        approvalItems = _getFilteredItems();
        _categoryLoading[categoryKey] = false;
        _categoryLoaded[categoryKey] = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        categoryErrors[categoryKey] = e.toString();
        _categoryLoading[categoryKey] = false;
      });
    }
  }

  /// Fires all 4 categories in parallel without blocking the UI.
  void _loadAllCategoriesInBackground() {
    _loadCategory('hr');
    _loadCategory('rfq');
    _loadCategory('invoice');
    _loadCategory('petty_cash');
  }

  List<dynamic> _getApprovalListForSelectedCategory() {
    switch (selectedCategoryKey) {
      case _CategoryKeys.hr:
        return hrItems;
      case _CategoryKeys.rfq:
        return rfqItems;
      case _CategoryKeys.invoice:
        return invoiceItems;
      case _CategoryKeys.pettyCash:
        return pettyCashItems;
      case _CategoryKeys.all:
      default:
        return allItems;
    }
  }

  int _getCategoryCount(String categoryKey) {
    switch (categoryKey) {
      case _CategoryKeys.all:
        return allItems.length;
      case _CategoryKeys.hr:
        return hrItems.length;
      case _CategoryKeys.rfq:
        return rfqItems.length;
      case _CategoryKeys.invoice:
        return invoiceItems.length;
      case _CategoryKeys.pettyCash:
        return pettyCashItems.length;
      default:
        return 0;
    }
  }

  Future<void> _fetchDelayedCount() async {
    setState(() => _delayedLoading = true);
    try {
      final counters = await _delayedRepo.fetchCounters();
      if (!mounted) return;
      setState(() {
        delayedCount = counters.totalCount;
        _delayedLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to fetch delayed count: $e');
      if (!mounted) return;
      setState(() => _delayedLoading = false);
    }
  }

  String _tabTitleFor(String categoryKey) {
    switch (categoryKey) {
      case _CategoryKeys.all:
        return 'ALL';
      case _CategoryKeys.hr:
        return 'HR';
      case _CategoryKeys.rfq:
        return 'RFQ';
      case _CategoryKeys.invoice:
        return 'INVOICE';
      case _CategoryKeys.pettyCash:
        return 'PETTY CASH';
      default:
        return categoryKey;
    }
  }

  String _iconFor(String categoryKey) {
    switch (categoryKey) {
      case _CategoryKeys.all:
        return "assets/png/all-icon.png";
      case _CategoryKeys.hr:
        return "assets/png/hr-icon.png";
      case _CategoryKeys.rfq:
        return "assets/png/rfq-icon.png";
      case _CategoryKeys.invoice:
        return "assets/png/invoice-icon.png";
      case _CategoryKeys.pettyCash:
        return "assets/png/petty-cash-icon.png";
      default:
        return "assets/icons/default.png";
    }
  }

  final List<String> categoryKeys = const [
    _CategoryKeys.all,
    _CategoryKeys.hr,
    _CategoryKeys.rfq,
    _CategoryKeys.invoice,
    _CategoryKeys.pettyCash,
  ];
  bool isSearch = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      extendBody: true,
      body: Stack(
        children: [
          // Main content - starts from top and scrolls behind tabs
          NotificationListener<ScrollNotification>(
            onNotification: (scrollNotification) {
              if (scrollNotification is ScrollUpdateNotification ||
                  scrollNotification is ScrollEndNotification) {
                final isScrolled = scrollNotification.metrics.pixels > 10;
                if (isScrolled != _isScrolled) {
                  setState(() {
                    _isScrolled = isScrolled;
                  });
                }
              }
              return false;
            },
            child: Column(
              children: [
                body(),
              ],
            ),
          ),
          // iOS-style translucent tabs bar - fixed position, content scrolls behind it
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _isScrolled ? 5.0 : 0.0,
                  sigmaY: _isScrolled ? 5.0 : 0.0,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isScrolled
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: _isScrolled
                            ? Colors.grey.withOpacity(0.3)
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: _tabScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    child: Row(
                      children: categoryKeys.asMap().entries.map((entry) {
                        int index = entry.key;
                        String categoryKey = entry.value;
                        bool isSelected = selectedCategoryKey == categoryKey;
                        return Container(
                          margin: const EdgeInsets.only(right: 20.0, left: 5.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategoryKey = categoryKey;
                                approvalItems = _getFilteredItems();
                                _isScrolled = false;
                              });
                              _scrollToSelectedTab(index);
                              // Trigger category load on tap (no-op if already loading/loaded)
                              if (categoryKey != _CategoryKeys.all) {
                                _loadCategory(_categoryApiKey(categoryKey));
                              }
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && _isScrolled) {
                                  setState(() { _isScrolled = false; });
                                }
                              });
                            },
                            child: _buildGlassTab(
                              icon: _iconFor(categoryKey),
                              title: _tabTitleFor(categoryKey),
                              isSelected: isSelected,
                              count: 0,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Floating bottom navigation bar
        ],
      ),
    );
  }

  body() {
    // ALL tab: show instantly with live-updating counts as categories load in background
    if (selectedCategoryKey == _CategoryKeys.all) {
      return AllApprovalsOverview(
        invoiceCount: invoiceItems.length,
        pettyCashCount: pettyCashItems.length,
        rfqCount: rfqItems.length,
        hrCount: hrItems.length,
        delayedCount: delayedCount,
        onDelayedTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DelayedRequestsScreen(),
            ),
          );
        },
      );
    }

    // For specific category tabs: show spinner only while that category is loading
    final apiKey = _categoryApiKey(selectedCategoryKey);
    final isLoadingCategory = _categoryLoading[apiKey] == true;
    final hasError = categoryErrors.containsKey(apiKey);

    if (isLoadingCategory) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(categoryErrors[apiKey]!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _loadCategory(apiKey),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (selectedCategoryKey == _CategoryKeys.hr ||
        selectedCategoryKey == _CategoryKeys.pettyCash) {
      return HrAndPettycashCard(
        approvalItems: approvalItems,
        categoryType: selectedCategoryKey,
      );
    } else if (selectedCategoryKey == _CategoryKeys.rfq ||
        selectedCategoryKey == _CategoryKeys.invoice) {
      return InvoiceAndRfqCard(
        approvalItems: approvalItems,
        categoryType: selectedCategoryKey,
      );
    }

    return const SizedBox.shrink();
  }

  /// Maps a category UI key to the API group_type string.
  String _categoryApiKey(String categoryKey) {
    switch (categoryKey) {
      case _CategoryKeys.hr: return 'hr';
      case _CategoryKeys.rfq: return 'rfq';
      case _CategoryKeys.invoice: return 'invoice';
      case _CategoryKeys.pettyCash: return 'petty_cash';
      default: return categoryKey;
    }
  }

  Widget _buildGlassTab({
    required String icon,
    required String title,
    required bool isSelected,
    int count = 0,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 90.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // Shadow for depth
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.08 * 255).toInt()),
                blurRadius: 4,
                spreadRadius: 2,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              // Solid/gradient based on selection
              color: isSelected ? const Color(0xFF1A2540) : null,
              gradient: isSelected
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xffD6D6D6), Color(0xffADB2BD)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              // Glass border
              border: Border.all(
                color: isSelected
                    ? Colors.white.withOpacity(0.03)
                    : Colors.grey.withOpacity(0.03),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  icon,
                  height: 30.w,
                  width: 30.w,
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: GoogleFonts.koulen(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : appFontColor, // White for active, blue for inactive
                    letterSpacing: 1.0,
                    shadows: isSelected
                        ? [
                            Shadow(
                              color: Colors.black.withOpacity(0.03),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Badge for count
        if (count > 0)
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryKeys {
  static const String all = 'all';
  static const String hr = 'hr';
  static const String rfq = 'rfq';
  static const String invoice = 'invoice';
  static const String pettyCash = 'petty_cash';
}