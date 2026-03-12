import 'dart:convert';

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
  static const Map<int, String> _caseByTypeId = {
    35849: 'sick',
    35651: 'short',
    35842: 'annual',
    24602: 'maternity',
    35847: 'job_mission',
    35564: 'temporary_permission',
    35841: 'clearance',
    35837: 'effective_date',
    34068: 'salary_certificate',
    32938: 'loan',
    33800: 'increment',
    32312: 'promotion',
    18915: 'parental',
    31615: 'resignation',
    25165: 'termination',
    31875: 'transfer',
    30388: 'passport',
    35803: 'leave_encashment',
    33244: 'car_rent',
  };

  static const Map<String, String> _caseTitle = {
    'sim': 'Sim Card Request',
    'sick': 'Sick Leave',
    'short': 'Short Leave',
    'annual': 'Annual Leave',
    'maternity': 'Maternity Leave',
    'job_mission': 'Job Mission',
    'temporary_permission': 'Temporary Permission',
    'clearance': 'Clearance',
    'effective_date': 'Effective Date',
    'salary_certificate': 'Salary Certificate',
    'certificate_request': 'Certificate Request',
    'loan': 'Loan',
    'increment': 'Salary Increment',
    'salary_increment': 'Salary Increment',
    'promotion': 'Promotion',
    'parental': 'Parental',
    'resignation': 'Resignation',
    'resign': 'Resign',
    'termination': 'Termination',
    'transfer': 'Transfer',
    'passport': 'Passport',
    'leave_encashment': 'Leave Encashment',
    'car_rent': 'Car Rent',
    'generic': 'HR Request',
  };

  static const Map<String, String> _caseByTypeCode = {
    'sim': 'sim',
    'annualleave_short': 'short',
    'annualleave_sick': 'sick',
    'annualleave_annual': 'annual',
    'annualleave_parental': 'parental',
    'annualleave_maternity': 'maternity',
    'clearance': 'clearance',
    'temp': 'temporary_permission',
    'effective_date': 'effective_date',
    'jm': 'job_mission',
    'resignation': 'resignation',
    'resign': 'resignation',
    'encashment': 'leave_encashment',
    'salary_certificate': 'salary_certificate',
    'certificate_request': 'salary_certificate',
    'loan': 'loan',
    'promotion': 'promotion',
    'transfer': 'transfer',
    'increment': 'increment',
    'salary_increment': 'increment',
    'termination': 'termination',
    'carrent': 'car_rent',
    'car_rent': 'car_rent',
    'passport': 'passport',
    'passport_request': 'passport',
  };

  bool _isLoading = true;
  String _error = '';

  Map<String, dynamic> _formData = const {};
  Map<String, dynamic> _employeeInfo = const {};
  Map<String, dynamic> _requestInfo = const {};

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

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value as Map);
    }
    return const {};
  }

  String _normalizeToken(String value) {
    return value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
  }

  int? _toInt(dynamic value) {
    if (value == null || value == false || value == true) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  String _pickFromMaps(List<Map<String, dynamic>> maps, List<String> keys,
      {String fallback = ''}) {
    final values = <dynamic>[];
    for (final key in keys) {
      for (final map in maps) {
        values.add(map[key]);
      }
    }
    return _pick(values, fallback: fallback);
  }

  int? _resolveCaseIdFromData(List<Map<String, dynamic>> maps) {
    final idKeys = [
      'leave_request_subtype_id',
      'leave_request_subtype',
      'request_subtype_id',
      'request_subtype',
      'request_type_id',
      'type_id',
      'sub_type_id',
      'hr_request_type_id',
    ];

    for (final key in idKeys) {
      for (final map in maps) {
        final id = _toInt(map[key]);
        if (id != null && _caseByTypeId.containsKey(id)) {
          return id;
        }
      }
    }
    return null;
  }

  String _resolveCaseKey({
    required String requestName,
    required List<Map<String, dynamic>> requestMaps,
  }) {
    final directRequestId = int.tryParse(widget.requestId);
    if (directRequestId != null && _caseByTypeId.containsKey(directRequestId)) {
      return _caseByTypeId[directRequestId] ?? 'generic';
    }

    final caseId = _resolveCaseIdFromData(requestMaps);
    if (caseId != null) {
      return _caseByTypeId[caseId] ?? 'generic';
    }

    final rawTypeCode = _pick([
      _pickFromMaps(requestMaps, [
        'request_type_code',
        'request_code',
        'type_code',
        'leave_type_code',
        'request_type',
        'leave_type',
      ]),
      widget.type,
    ]);

    if (rawTypeCode.isNotEmpty) {
      final normalizedTypeCode = _normalizeToken(rawTypeCode);
      final mapped = _caseByTypeCode[normalizedTypeCode];
      if (mapped != null) return mapped;
    }

    final n = requestName.toLowerCase();
    if (n.contains('sim')) return 'sim';
    if (n.contains('sick')) return 'sick';
    if (n.contains('short')) return 'short';
    if (n.contains('annual')) return 'annual';
    if (n.contains('maternity')) return 'maternity';
    if (n.contains('parental')) return 'parental';
    if (n.contains('job mission') || n.contains('مهمة')) return 'job_mission';
    if (n.contains('temporary')) return 'temporary_permission';
    if (n.contains('clearance')) return 'clearance';
    if (n.contains('effective')) return 'effective_date';
    if (n.contains('certificate')) return 'salary_certificate';
    if (n.contains('loan')) return 'loan';
    if (n.contains('promotion')) return 'promotion';
    if (n.contains('salary') && n.contains('increment')) return 'increment';
    if (n.contains('increment')) return 'increment';
    if (n.contains('resign')) return 'resignation';
    if (n.contains('terminat')) return 'termination';
    if (n.contains('transfer')) return 'transfer';
    if (n.contains('passport')) return 'passport';
    if (n.contains('encash')) return 'leave_encashment';
    if (n.contains('car') && n.contains('rent')) return 'car_rent';
    return 'generic';
  }

  List<_DetailItem> _buildRequestDetailItems(
      String caseKey, List<Map<String, dynamic>> dataMaps) {
    List<_DetailItem> makeItems(List<_FieldDef> defs) {
      final items = <_DetailItem>[];
      for (final def in defs) {
        final value = _pickFromMaps(dataMaps, def.keys);
        if (value.isNotEmpty) {
          items.add(_DetailItem(def.label, value, multiline: def.multiline));
        }
      }
      return items;
    }

    final common = [
      const _FieldDef(
          'Requested By', ['requested_by', 'requester_name', 'employee_name']),
      const _FieldDef('Request Date', [
        'request_date',
        'request_datetime',
        'request_date_from',
        'date',
        'create_date',
      ]),
    ];

    switch (caseKey) {
      case 'sim':
        return makeItems([
          ...common,
          const _FieldDef('Company No.', ['company_no']),
          const _FieldDef('Employee ID', ['employee_id', 'emp_id']),
        ]);
      case 'sick':
        return makeItems([
          ...common,
          const _FieldDef('Start Date', ['start_date', 'request_date_from']),
          const _FieldDef('Requested Duration', [
            'requested_duration',
            'duration',
            'number_of_days',
          ]),
          const _FieldDef('Remaining Leave Days', [
            'remaining_leave_days',
            'balance_leave',
            'leave_balance',
          ]),
          const _FieldDef('Allowed Sick Days', ['allowed_sick_days']),
          const _FieldDef('Sick Leave Reference No', [
            'sick_leave_reference_no',
            'certificate_no',
          ]),
          const _FieldDef('Emirates ID', ['emirates_id']),
          const _FieldDef('Review Validation URL', [
            'review_validation_url',
            'validation_url',
            'review_url',
          ]),
          const _FieldDef('Note', ['note', 'description'], multiline: true),
        ]);
      case 'short':
        return makeItems([
          ...common,
          const _FieldDef('Start Date', ['start_date', 'request_date_from']),
          const _FieldDef('Requested Duration', [
            'requested_duration',
            'duration',
            'number_of_days',
          ]),
          const _FieldDef('Remaining Leave Days', [
            'remaining_leave_days',
            'balance_leave',
            'leave_balance',
          ]),
        ]);
      case 'annual':
        return makeItems([
          ...common,
          const _FieldDef('Start Date', ['start_date', 'request_date_from']),
          const _FieldDef('End Date', ['end_date', 'request_date_to']),
          const _FieldDef('Requested Duration', [
            'requested_duration',
            'duration',
            'number_of_days',
          ]),
          const _FieldDef('Available Days', ['available_days']),
          const _FieldDef('Remaining Leave Days', [
            'remaining_leave_days',
            'balance_leave',
            'leave_balance',
          ]),
          const _FieldDef('Annual Short Leaves Remaining', [
            'annual_short_leaves_remaining',
          ]),
          const _FieldDef('Note', ['note', 'description'], multiline: true),
        ]);
      case 'parental':
        return makeItems([
          ...common,
          const _FieldDef('Start Date', ['start_date', 'request_date_from']),
          const _FieldDef('End Date', ['end_date', 'request_date_to']),
          const _FieldDef('Requested Duration', [
            'requested_duration',
            'duration',
            'number_of_days',
          ]),
          const _FieldDef('Birth Attachment', ['birth_attachment']),
        ]);
      case 'maternity':
        return makeItems([
          ...common,
          const _FieldDef('Start Date', ['start_date', 'request_date_from']),
          const _FieldDef('End Date', ['end_date', 'request_date_to']),
          const _FieldDef('Requested Duration', [
            'requested_duration',
            'duration',
            'number_of_days',
          ]),
          const _FieldDef(
              'Discharge Report Attachment', ['discharge_report_attachment']),
        ]);
      case 'job_mission':
        return makeItems([
          ...common,
          const _FieldDef('Start Time', ['start_time', 'job_time']),
          const _FieldDef('Duration Type', ['duration_type']),
          const _FieldDef('Job Mission Type', ['job_mission_type', 'job_type']),
          const _FieldDef('Only Afternoon', ['only_afternoon']),
          const _FieldDef('Client Details', ['client_details']),
          const _FieldDef('Project Details', ['project_details']),
          const _FieldDef('Note', ['note', 'description'], multiline: true),
        ]);
      case 'temporary_permission':
        return makeItems([
          ...common,
          const _FieldDef('Available Days', ['available_days']),
          const _FieldDef('Remaining Leave Days', [
            'remaining_leave_days',
            'leave_balance',
            'balance_leave',
          ]),
          const _FieldDef('Temp Hours', ['temp_hours']),
          const _FieldDef('Temp Selection', ['temp_selection']),
          const _FieldDef('Start Time', ['start_time', 'hour_from']),
          const _FieldDef('Note', ['note', 'description'], multiline: true),
        ]);
      case 'clearance':
        return makeItems([
          ...common,
          const _FieldDef('Last Work Date', ['last_work_date', 'end_date']),
          const _FieldDef(
              'Reason For Leaving', ['reason_for_leaving', 'reason']),
        ]);
      case 'effective_date':
        return makeItems([
          ...common,
          const _FieldDef('Joined Date', ['joined_date', 'join_date']),
          const _FieldDef('Discipline Reason', [
            'discipline_reason',
            'e_reason',
            'reason',
          ]),
        ]);
      case 'salary_certificate':
      case 'certificate_request':
        return makeItems([
          ...common,
          const _FieldDef(
              'Certificate Type', ['certificate_type', 'document_type']),
          const _FieldDef('Language', ['certificate_language', 'language']),
          const _FieldDef('Note', ['note', 'description'], multiline: true),
        ]);
      case 'loan':
        return makeItems([
          ...common,
          const _FieldDef('EOS Date', ['eos_date']),
          const _FieldDef('Loan Type', ['loan_type']),
          const _FieldDef('Net Worked Days', ['net_worked_days']),
          const _FieldDef('Years', ['years']),
          const _FieldDef('Total Absent Days', ['total_absent_days']),
          const _FieldDef('Total Gratuity', ['total_gratuity']),
          const _FieldDef(
              'Loan Amount', ['loan_amount', 'amount', 'requested_amount']),
        ]);
      case 'promotion':
        return makeItems([
          ...common,
          const _FieldDef('Effective Date', ['effective_date']),
          const _FieldDef('New Job', ['new_job']),
          const _FieldDef('Old Manager', ['old_manager']),
          const _FieldDef('New Manager', ['new_manager']),
          const _FieldDef('Overall Score', ['overall_score']),
        ]);
      case 'increment':
      case 'salary_increment':
        return makeItems([
          ...common,
          const _FieldDef('Increment Effective Date', [
            'increment_effective_date',
            'effective_date',
          ]),
          const _FieldDef('Salary Max', ['salary_max']),
          const _FieldDef(
              'Employee Suggested Salary', ['employee_suggested_salary']),
          const _FieldDef(
              'Manager Suggested Salary', ['manager_suggested_salary']),
          const _FieldDef('Suggested Total', ['suggested_total']),
          const _FieldDef('Evaluation Attachment', ['evaluation_attachment']),
          const _FieldDef('Overall Score', ['overall_score']),
        ]);
      case 'resignation':
      case 'resign':
        return makeItems([
          ...common,
          const _FieldDef(
              'Notice Period Start Date', ['notice_period_start_date']),
          const _FieldDef('Resignation Type', ['resignation_type']),
          const _FieldDef(
              'Expected Relieving Date', ['expected_relieving_date']),
          const _FieldDef('Notice Period', ['notice_period']),
          const _FieldDef('Reason', ['reason', 'note'], multiline: true),
        ]);
      case 'termination':
        return makeItems([
          ...common,
          const _FieldDef('Termination Type', ['termination_type']),
          const _FieldDef('Termination Reason', ['termination_reason']),
          const _FieldDef('Employee Last Day', ['emp_last_day']),
          const _FieldDef('Company No.', ['company_no']),
          const _FieldDef('Note', ['note', 'description'], multiline: true),
        ]);
      case 'transfer':
        return makeItems([
          ...common,
          const _FieldDef('Effective Date', ['effective_date']),
          const _FieldDef('Transfer Type', ['transfer_type']),
          const _FieldDef('New Manager', ['new_manager']),
          const _FieldDef('Transfer From', ['transfer_from']),
          const _FieldDef('Transfer To', ['transfer_to']),
          const _FieldDef('Forman', ['forman']),
          const _FieldDef('Reason', ['reason', 'note'], multiline: true),
        ]);
      case 'passport':
        return makeItems([
          ...common,
          const _FieldDef('Passport No', ['passport_no', 'passport_number']),
          const _FieldDef('Issue Date', ['issue_date']),
          const _FieldDef('Expiry Date', ['expiry_date']),
          const _FieldDef('Return Date', ['return_date']),
          const _FieldDef('Note', ['note', 'description'], multiline: true),
        ]);
      case 'leave_encashment':
        return makeItems([
          ...common,
          const _FieldDef(
              'Encashment Days', ['encashment_days', 'encash_days']),
          const _FieldDef('Available Days', ['available_days']),
          const _FieldDef('Request Date To', ['request_date_to']),
          const _FieldDef('Remaining Leave Days', [
            'remaining_leave_days',
            'available_balance',
            'leave_balance',
          ]),
          const _FieldDef('GM Attachment', ['gm_attachment']),
          const _FieldDef('Note', ['note', 'description'], multiline: true),
        ]);
      case 'car_rent':
        return makeItems([
          ...common,
          const _FieldDef('Car Request Type', ['car_req_type']),
          const _FieldDef('Rent Type', ['rent_type']),
          const _FieldDef('Rent Duration', ['rent_duration']),
          const _FieldDef('Company No.', ['company_no']),
          const _FieldDef('Note', ['note', 'description'], multiline: true),
        ]);
      default:
        return makeItems([
          ...common,
          const _FieldDef('Start Date', ['start_date', 'request_date_from']),
          const _FieldDef('Duration', [
            'requested_duration',
            'duration',
            'number_of_days',
          ]),
          const _FieldDef('End Date', ['end_date', 'request_date_to']),
          const _FieldDef('Note', ['note', 'description'], multiline: true),
        ]);
    }
  }

  bool get _isLocalFakeRequest => widget.requestId == _localFakeHrRequestId;

  Map<String, dynamic> _buildLocalFakeFormData() {
    return {
      'employee_info': {
        'employee_name': 'Local Test Employee',
        'emp_id': 'EMP-FAKE-001',
        'type': 'Staff',
        'section': 'Media',
        'job_title': 'Media Manager',
        'city_id': 'Al Ain',
        'joining_date': '2023-10-16',
        'working_days': '2 years 4 months 24 days',
      },
      'request_info': {
        'request_no': 'REQ/FAKE/001',
        'request_name': 'Temporary Permission',
        'request_date_from': '2026-03-04',
        'request_date_to': '2026-03-05',
        'duration_type': '3',
        'start_time': '8 am',
        'leave_balance': '42.50',
      },
    };
  }

  @override
  void initState() {
    super.initState();
    if (_isLocalFakeRequest) {
      _formData = _buildLocalFakeFormData();
      _employeeInfo = _asMap(_formData['employee_info']);
      _requestInfo = _asMap(_formData['request_info']);
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
        final employeeInfo = _asMap(rawData['employee_info']).isNotEmpty
            ? _asMap(rawData['employee_info'])
            : _asMap(formData['employee_info']);
        final requestInfo = _asMap(rawData['request_info']).isNotEmpty
            ? _asMap(rawData['request_info'])
            : _asMap(formData['request_info']);

        print('🟢 Success - FormData: $formData');
        if (employeeInfo.isNotEmpty) {
          print('🟢 Employee Info: $employeeInfo');
        }
        if (requestInfo.isNotEmpty) {
          print('🟢 Request Info: $requestInfo');
        }

        setState(() {
          _formData = Map<String, dynamic>.from(formData);
          _employeeInfo = Map<String, dynamic>.from(employeeInfo);
          _requestInfo = Map<String, dynamic>.from(requestInfo);
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

  Widget _detailDescriptionBox(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _value(label, size: 13.sp, weight: FontWeight.w600),
          SizedBox(height: 6.w),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFD4D4D4)),
              color: const Color(0xFFF8F8F8),
            ),
            child: _value(value,
                size: 12.sp,
                weight: FontWeight.w500,
                color: const Color(0xFF333333)),
          ),
        ],
      ),
    );
  }

  Widget _requestMetaBox({
    required String label,
    required String value,
  }) {
    return Container(
      height: 70.w,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFB3B3B3),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFACACAC),
              letterSpacing: 0.1,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF111111),
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employeeMaps = <Map<String, dynamic>>[_employeeInfo, _formData];
    final requestMaps = <Map<String, dynamic>>[_requestInfo, _formData];

    final requestNo = _pick([
      _pickFromMaps(requestMaps, ['request_no', 'name', 'ref_no']),
    ], fallback: widget.requestId);

    final rawRequestType = _pickFromMaps(
      requestMaps,
      [
        'request_name',
        'request_type',
        'holiday_status_name',
        'holiday_status_id',
        'leave_type',
        'type',
      ],
      fallback: 'HR Request',
    );
    final caseKey = _resolveCaseKey(
      requestName: rawRequestType,
      requestMaps: requestMaps,
    );
    final requestType = rawRequestType == 'HR Request'
        ? (_caseTitle[caseKey] ?? rawRequestType)
        : rawRequestType;

    final employeeName = _pick([
      _pickFromMaps(employeeMaps, [
        'employee_name',
        'emp_name',
        'requested_by',
        'requester_name',
      ]),
      _pickFromMaps(employeeMaps, ['employee_id', 'emp_id']),
    ], fallback: 'Employee Name');

    // Additional name for manager or secondary person
    final secondaryName = _pick([
      _pickFromMaps(employeeMaps, [
        'manager_name',
        'parent_id',
        'department_manager',
        'approver_name',
      ]),
    ]);

    final employeeImage = _pick([
      _pickFromMaps(employeeMaps, [
        'employee_image',
        'image_emp',
        'emp_image',
        'employee_img',
        'image',
        'avatar',
        'photo',
        'profile_image',
      ]),
    ]);

    // Log the image URL for debugging
    if (employeeImage.isNotEmpty) {
      print('🟢 Employee Image URL: $employeeImage');
    } else {
      print('🔴 No employee image found in data');
      print('🔴 Available keys: ${_formData.keys.toList()}');
    }

    final employeeDetails = <_DetailItem>[
      _DetailItem('Employee Type',
          _pickFromMaps(employeeMaps, ['type', 'employee_type'])),
      _DetailItem(
          'Section', _pickFromMaps(employeeMaps, ['section', 'department'])),
      _DetailItem('Job Position',
          _pickFromMaps(employeeMaps, ['job_title', 'job_position'])),
      _DetailItem('City/Branch',
          _pickFromMaps(employeeMaps, ['city_id', 'city', 'branch'])),
      _DetailItem('Employee ID',
          _pickFromMaps(employeeMaps, ['emp_id', 'employee_id'])),
      _DetailItem('Joining Date',
          _pickFromMaps(employeeMaps, ['joining_date', 'join_date'])),
      _DetailItem(
          'Total Working Days', _pickFromMaps(employeeMaps, ['working_days'])),
    ].where((item) => item.value.isNotEmpty).toList();

    final detailMaps = <Map<String, dynamic>>[
      _requestInfo,
      _formData,
      _employeeInfo,
    ];
    final requestDetailItems = _buildRequestDetailItems(caseKey, detailMaps);

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
                                'HR REQUEST',
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

                              Row(
                                children: [
                                  Expanded(
                                    child: _requestMetaBox(
                                      label: 'Request No',
                                      value: requestNo,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: _requestMetaBox(
                                      label: 'Request Type',
                                      value: requestType,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.w),

                              _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(child: _label('Employee Details')),
                                    SizedBox(height: 12.w),
                                    if (employeeDetails.isEmpty)
                                      _value('No employee details available',
                                          size: 12.sp,
                                          weight: FontWeight.w500,
                                          color: const Color(0xFF6E6E6E))
                                    else
                                      for (int i = 0;
                                          i < employeeDetails.length;
                                          i++) ...[
                                        _detailRow(employeeDetails[i].label,
                                            employeeDetails[i].value),
                                        if (i != employeeDetails.length - 1)
                                          const Divider(
                                            color: Color(0xFFE0E0E0),
                                            height: 1,
                                          ),
                                      ],
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
                                    if (requestDetailItems.isEmpty)
                                      _value(
                                          'No request-specific details available',
                                          size: 12.sp,
                                          weight: FontWeight.w500,
                                          color: const Color(0xFF6E6E6E))
                                    else
                                      for (int i = 0;
                                          i < requestDetailItems.length;
                                          i++) ...[
                                        requestDetailItems[i].multiline
                                            ? _detailDescriptionBox(
                                                requestDetailItems[i].label,
                                                requestDetailItems[i].value,
                                              )
                                            : _detailRow(
                                                requestDetailItems[i].label,
                                                requestDetailItems[i].value,
                                              ),
                                        if (i != requestDetailItems.length - 1)
                                          const Divider(
                                            color: Color(0xFFE0E0E0),
                                            height: 1,
                                          ),
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

class _FieldDef {
  const _FieldDef(this.label, this.keys, {this.multiline = false});

  final String label;
  final List<String> keys;
  final bool multiline;
}

class _DetailItem {
  const _DetailItem(this.label, this.value, {this.multiline = false});

  final String label;
  final String value;
  final bool multiline;
}
