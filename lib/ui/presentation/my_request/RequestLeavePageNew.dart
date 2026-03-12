import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/signin/data/repository.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RequestLeavePageNew extends StatefulWidget {
  final dynamic loginResponseModel;
  final String leaveType; // 'SICK', 'SHORT', or 'ANNUAL'

  const RequestLeavePageNew({
    super.key,
    required this.loginResponseModel,
    required this.leaveType,
  });

  @override
  State<RequestLeavePageNew> createState() => _RequestLeavePageNewState();
}

class _RequestLeavePageNewState extends State<RequestLeavePageNew> {
  final UserRepo userRepo = UserRepo();
  static const Color _primary = Color(0xFF151544);
  static const Color _accentGrey = Color(0xFF5E5E5E);
  DateTime? startDate;
  DateTime? endDate;
  DateTime displayedMonth = DateTime.now();
  String duration = '5';
  String? leaveBalance;
  String certificateNo = '';
  String description = '';
  bool isLoading = false;

  // Holiday list includes:
  // Only official public holidays (NOT weekends)
  // Weekends are regular working days that can be selected
  final Set<DateTime> holidays = {};
  final Set<DateTime> officialHolidays = {}; // Official holidays from API
  bool isLoadingHolidays = false;

  // Minimum start date (20 days from now for SHORT leave)
  late DateTime minimumStartDate;

  // SHORT leave restrictions
  static const int maxShortLeaveDays = 7; // Maximum 7 days for SHORT leave
  static const int shortLeaveGapDays =
      30; // Minimum 30 days gap between SHORT leaves

