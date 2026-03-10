import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_action_buttons.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class HrDetailsScreen extends StatefulWidget {
  final String requestId;
  final String type;

  const HrDetailsScreen({
    super.key,
    required this.requestId,
    required this.type,
  });

  @override
  State<HrDetailsScreen> createState() => _HrDetailsScreenState();
}

class _HrDetailsScreenState extends State<HrDetailsScreen> {
  static const String _localFakeHrRequestId = 'LOCAL_FAKE_HR_001';

  bool _isLoading = true;
  String _error = '';

  Map<String, dynamic> _formData = const {};

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

  bool get _isLocalFakeRequest => widget.requestId == _localFakeHrRequestId;

  Map<String, dynamic> _buildLocalFakeFormData() {
    return {
      'request_no': 'REQ/FAKE/001',
      'request_type': 'Annual Leave',
      'employee_name': 'Local Test Employee',
      'employee_id': 'EMP-FAKE-001',
      'request_date': '2026-03-04',
      'start_date': '2026-03-10',
      'duration': '3',
      'end_date': '2026-03-12',
      'balance_leave': '8',
    };
  }

  @override
  void initState() {
    super.initState();
    if (_isLocalFakeRequest) {
      _formData = _buildLocalFakeFormData();
      _isLoading = false;
      return;
    }
    _fetchHrDetails();
  }

