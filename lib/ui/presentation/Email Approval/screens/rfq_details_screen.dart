import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_action_buttons.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/file_binary.dart';
import 'package:el_race/ui/widgets/header_widget.dart';

class RfqDetailsScreen extends StatefulWidget {
  final String requestId;
  final String type;
  final Map<String, dynamic>? initialData;

  const RfqDetailsScreen({
    super.key,
    required this.requestId,
    required this.type,
    this.initialData,
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
    // Pre-populate with card data immediately so screen isn't blank
    if (widget.initialData != null) {
      _formData = Map<String, dynamic>.from(widget.initialData!);
    }
    _fetchRfqDetails();
  }

  String _pick(List<dynamic> values, {String fallback = ''}) {
    for (var val in values) {
      if (val == null || val == false || val == true) continue;
      final str = val.toString().trim();
      if (str.isEmpty ||
          str.toLowerCase() == 'false' ||
          str.toLowerCase() == 'true' ||
          str.toLowerCase() == 'null') continue;
      return str;
    }
    return fallback;
  }

  String _displayOrNA(String? value) {
    final normalized = (value ?? '').trim();
    return normalized.isEmpty ? 'N/A' : normalized;
  }

  String _normalizeImageUrl(String? rawUrl) {
    final value = (rawUrl ?? '').trim();
    if (value.isEmpty) return '';
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;
    if (value.startsWith('/')) return 'https://erp.elrace.com$value';
    return 'https://erp.elrace.com/$value';
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

    print('══════════ [RFQ] API REQUEST ══════════');
    print('[RFQ] URL: $url');
    print('[RFQ] METHOD: GET');
    print(
        '[RFQ] HEADERS: ${headers.map((k, v) => MapEntry(k, k == "Authorization" ? "Bearer ***" : v))}');
    print('[RFQ] BODY: $body');
    print('═══════════════════════════════════════');

    try {
      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print('══════════ [RFQ] API RESPONSE ══════════');
      print('[RFQ] STATUS: ${response.statusCode}');
      print('[RFQ] BODY: ${response.body}');
      print('════════════════════════════════════════');

      final data = jsonDecode(response.body);

      if (data['result'] != null) {
        final result = data['result'] as Map;
        final formData = result['data'] as Map? ?? {};
        final attachmentList = result['attachment_ids'] as List? ?? [];

        print('[RFQ] PARSED formData keys: ${formData.keys.toList()}');
        print('[RFQ] PARSED formData: $formData');
        print('[RFQ] PARSED attachmentIds: $attachmentList');

        setState(() {
          // Merge: start with initialData (card fields), then overlay API response
          final merged = Map<String, dynamic>.from(_formData);
          merged.addAll(Map<String, dynamic>.from(formData));
          _formData = merged;
          _attachmentIds = attachmentList.map((e) => e.toString()).toList();
          _isLoading = false;
        });
      } else {
        print('[RFQ] ERROR: result is null. Full response: ${response.body}');
        setState(() {
          // Keep pre-populated card data even if API fails
          _isLoading = false;
          if (_formData.isEmpty) {
            _error = 'Failed to load RFQ details';
          }
        });
      }
    } catch (e) {
      print('══════════ [RFQ] API ERROR ══════════');
      print('[RFQ] EXCEPTION: $e');
      print('══════════════════════════════════════');
      setState(() {
        _isLoading = false;
        // Only show error if we have no pre-populated data to show
        if (_formData.isEmpty) {
          _error = 'Error loading RFQ details: $e';
        }
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
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFF9F9F9F), width: 1),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text, {TextAlign? align}) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFADADAD),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _label(String text, {TextAlign? align}) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFA9A9A9),
      ),
    );
  }

  Widget _value(String text,
      {double? size, FontWeight? weight, Color? color, TextAlign? align}) {
    return Text(
      _displayOrNA(text),
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

  Widget _tagChip(String text, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildClientAvatar({required String imageUrl, required String name}) {
    final initials = name.trim().isEmpty ? 'CL' : name.trim()[0].toUpperCase();

    Widget placeholder() {
      return Container(
        color: const Color(0xFFE8EDF5),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF4A607A),
          ),
        ),
      );
    }

    if (imageUrl.isEmpty) {
      return ClipOval(child: placeholder());
    }

    return ClipOval(
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return placeholder();
        },
      ),
    );
  }

  Widget _bulletLine({required String label, String? value, bool dim = false}) {
    final hasValue = value != null;
    final displayLabel = _displayOrNA(label);
    final displayValue = _displayOrNA(value);
    return Padding(
      padding: EdgeInsets.only(bottom: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4.w),
            child: Text(
              '•',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: dim ? const Color(0xFFBDBDBD) : const Color(0xFF0E0E0E),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: displayLabel,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: dim
                          ? const Color(0xFFBDBDBD)
                          : const Color(0xFF131313),
                    ),
                  ),
                  if (hasValue)
                    TextSpan(
                      text: ' $displayValue',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: dim
                            ? const Color(0xFFBDBDBD)
                            : const Color(0xFF131313),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(String raw) {
    if (raw.trim().isEmpty) return 'N/A';
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    final value = double.tryParse(cleaned);
    if (value == null) return 'N/A';
    if (value % 1 == 0) {
      return NumberFormat('#,##0', 'en_US').format(value);
    }
    return NumberFormat('#,##0.##', 'en_US').format(value);
  }

  List<String> _extractTags(List<dynamic> candidates) {
    for (final raw in candidates) {
      if (raw == null || raw == false || raw == true) continue;

      if (raw is List) {
        final listTags = raw
            .map((e) => e.toString().trim())
            .map((e) => e
                .replaceAll('[', '')
                .replaceAll(']', '')
                .replaceAll('"', '')
                .replaceAll("'", '')
                .trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (listTags.isNotEmpty) return listTags;
        continue;
      }

      final str = raw.toString().trim();
      if (str.isEmpty ||
          str.toLowerCase() == 'null' ||
          str.toLowerCase() == 'false' ||
          str.toLowerCase() == 'true') {
        continue;
      }

      final parsed = str
          .split(RegExp(r'[,|]'))
          .map((e) => e.trim())
          .map((e) => e
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .replaceAll("'", '')
              .trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (parsed.isNotEmpty) return parsed;
    }

    return const <String>[];
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
      _formData['client'],
      _formData['supplier'],
    ], fallback: '');

    final projectName = _pick([
      _formData['project_name'],
      _formData['project_title'],
      _formData['project'],
      _formData['project_name_id'],
      _formData['project_id'],
      _formData['name'],
    ]);

    final lpoContract = _pick([
      _formData['lpo_no'],
      _formData['lpo'],
      _formData['lpo_number'],
      _formData['contract'],
      _formData['contract_no'],
    ], fallback: '');

    final workOrderNo = _pick([
      _formData['work_order_no'],
      _formData['work_order_number'],
      _formData['wo_no'],
      _formData['wono'],
    ]);

    final lpoDate = _pick([
      _formData['lpo_date'],
      _formData['contract_date'],
      _formData['date_lpo'],
      _formData['due_date'],
    ]);

    final lpoType = _pick([
      _formData['lpo_type'],
      _formData['lpo_contract_type'],
      _formData['contract_type'],
      _formData['po_type'],
      _formData['type_name'],
    ]);

    final totalAmount = _pick([
      _formData['total_amount'],
      _formData['amount_total'],
      _formData['amount'],
      _formData['total'],
    ], fallback: '');

    final materialType = _pick([
      _formData['material_type'],
      _formData['material_type_name'],
      _formData['material'],
      _formData['item_type'],
      _formData['product_type'],
    ]);

    final clientPhotoUrl = _normalizeImageUrl(_pick([
      _formData['client_photo_url'],
      _formData['vendor_photo_url'],
      _formData['partner_image_url'],
      _formData['image_url'],
      _formData['photo_url'],
    ]));

    final detailsDate = _pick([
      _formData['rfq_date'],
      _formData['req_date'],
      _formData['request_date'],
      _formData['date'],
    ], fallback: reqDate);

    final vendorTags = _extractTags([
      _formData['vendor_tag'],
      _formData['vendor_tags'],
      _formData['tags'],
      _formData['tag_names'],
      _formData['tag'],
      _formData['rfq_tag'],
    ]);

    final chips = vendorTags.take(4).toList();
    final formattedAmount = _formatAmount(totalAmount);

    final userId =
        SharedPref.getLoginData().result?.data?.uid?.toString() ?? '';

    final pillWidth =
        ((MediaQuery.of(context).size.width - 96.w) / 2).clamp(110.w, 150.w);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: const HeaderWidget(),
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
                              horizontal: 18.w, vertical: 10.w),
                          child: Column(
                            children: [
                              SizedBox(height: 8.w),
                              Text(
                                'RFQ DETAILS',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0E0E0E),
                                  letterSpacing: 0.1,
                                ),
                              ),
                              SizedBox(height: 14.w),
                              Row(
                                children: [
                                  Expanded(
                                    child: _card(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _sectionTitle('Req No'),
                                          SizedBox(height: 10.w),
                                          _value(requestNo,
                                              size: 12.sp,
                                              weight: FontWeight.w900),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _card(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _sectionTitle('Req Date'),
                                          SizedBox(height: 10.w),
                                          _value(reqDate,
                                              size: 12.sp,
                                              weight: FontWeight.w900),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.w),
                              _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionTitle('Vendor Details'),
                                    SizedBox(height: 8.w),
                                    _value(vendorName,
                                        size: 11.sp, weight: FontWeight.w900),
                                    if (chips.isNotEmpty) ...[
                                      SizedBox(height: 6.w),
                                      _label('Vendor Tags'),
                                      SizedBox(height: 8.w),
                                      Wrap(
                                        spacing: 8.w,
                                        runSpacing: 8.w,
                                        children: [
                                          for (int i = 0; i < chips.length; i++)
                                            _tagChip(
                                              chips[i],
                                              [
                                                const Color(0xFFE1E4FF),
                                                const Color(0xFFFCE6E6),
                                                const Color(0xFFFFF1D8),
                                                const Color(0xFFE1F5EC),
                                              ][i % 4],
                                              [
                                                const Color(0xFF3F51E8),
                                                const Color(0xFFD32F2F),
                                                const Color(0xFFE08A00),
                                                const Color(0xFF00A05A),
                                              ][i % 4],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(height: 12.w),
                              _card(
                                child: Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _sectionTitle('Project Details'),
                                        SizedBox(height: 8.w),
                                        _bulletLine(
                                          label: 'Project Name',
                                          value: projectName,
                                        ),
                                        _bulletLine(
                                          label: 'Work order no',
                                          value: workOrderNo,
                                          dim: true,
                                        ),
                                      ],
                                    ),
                                    PositionedDirectional(
                                      top: 0,
                                      end: 0,
                                      child: Container(
                                        width: 26.w,
                                        height: 26.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFC92626),
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: _buildClientAvatar(
                                            imageUrl: clientPhotoUrl,
                                            name: vendorName,
                                          ),
                                        ),
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
                                    _sectionTitle('LPO / Contract'),
                                    SizedBox(height: 8.w),
                                    if (lpoContract.isNotEmpty)
                                      _bulletLine(label: lpoContract),
                                    if (lpoDate.isNotEmpty)
                                      _bulletLine(label: lpoDate),
                                    if (lpoType.isNotEmpty)
                                      _bulletLine(label: lpoType),
                                    SizedBox(height: 2.w),
                                    if (formattedAmount.isNotEmpty)
                                      Align(
                                        alignment:
                                            AlignmentDirectional.centerEnd,
                                        child: _value(
                                          formattedAmount,
                                          size: 14.sp,
                                          weight: FontWeight.w900,
                                          color: const Color(0xFFE58B00),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _sectionTitle('RFQ Details'),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10.w, vertical: 4.w),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECECEC),
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                            border: Border.all(
                                                color: const Color(0xFF9F9F9F)),
                                          ),
                                          child: Text(
                                            _displayOrNA(detailsDate),
                                            style: GoogleFonts.inter(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF7C7C7C),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10.w),
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 8.w),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(top: 4.w),
                                            child: Text(
                                              '•',
                                              style: GoogleFonts.inter(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0E0E0E),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: 'Amount',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13.sp,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: const Color(
                                                          0xFF131313),
                                                    ),
                                                  ),
                                                  if (formattedAmount
                                                      .isNotEmpty)
                                                    TextSpan(
                                                      text: ' $formattedAmount',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13.sp,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: const Color(
                                                            0xFFE58B00),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _bulletLine(
                                      label: 'Material Type',
                                      value: materialType.trim().isEmpty
                                          ? null
                                          : materialType,
                                    ),
                                    Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: SizedBox(
                                        height: 28.w,
                                        child: ElevatedButton(
                                          onPressed: _attachmentIds.isEmpty
                                              ? null
                                              : _viewAttachment,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF64666D),
                                            disabledBackgroundColor:
                                                const Color(0xFF64666D)
                                                    .withValues(alpha: 0.45),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 14.w),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.r),
                                            ),
                                          ),
                                          child: Text(
                                            'View',
                                            style: GoogleFonts.inter(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 14.w),
                              SizedBox(
                                width: double.infinity,
                                height: 52.w,
                                child: ElevatedButton.icon(
                                  onPressed: _attachmentIds.isEmpty
                                      ? null
                                      : _viewAttachment,
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
                                    backgroundColor: const Color(0xFF64666D),
                                    disabledBackgroundColor:
                                        const Color(0xFF64666D)
                                            .withValues(alpha: 0.45),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20.w),
                            ],
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFB7B7B7),
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
                              pillHeight: 36.w,
                              pillSpacing: 24.w,
                              pillBorderRadius: BorderRadius.circular(20.r),
                              pillTextStyle: GoogleFonts.inter(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                height: 1,
                              ),
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