  // Text formatting states
  bool isBold = false;
  bool isItalic = false;
  bool isBulletList = false;
  bool isNumberedList = false;
  final TextEditingController _descController = TextEditingController();

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _initializeMinimumDate();
    _fetchHolidaysFromAPI();
    _initAsync();
  }

  void _initializeMinimumDate() {
    // For SHORT and ANNUAL leave, minimum start date is 20 days from today
    // This enforces the 20-day advance notice requirement
    if (widget.leaveType == 'SHORT' || widget.leaveType == 'ANNUAL') {
      minimumStartDate = DateTime.now().add(const Duration(days: 20));
    } else {
      minimumStartDate = DateTime.now();
    }
  }

  Future<void> _fetchHolidaysFromAPI() async {
    setState(() => isLoadingHolidays = true);

    try {
      final token = SharedPref.getLoginData().result?.token;
      final url = Uri.parse('https://erp.elrace.com/api/public/holidays');

      debugPrint('🔵 === FETCHING HOLIDAYS FROM API ===');
      debugPrint('🔵 URL: $url');
      debugPrint('🔵 Token: ${token?.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'params': {
            'token': token,
          }
        }),
      );

      debugPrint('🔵 Response Status: ${response.statusCode}');
      debugPrint('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        debugPrint('🔵 Parsed Result: $result');

        if (result['result'] != null && result['result'] is List) {
          final List<dynamic> holidayList = result['result'];

          debugPrint(
              '🔵 Total Holiday Periods from API: ${holidayList.length}');

          for (var holiday in holidayList) {
            try {
              final String dateFrom = holiday['date_from'];
              final String dateTo = holiday['date_to'];
              final String name = holiday['name'] ?? 'Holiday';

              final startDate = DateTime.parse(dateFrom);
              final endDate = DateTime.parse(dateTo);

              // Add all days in the holiday range
              DateTime current = startDate;
              while (current.isBefore(endDate) ||
                  current.isAtSameMomentAs(endDate)) {
                final holidayDate =
                    DateTime(current.year, current.month, current.day);
                holidays.add(holidayDate);
                officialHolidays
                    .add(holidayDate); // Add to official holidays list
                current = current.add(const Duration(days: 1));
              }

              debugPrint('🔵 Added holiday: $name ($dateFrom to $dateTo)');
            } catch (e) {
              debugPrint('❌ Error parsing holiday: $e');
            }
          }

          debugPrint('🔵 Total holidays loaded from API: ${holidays.length}');
        } else {
          debugPrint('⚠️ No holidays in API response');
        }
      } else {
        debugPrint('❌ API returned status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching holidays from API: $e');
    }

    debugPrint('🔵 Total holidays after adding weekends: ${holidays.length}');

    setState(() => isLoadingHolidays = false);
  }

  Future<void> _initAsync() async {
    await _fetchLeaveBalance();
  }

  Future<void> _fetchLeaveBalance() async {
    try {
      final loginResp = await userRepo.getLoginResponse();
      if (loginResp?.result?.data?.leaveBalance != null) {
        setState(() {
          leaveBalance = loginResp!.result!.data!.leaveBalance;
        });
        debugPrint('✅ Leave Balance fetched: $leaveBalance');
      } else {
        debugPrint('⚠️ Leave Balance is null in response');
        setState(() {
          leaveBalance = '0';
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching leave balance: $e');
      setState(() {
        leaveBalance = '0';
      });
    }
  }

  void _onDateSelected(DateTime date) {
    // Check if date is selectable
    if (!_isDateSelectable(date)) {
      String errorMessage = 'Selected date is not available. ';

      if (_isHoliday(date)) {
        errorMessage += 'Cannot select a holiday.';
      } else if (_isWithin3DaysOfHoliday(date)) {
        errorMessage +=
            'Cannot select dates within 3 days before or 4 days after official holidays.';
      } else if (date.isBefore(minimumStartDate)) {
        errorMessage += 'Must be at least 20 days from request date.';
      } else {
        errorMessage += 'Please choose a valid working day.';
      }

      _showErrorDialog(errorMessage);
      return;
    }

    setState(() {
      if (startDate == null || (endDate != null)) {
        startDate = date;
        endDate = null;
      } else if (date.isBefore(startDate!)) {
        startDate = date;
        endDate = null;
      } else {
        endDate = date;
        // Calculate duration excluding holidays
        duration = _calculateWorkingDays(startDate!, endDate!).toString();
      }
    });
  }

  bool _isDateSelectable(DateTime date) {
    // Sick leave supports selecting past dates (retroactive request use case).
    if (widget.leaveType == 'SICK') {
      return true;
    }

    // Cannot select past dates
    final today = _dateOnly(DateTime.now());
    if (_dateOnly(date).isBefore(today)) {
      debugPrint('🔴 Date not selectable: $date (Past date)');
      return false;
    }

    // Cannot select dates before minimum start date
    if (_dateOnly(date).isBefore(_dateOnly(minimumStartDate))) {
      debugPrint(
          '🔴 Date not selectable: $date (Before minimum: $minimumStartDate)');
      return false;
    }

    // Cannot select holidays
    if (_isHoliday(date)) {
      debugPrint('🔴 Date not selectable: $date (Holiday)');
      return false;
    }

    // Cannot select dates within 3 days before or after a holiday
    // This applies to both ANNUAL and SHORT leave
    if (widget.leaveType == 'ANNUAL' || widget.leaveType == 'SHORT') {
      if (_isWithin3DaysOfHoliday(date)) {
        debugPrint('🔴 Date not selectable: $date (Within 3 days of holiday)');
        return false;
      }
    }

    debugPrint('🟢 Date selectable: $date');
    return true;
  }

  bool _isHoliday(DateTime date) {
    return holidays.any((holiday) => _isSameDay(holiday, date));
  }

  bool _isWithin3DaysOfHoliday(DateTime date) {
    // Check if date is within restricted days before or after any OFFICIAL holiday
    // Restriction: 3 days BEFORE holiday + 4 days AFTER holiday
    // This prevents employees from applying leave close to official holidays
    // NOTE: This applies to official holidays only, NOT weekends
    for (final holiday in officialHolidays) {
      final daysDifference = date.difference(holiday).inDays;

      // Check if date is 3 days before the holiday (negative difference)
      if (daysDifference < 0 && daysDifference >= -3) {
        debugPrint(
            '🔴 Date blocked: $date (${daysDifference.abs()} days before holiday)');
        return true;
      }

      // Check if date is 4 days after the holiday (positive difference)
      if (daysDifference > 0 && daysDifference <= 4) {
        debugPrint(
            '🔴 Date blocked: $date ($daysDifference days after holiday)');
        return true;
      }
    }
    return false;
  }

  int _calculateWorkingDays(DateTime start, DateTime end) {
    // Sick leave duration should count all consecutive days from certificate.
    if (widget.leaveType == 'SICK') {
      return end.difference(start).inDays + 1;
    }

    int workingDays = 0;
    DateTime current = start;

    while (current.isBefore(end) || _isSameDay(current, end)) {
      if (!_isHoliday(current)) {
        workingDays++;
      }
      current = current.add(const Duration(days: 1));
    }

    return workingDays;
  }

  Future<void> _submitRequest() async {
    if (startDate == null || endDate == null || description.trim().isEmpty) {
      _showErrorDialog('Please fill in all required fields.');
      return;
    }

    if (widget.leaveType == 'SICK' && certificateNo.trim().isEmpty) {
      _showErrorDialog('Please enter certificate number for sick leave.');
      return;
    }

    // Backdated sick leave can only be submitted within 3 days
    // after the last sick day (assumes return-to-work is next day).
    if (widget.leaveType == 'SICK') {
      final today = _dateOnly(DateTime.now());
      final selectedEndDate = _dateOnly(endDate!);

      if (selectedEndDate.isBefore(today)) {
        final lastAllowedSubmitDate =
            selectedEndDate.add(const Duration(days: 3));
        if (today.isAfter(lastAllowedSubmitDate)) {
          _showErrorDialog(
              'Late sick leave can only be submitted within 3 days after returning to work.');
          return;
        }
      }
    }

    // SHORT leave specific validations
    if (widget.leaveType == 'SHORT') {
      final durationInt = int.tryParse(duration) ?? 0;

      // Check maximum 7 days
      if (durationInt > maxShortLeaveDays) {
        _showErrorDialog('Short leave cannot exceed $maxShortLeaveDays days.');
        return;
      }

      // TODO: Check 30 days gap from last SHORT leave
      // This needs API call to get employee's last SHORT leave date
      // For now, we'll send it to backend and let it validate
    }

    setState(() => isLoading = true);

    try {
      final token = SharedPref.getLoginData().result?.token;
      final url = Uri.parse('https://erp.elrace.com/api/submit_request');

      final body = jsonEncode({
        'jsonrpc': '2.0',
        'params': {
          'request_type': 'leave',
          'leave_type': widget.leaveType.toLowerCase(),
          'start_date': DateFormat('yyyy-MM-dd').format(startDate!),
          'duration': duration,
          'end_date': DateFormat('yyyy-MM-dd').format(endDate!),
          'description': description,
          'note': description,
          'certificate_no': widget.leaveType == 'SICK' ? certificateNo : null,
          'duration_type': 'days',
        }
      });

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      };

      final response = await http.post(url, body: body, headers: headers);
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 &&
          data['result']?['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        _showErrorDialog(data['result']?['message'] ?? 'Request failed');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred. Please try again.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorDialog(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (widget.leaveType) {
      case 'SICK':
        return 'SICK LEAVE';
      case 'SHORT':
        return 'SHORT LEAVE';
      case 'ANNUAL':
        return 'ANNUAL LEAVE';
      default:
        return 'LEAVE REQUEST';
    }
  }

  String _getNoticeText() {
    switch (widget.leaveType) {
      case 'SICK':
        return 'Sick leave requires a certificate number. Backdated sick leave must be submitted within 3 days after returning to work.';
      case 'SHORT':
        return 'Please be aware that you are eligible for 4 leaves per year';
      case 'ANNUAL':
        return 'Must submit 20 days in advance. Blocked 3 days before & 4 days after official holidays.';
      default:
        return 'Please be aware that you have to submit your request 15 days prior your leave start date.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while holidays are being fetched
    if (isLoadingHolidays) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: const HeaderWidget(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading holidays...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const HeaderWidget(),
      body: SafeArea(
        child: Column(
          children: [
            // Title
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Text(
                _getPageTitle(),
                style: GoogleFonts.koulen(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.5,
                  color: _primary,
                ),
              ),
            ),

            // Content Card
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Calendar
                      _buildCalendar(),
                      SizedBox(height: 20.h),

                      // Duration Row
                      _buildInfoRow('Duration', '$duration days'),
                      SizedBox(height: 12.h),

                      // Leave Balance Row
                      if (leaveBalance != null)
                        _buildInfoRow('Leave Balance', '$leaveBalance days'),
                      SizedBox(height: 12.h),

                      // Certificate No (for SICK leave only)
                      if (widget.leaveType == 'SICK') ...[
                        _buildInfoRow('Certificate No', ''),
                        SizedBox(height: 20.h),
                      ],

                      // Description
                      Text(
                        'Description',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _descController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Write your description...',
                                hintStyle: TextStyle(fontSize: 12),
                              ),
                              style: TextStyle(
                                fontWeight: isBold
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontStyle: isItalic
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                              onChanged: (val) =>
                                  setState(() => description = val),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    // Bold
                                    IconButton(
                                      icon: Icon(Icons.format_bold,
                                          size: 18.w,
                                          color: isBold
                                              ? _accentGrey
                                              : Colors.grey),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        setState(() {
                                          isBold = !isBold;
                                          _applyFormatting();
                                        });
                                      },
                                    ),
                                    SizedBox(width: 8.w),
                                    // Italic
                                    IconButton(
                                      icon: Icon(Icons.format_italic,
                                          size: 18.w,
                                          color: isItalic
                                              ? _accentGrey
                                              : Colors.grey),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        setState(() {
                                          isItalic = !isItalic;
                                          _applyFormatting();
                                        });
                                      },
                                    ),
                                    SizedBox(width: 8.w),
                                    // Bullet List
                                    IconButton(
                                      icon: Icon(Icons.format_list_bulleted,
                                          size: 18.w,
                                          color: isBulletList
                                              ? _accentGrey
                                              : Colors.grey),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        setState(() {
                                          isBulletList = !isBulletList;
                                          isNumberedList = false;
                                          _insertListPrefix('• ');
                                        });
                                      },
                                    ),
                                    SizedBox(width: 8.w),
                                    // Numbered List
                                    IconButton(
                                      icon: Icon(Icons.format_list_numbered,
                                          size: 18.w,
                                          color: isNumberedList
                                              ? _accentGrey
                                              : Colors.grey),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        setState(() {
                                          isNumberedList = !isNumberedList;
                                          isBulletList = false;
                                          _insertNumberedList();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  '${description.trim().isEmpty ? 0 : description.trim().split(RegExp(r'\s+')).length}/50',
                                  style: TextStyle(
                                      fontSize: 10.sp, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Notice
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              size: 20.w, color: Colors.grey),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              _getNoticeText(),
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            elevation: 2,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Text(
                                  'SUBMIT',
                                  style: GoogleFonts.koulen(
                                    fontSize: 16.sp,
                                    letterSpacing: 1.5,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Month/Year selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    displayedMonth =
                        DateTime(displayedMonth.year, displayedMonth.month - 1);
                  });
                },
              ),
              Row(
                children: [
                  DropdownButton<int>(
                    value: displayedMonth.month,
                    underline: const SizedBox(),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                  DateFormat('MMM').format(DateTime(2000, m))),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          displayedMonth = DateTime(displayedMonth.year, val);
                        });
                      }
                    },
                  ),
                  SizedBox(width: 8.w),
                  DropdownButton<int>(
                    value: displayedMonth.year,
                    underline: const SizedBox(),
                    items: List.generate(10, (i) => DateTime.now().year - 5 + i)
                        .map((y) =>
                            DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          displayedMonth = DateTime(val, displayedMonth.month);
                        });
                      }
                    },
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    displayedMonth =
                        DateTime(displayedMonth.year, displayedMonth.month + 1);
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map((day) => SizedBox(
                      width: 32.w,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: 8.h),

          // Calendar grid
          ..._buildCalendarRows(),
        ],
      ),
    );
  }

  List<Widget> _buildCalendarRows() {
    final firstDay = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final lastDay = DateTime(displayedMonth.year, displayedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;

    final days = <Widget>[];
    for (int i = 0; i < startWeekday; i++) {
      days.add(SizedBox(width: 32.w, height: 32.w));
    }

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(displayedMonth.year, displayedMonth.month, day);
      final isSelected = (startDate != null && _isSameDay(date, startDate!)) ||
          (endDate != null && _isSameDay(date, endDate!));
      final isInRange = startDate != null &&
          endDate != null &&
          date.isAfter(startDate!) &&
          date.isBefore(endDate!);

      final isSelectable = _isDateSelectable(date);
      final bool enforceHolidayBlocks = widget.leaveType != 'SICK';
      final isHolidayDate = enforceHolidayBlocks && _isHoliday(date);
      final isNearHoliday =
          enforceHolidayBlocks && _isWithin3DaysOfHoliday(date);

      days.add(
        GestureDetector(
          onTap: isSelectable ? () => _onDateSelected(date) : null,
          child: Container(
            width: 32.w,
            height: 32.w,
            margin: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? _accentGrey
                  : isInRange
                      ? _accentGrey.withAlpha(64)
                      : isHolidayDate
                          ? Colors.red.withAlpha(25)
                          : isNearHoliday
                              ? Colors.orange.withAlpha(25)
                              : Colors.transparent,
              shape: BoxShape.circle,
              border: !isSelectable && !isHolidayDate && !isNearHoliday
                  ? Border.all(color: Colors.grey.withAlpha(50), width: 1)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 12.sp,
                color: isSelected
                    ? Colors.white
                    : !isSelectable
                        ? Colors.grey.withAlpha(128)
                        : isHolidayDate
                            ? Colors.red
                            : isNearHoliday
                                ? Colors.orange
                                : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                decoration: (isHolidayDate || isNearHoliday) && !isSelected
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        ),
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < days.length; i += 7) {
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              days.sublist(i, (i + 7 > days.length) ? days.length : i + 7),
        ),
      );
      rows.add(SizedBox(height: 4.h));
    }
    return rows;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          if (label == 'Certificate No')
            Expanded(
              child: TextField(
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter number',
                  isDense: true,
                ),
                style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                onChanged: (val) => setState(() => certificateNo = val),
              ),
            )
          else
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
        ],
      ),
    );
  }

  void _applyFormatting() {
    final text = _descController.text;
    _descController.value = _descController.value.copyWith(
      text: text,
    );
  }

  void _insertListPrefix(String prefix) {
    final text = _descController.text;
    final selection = _descController.selection;

    if (text.isEmpty || selection.start == 0) {
      _descController.text = '$prefix$text';
      _descController.selection =
          TextSelection.collapsed(offset: prefix.length);
    } else {
      final newText =
          '${text.substring(0, selection.start)}\n$prefix${text.substring(selection.start)}';
      _descController.text = newText;
      _descController.selection =
          TextSelection.collapsed(offset: selection.start + prefix.length + 1);
    }
    description = _descController.text;
  }

  void _insertNumberedList() {
    final text = _descController.text;
    final lines = text.split('\n');
    final newLines = <String>[];

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().isNotEmpty) {
        newLines
            .add('${i + 1}. ${lines[i].replaceAll(RegExp(r'^\d+\.\s*'), '')}');
      } else {
        newLines.add(lines[i]);
      }
    }

    _descController.text = newLines.join('\n');
    description = _descController.text;
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }
}
