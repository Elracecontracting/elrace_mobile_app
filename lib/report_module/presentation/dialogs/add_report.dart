import 'package:el_race/main.dart';
import 'package:el_race/report_module/data/provider/reports_provider.dart';
import 'package:el_race/report_module/data/repositories/company_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

Future<bool> showAddNewReport(BuildContext context,
    {required int type, String? folderID}) async {
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  // ── Available companies ──
  final companies = <String>[
    'RCC',
    'El Race Cons. & Gen. Cont. Co. L.C.C',
    'Al Hewar Contracting & Irrigation Est.',
  ];
  final currentCompany =
      CompanyRepository.company?.companyName ?? companies.first;

  String selectedCompany = companies.contains(currentCompany) ? currentCompany : companies.first;

  bool cancel = true;

  await showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding:
                  EdgeInsets.symmetric(vertical: 28.h, horizontal: 22.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _InputSection(
                    label: 'Project',
                    subLabel: 'Name',
                    hint: 'Write here',
                    controller: nameController,
                  ),

                  SizedBox(height: 16.h),

                  // ── Company Name dropdown ──
                  _DropdownSection(
                    label: 'Company',
                    subLabel: 'Name',
                    hint: 'Select company',
                    value: selectedCompany,
                    items: companies,
                    onChanged: (v) {
                      setDialogState(() => selectedCompany = v ?? companies.first);
                      descriptionController.text = v ?? '';
                    },
                  ),

                  SizedBox(height: 24.h),

                  // ── Buttons ──
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48.h,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC62828),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'CANCEL',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: SizedBox(
                          height: 48.h,
                          child: ElevatedButton(
                            onPressed: () {
                              if (nameController.text.trim().isNotEmpty) {
                                descriptionController.text = selectedCompany;
                                cancel = false;
                                Navigator.pop(ctx);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'SUBMIT',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  if (cancel || nameController.text.trim().isEmpty) return false;

  ReportProvider provider =
      Provider.of<ReportProvider>(navKey.currentContext!, listen: false);
  if (type == 2) {
    await provider.createFolder(
        title: nameController.text, description: descriptionController.text);
    return true;
  } else {
    await provider.createReport(
        title: nameController.text, folderID: folderID!);
    return true;
  }
}

class _InputSection extends StatelessWidget {
  final String label;
  final String subLabel;
  final String hint;
  final TextEditingController controller;

  const _InputSection({
    required this.label,
    required this.subLabel,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFD1D3DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
            ),
          ),
          Text(
            subLabel,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            height: 44.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: const Color(0xFFD1D3DA)),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: controller,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFF374151),
              ),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isCollapsed: true,
                hintStyle: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFFA3A6B1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable styled dropdown section matching the design mockup.
class _DropdownSection extends StatelessWidget {
  final String label;
  final String subLabel;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownSection({
    required this.label,
    required this.subLabel,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFD1D3DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
            ),
          ),
          Text(
            subLabel,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            height: 44.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: const Color(0xFFD1D3DA)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(
                  hint,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFFA3A6B1),
                  ),
                ),
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  size: 22.w,
                  color: const Color(0xFF374151),
                ),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF374151),
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                items: items
                    .map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
