import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_action_buttons.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/file_binary.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class PettyCashDetailsScreen extends StatefulWidget {
  final String requestId;
  final String type;
  final Map<String, dynamic>? initialData;

  const PettyCashDetailsScreen({
    super.key,
    required this.requestId,
    required this.type,
    this.initialData,
  });

  @override
  State<PettyCashDetailsScreen> createState() => _PettyCashDetailsScreenState();
}

class _PettyCashDetailsScreenState extends State<PettyCashDetailsScreen> {
  bool _isLoading = true;
  String _error = '';

  Map<String, dynamic> _formData = const {};
  List<dynamic> _attachmentIds = const [];

  String _safe(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    if (v == false || v == true) return fallback;
    final s = v.toString();
    if (s.isEmpty) return fallback;
    final lower = s.toLowerCase();
    if (lower == 'false' || lower == 'true' || lower == 'null') return fallback;
    return s;
  }

  String _pick(List<dynamic> values, {String fallback = ''}) {
    for (final v in values) {
      final s = _safe(v);
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _formData = Map<String, dynamic>.from(widget.initialData!);
    }
    _fetchPettyCashDetails();
  }

  Future<void> _fetchPettyCashDetails() async {
    final token = SharedPref.getLoginData().result?.token;
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('https://erp.elrace.com/api/get_petty_cash_details');
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'params': {
        'petty_cash_id': int.tryParse(widget.requestId),
      },
    });

    print('══════════ [PETTYCASH] API REQUEST ══════════');
    print('[PETTYCASH] URL: $url');
    print('[PETTYCASH] METHOD: GET');
    print('[PETTYCASH] HEADERS: ${headers.map((k, v) => MapEntry(k, k == "Authorization" ? "Bearer ***" : v))}');
    print('[PETTYCASH] BODY: $body');
    print('═════════════════════════════════════════════');

    try {
      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print('══════════ [PETTYCASH] API RESPONSE ══════════');
      print('[PETTYCASH] STATUS: ${response.statusCode}');
      print('[PETTYCASH] BODY: ${response.body}');
      print('══════════════════════════════════════════════');

      final data = jsonDecode(response.body);

      if (data['result'] != null) {
        final result = data['result'] as Map;
        final formData = result['data'] as Map? ?? {};
        final attachmentList = result['attachment_ids'] as List? ?? [];

        print('[PETTYCASH] PARSED formData keys: ${formData.keys.toList()}');
        print('[PETTYCASH] PARSED formData: $formData');
        print('[PETTYCASH] PARSED attachmentIds: $attachmentList');

        setState(() {
          final merged = Map<String, dynamic>.from(_formData);
          merged.addAll(Map<String, dynamic>.from(formData));
          _formData = merged;
          _attachmentIds = attachmentList;
          _isLoading = false;
        });
      } else {
        print('[PETTYCASH] ERROR: result is null. Full response: ${response.body}');
        setState(() {
          _isLoading = false;
          if (_formData.isEmpty) {
            _error = 'Failed to load Petty Cash details';
          }
        });
      }
    } catch (e) {
      print('══════════ [PETTYCASH] API ERROR ══════════');
      print('[PETTYCASH] EXCEPTION: $e');
      print('═══════════════════════════════════════════');
      setState(() {
        _isLoading = false;
        if (_formData.isEmpty) {
          _error = e.toString();
        }
      });
    }
  }

  Future<void> _viewAttachment() async {
    if (_attachmentIds.isEmpty) return;

    final attachmentId = (_attachmentIds.first is Map)
        ? (_attachmentIds.first['attachment_id'] ?? _attachmentIds.first)
        : _attachmentIds.first;

    final token = SharedPref.getLoginData().result?.token;
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final data = {
      'jsonrpc': '2.0',
      'params': {
        'attachment_id': attachmentId,
      },
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await Dio().fetch(
        RequestOptions(
          method: 'GET',
          path: 'https://erp.elrace.com/api/get_attachment_details',
          headers: headers,
          data: data,
          responseType: ResponseType.json,
        ),
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      final resData = response.data as Map;
      final result = resData['result'] as Map?;
      final dataMap = result?['data'] as Map?;
      final binaryBase64 = dataMap?['attachment_binary_data']?.toString() ?? '';
      final fileName = dataMap?['attachment_name']?.toString() ?? '';

      if (binaryBase64.isEmpty) {
        Fluttertoast.showToast(
          msg: 'No binary data found.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black,
          textColor: Colors.white,
        );
        return;
      }

      final pdfBytes = base64Decode(binaryBase64);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AttachmentPdfViewer(
            pdfBytes: pdfBytes,
            attchmentName: fileName,
          ),
        ),
      );
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      Fluttertoast.showToast(
        msg: 'Error: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
    }
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFF9F9F9F), width: 1),
      ),
      child: child,
    );
  }

  Widget _label(String text, {TextAlign? align}) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFB4B4B4),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _value(String text,
      {double? size, FontWeight? weight, Color? color, TextAlign? align}) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.inter(
        fontSize: size ?? 14.sp,
        fontWeight: weight ?? FontWeight.w800,
        color: color ?? const Color(0xFF0E0E0E),
        letterSpacing: 0.1,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestNo = _pick([
      _formData['request_no'],
      _formData['pettycash_no'],
      _formData['name'],
      _formData['ref_no'],
    ], fallback: widget.requestId);

    final requester = _pick([
      _formData['requester_name'],
      _formData['requester'],
      _formData['emp_name'],
      _formData['employee_name'],
    ]);

    final pettycashHolder = _pick([
      _formData['pettycash_holder'],
      _formData['holder_name'],
      _formData['holder'],
    ]);

    final pettycashLimit = _pick([
      _formData['pettycash_limit'],
      _formData['limit'],
      _formData['limit_amount'],
    ], fallback: '0');

    final projectName = _pick([
      _formData['project_name'],
      _formData['project_title'],
      _formData['project'],
    ]);

    final date = _pick([
      _formData['date'],
      _formData['request_date'],
      _formData['req_date'],
    ]);

    final total = _pick([
      _formData['total'],
      _formData['total_amount'],
      _formData['amount_total'],
    ], fallback: '0');

    final lines = _formData['lines'] as List? ?? [];

    final userId =
        SharedPref.getLoginData().result?.data?.uid?.toString() ?? '';

    final pillWidth = ((MediaQuery.of(context).size.width - 40.w) - 16.w) / 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: HeaderWidget(),
      body: SafeArea(
        top: false,
        child: (_isLoading && _formData.isEmpty)
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        _error,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      if (_isLoading && _formData.isNotEmpty)
                        const LinearProgressIndicator(
                          backgroundColor: Color(0xFFE0E0E0),
                          color: Color(0xFF0A3887),
                          minHeight: 3,
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.w),
                          child: Column(
                            children: [
                              SizedBox(height: 4.w),
                              Text(
                                'PETTYCASH DETAILS',
                                style: GoogleFonts.inter(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0E0E0E),
                                  letterSpacing: 0.6,
                                ),
                              ),
                              SizedBox(height: 16.w),
                              // Row 1: Req No | Requester
                              Row(
                                children: [
                                  Expanded(
                                    child: _card(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 14.w, vertical: 12.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _label('Req No'),
                                          SizedBox(height: 8.w),
                                          _value(requestNo,
                                              size: 11.5.sp,
                                              weight: FontWeight.w900),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: _card(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 14.w, vertical: 12.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _label('Requester'),
                                          SizedBox(height: 8.w),
                                          _value(requester,
                                              size: 11.5.sp,
                                              weight: FontWeight.w900),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.w),
                              // Row 2: Pettycash Holder | Pettycash Limit
                              Row(
                                children: [
                                  Expanded(
                                    child: _card(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 14.w, vertical: 12.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _label('Pettycash Holder'),
                                          SizedBox(height: 8.w),
                                          _value(pettycashHolder,
                                              size: 11.5.sp,
                                              weight: FontWeight.w900),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: _card(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 14.w, vertical: 12.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _label('Pettycash Limit'),
                                          SizedBox(height: 8.w),
                                          _value(pettycashLimit,
                                              size: 11.5.sp,
                                              weight: FontWeight.w900),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.w),
                              // Items card
                              _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (lines.isNotEmpty)
                                      ...lines.asMap().entries.map((entry) {
                                        final i = entry.key;
                                        final line = entry.value;
                                        final lineMap = line as Map? ?? {};
                                        final description = _pick([
                                          lineMap['description'],
                                          lineMap['name'],
                                          projectName,
                                        ], fallback: 'Item');
                                        final lineDate = _pick([
                                          lineMap['date'],
                                          lineMap['line_date'],
                                          date,
                                        ]);
                                        final amount = _pick([
                                          lineMap['amount'],
                                          lineMap['price'],
                                          lineMap['subtotal'],
                                        ], fallback: '0');

                                        return Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      _value(description,
                                                          size: 14.sp,
                                                          weight: FontWeight.w900),
                                                      SizedBox(height: 6.w),
                                                      _label(lineDate),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(width: 12.w),
                                                _value(amount,
                                                    size: 14.sp,
                                                    weight: FontWeight.w900,
                                                    color: const Color(0xFF15A98A)),
                                              ],
                                            ),
                                            if (i < lines.length - 1) ...[
                                              SizedBox(height: 10.w),
                                              const Divider(
                                                color: Color(0xFFD2D2D2),
                                                height: 1,
                                              ),
                                              SizedBox(height: 10.w),
                                            ],
                                          ],
                                        );
                                      })
                                    else
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _value(projectName,
                                                    size: 14.sp,
                                                    weight: FontWeight.w900),
                                                SizedBox(height: 6.w),
                                                _label(date),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 12.w),
                                          _value(pettycashLimit,
                                              size: 14.sp,
                                              weight: FontWeight.w900,
                                              color: const Color(0xFF15A98A)),
                                        ],
                                      ),
                                    SizedBox(height: 8.w),
                                    Center(
                                      child: Icon(
                                        Icons.keyboard_double_arrow_down_rounded,
                                        color: const Color(0xFFBFBFBF),
                                        size: 38.w,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10.w),
                              // Total card
                              _card(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 12.w),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _value('TOTAL',
                                        size: 15.sp,
                                        weight: FontWeight.w900,
                                        color: const Color(0xFFD31721)),
                                    _value(total,
                                        size: 18.sp,
                                        weight: FontWeight.w900,
                                        color: const Color(0xFFD31721)),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10.w),
                              // Attachments button
                              SizedBox(
                                width: double.infinity,
                                height: 46.w,
                                child: ElevatedButton.icon(
                                  onPressed: _attachmentIds.isEmpty
                                      ? null
                                      : _viewAttachment,
                                  icon: Icon(Icons.attach_file,
                                      color: Colors.white, size: 18.w),
                                  label: Text(
                                    'View Attachments',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF64676B),
                                    disabledBackgroundColor:
                                        const Color(0xFF64676B)
                                            .withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.r),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 14.w),
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 14.w),
                          child: Center(
                            child: ApprovalActionButtons(
                              requestId: widget.requestId,
                              type: widget.type,
                              userIds: [userId],
                              variant: ApprovalActionButtonsVariant.pill,
                              pillWidth: pillWidth,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
