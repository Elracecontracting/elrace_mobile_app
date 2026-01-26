import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashPopUpScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:el_race/ui/widgets/header_widget.dart';

class PettyCashSubmittedScreen extends StatefulWidget {
  const PettyCashSubmittedScreen({super.key});

  @override
  _PettyCashSubmittedScreenState createState() =>
      _PettyCashSubmittedScreenState();
}

class _PettyCashSubmittedScreenState extends State<PettyCashSubmittedScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> submittedSheets = [];
  int _currentPage = 1;
  final int _pageCount = 4;
  final int _itemsPerPage = 10; // عدد العناصر لكل صفحة

  final NumberFormat _amountFormat = NumberFormat('#,##0');

  // حساب العناصر المعروضة حسب الصفحة الحالية
  List<Map<String, dynamic>> get _visibleItems {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    
    if (startIndex >= submittedSheets.length) return [];
    
    return submittedSheets.sublist(
      startIndex,
      endIndex > submittedSheets.length ? submittedSheets.length : endIndex,
    );
  }

  // حساب عدد الصفحات الفعلي حسب عدد العناصر
  int get _actualPageCount {
    if (submittedSheets.isEmpty) return 1;
    return (submittedSheets.length / _itemsPerPage).ceil().clamp(1, _pageCount);
  }

  @override
  void initState() {
    super.initState();
    _fetchSubmittedData();
  }

  String _formatAmount(dynamic value) {
    final numVal = (value is num)
        ? value
        : num.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
    return _amountFormat.format(numVal.round());
  }

  String _formatSheetTitle(Map<String, dynamic> sheet) {
    final titleCandidates = [
      sheet['name'],
      sheet['reference'],
      sheet['display_name'],
      sheet['employee_name'],
      sheet['employee'],
    ];
    for (final c in titleCandidates) {
      final s = (c ?? '').toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'false') return s;
    }
    return 'RCC PC 1';
  }

  String _formatSheetDate(Map<String, dynamic> sheet) {
    final candidates = [sheet['create_date'], sheet['date'], sheet['datetime']];
    DateTime? parsed;
    for (final c in candidates) {
      final raw = (c ?? '').toString().trim();
      if (raw.isEmpty || raw.toLowerCase() == 'false') continue;
      parsed = DateTime.tryParse(raw);
      if (parsed != null) break;
    }

    if (parsed == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(parsed.year, parsed.month, parsed.day);
    final diffDays = today.difference(day).inDays;

    final timeStr = DateFormat('HH:mm').format(parsed);
    if (diffDays == 0) return 'Today : $timeStr';
    if (diffDays == 1) return 'Yesterday : $timeStr';
    return '${DateFormat('MMM d').format(parsed)} : $timeStr';
  }

  Color _statusDotColor(Map<String, dynamic> sheet) {
    final s = (sheet['state'] ?? '').toString().toLowerCase();
    if (s.contains('paid') || s.contains('approve') || s.contains('done')) {
      return const Color(0xFF18A558);
    }
    if (s.contains('submit') || s.contains('pending') || s.contains('draft')) {
      return const Color(0xFFF0B400);
    }
    if (s.contains('reject') || s.contains('cancel') || s.contains('refuse')) {
      return const Color(0xFFD1002C);
    }
    return const Color(0xFF18A558);
  }

  Future<void> _fetchSubmittedData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final loginData = SharedPref.getLoginData();
      final token = loginData.result?.token;

      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      final url = Uri.parse("https://erp.elrace.com/api/petty_cash_home");

      final now = DateTime.now();
      final currentDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final bodyData = {
        "jsonrpc": "2.0",
        "params": {
          "last_limit": 0,
          "last_limit_date": currentDate,
        },
      };
      final body = jsonEncode(bodyData);

      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result']['data'];

        List<Map<String, dynamic>> allSheets = [];
        if (result['expense_sheets'] is List) {
          allSheets = List<Map<String, dynamic>>.from(result['expense_sheets']);
        }

        // Filter submitted only (non-draft)
        final submitted = allSheets.where((e) {
          final state = (e['state'] ?? '').toString().toLowerCase();
          return !state.contains('draft');
        }).toList();

        setState(() {
          submittedSheets = submitted;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load submitted data: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const HeaderWidget(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSubmittedData,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/png/Bill.png',
                            width: 24,
                            height: 24,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SUBMITTED',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6E6E6E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'TOTAL ${submittedSheets.length}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _buildPagination(),
                        ],
                      ),
                    ),
                  ),
                  if (submittedSheets.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 34),
                        child: Center(
                          child: Text(
                            'No record found.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList.separated(
                      itemCount: _visibleItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final sheet = _visibleItems[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          child: _buildExpenseRow(sheet),
                        );
                      },
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (_currentPage > 1) {
              setState(() => _currentPage--);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.chevron_left,
              size: 24,
              color: _currentPage > 1
                  ? Colors.black.withOpacity(0.7)
                  : Colors.black.withOpacity(0.25),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: List.generate(_actualPageCount, (i) {
            final page = i + 1;
            final selected = page == _currentPage;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() => _currentPage = page);
                print('📄 Page changed to: $page (showing items ${(_currentPage - 1) * _itemsPerPage + 1} - ${(_currentPage * _itemsPerPage).clamp(0, submittedSheets.length)})');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF6A7B8A)
                            : const Color(0xFFD9D9D9),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$page',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w700,
                        color: selected
                            ? Colors.black.withOpacity(0.9)
                            : Colors.black.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (_currentPage < _actualPageCount) {
              setState(() => _currentPage++);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.chevron_right,
              size: 24,
              color: _currentPage < _actualPageCount
                  ? Colors.black.withOpacity(0.7)
                  : Colors.black.withOpacity(0.25),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseRow(Map<String, dynamic> sheet) {
    final title = _formatSheetTitle(sheet);
    final subtitle = _formatSheetDate(sheet);
    final amountRaw = sheet['total_amount'] ?? sheet['amount'] ?? 0;
    final amountText = _formatAmount(amountRaw);
    final dotColor = _statusDotColor(sheet);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PettyCashPopUpScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.chevron_right,
                  size: 24, color: Colors.black.withOpacity(0.4)),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/png/Bill.png',
                    width: 20,
                    height: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '-$amountText',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFD1002C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
