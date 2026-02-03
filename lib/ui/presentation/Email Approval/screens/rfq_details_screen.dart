import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_action_buttons.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/file_binary.dart';
import 'package:el_race/ui/widgets/header_widget.dart';

class RfqDetailsScreen extends StatefulWidget {
  final String requestId;
  final String type;

  const RfqDetailsScreen({
    super.key,
    required this.requestId,
    required this.type,
  });

  @override
  State<RfqDetailsScreen> createState() => _RfqDetailsScreenState();
}

class _RfqDetailsScreenState extends State<RfqDetailsScreen> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic> _formData = {};
  List<String> _attachmentIds = [];

  @override
  void initState() {
    super.initState();
    _fetchRfqDetails();
  }

  String _pick(List<dynamic> values, {String fallback = ''}) {
    for (var val in values) {
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString();
      }
    }
    return fallback;
  }

  Future<void> _fetchRfqDetails() async {
    final token = SharedPref.getLoginData().result?.token;
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('https://erp.elrace.com/api/get_rfq_details');
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'params': {
        'rfq_id': int.tryParse(widget.requestId),
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
          _attachmentIds = attachmentList.map((e) => e.toString()).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load RFQ details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading RFQ details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _viewAttachment() async {
    if (_attachmentIds.isEmpty) return;

    final attachmentIdStr = _attachmentIds.first;
    final attachmentId = int.tryParse(attachmentIdStr) ?? 0;

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
      _formData['rfq_no_code'],
      _formData['rfq_no'],
      _formData['name'],
      _formData['ref_no'],
    ], fallback: widget.requestId);

    final reqDate = _pick([
      _formData['req_date'],
      _formData['request_date'],
      _formData['rfq_date'],
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

    final tag = _pick([
      _formData['tag'],
      _formData['rfq_tag'],
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
                                'RFQ DETAILS',
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
                                        _label('RFQ Details'),
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
