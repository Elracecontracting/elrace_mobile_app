import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_action_buttons.dart';
import 'package:el_race/ui/presentation/lpo/screens/lpo_pdf_viewer_screen.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
  static const String _localFakeRfqRequestId = 'LOCAL_FAKE_RFQ_001';
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic> _formData = {};

  bool get _isLocalFakeRequest => widget.requestId == _localFakeRfqRequestId;

  Map<String, dynamic> _buildLocalFakeRfqData() {
    return {
      'request_no': 'RFQ/1254/89585',
      'project_name': 'Project Name',
      'city_id': 'City',
      'department': 'Department',
      'vendor_name': 'Vendor Name',
      'vendor_tags': ['Ceiling', 'Civil', 'Fitout', 'Label'],
      'work_order_no': '123345654874954652',
      'request_date': '2025-01-10',
      'material_type': 'Ceramic',
      'total_amount': '1000000',
      'comment': '',
      'client_photo_url': '',
      'attachment_ids': ['1'],
    };
  }

  @override
  void initState() {
    super.initState();
    if (_isLocalFakeRequest) {
      final fake = _buildLocalFakeRfqData();
      _formData = fake;
      _isLoading = false;
      return;
    }
    if (widget.initialData != null) {
      _formData = Map<String, dynamic>.from(widget.initialData!);
    }
    _fetchRfqDetails();
  }

  String _pick(List<dynamic> values, {String fallback = ''}) {
    for (final val in values) {
      if (val == null || val == false || val == true) continue;
      final str = val.toString().trim();
      if (str.isEmpty) continue;
      final lower = str.toLowerCase();
      if (lower == 'null' || lower == 'false' || lower == 'true') continue;
      return str;
    }
    return fallback;
  }

  String _displayOrDash(String? value) {
    final normalized = (value ?? '').trim();
    return normalized.isEmpty ? '-' : normalized;
  }

  String _pickName(dynamic source, {String fallback = ''}) {
    if (source is Map) {
      final map = Map<String, dynamic>.from(source);
      return _pick([
        map['name'],
        map['display_name'],
        map['label'],
      ], fallback: fallback);
    }
    return _pick([source], fallback: fallback);
  }

  String _normalizeImageUrl(String? rawUrl) {
    final value = (rawUrl ?? '').trim();
    if (value.isEmpty) return '';
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;
    if (value.startsWith('/')) return 'https://erp.elrace.com$value';
    return 'https://erp.elrace.com/$value';
  }

  String _dateForDisplay(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '-';
    final normalized =
        value.contains(' ') ? value.replaceFirst(' ', 'T') : value;
    final parsed = DateTime.tryParse(normalized) ?? DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  String _formatAmount(String raw) {
    if (raw.trim().isEmpty) return '-';
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    final value = double.tryParse(cleaned);
    if (value == null) return _displayOrDash(raw);
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
      if (str.isEmpty) continue;
      final lower = str.toLowerCase();
      if (lower == 'null' || lower == 'false' || lower == 'true') continue;

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

  Map<String, dynamic> _extractRfqFormData(Map result) {
    final rawData = result['data'];
    if (rawData is! Map) return const <String, dynamic>{};

    final data = Map<String, dynamic>.from(rawData);
    final formView = data['form_view'];

    final flattened = Map<String, dynamic>.from(data);
    if (formView is Map) {
      flattened.addAll(Map<String, dynamic>.from(formView));
    }

    return flattened;
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
        final formData = _extractRfqFormData(result);

        setState(() {
          final merged = Map<String, dynamic>.from(_formData);
          merged.addAll(formData);
          _formData = merged;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          if (_formData.isEmpty) {
            _error = 'Failed to load RFQ details';
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (_formData.isEmpty) {
          _error = 'Error loading RFQ details: $e';
        }
      });
    }
  }

  Future<void> _viewAttachment() async {
    final poId = int.tryParse(widget.requestId);
    if (poId == null || poId <= 0) {
      Fluttertoast.showToast(
        msg: 'Invalid RFQ id.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
      return;
    }

    final token = SharedPref.getLoginData().result?.token;

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final data = {
      'jsonrpc': '2.0',
      'params': {
        'po_id': poId,
      },
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse('https://erp.elrace.com/api/po/report_url'),
        headers: headers,
        body: jsonEncode(data),
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (response.statusCode != 200) {
        Fluttertoast.showToast(
          msg: 'Failed to load PDF: HTTP ${response.statusCode}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black,
          textColor: Colors.white,
        );
        return;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final result = decoded['result'] as Map?;
      final pdfUrl = result?['report_url']?.toString() ?? '';

      if (pdfUrl.isEmpty) {
        final error = decoded['error'] as Map?;
        final errorData = error?['data'] as Map?;
        Fluttertoast.showToast(
          msg: result?['message']?.toString() ??
              result?['error']?.toString() ??
              errorData?['message']?.toString() ??
              error?['message']?.toString() ??
              'Failed to retrieve PDF URL.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black,
          textColor: Colors.white,
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LpoPdfViewerScreen(
            pdfUrl: pdfUrl,
            title: 'RFQ ${_pick([
                  _formData['title'],
                  _formData['request_no'],
                  _formData['rfq_no_code'],
                  _formData['rfq_no'],
                  _formData['name'],
                ], fallback: widget.requestId)}',
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

  Widget _tagChip(String text, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _simSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E2E2), width: 1),
              ),
            ),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5A5A5A),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoCell(String label, String value, {Color? valueColor}) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFA0A0A0),
            ),
          ),
          TextSpan(
            text: _displayOrDash(value),
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF202020),
            ),
          ),
        ],
      ),
      maxLines: null,
      overflow: TextOverflow.visible,
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
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
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

  @override
  Widget build(BuildContext context) {
    final requestNo = _pick([
      _formData['request_no'],
      _formData['rfq_no_code'],
      _formData['rfq_no'],
      _formData['title'],
      _formData['name'],
      _formData['ref_no'],
    ], fallback: widget.requestId);

    final reqDateRaw = _pick([
      _formData['request_date'],
      _formData['create_date'],
      _formData['req_date'],
      _formData['rfq_date'],
      _formData['date'],
    ]);
    final reqDate = _dateForDisplay(reqDateRaw);

    final projectName = _pick([
      _formData['project_name'],
      _formData['project_title'],
      _formData['project'],
      _formData['project_name_id'],
      _formData['project_id'],
      _formData['name'],
    ]);

    final city = _pick([
      _pickName(_formData['city_id']),
      _formData['city_id'],
      _formData['city'],
      _formData['branch'],
    ]);

    final department = _pick([
      _pickName(_formData['department_id']),
      _formData['department'],
      _formData['section'],
      _formData['dept_name'],
    ]);

    final vendorName = _pick([
      _formData['vendor_name'],
      _formData['vendor'],
      _formData['partner_name'],
      _formData['client_name'],
      _formData['client'],
      _formData['supplier'],
    ]);

    final workOrderNo = _pick([
      _formData['work_order_no'],
      _formData['work_order_number'],
      _formData['wo_no'],
      _formData['wono'],
      _formData['wo_no#'],
      _formData['wo'],
    ]);

    final totalAmount = _pick([
      _formData['total_amount'],
      _formData['amount_total'],
      _formData['amount'],
      _formData['total'],
    ]);
    final formattedAmount = _formatAmount(totalAmount);

    final materialType = _pick([
      _formData['material_type'],
      _formData['material_type_name'],
      _formData['material'],
      _formData['item_type'],
      _formData['product_type'],
    ]);

    final comment = _pick([
      _formData['comment'],
      _formData['note'],
      _formData['description'],
    ]);

    final clientPhotoUrl = _normalizeImageUrl(_pick([
      _formData['client_photo_url'],
      _formData['vendor_photo_url'],
      _formData['partner_image_url'],
      _formData['image_url'],
      _formData['photo_url'],
    ]));

    final tags = _extractTags([
      _formData['vendor_tag'],
      _formData['vendor_tags'],
      _formData['tags'],
      _formData['tag_names'],
      _formData['tag'],
      _formData['rfq_tag'],
    ]).take(4).toList();

    final canViewReport = int.tryParse(widget.requestId) != null;

    final userId =
        SharedPref.getLoginData().result?.data?.uid?.toString() ?? '';
    final pillWidth =
        ((MediaQuery.of(context).size.width - 96.w) / 2).clamp(110.w, 150.w);

    return Scaffold(
      backgroundColor: Colors.white,
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
                        style: GoogleFonts.poppins(
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
                                'RFQ',
                                style: GoogleFonts.poppins(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF0E0E0E),
                                ),
                              ),
                              SizedBox(height: 14.w),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 92.w,
                                    height: 92.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFC92626),
                                        width: 1,
                                      ),
                                    ),
                                    child: _buildClientAvatar(
                                      imageUrl: clientPhotoUrl,
                                      name: vendorName,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 12.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _displayOrDash(projectName),
                                            style: GoogleFonts.poppins(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF181818),
                                            ),
                                          ),
                                          SizedBox(height: 8.w),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 6.w,
                                                      vertical: 5.w),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFC9C9C9),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.r),
                                                  ),
                                                  child: Text(
                                                    _displayOrDash(requestNo),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: const Color(
                                                          0xFF1E1E1E),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 6.w,
                                                      vertical: 5.w),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFFFAE32),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.r),
                                                  ),
                                                  child: Text(
                                                    _displayOrDash(city),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: const Color(
                                                          0xFF1E1E1E),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 6.w,
                                                      vertical: 5.w),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF2EA6DE),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.r),
                                                  ),
                                                  child: Text(
                                                    _displayOrDash(department),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: const Color(
                                                          0xFF1E1E1E),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.w),
                              _simSectionCard(
                                title: 'Vendor Details',
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 10.w),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _displayOrDash(vendorName),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF111111),
                                        ),
                                      ),
                                      SizedBox(height: 6.w),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Vendor Tags',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF9D9D9D),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: tags.isEmpty
                                                ? Text(
                                                    '-',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: const Color(
                                                          0xFF9D9D9D),
                                                    ),
                                                  )
                                                : Wrap(
                                                    spacing: 8.w,
                                                    runSpacing: 4.w,
                                                    children: [
                                                      for (int i = 0;
                                                          i < tags.length;
                                                          i++)
                                                        _tagChip(
                                                          tags[i],
                                                          [
                                                            const Color(
                                                                0xFFE1E4FF),
                                                            const Color(
                                                                0xFFFCE6E6),
                                                            const Color(
                                                                0xFFFFF1D8),
                                                            const Color(
                                                                0xFFE1F5EC),
                                                          ][i % 4],
                                                          [
                                                            const Color(
                                                                0xFF3F51E8),
                                                            const Color(
                                                                0xFFD32F2F),
                                                            const Color(
                                                                0xFFE08A00),
                                                            const Color(
                                                                0xFF00A05A),
                                                          ][i % 4],
                                                        ),
                                                    ],
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.w),
                              _simSectionCard(
                                title: 'RFQ Info',
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10.w,
                                                vertical: 8.w),
                                            child: _buildInfoCell(
                                              'W.O No#',
                                              workOrderNo,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 40.w,
                                          color: const Color(0xFFE6E6E6),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10.w,
                                                vertical: 8.w),
                                            child: _buildInfoCell(
                                              'Request Date',
                                              reqDate,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFE6E6E6),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10.w,
                                                vertical: 8.w),
                                            child: _buildInfoCell(
                                              'RFQ Amount',
                                              formattedAmount,
                                              valueColor:
                                                  const Color(0xFFFF8A00),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 40.w,
                                          color: const Color(0xFFE6E6E6),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10.w,
                                                vertical: 8.w),
                                            child: _buildInfoCell(
                                              'Material Type',
                                              materialType,
                                              valueColor:
                                                  const Color(0xFFFF8A00),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12.w),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(
                                      color: const Color(0xFF9E9E9E), width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Comment',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF5A5A5A),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${comment.characters.length}/50',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFFA8A8A8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6.w),
                                    Container(
                                      width: double.infinity,
                                      constraints:
                                          BoxConstraints(minHeight: 38.w),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.w, vertical: 8.w),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4F4F4),
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                        border: Border.all(
                                            color: const Color(0xFFDADADA),
                                            width: 1),
                                      ),
                                      child: Text(
                                        _displayOrDash(comment),
                                        maxLines: null,
                                        overflow: TextOverflow.visible,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF3B3B3B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (canViewReport) ...[
                                SizedBox(height: 16.w),
                                SizedBox(
                                  width: 0.88.sw,
                                  child: InkWell(
                                    onTap: _viewAttachment,
                                    borderRadius: BorderRadius.circular(14.r),
                                    child: Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 13.w),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(14.r),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xFF777B84),
                                            Color(0xFF63676F),
                                          ],
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.attach_file_rounded,
                                            color: Colors.white,
                                            size: 20.sp,
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'View Attachments',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(height: 20.w),
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 12.w),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 12.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD7D7D7),
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            child: Center(
                              child: ApprovalActionButtons(
                                requestId: widget.requestId,
                                type: widget.type,
                                userIds: [userId],
                                variant: ApprovalActionButtonsVariant.pill,
                                showHrApproveConfirmation: true,
                                pillWidth: pillWidth,
                                pillHeight: 36.w,
                                pillSpacing: 24.w,
                                pillBorderRadius: BorderRadius.circular(20.r),
                                pillTextStyle: GoogleFonts.poppins(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  height: 1,
                                ),
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
