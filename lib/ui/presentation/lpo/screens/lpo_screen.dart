import 'dart:async';
import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/lpo/widgets/lpo_card_widget.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class LpoListScreen extends StatefulWidget {
  const LpoListScreen({super.key});

  @override
  State<LpoListScreen> createState() => _LpoListScreenState();
}

class _LpoListScreenState extends State<LpoListScreen> {
  final _scrollController = ScrollController();
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  String _keyword = '';

  // Search UI (match MediaListScreen)
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchLpos();

    _searchController.addListener(() {
      final text = _searchController.text.trim();
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() {
          _keyword = text;
        });
        _fetchLpos(keyword: text);
      });
    });
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();

  // }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {}
  }

  Future<void> _fetchLpos({String? keyword}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = SharedPref.getLoginData().result?.token ?? '';
      final url = Uri.parse('https://test.elrace.com/api/get_lpos');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final effectiveKeyword = (keyword ?? _keyword).trim();
      final Map<String, dynamic> params = {};
      if (effectiveKeyword.isNotEmpty) {
        params['keyword'] = effectiveKeyword;
      }

      final body = jsonEncode({
        'jsonrpc': '2.0',
        'params': params,
      });

      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['result'] != null) {
        final List list = (data['result']['data'] ?? []) as List;
        setState(() {
          _items = list.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = data['error']?.toString() ?? 'Failed to load LPOs';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildInlineSearchField() {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/png/bg_atten.png'),
          fit: BoxFit.none,
        ),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(29.w),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.2 * 255).toInt()),
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Find LPO',
          prefixIcon: Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.search, size: 18, color: appFontColor),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('${SharedPref.getLoginData().result?.token}');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 🔹 LPO Title Section (Scrollable)
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/png/lpo_blue.svg",
                        height: 24.w,
                        width: 24.w,
                      ),
                      SizedBox(width: 4.w),
                      if (!_showSearch)
                        Text(
                          translate('home.lpo'),
                          style: GoogleFonts.koulen(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w500,
                            color: appFontColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Expanded(child: _buildInlineSearchField()),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _items[index];
                          final name = (item['name'] ?? '').toString();
                          final vendor = (item['partner_id'] ?? '').toString();
                          final project = (item['project'] ?? '').toString();
                          final dateStr = (item['date_order'] ?? '').toString();
                          final amount =
                              (item['amount_total'] ?? '').toString();
                          final clientPhoto = item['client_photo'];
                          final requestedByPhoto =
                              item['requested_by_user_photo'];
                          final requestedBy =
                              (item['requested_by'] ?? '').toString();
                          final requesterManager =
                              (item['requester_manager'] ?? '').toString();
                          final state = (item['state'] ?? '').toString();
                          final attachments =
                              (item['attachments'] ?? []) as List;

                          return LpoCardWidget(
                            name: name,
                            vendorName: vendor,
                            projectName: project,
                            date: dateStr,
                            amount: amount,
                            clientPhoto: clientPhoto,
                            requestedByUserPhoto: requestedByPhoto,
                            requestedBy: requestedBy,
                            requesterManager: requesterManager,
                            state: state,
                            attachments: attachments,
                          );
                        },
                        childCount: _items.length,
                      ),
                    ),
        ],
      ),
    );
  }
}
