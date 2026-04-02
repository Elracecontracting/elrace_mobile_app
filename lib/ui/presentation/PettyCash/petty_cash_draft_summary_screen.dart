import 'dart:convert';
import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/My_task/screens/report_detail/camera_screen.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashAddExpense.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class PettyCashDraftSummaryScreen extends StatefulWidget {
  final String title;
  final String expenseType;
  final IconData titleIcon;

  const PettyCashDraftSummaryScreen({
    super.key,
    required this.title,
    required this.expenseType,
    required this.titleIcon,
  });

  @override
  State<PettyCashDraftSummaryScreen> createState() =>
      _PettyCashDraftSummaryScreenState();
}

class _PettyCashDraftSummaryScreenState
    extends State<PettyCashDraftSummaryScreen> {
  final NumberFormat _amountFormat = NumberFormat('#,##0.##');
  final List<File> _draftAttachments = [];

  bool _isLoading = true;
  String _error = '';
  double _totalBalance = 0;
  double _totalDraftAmount = 0;
  bool _canBeSubmit = false;
  List<_DraftExpense> _draftExpenses = const [];

  @override
  void initState() {
    super.initState();
    _fetchDraftSummary();
  }

  int? _resolveHolderId() {
    final loginData = SharedPref.getLoginData();
    final modeledHolderId = loginData.result?.data?.holder_id;
    if (modeledHolderId != null) {
      return modeledHolderId;
    }

    final loginJson = SharedPref.sharedPreferences.getString('loginResponse') ??
        SharedPref.sharedPreferences.getString('LOGIN_RESPONSE');
    if (loginJson == null || loginJson.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(loginJson) as Map<String, dynamic>;
      final result = decoded['result'];
      if (result is! Map<String, dynamic>) {
        return null;
      }

      final data = result['data'];
      if (data is! Map<String, dynamic>) {
        return null;
      }

      final rawHolderId = data['holder_id'];
      if (rawHolderId is int) {
        return rawHolderId;
      }
      return int.tryParse(rawHolderId?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchDraftSummary() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final token = SharedPref.getLoginData().result?.token;
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token is missing');
      }

      final holderId = _resolveHolderId();
      debugPrint('DraftSummary holderId: $holderId');
      debugPrint('DraftSummary type: ${widget.expenseType}');
      if (holderId == null) {
        throw Exception('Petty cash holder_id is missing from login data');
      }

      final payload = <String, dynamic>{
        'jsonrpc': '2.0',
        'params': <String, dynamic>{
          'holder_id': holderId,
          'type': widget.expenseType,
        },
      };

      debugPrint('DraftSummary request: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse('https://erp.elrace.com/api/draft_summary'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint('DraftSummary statusCode: ${response.statusCode}');
      debugPrint('DraftSummary body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to load draft summary: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final result = decoded['result'];
      if (result is! Map<String, dynamic>) {
        throw Exception('Invalid draft summary response');
      }

      final data = (result['data'] is Map<String, dynamic>)
          ? result['data'] as Map<String, dynamic>
          : result;

      final rawExpenses = data['draft_expenses'];
      final expenses = rawExpenses is List
          ? rawExpenses
              .whereType<Map>()
              .map((item) =>
                  _DraftExpense.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false)
          : const <_DraftExpense>[];

      if (!mounted) return;
      setState(() {
        _totalBalance = _toDouble(data['total_balance']);
        _totalDraftAmount = _toDouble(data['total_draft_amount']);
        _canBeSubmit = data['can_be_submit'] == true;
        _draftExpenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('DraftSummary fetch error: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatAmount(num value) {
    return _amountFormat.format(value);
  }

  String _formatDate(String rawDate) {
    final normalized = rawDate.trim();
    if (normalized.isEmpty) return '';

    final parsed = DateTime.tryParse(normalized.replaceFirst(' ', 'T'));
    if (parsed == null) return normalized;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(parsed.year, parsed.month, parsed.day);
    final diff = today.difference(targetDay).inDays;
    final time = DateFormat('HH:mm').format(parsed);

    if (diff == 0) return 'Today · $time';
    if (diff == 1) return 'Yesterday · $time';
    return '${DateFormat('dd/MM/yyyy').format(parsed)} · $time';
  }

  String _resolveSheetTitle() {
    if (_draftExpenses.isEmpty) return 'RCC PC 1';

    final title = _draftExpenses.first.sheetTitle.trim();
    if (title.isNotEmpty) {
      return title;
    }

    return widget.expenseType == 'fleet' ? 'Transportation' : 'Miscellaneous';
  }

  Future<void> _addCameraAttachment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomCameraScreen(onePicture: false),
      ),
    );

    if (!mounted) return;
    if (result is List<XFile> && result.isNotEmpty) {
      setState(() {
        _draftAttachments.addAll(result.map((file) => File(file.path)));
      });
    }
  }

  Future<void> _scanDocumentAttachment() async {
    try {
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 20,
        isGalleryImportAllowed: true,
      );

      if (!mounted) return;
      if (pictures == null || pictures.isEmpty) return;

      setState(() {
        _draftAttachments.addAll(pictures.map((path) => File(path)));
      });
    } on PlatformException {
      return;
    }
  }

  void _showAttachmentSourcePicker() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF5B5E63).withOpacity(0.96),
                  const Color(0xFF3F4247).withOpacity(0.96),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachmentSourceTile(
                  icon: Icons.camera_alt_outlined,
                  label: 'camera',
                  onTap: () {
                    Navigator.pop(context);
                    _addCameraAttachment();
                  },
                ),
                _AttachmentSourceTile(
                  icon: Icons.document_scanner_outlined,
                  label: 'scan',
                  onTap: () {
                    Navigator.pop(context);
                    _scanDocumentAttachment();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAddExpenseDialog() {
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
          final scale = Tween<double>(begin: 0.98, end: 1.0).animate(fade);
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: Column(
        children: [
          Container(
            height: 74,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.titleIcon,
                    size: 33, color: const Color(0xFF111111)),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: GoogleFonts.oswald(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _fetchDraftSummary,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA6A6A6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'total ${_draftExpenses.length}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: _showAttachmentSourcePicker,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFF161616),
                                  width: 1.3,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.attach_file_rounded,
                                    size: 20,
                                    color: Color(0xFF111111),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Add Attachments',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF111111),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Balance ${_formatAmount(_totalBalance)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF9A9A9A),
                              ),
                            ),
                          ),
                          Text(
                            _canBeSubmit
                                ? 'Ready to submit'
                                : 'Submission blocked',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _canBeSubmit
                                  ? const Color(0xFF129A59)
                                  : const Color(0xFF9A9A9A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 120),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Column(
                            children: [
                              Text(
                                'Failed to load draft expenses',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF141414),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF8E8E8E),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchDraftSummary,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      else if (_draftExpenses.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 110),
                          child: Column(
                            children: [
                              Text(
                                'No draft expenses',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF171717),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Start adding ${widget.expenseType == 'fleet' ? 'transportation' : 'miscellaneous'} expenses.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF8E8E8E),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        _buildHeaderCard(),
                        const SizedBox(height: 22),
                        ..._draftExpenses.map(_buildExpenseRow),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: Center(
                    child: InkWell(
                      onTap: _openAddExpenseDialog,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        width: 246,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF767A80), Color(0xFF5C6066)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+ ADD EXPENSE',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            color: Color(0xFFBABABA),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              'assets/png/Bill.png',
              width: 28,
              height: 28,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _resolveSheetTitle(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(_draftExpenses.first.rawDate),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9A9A9A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '-${_formatAmount(_totalDraftAmount)}',
          style: GoogleFonts.inter(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFF1123),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseRow(_DraftExpense expense) {
    return Padding(
      padding: const EdgeInsets.only(left: 35, bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 38),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(expense.rawDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9A9A9A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '-${_formatAmount(expense.amount)}',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFF1123),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftExpense {
  final String title;
  final String sheetTitle;
  final String rawDate;
  final double amount;

  const _DraftExpense({
    required this.title,
    required this.sheetTitle,
    required this.rawDate,
    required this.amount,
  });

  factory _DraftExpense.fromJson(Map<String, dynamic> json) {
    String pickString(List<dynamic> candidates, {String fallback = ''}) {
      for (final candidate in candidates) {
        final value = (candidate ?? '').toString().trim();
        if (value.isNotEmpty && value.toLowerCase() != 'false') {
          return value;
        }
      }
      return fallback;
    }

    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
    }

    return _DraftExpense(
      title: pickString([
        json['expense_type_label'],
        json['label'],
        json['name'],
        json['description'],
        json['display_name'],
        json['expense_name'],
      ], fallback: 'Expense'),
      sheetTitle: pickString([
        json['sheet_name'],
        json['petty_cash_name'],
        json['holder_name'],
        json['batch_name'],
        json['summary_name'],
      ]),
      rawDate: pickString([
        json['last_update'],
        json['create_date'],
        json['date'],
        json['datetime'],
      ]),
      amount: toDouble(
          json['amount'] ?? json['total_amount'] ?? json['unit_amount']),
    );
  }
}

class _AttachmentSourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 34, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
