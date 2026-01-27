import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashAddExpense.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashPopUpScreen.dart';
import 'package:el_race/utils/api_logger.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:el_race/ui/widgets/header_widget.dart';

class PettyCashDraftScreen extends StatefulWidget {
  const PettyCashDraftScreen({super.key});

  @override
  _PettyCashDraftScreenState createState() => _PettyCashDraftScreenState();
}

class _PettyCashDraftScreenState extends State<PettyCashDraftScreen> {
  bool isLoading = true;
  double balance = 0.0;
  double draftAmount = 0.0;
  double draftExpensesTotal = 0.0;
  int draftExpensesCount = 0;
  List<Map<String, dynamic>> draftExpenses = [];

  final NumberFormat _amountFormat = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();
    _fetchDraftSummary();
  }

  String _formatAmount(dynamic value) {
    final numVal = (value is num)
        ? value
        : num.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
    return _amountFormat.format(numVal.round());
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

  Future<void> _fetchDraftSummary() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });


    try {
      final loginData = SharedPref.getLoginData();
      final token = loginData.result?.token;
      // last_limit: من بيانات المستخدم (مثلاً balance أو emp_id أو حسب ما هو متوفر)
      // هنا سنستخدم balance إذا متوفر، أو 0 كقيمة افتراضية
      final lastLimit = balance > 0 ? balance.toInt() : 0;
      final now = DateTime.now();
      final lastLimitDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      final url = Uri.parse("https://erp.elrace.com/api/draft_summary");
      final body = jsonEncode({
        "jsonrpc": "2.0",
        "params": {
          "last_limit": lastLimit,
          "last_limit_date": lastLimitDate,
        },
      });

      print('📤 DraftSummary GET body: ' + body);

      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final startTime = DateTime.now();
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final duration = DateTime.now().difference(startTime);

      final responseData = jsonDecode(response.body);

      ApiLogger.logResponse(
        endpoint: url.toString(),
        statusCode: response.statusCode,
        responseBody: responseData,
        duration: duration,
      );

      if (response.statusCode == 200) {
        final data = responseData;
        
        // Check if response has error
        if (data['error'] != null) {
          print('⚠️ Draft Summary API returned error: ${data['error']['message']}');
          setState(() => isLoading = false);
          return;
        }
        
        // Safely access result and data
        final resultData = data['result'];
        if (resultData == null) {
          print('⚠️ Draft Summary API returned null result');
          setState(() => isLoading = false);
          return;
        }
        
        final result = resultData['data'] ?? resultData;

        final rawDraftExpenses = result['draft_expenses'];
        final parsedDraftExpenses = (rawDraftExpenses is List)
            ? List<Map<String, dynamic>>.from(rawDraftExpenses)
            : const <Map<String, dynamic>>[];

        setState(() {
          balance = (result['total_balance'] ?? 0).toDouble();
          draftAmount = (result['total_draft_amount'] ?? 0).toDouble();
          draftExpenses = parsedDraftExpenses;
          draftExpensesCount = parsedDraftExpenses.isNotEmpty
              ? parsedDraftExpenses.length
              : 0;
          draftExpensesTotal = draftAmount;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch draft summary: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      ApiLogger.logError(
        endpoint: 'https://erp.elrace.com/api/draft_summary',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDraftSummary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.hourglass_empty,
                            size: 24,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'DRAFT',
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
                      padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6E6E6E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'TOTAL ${draftExpenses.length}',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PettyCashPopUpScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.black.withOpacity(0.25), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.attach_file, size: 16, color: Colors.black87),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Add Attachments',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (draftExpenses.isEmpty)
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
                    ..._buildDraftContent(),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildDraftContent() {
    final headerAmount = _formatAmount(draftExpensesTotal);

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
          child: _buildDraftHeaderCard(
            title: 'RCC PC 1',
            subtitle: _formatSheetDate(draftExpenses.first),
            amountText: '-$headerAmount',
          ),
        ),
      ),
      SliverList.separated(
        itemCount: draftExpenses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final e = draftExpenses[index];
          return Padding(
            padding: EdgeInsets.zero,
            child: _buildDraftBulletRow(e),
          );
        },
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 22, 0, 10),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false,
                    barrierDismissible: true,
                    barrierColor: Colors.black.withOpacity(0.20),
                    pageBuilder: (_, __, ___) => const PettyCashAddExpense(),
                    transitionsBuilder: (_, animation, __, child) {
                      final fade = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      );
                      final scale = Tween<double>(begin: 0.98, end: 1.0)
                          .animate(fade);
                      return FadeTransition(
                        opacity: fade,
                        child: ScaleTransition(scale: scale, child: child),
                      );
                    },
                  ),
                );
              },
              child: Container(
                width: 240,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6E6E6E),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Center(
                  child: Text(
                    '+ ADD EXPENSE',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildDraftHeaderCard({
    required String title,
    required String subtitle,
    required String amountText,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F0FF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Image.asset(
                'assets/png/Bill.png',
                width: 22,
                height: 22,
                color: Colors.black87,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              amountText,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFD1002C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftBulletRow(Map<String, dynamic> item) {
    final titleCandidates = [
      item['name'],
      item['description'],
      item['label'],
      item['display_name'],
    ];

    String title = '';
    for (final c in titleCandidates) {
      final s = (c ?? '').toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'false') {
        title = s;
        break;
      }
    }
    if (title.isEmpty) title = 'Expense';

    final subtitle = _formatSheetDate(item);
    final amountRaw = item['total_amount'] ?? item['amount'] ?? item['unit_amount'] ?? 0;
    final amountText = _formatAmount(amountRaw);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '-$amountText',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFD1002C),
          ),
        ),
      ],
    );
  }
}
