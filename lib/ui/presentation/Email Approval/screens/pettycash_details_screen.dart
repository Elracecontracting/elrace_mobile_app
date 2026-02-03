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

  const PettyCashDetailsScreen({
    super.key,
    required this.requestId,
    required this.type,
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
    _fetchPettyCashDetails();
  }

  Future<void> _fetchPettyCashDetails() async {
    final token = SharedPref.getLoginData().result?.token;
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('https://erp.elrace.com/api/get_pettycash_details');
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'params': {
        'pettycash_id': int.tryParse(widget.requestId),
      },
    });

    try {
      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      if (data['result'] != null) {
        final result = data['result'] as Map;
        final formData = result['data'] as Map? ?? {};
        final attachmentList = result['attachment_ids'] as List? ?? [];

        setState(() {
          _formData = Map<String, dynamic>.from(formData);
          _attachmentIds = attachmentList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load Petty Cash details';
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
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFBDBDBD), width: 1),
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
        fontWeight: FontWeight.w700,
        color: const Color(0xFFB0B0B0),
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
        fontSize: size ?? 13.sp,
        fontWeight: weight ?? FontWeight.w600,
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
    ], fallback: 'Requester');

    final pettycashHolder = _pick([
      _formData['pettycash_holder'],
      _formData['holder_name'],
      _formData['holder'],
    ], fallback: 'Petty Cash Holder');

    final pettycashLimit = _pick([
      _formData['pettycash_limit'],
      _formData['limit'],
      _formData['limit_amount'],
    ], fallback: '0');

    final projectName = _pick([
      _formData['project_name'],
      _formData['project_title'],
      _formData['project'],
    ], fallback: 'Project Name');

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

    // Parse lines for petty cash items
    final lines = _formData['lines'] as List? ?? [];

    final userId =
        SharedPref.getLoginData().result?.data?.uid?.toString() ?? '';

    final pillWidth = ((MediaQuery.of(context).size.width - 40.w) - 16.w) / 2;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HeaderWidget(),
      body: SafeArea(
        top: false,
        child: _isLoading
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
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 10.w),
                          child: Column(
                            children: [
                              SizedBox(height: 8.w),
                              Text(
                                'PETTYCASH DETAILS',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0E0E0E),
                                  letterSpacing: 0.6,
                                ),
                              ),
                              SizedBox(height: 14.w),

                              _card(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 18.w, vertical: 14.w),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _label('Request No.'),
                                          SizedBox(height: 6.w),
                                          _value(requestNo,
                                              size: 12.sp,
                                              weight: FontWeight.w900),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 44.w,
                                      color: const Color(0xFFBDBDBD),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          _label('Requester'),
                                          SizedBox(height: 6.w),
                                          _value(requester,
                                              size: 12.sp,
                                              weight: FontWeight.w900,
                                              align: TextAlign.end),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12.w),

                              _card(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 18.w, vertical: 14.w),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _label('Pettycash Holder'),
                                          SizedBox(height: 6.w),
                                          _value(pettycashHolder,
                                              size: 12.sp,
                                              weight: FontWeight.w900),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 44.w,
                                      color: const Color(0xFFBDBDBD),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          _label('Pettycash Limit'),
                                          SizedBox(height: 6.w),
                                          _value(pettycashLimit,
                                              size: 12.sp,
                                              weight: FontWeight.w900,
                                              align: TextAlign.end),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12.w),

                              _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _value(projectName,
                                              size: 15.sp, weight: FontWeight.w900),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.w),
                                    _label(date),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12.w),

                              // Petty Cash Items List
                              _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...lines.map((line) {
                                      final lineMap = line as Map? ?? {};
                                      final description = _pick([
                                        lineMap['description'],
                                        lineMap['name'],
                                      ], fallback: 'Item');
                                      final lineDate = _pick([
                                        lineMap['date'],
                                      ], fallback: date);
                                      final amount = _pick([
                                        lineMap['amount'],
                                        lineMap['price'],
                                      ], fallback: '0');

                                      return Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _value(description,
                                                        size: 13.sp,
                                                        weight: FontWeight.w900),
                                                    SizedBox(height: 4.w),
                                                    _label(lineDate),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              _value(amount,
                                                  size: 14.sp,
                                                  weight: FontWeight.w900,
                                                  color: const Color(0xFF1E9B7E)),
                                            ],
                                          ),
                                          if (lines.last != line) ...[
                                            SizedBox(height: 12.w),
                                            Divider(
                                              color: const Color(0xFFE0E0E0),
                                              height: 1,
                                            ),
                                            SizedBox(height: 12.w),
                                          ],
                                        ],
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12.w),

                              _card(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 18.w, vertical: 14.w),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _value('TOTAL',
                                        size: 14.sp,
                                        weight: FontWeight.w900,
                                        color: Colors.red),
                                    _value(total,
                                        size: 16.sp,
                                        weight: FontWeight.w900,
                                        color: Colors.red),
                                  ],
                                ),
                              ),
                              SizedBox(height: 14.w),

                              SizedBox(
                                width: double.infinity,
                                height: 52.w,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _attachmentIds.isEmpty ? null : _viewAttachment,
                                  icon: const Icon(Icons.attach_file,
                                      color: Colors.white),
                                  label: Text(
                                    'View Attachments',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6B6B6B),
                                    disabledBackgroundColor:
                                        const Color(0xFF6B6B6B).withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20.w),
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.w),
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
