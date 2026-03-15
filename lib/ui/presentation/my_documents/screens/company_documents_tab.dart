import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Company Documents Tab
/// Fetches documents from GET /api/company/attachments
class CompanyDocumentsTab extends StatefulWidget {
  const CompanyDocumentsTab({
    super.key,
    this.onAddDocument,
  });

  final VoidCallback? onAddDocument;

  @override
  State<CompanyDocumentsTab> createState() => _CompanyDocumentsTabState();
}

class _CompanyDocumentsTabState extends State<CompanyDocumentsTab> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _fetchCompanyDocuments();
  }

  Future<void> _fetchCompanyDocuments() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = SharedPref.getLoginData().result?.token ?? '';
      final url = Uri.parse('https://erp.elrace.com/api/company/attachments');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final body = jsonEncode({'jsonrpc': '2.0', 'params': {}});

      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['result'] != null &&
          data['result']['status'] == 'success') {
        final List list = (data['result']['data'] ?? []) as List;
        final docs = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (mounted) {
          setState(() {
            _documents = docs;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = data['result']?['message']?.toString() ??
                data['error']?.toString() ??
                'Failed to load company documents';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null || raw == false || raw.toString().trim().isEmpty) return '';
    try {
      final date = DateTime.parse(raw.toString());
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.aBeeZee(
                fontSize: 13.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: _fetchCompanyDocuments,
              child: Text(
                'Retry',
                style: GoogleFonts.aBeeZee(fontSize: 13.sp),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCompanyDocuments,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.w, top: 8.h, bottom: 8.h),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.18.r),
                  border: Border.all(color: const Color(0xffD9D9D9)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 13.5.w, vertical: 8.5.h),
                  child: Text(
                    'Files No.  |  \${_documents.length}',
                    style: GoogleFonts.aBeeZee(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      letterSpacing: .10,
                      color: const Color(0xff949494),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: _documents.length + 1,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: widget.onAddDocument,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: const Color(0xffD9D9D9)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_add_outlined,
                            size: 48.sp,
                            color: const Color(0xff949494),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Add New',
                            style: GoogleFonts.aBeeZee(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xff949494),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final doc = _documents[index - 1];
                final title = (doc['name'] ??
                        doc['title'] ??
                        doc['attachment_name'] ??
                        'Document')
                    .toString();
                final fileName = (doc['file_name'] ??
                        doc['attachment_filename'] ??
                        doc['filename'] ??
                        '')
                    .toString();
                final expiryDate =
                    _formatDate(doc['expiry_date'] ?? doc['date']);

                return _CompanyDocumentCard(
                  title: title,
                  fileName: fileName,
                  expiryDate: expiryDate,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyDocumentCard extends StatelessWidget {
  const _CompanyDocumentCard({
    required this.title,
    required this.fileName,
    this.expiryDate = '',
  });

  final String title;
  final String fileName;
  final String expiryDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xffD9D9D9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 12.h),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  color: const Color(0xFFF4F6FB),
                  border: Border.all(color: const Color(0xffE5E8F3)),
                ),
                child: Text(
                  'PDF',
                  style: GoogleFonts.aBeeZee(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xffBA1719),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/newapp/pdf.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.aBeeZee(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            if (fileName.isNotEmpty) ...[  
              SizedBox(height: 3.h),
              Text(
                fileName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.aBeeZee(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xff949494),
                ),
              ),
            ],
            if (expiryDate.isNotEmpty) ...[  
              SizedBox(height: 2.h),
              Text(
                'Exp: \$expiryDate',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.aBeeZee(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xffBA1719),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