  Future<void> _fetchHrDetails() async {
    final token = SharedPref.getLoginData().result?.token;
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('https://erp.elrace.com/api/get_hr_request_details');
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'params': {
        'request_id': int.tryParse(widget.requestId),
      },
    });

    print('🔵 HR Details Request - ID: ${widget.requestId}');
    print('🔵 URL: $url');
    print('🔵 Body: $body');

    try {
      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print('🔵 Response Status: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (data['result'] != null) {
        final result = data['result'] as Map;
        final rawData = result['data'] as Map? ?? {};
        // Data is inside form_view
        final formData = rawData['form_view'] as Map? ?? rawData;

        print('🟢 Success - FormData: $formData');

        setState(() {
          _formData = Map<String, dynamic>.from(formData);
          _isLoading = false;
        });
      } else {
        print('🔴 Error - No result in response: $data');
        setState(() {
          _error = data['error']?['message'] ?? 'Failed to load HR details';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('🔴 Exception: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
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

  Widget _buildEmployeeImage(String imageData) {
    // Check if it's a base64 encoded image
    if (imageData.startsWith('data:image') ||
        (!imageData.startsWith('http://') &&
            !imageData.startsWith('https://'))) {
      try {
        // Remove the data:image/png;base64, prefix if it exists
        String base64String = imageData;
        if (imageData.contains('base64,')) {
          base64String = imageData.split('base64,')[1];
        }

        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.person,
            color: const Color(0xFF6B6B6B),
            size: 30.w,
          ),
        );
      } catch (e) {
        print('🔴 Error decoding base64 image: $e');
        return Icon(
          Icons.person,
          color: const Color(0xFF6B6B6B),
          size: 30.w,
        );
      }
    }

    // It's a URL, use Image.network
    return Image.network(
      imageData,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (_, __, ___) => Icon(
        Icons.person,
        color: const Color(0xFF6B6B6B),
        size: 30.w,
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _value(label, size: 13.sp, weight: FontWeight.w600),
          _value(value, size: 13.sp, weight: FontWeight.w900),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestNo = _pick([
      _formData['request_no'],
      _formData['name'],
      _formData['ref_no'],
    ], fallback: widget.requestId);

    final requestType = _pick([
      _formData['request_type'],
      _formData['holiday_status_id'],
      _formData['leave_type'],
      _formData['type'],
    ], fallback: 'HR Request');

    final employeeName = _pick([
      _formData['employee_name'],
      _formData['employee_id'],
      _formData['emp_name'],
      _formData['requester_name'],
    ], fallback: 'Employee Name');

    // Additional name for manager or secondary person
    final secondaryName = _pick([
      _formData['manager_name'],
      _formData['parent_id'],
      _formData['department_manager'],
      _formData['approver_name'],
    ]);

    final employeeImage = _pick([
      _formData['employee_image'],
      _formData['image_emp'],
      _formData['emp_image'],
      _formData['employee_img'],
      _formData['image'],
      _formData['avatar'],
      _formData['photo'],
      _formData['profile_image'],
    ]);

    // Log the image URL for debugging
    if (employeeImage.isNotEmpty) {
      print('🟢 Employee Image URL: $employeeImage');
    } else {
      print('🔴 No employee image found in data');
      print('🔴 Available keys: ${_formData.keys.toList()}');
    }

    final requestDate = _pick([
      _formData['request_date'],
      _formData['date'],
      _formData['create_date'],
    ]);

    final startDate = _pick([
      _formData['start_date'],
      _formData['date_from'],
      _formData['request_date_from'],
    ]);

    final duration = _pick([
      _formData['duration'],
      _formData['number_of_days'],
    ], fallback: '0');

    final endDate = _pick([
      _formData['end_date'],
      _formData['date_to'],
      _formData['request_date_to'],
    ]);

    String balanceLeaveRaw = _pick([
      _formData['balance_leave'],
      _formData['remaining_leaves'],
      _formData['leave_balance'],
    ]);
    // Format balance leave to avoid excessive decimal places
    final balanceLeave = () {
      if (balanceLeaveRaw.isEmpty) return balanceLeaveRaw;
      final num? parsed = num.tryParse(balanceLeaveRaw);
      if (parsed == null) return balanceLeaveRaw;
      // Show as integer if no fractional part, else 2 decimal places
      if (parsed == parsed.truncate()) return parsed.toInt().toString();
      return parsed.toStringAsFixed(2);
    }();

    final userId =
        SharedPref.getLoginData().result?.data?.uid?.toString() ?? '';

    final pillWidth =
      ((MediaQuery.of(context).size.width - 96.w) / 2).clamp(110.w, 150.w);

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
                                'HR DETAILS',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0E0E0E),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 14.w),

                              // Employee Info Card
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 12.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1C1E),
                                  borderRadius: BorderRadius.circular(50.r),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50.w,
                                      height: 50.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: employeeImage.isNotEmpty
                                            ? _buildEmployeeImage(employeeImage)
                                            : Icon(
                                                Icons.person,
                                                color: const Color(0xFF6B6B6B),
                                                size: 30.w,
                                              ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            employeeName,
                                            style: GoogleFonts.inter(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                          if (secondaryName.isNotEmpty)
                                            Text(
                                              secondaryName,
                                              style: GoogleFonts.inter(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                              ),
                                            ),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _label('Request No'),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          _label('Request Type'),
                                          SizedBox(height: 6.w),
                                          _value(requestType,
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
                                    Center(child: _label('Request Details')),
                                    SizedBox(height: 12.w),
                                    _detailRow('Request Date', requestDate),
                                    Divider(
                                      color: const Color(0xFFE0E0E0),
                                      height: 1,
                                    ),
                                    _detailRow('Start Date', startDate),
                                    Divider(
                                      color: const Color(0xFFE0E0E0),
                                      height: 1,
                                    ),
                                    _detailRow('Duration', '$duration days'),
                                    Divider(
                                      color: const Color(0xFFE0E0E0),
                                      height: 1,
                                    ),
                                    _detailRow('End Date', endDate),
                                    if (balanceLeave.isNotEmpty) ...[
                                      Divider(
                                        color: const Color(0xFFE0E0E0),
                                        height: 1,
                                      ),
                                      _detailRow('Balance Leave', balanceLeave),
                                    ],
                                  ],
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
                              showHrApproveConfirmation: true,
                              enableFakeApproveDemo: _isLocalFakeRequest,
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
