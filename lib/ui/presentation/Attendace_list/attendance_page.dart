import 'package:el_race/ui/presentation/Attendace_list/attendance_widgets/colleasped_card.dart';
import 'package:el_race/ui/presentation/Attendace_list/model/attendance_model.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:el_race/core/utils/shared_pref.dart';
import '../../widgets/header_widget.dart';
import 'bloc/attendance_bloc.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({
    super.key,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late AttendanceBloc _attendanceBloc;
  Set<String> expandedRecords = {};
  int? selectedMonth;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Pagination state
  int _displayedItemsCount = 10;
  final int _itemsPerLoad = 10;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (mounted) setState(() {});
    });

    _scrollController.addListener(_onScroll);

    selectedMonth = DateTime.now().month;

    _attendanceBloc = AttendanceBloc();

    final isAttendanceManager =
        SharedPref.getLoginDataOrNull()?.result?.data?.isAttendanceManager ==
            true;

    // Initial load - both manager and non-manager load data
    _attendanceBloc.add(GetAttendanceListET(
      keyword: null,
      month: selectedMonth,
    ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _displayedItemsCount += _itemsPerLoad;
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _attendanceBloc.close();
    super.dispose();
  }

  void _onSearch() {
    final keyword = _searchController.text.trim();
    setState(() {
      _displayedItemsCount = 10;
    });
    _attendanceBloc.add(GetAttendanceListET(
      keyword: keyword.isEmpty ? null : keyword,
      month: selectedMonth,
    ));
  }

  Future<void> _selectMonth(BuildContext context) async {
    final int? picked = await showDialog<int>(
      context: context,
      builder: (context) => _MonthPickerDialog(
        selectedMonth: selectedMonth,
        currentYear: DateTime.now().year,
      ),
    );

    if (picked != null) {
      setState(() {
        selectedMonth = picked;
        _displayedItemsCount = 10; // Reset to initial count on month change
      });

      final isAttendanceManager =
          SharedPref.getLoginDataOrNull()?.result?.data?.isAttendanceManager ==
              true;
      
      if (isAttendanceManager) {
        _attendanceBloc.add(GetAttendanceListET(
          keyword: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          month: selectedMonth,
        ));
      } else {
        _attendanceBloc.add(GetAttendanceListET(
          keyword: null,
          month: selectedMonth,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAttendanceManager =
        SharedPref.getLoginDataOrNull()?.result?.data?.isAttendanceManager ==
            true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        bloc: _attendanceBloc,
        builder: (context, state) {
          if (isAttendanceManager) {
            return _buildManagerView(context, state);
          } else {
            return _buildEmployeeView(context, state);
          }
        },
      ),
    );
  }

  Widget _buildManagerView(BuildContext context, AttendanceState state) {
    if (state is AttendanceLoadingState && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is AttendanceErrorState) {
      return Center(child: Text(state.message));
    }

    Result? attendanceData;
    if (state is AttendanceDataLoaded) {
      attendanceData = state.attendanceData;
    }

    final monthName = selectedMonth != null
        ? DateFormat('MMMM').format(DateTime(2020, selectedMonth!))
        : 'Select Month';
    final year = DateTime.now().year.toString();

    return ListView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 48),
            Text(
              'ATTENDANCE',
              style: GoogleFonts.koulen(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: appFontColor,
                letterSpacing: 1.9,
              ),
            ),
            _MonthChip(
              label: monthName,
              onTap: () => _selectMonth(context),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SearchBox(
          controller: _searchController,
          hintText: 'Search employee name or ID',
          onSearch: _onSearch,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '$monthName, $year',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9AA0A6),
            ),
          ),
        ),
        const SizedBox(height: 10),

        if (attendanceData == null)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Text(
                'Loading attendance data...',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5A5A5A),
                ),
              ),
            ),
          )
        else if (attendanceData.status == "error")
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Text(
                'No data found.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5A5A5A),
                ),
              ),
            ),
          )
        else if (attendanceData.mode == "flat" && attendanceData.data != null)
          _buildFlatEmployeeList(attendanceData.data!)
        else if (attendanceData.mode == "grouped" && attendanceData.records != null)
          _buildEmployeeAttendanceWithCount(attendanceData)
        else
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Text(
                'No data found.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5A5A5A),
                ),
              ),
            ),
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFlatEmployeeList(List<FlatAttendanceData> employees) {
    if (employees.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Center(
          child: Text(
            'No employees found.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5A5A5A),
            ),
          ),
        ),
      );
    }

    // Calculate how many items to display
    final displayCount = _displayedItemsCount.clamp(0, employees.length);
    final displayedEmployees = employees.sublist(0, displayCount);
    final hasMore = displayCount < employees.length;

    return Column(
      children: [
        // Employee list
        ...displayedEmployees.map((employee) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFE6E6E6),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  _EmployeeAvatar(
                    size: 38,
                    imageUrl: employee.employeeImageUrl,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.employeeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'ID: ${employee.empId}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        
        // Loading indicator when loading more
        if (_isLoadingMore && hasMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        
        // Total count
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            'Showing $displayCount of ${employees.length} employees',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9AA0A6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeView(BuildContext context, AttendanceState state) {
    if (state is AttendanceLoadingState && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is AttendanceErrorState) {
      return Center(child: Text(state.message));
    }

    Result? attendanceData;
    if (state is AttendanceDataLoaded) {
      attendanceData = state.attendanceData;
    }

    final monthName = selectedMonth != null
        ? DateFormat('MMMM').format(DateTime(2020, selectedMonth!))
        : 'Select Month';
    final year = DateTime.now().year.toString();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 48),
            Text(
              'ATTENDANCE',
              style: GoogleFonts.koulen(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: appFontColor,
                letterSpacing: 1.9,
              ),
            ),
            _MonthChip(
              label: monthName,
              onTap: () => _selectMonth(context),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            '$monthName, $year',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9AA0A6),
            ),
          ),
        ),
        const SizedBox(height: 10),

        if (attendanceData == null)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (attendanceData.mode == "grouped" && attendanceData.records != null)
          _buildEmployeeAttendanceWithCount(attendanceData)
        else
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(
              child: Text('No data available'),
            ),
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEmployeeAttendanceWithCount(Result data) {
    final records = data.records ?? [];
    
    // Remove duplicate records
    final Map<String, AttendanceRecord> uniqueRecords = {};
    for (var record in records) {
      final key = '${record.date}_${record.checkIn}';
      if (!uniqueRecords.containsKey(key)) {
        uniqueRecords[key] = record;
      }
    }
    
    final uniqueRecordsList = uniqueRecords.values.toList();

    return Column(
      children: [
        // Employee header with count
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE6E6E6),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              _EmployeeAvatar(
                size: 38,
                imageUrl: data.employeeImageUrl ?? "",
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.employeeName ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                '${data.totalPresentDays ?? 0}/${data.totalWorkingDays ?? 0}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Attendance records
        ...uniqueRecordsList.map((record) {
          final checkInTime = DateTime.parse(record.checkIn);
          DateTime? checkOutTime;
          if (record.checkOut != null && record.checkOut != false) {
            checkOutTime = DateTime.parse(record.checkOut!);
          }

          String status = 'ONTIME';
          Color textColor = Colors.green;

          if (checkOutTime == null) {
            status = 'ABSENT';
            textColor = const Color(0xff535353);
          } else if (checkInTime.isAfter(DateTime(
              checkInTime.year, checkInTime.month, checkInTime.day, 8, 15))) {
            final lateMinutes = checkInTime
                .difference(DateTime(checkInTime.year, checkInTime.month,
                    checkInTime.day, 8, 15))
                .inMinutes;
            status = '$lateMinutes MINS LATE';
            textColor = red;
          } else {
            textColor = const Color(0xff535353);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ColleaspedCard(
              status: status,
              textColor: textColor,
              bgColorStart: const Color(0xFF0F0C29),
              bgColorEnd: const Color(0xFF302B63),
              isExpanded: false,
              checkInTime: checkInTime,
              checkOutTime: checkOutTime,
            ),
          );
        }),
      ],
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  final int? selectedMonth;
  final int currentYear;

  const _MonthPickerDialog({
    required this.selectedMonth,
    required this.currentYear,
  });

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.selectedMonth;
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr',
      'May', 'Jun', 'Jul', 'Aug',
      'Sept', 'Oct', 'Nov', 'Dec'
    ];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Yearly Calendar 2026',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9AA0A6),
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthNumber = index + 1;
                final isSelected = _selectedMonth == monthNumber;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedMonth = monthNumber;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF757575)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      months[index],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_selectedMonth);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF757575),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

class _MonthChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _MonthChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.15 * 255).toInt()),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: appFontColor,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 16),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onSearch;

  const _SearchBox({
    required this.controller,
    required this.hintText,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: (_) => onSearch?.call(),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: IconButton(
          icon: const Icon(Icons.send, size: 20),
          onPressed: onSearch,
        ),
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF5A5A5A),
        ),
        filled: true,
        fillColor: const Color(0xFFF3F3F3),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _EmployeeAvatar extends StatelessWidget {
  final double size;
  final String imageUrl;
  final bool withShadow;

  const _EmployeeAvatar({
    required this.size,
    required this.imageUrl,
    this.withShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFBDBDBD), width: 1),
      boxShadow: withShadow
          ? [
              BoxShadow(
                color: Colors.black.withAlpha((0.12 * 255).toInt()),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ]
          : null,
    );

    Widget image;
    if (imageUrl.trim().isNotEmpty) {
      image = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/png/profile_1.png', fit: BoxFit.cover);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(color: const Color(0xFFE6E6E6));
        },
      );
    } else {
      image = Image.asset('assets/png/profile_1.png', fit: BoxFit.cover);
    }

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: decoration,
      child: ClipOval(child: image),
    );
  }
}
