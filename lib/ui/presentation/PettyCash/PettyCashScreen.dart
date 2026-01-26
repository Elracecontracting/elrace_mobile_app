import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashDraftScreen.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashSubmittedScreen.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashPopUpScreen.dart';
import 'package:el_race/utils/api_logger.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:el_race/ui/widgets/header_widget.dart';

class PettyCashScreen extends StatefulWidget {
  const PettyCashScreen({super.key});

  @override
  _PettyCashScreenState createState() => _PettyCashScreenState();
}

class _PettyCashScreenState extends State<PettyCashScreen> {
  bool isLoading = true;
  String error = '';
  double balance = 0.0;
  double incoming = 0.0;
  double spent = 0.0;
  List<Map<String, dynamic>> expenseSheets = [];

  final NumberFormat _amountFormat = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();
    _fetchPettyCashData();
  }

  bool _isDraft(dynamic state) {
    final s = (state ?? '').toString().toLowerCase();
    return s.contains('draft') || s.isEmpty || s == 'false';
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

  Future<void> _fetchPettyCashData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final loginData = SharedPref.getLoginData();
      final token = loginData.result?.token;
      final empId = loginData.result?.data?.emp_id;

      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      final url = Uri.parse("https://erp.elrace.com/api/petty_cash_home");

      final now = DateTime.now();
      final currentDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final lastLimit = balance > 0 ? balance.toInt() : 0;

      final bodyData = {
        "jsonrpc": "2.0",
        "params": {
          "last_limit": lastLimit,
          "last_limit_date": currentDate,
        },
      };
      final body = jsonEncode(bodyData);

      print(
          '\n╔═══════════════════════════════════════════════════════════════');
      print('║ 📡 PETTY CASH API: PETTY CASH HOME');
      print('╠═══════════════════════════════════════════════════════════════');
      print('║ 🌐 URL: $url');
      print('║ 📤 METHOD: GET');
      print('║ 👤 Employee ID: $empId');
      print('║ 📋 HEADERS:');
      headers.forEach((key, value) {
        if (key == 'Authorization') {
          print('║    $key: Bearer ${value.toString().substring(7, 27)}...');
        } else {
          print('║    $key: $value');
        }
      });
      print('║ 📦 BODY:');
      print('║    last_limit: $lastLimit');
      print('║    last_limit_date: $currentDate');
      print('║    Full: $body');
      print(
          '╚═══════════════════════════════════════════════════════════════\n');

      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
          '\n╔═══════════════════════════════════════════════════════════════');
      print('║ 📥 PETTY CASH API RESPONSE: PETTY CASH HOME');
      print('╠═══════════════════════════════════════════════════════════════');
      print('║ ✅ STATUS CODE: ${response.statusCode}');
      print('║ 📄 RESPONSE BODY:');
      print('║ ${response.body}');
      print(
          '╚═══════════════════════════════════════════════════════════════\n');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result']['data'];

        print(
            '╔═══════════════════════════════════════════════════════════════');
        print('║ 📊 PARSED PETTY CASH DATA');
        print(
            '╠═══════════════════════════════════════════════════════════════');
        print('║ 👤 Employee ID: ${result['employee_id']}');
        print('║ 💰 Balance: ${result['balance']} AED');
        print('║ 📈 Incoming: ${result['incoming']} AED');
        print('║ 📉 Spent: ${result['spent']} AED');
        print('║ 📝 Draft Expenses Count: ${result['draft_expenses_count']}');
        print(
            '║ 💵 Draft Expenses Total: ${result['draft_expenses_total']} AED');
        print('║ 📋 Expense Sheets: ${result['expense_sheets']}');
        print(
            '╚═══════════════════════════════════════════════════════════════\n');

        setState(() {
          balance = result['balance'].toDouble();
          incoming = result['incoming'].toDouble();
          spent = result['spent'].toDouble();

          if (result['expense_sheets'] is List) {
            expenseSheets =
                List<Map<String, dynamic>>.from(result['expense_sheets']);
            print('✅ Expense sheets loaded: ${expenseSheets.length} items');
          } else {
            expenseSheets = [];
            print('ℹ️ Expense sheets is String: ${result['expense_sheets']}');
          }

          isLoading = false;
        });
        print('   Balance: $balance | Incoming: $incoming | Spent: $spent\n');
      } else {
        print(
            '\n╔═══════════════════════════════════════════════════════════════');
        print('║ ❌ PETTY CASH API FAILED');
        print(
            '╠═══════════════════════════════════════════════════════════════');
        print('║ Status Code: ${response.statusCode}');
        print('║ Response Body: ${response.body}');
        print(
            '╚═══════════════════════════════════════════════════════════════\n');
        throw Exception(
            "Failed to load petty cash data: ${response.statusCode}\n${response.body}");
      }
    } catch (e, stackTrace) {
      print(
          '\n╔═══════════════════════════════════════════════════════════════');
      print('║ ⚠️ PETTY CASH API ERROR');
      print('╠═══════════════════════════════════════════════════════════════');
      print('║ Error: $e');
      print(
          '║ Stack Trace: ${stackTrace.toString().split('\n').take(3).join('\n║ ')}');
      print(
          '╚═══════════════════════════════════════════════════════════════\n');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        error = e.toString();
      });
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
              onRefresh: _fetchPettyCashData,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderStack(context),
                        ],
                      ),
                    ),
                  ),
                  if (expenseSheets.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
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
                      itemCount: expenseSheets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final sheet = expenseSheets[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          child: _buildExpenseRow(sheet),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderStack(BuildContext context) {
    return SizedBox(
      height: 190 + 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 0,
            bottom: 84,
            child: _buildBalanceCard(context),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildTabs(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    // Calculate draft and not paid from expense_sheets
    double draftTotal = 0.0;
    double notPaidTotal = 0.0;
    for (final sheet in expenseSheets) {
      final amount =
          (sheet['total_amount'] ?? sheet['amount'] ?? 0).toDouble();
      if (_isDraft(sheet['state'])) {
        draftTotal += amount;
      } else {
        notPaidTotal += amount;
      }
    }

    final balanceText = _formatAmount(balance);
    final amountText = _formatAmount(incoming);
    final draftText = _formatAmount(draftTotal);
    final notPaidText = _formatAmount(notPaidTotal);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/png/petty-colors.png',
                  fit: BoxFit.cover,
                ),
                Image.asset(
                  'assets/png/lines.png',
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/png/petty-cash-icon.png',
                        width: 28,
                        height: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PETTYCASH',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Your Balance',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            balanceText,
                            style: GoogleFonts.koulen(
                              fontSize: 46,
                              height: 1.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetric('Incoming', amountText),
                      _buildMetric('Draft', draftText),
                      _buildMetric('Not Paid', notPaidText),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.85),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.koulen(
            fontSize: 24,
            height: 1.0,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(BuildContext context) {
    Widget tabItem({
      required String assetPath,
      required String label,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  assetPath,
                  width: 34,
                  height: 34,
                  color: Colors.black87,
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          tabItem(
            assetPath: 'assets/png/draft2.png',
            label: 'Draft',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PettyCashDraftScreen()),
              );
            },
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.black.withOpacity(0.08),
          ),
          tabItem(
            assetPath: 'assets/png/Bill.png',
            label: 'Submitted',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PettyCashSubmittedScreen()),
              );
            },
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
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
              const Icon(
                Icons.chevron_right,
                color: Colors.black54,
                size: 24,
              ),
              const SizedBox(width: 10),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '-$amountText',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFD1002C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
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
