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
  static const double _kChevronSize = 26;
  static const double _kChevronGap = 10;
  static const double _kBubbleSize = 52;
  static const double _kBubbleRadius = 26;
  static const double _kBubbleIconSize = 22;
  static const double _kTitleSize = 20;
  static const double _kSubtitleSize = 14;
  static const double _kAmountSize = 34;
  static const double _kStatusDotSize = 14;
  final int _pageCount = 4;
  final int _itemsPerPage = 10; // عدد العناصر لكل صفحة

  int? _expandedSheetId;
  final Map<int, List<Map<String, dynamic>>> _sheetLinesById = {};
  final Set<int> _sheetLinesLoading = {};
  final Map<int, String> _sheetLinesError = {};

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
    final rawDate = line['date'] ?? line['date_order'] ?? line['create_date'];
    if (rawDate == null || rawDate == false) return 'No date';
    try {
      final parsed = DateTime.parse(rawDate.toString());
      final now = DateTime.now();
      final diffDays = now.difference(parsed).inDays;
      final timeStr = DateFormat('HH:mm').format(parsed);
      if (diffDays == 0) return 'Today : $timeStr';
      if (diffDays == 1) return 'Yesterday : $timeStr';
      return '${DateFormat('MMM d').format(parsed)} : $timeStr';
    } catch (_) {
      return rawDate.toString();
    }
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
        if (token != null) 'Authorization': 'Bearer $token',
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
      final result = decoded['result'] ?? decoded;
      final data = result['data'] ?? result;
      final List<Map<String, dynamic>> lines = (data is List)
          ? data.map((e) => Map<String, dynamic>.from(e as Map)).toList()
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

      // Use the new API endpoint for viewing all submitted expense sheets
      final url = Uri.parse("https://erp.elrace.com/api/view_all_hr_expense_sheets");

      final bodyData = {
        "jsonrpc": "2.0",
        "params": {},
      };
      final body = jsonEncode(bodyData);

      print(
          '\n╔═══════════════════════════════════════════════════════════════');
      print('║ 📡 PETTY CASH API: VIEW ALL HR EXPENSE SHEETS');
      print('╠═══════════════════════════════════════════════════════════════');
      print('║ 🌐 URL: $url');
      print('║ 📤 METHOD: GET (with body)');
      print('║ 📋 HEADERS:');
      headers.forEach((key, value) {
        if (key == 'Authorization') {
          print('║    $key: Bearer ${value.toString().substring(7, 27)}...');
        } else {
          print('║    $key: $value');
        }
      });
      print('║ 📦 BODY: $body');
      print(
          '╚═══════════════════════════════════════════════════════════════\n');

      // Use GET with body (same pattern as petty_cash_home)
      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
          '\n╔═══════════════════════════════════════════════════════════════');
      print('║ 📥 PETTY CASH API RESPONSE: VIEW ALL HR EXPENSE SHEETS');
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
        final result = data['result'];

        List<Map<String, dynamic>> allSheets = [];
        if (result != null && result['data'] != null) {
          if (result['data'] is List) {
            allSheets = List<Map<String, dynamic>>.from(result['data']);
          } else if (result['data']['expense_sheets'] is List) {
            allSheets = List<Map<String, dynamic>>.from(result['data']['expense_sheets']);
          }
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
        
        print('✅ Submitted sheets loaded: ${submittedSheets.length} items');
      } else {
        throw Exception("Failed to load submitted data: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      print(
          '\n╔═══════════════════════════════════════════════════════════════');
      print('║ ⚠️ VIEW ALL HR EXPENSE SHEETS API ERROR');
      print('╠═══════════════════════════════════════════════════════════════');
      print('║ Error: $e');
      print(
          '║ Stack Trace: ${stackTrace.toString().split('\n').take(3).join('\n║ ')}');
      print(
          '╚═══════════════════════════════════════════════════════════════\n');
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
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
    final sheetId = _sheetIdFrom(sheet['id']);
    final isExpanded = sheetId != null && _expandedSheetId == sheetId;

    final header = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(
                isExpanded ? Icons.expand_more : Icons.chevron_right,
                size: 24,
                color: Colors.black.withOpacity(0.4),
              ),
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
                        fontSize: 18,
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
              const SizedBox(width: 12),
              Text(
                '-$amountText',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
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
