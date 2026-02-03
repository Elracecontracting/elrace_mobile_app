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

class InvoiceDetailsScreen extends StatefulWidget {
  final String requestId;
  final String type;

  const InvoiceDetailsScreen({
    super.key,
    required this.requestId,
    required this.type,
  });

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
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
    _fetchInvoiceDetails();
  }

  Future<void> _fetchInvoiceDetails() async {
    final token = SharedPref.getLoginData().result?.token;
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('https://erp.elrace.com/api/get_invoice_details');
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'params': {
        'invoice_id': int.tryParse(widget.requestId),
      },
    });

    try {
      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        throw Exception('Failed to load invoice details: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final result = (decoded['result'] as Map?)?['data'] as Map?;
      final formView = (result?['form_view'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final attachmentIds = (result?['attachment_ids'] as List?) ?? const [];

      if (!mounted) return;
      setState(() {
        _formData = formView;
        _attachmentIds = attachmentIds;
        _isLoading = false;
        _error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _viewAttachment() async {
    if (_attachmentIds.isEmpty) {
      Fluttertoast.showToast(
        msg: 'No attachment found.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
      return;
    }

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
      _formData['invoice_no_code'],
      _formData['invoice_no'],
      _formData['name'],
      _formData['ref_no'],
    ], fallback: widget.requestId);

    final reqDate = _pick([
      _formData['req_date'],
      _formData['request_date'],
      _formData['invoice_date'],
      _formData['date_of_invoice'],
      _formData['date'],
    ]);

    final vendorName = _pick([
      _formData['vendor_name'],
      _formData['vendor'],
      _formData['partner_name'],
      _formData['client_name'],
      _formData['supplier'],
    ], fallback: 'Vendor Name');

    final projectName = _pick([
      _formData['project_name'],
      _formData['project_title'],
      _formData['project'],
      _formData['project_name_id'],
      _formData['project_id'],
      _formData['name'],
    ], fallback: 'Project Name');

    final lpoContract = _pick([
      _formData['lpo_no'],
      _formData['lpo'],
      _formData['lpo_number'],
      _formData['contract'],
      _formData['contract_no'],
    ], fallback: '');

    final remainingBalance = _pick([
      _formData['remaining_balance'],
      _formData['balance'],
      _formData['balance_amount'],
    ], fallback: '');

    final tag = _pick([
      _formData['tag'],
      _formData['invoice_tag'],
    ], fallback: '');

    final totalAmount = _pick([
      _formData['total_amount'],
      _formData['amount_total'],
      _formData['amount'],
      _formData['total'],
    ], fallback: '');

    final previous = _pick([
      _formData['previous_amount'],
      _formData['previous'],
    ], fallback: '');

    final retention = _pick([
      _formData['retention'],
      _formData['retention_percent'],
    ], fallback: '');

    final userId =
        SharedPref.getLoginData().result?.data?.uid?.toString() ?? '';

    final pillWidth = ((MediaQuery.of(context).size.width - 40.w) - 16.w) / 2;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
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
                                'INVOICE DETAILS',
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
                                    _label('Req No'),
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
                                    _label('Req Date'),
                                    SizedBox(height: 6.w),
                                    _value(reqDate,
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
                                    _label('Vendor Name'),
                              SizedBox(height: 8.w),
                              _value(vendorName,
                                  size: 16.sp, weight: FontWeight.w900),
                            ],
                          ),
                              ),
                              SizedBox(height: 12.w),

                              _card(
                                child: Row(
                            children: [
                              Container(
                                width: 44.w,
                                height: 44.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFB10D0D),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/png/invoice-icon.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const SizedBox(),
                                  ),
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: _value(projectName,
                                    size: 15.sp, weight: FontWeight.w900),
                              ),
                            ],
                          ),
                              ),
                              SizedBox(height: 12.w),

                              _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('LPO / Contract'),
                                    SizedBox(height: 8.w),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _value(lpoContract,
                                                  size: 14.sp,
                                                  weight: FontWeight.w900),
                                              SizedBox(height: 16.w),
                                              Text(
                                                'Tag',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w900,
                                                  color: const Color(0xFF0E0E0E),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 56.w,
                                          color: const Color(0xFFBDBDBD),
                                        ),
                                        SizedBox(width: 14.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _value(totalAmount,
                                                  size: 18.sp,
                                                  weight: FontWeight.w900,
                                                  color: const Color(0xFFBA1719),
                                                  align: TextAlign.start),
                                              SizedBox(height: 4.w),
                                              _label('Remaining Balance',
                                                  align: TextAlign.start),
                                              SizedBox(height: 8.w),
                                              _value(tag,
                                                  size: 16.sp,
                                                  weight: FontWeight.w900,
                                                  color: const Color(0xFFFF8C00),
                                                  align: TextAlign.start),
                                            ],
                                          ),
                                        ),
                                      ],
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _label('Invoice Details'),
                                  Text(
                                    reqDate,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFB0B0B0),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.w),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.w, vertical: 8.w),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                        border: Border.all(
                                            color: const Color(0xFFBDBDBD)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _value('Total',
                                              size: 11.sp,
                                              weight: FontWeight.w900),
                                          SizedBox(height: 4.w),
                                          _value(totalAmount,
                                              size: 11.sp,
                                              weight: FontWeight.w900,
                                              color: const Color(0xFFBA1719)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.w, vertical: 8.w),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                        border: Border.all(
                                            color: const Color(0xFFBDBDBD)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _value('Previous',
                                              size: 11.sp,
                                              weight: FontWeight.w900),
                                          SizedBox(height: 4.w),
                                          _value(previous,
                                              size: 11.sp,
                                              weight: FontWeight.w900,
                                              color: const Color(0xFF6B717B)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.w, vertical: 8.w),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                        border: Border.all(
                                            color: const Color(0xFFBDBDBD)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _value('Retention',
                                              size: 11.sp,
                                              weight: FontWeight.w900),
                                          SizedBox(height: 4.w),
                                          _value(retention,
                                              size: 11.sp,
                                              weight: FontWeight.w900,
                                              color: const Color(0xFF6B717B)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
