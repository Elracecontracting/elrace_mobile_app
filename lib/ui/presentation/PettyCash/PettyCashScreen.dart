import 'dart:convert';
import 'dart:math' as math;

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
  static const double _kChevronSize = 26;
  static const double _kChevronGap = 10;
  static const double _kBubbleSize = 52;
  static const double _kBubbleRadius = 26;
  static const double _kBubbleIconSize = 22;
  static const double _kTitleSize = 20;
  static const double _kSubtitleSize = 14;
  static const double _kAmountSize = 34;
  static const double _kStatusDotSize = 14;

  bool isLoading = true;
  String error = '';
  double balance = 0.0;
  double incoming = 0.0;
  double spent = 0.0;
  double paid = 0.0;
  List<Map<String, dynamic>> expenseSheets = [];

  int? _expandedSheetId;
  final Map<int, List<Map<String, dynamic>>> _sheetLinesById = {};
  final Set<int> _sheetLinesLoading = {};
  final Map<int, String> _sheetLinesError = {};

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

  int? _sheetIdFrom(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  String _formatLineTitle(Map<String, dynamic> line) {
    final candidates = [
      line['name'],
      line['description'],
      line['remarks'],
      line['label'],
    ];
    for (final c in candidates) {
      final s = (c ?? '').toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'false') return s;
    }
    return 'Expense';
  }

  String _formatLineDate(Map<String, dynamic> line) {
    final candidates = [line['date'], line['create_date'], line['datetime']];
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

  Future<void> _fetchExpenseLinesForSheet(int sheetId) async {
    if (_sheetLinesLoading.contains(sheetId)) return;

    setState(() {
      _sheetLinesLoading.add(sheetId);
      _sheetLinesError.remove(sheetId);
    });

    try {
      final token = SharedPref.getLoginData().result?.token;
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final url = Uri.parse('https://erp.elrace.com/api/expense/lines');
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'params': {
          'sheet_id': sheetId,
        }
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final result = decoded['result'];
      final data = result is Map ? result['data'] : null;
      final lines = (data is List)
          ? List<Map<String, dynamic>>.from(data)
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _sheetLinesById[sheetId] = lines;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sheetLinesError[sheetId] = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _sheetLinesLoading.remove(sheetId);
      });
    }
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
      print('║ 📄 RESPONSE BODY (RAW):');
      print('║ ${response.body}');
      print('║');
      print('║ 📄 RESPONSE BODY (FORMATTED):');
      try {
        final jsonData = jsonDecode(response.body);
        final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonData);
        prettyJson.split('\n').forEach((line) => print('║ $line'));
      } catch (e) {
        print('║ Failed to format JSON: $e');
      }
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
          paid = (result['paid'] ?? 0).toDouble();

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
                      padding: EdgeInsets.zero,
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
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16,vertical: 5),
                        child: Text(
                          'Recent ${math.min(10, expenseSheets.length)}/${math.min(10, expenseSheets.length)}',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    SliverList.separated(
                      itemCount: expenseSheets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final sheet = expenseSheets[index];
                        return Padding(
                          padding: EdgeInsets.zero,
                          child: _buildExpenseRow(sheet),
                        );
                      },
                    ),
                  ],
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

    return Stack(
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
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Image.asset(
                        'assets/png/ppcash.png',
                        width: 30,
                        height: 30,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PETTYCASH',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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
                        style: GoogleFonts.abhayaLibre(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          balanceText,
                          style: GoogleFonts.abhayaLibre(
                            fontSize: 46,
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric('Amount', amountText),
                      _buildMetric('Draft', draftText),
                      _buildMetric('Not Paid', notPaidText),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
          style: GoogleFonts.abhayaLibre(
            fontSize: 24,
            fontWeight: FontWeight.w600,
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
    final sheetId = _sheetIdFrom(sheet['id']);
    final isExpanded = sheetId != null && _expandedSheetId == sheetId;

    final header = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (sheetId == null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PettyCashPopUpScreen()),
            );
            return;
          }

          setState(() {
            _expandedSheetId = isExpanded ? null : sheetId;
          });

          if (!isExpanded && !_sheetLinesById.containsKey(sheetId)) {
            _fetchExpenseLinesForSheet(sheetId);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Icon(
                isExpanded ? Icons.expand_more : Icons.chevron_right,
                color: Colors.black.withOpacity(0.55),
                size: _kChevronSize,
              ),
              const SizedBox(width: _kChevronGap),
              Container(
                width: _kBubbleSize,
                height: _kBubbleSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F0FF),
                  borderRadius: BorderRadius.circular(_kBubbleRadius),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/png/Bill.png',
                    width: _kBubbleIconSize,
                    height: _kBubbleIconSize,
                    color: Colors.black87,
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
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: _kSubtitleSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '-$amountText',
                style: GoogleFonts.inter(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD1002C),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: _kStatusDotSize,
                height: _kStatusDotSize,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (sheetId == null) return header;

    return Column(
      children: [
        header,
        if (isExpanded) ...[
          const SizedBox(height: 6),
          _buildExpandedLines(sheetId),
        ],
      ],
    );
  }

  Widget _buildExpandedLines(int sheetId) {
    final isLoading = _sheetLinesLoading.contains(sheetId);
    final errorMsg = _sheetLinesError[sheetId];
    final lines = _sheetLinesById[sheetId] ?? const <Map<String, dynamic>>[];

    if (isLoading) {
      return _buildShimmerLines();
    }

    if (errorMsg != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Failed to load lines',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _fetchExpenseLinesForSheet(sheetId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (lines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'No expense lines',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lines.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        return _buildExpenseLineRow(lines[index]);
      },
    );
  }

  Widget _buildExpenseLineRow(Map<String, dynamic> line) {
    final title = _formatLineTitle(line);
    final subtitle = _formatLineDate(line);
    final amountRaw = line['unit_amount'] ?? line['amount'] ?? 0;
    final amountText = _formatAmount(amountRaw);

    const double leadingIndent = _kChevronSize + _kChevronGap;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              const SizedBox(width: leadingIndent),
              Container(
                width: _kBubbleSize,
                height: _kBubbleSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F0FF),
                  borderRadius: BorderRadius.circular(_kBubbleRadius),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/png/Bill.png',
                    width: _kBubbleIconSize,
                    height: _kBubbleIconSize,
                    color: Colors.black87,
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
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: _kSubtitleSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '-$amountText',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD1002C),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLines() {
    return Column(
      children: List.generate(3, (index) => _buildShimmerRow()),
    );
  }

  Widget _buildShimmerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const SizedBox(width: _kChevronSize + _kChevronGap),
            _buildShimmerBox(width: _kBubbleSize, height: _kBubbleSize, isCircle: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(width: 120, height: 16),
                  const SizedBox(height: 6),
                  _buildShimmerBox(width: 80, height: 12),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildShimmerBox(width: 60, height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({required double width, required double height, bool isCircle = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300]!.withOpacity(value),
            borderRadius: isCircle ? null : BorderRadius.circular(8),
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          ),
        );
      },
      onEnd: () {},
    );
  }
}
