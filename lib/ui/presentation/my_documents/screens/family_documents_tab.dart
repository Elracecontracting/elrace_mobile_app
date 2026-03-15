import 'dart:async';

import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Family Documents Tab
/// Shows folder categories (Emirates ID, Birth Certificates, etc.)
/// Tapping a folder opens a grid of individual document cards.
class FamilyDocumentsTab extends StatefulWidget {
  const FamilyDocumentsTab({
    super.key,
    required this.isActive,
    required this.documents,
    this.onOpenDocument,
    this.onAddDocument,
  });

  final bool isActive;
  final List<Map<String, dynamic>> documents;
  final Future<void> Function(Map<String, dynamic> document)? onOpenDocument;
  final VoidCallback? onAddDocument;

  @override
  State<FamilyDocumentsTab> createState() => _FamilyDocumentsTabState();
}

class _FamilyDocumentsTabState extends State<FamilyDocumentsTab> {
  bool _loading = false;
  String? _error;

  // Currently selected folder (null = show folders list)
  String? _selectedFolder;

  List<Map<String, dynamic>> _liveFamilyDocuments() {
    final docs = widget.documents;
    if (docs.isEmpty) return const [];

    final familyDocs = docs.where((doc) {
      final explicitFamily =
          doc['_isFamily'] == true || doc['is_family'] == true;
      if (explicitFamily) return true;

      final type = (doc['title'] ?? doc['document_type'] ?? doc['type'] ?? '')
          .toString()
          .toLowerCase();
      final name = (doc['name'] ?? '').toString().toLowerCase();
      return type.contains('family') || name.contains('family');
    }).toList();

    return familyDocs;
  }

  // ── Fake data for folders ──
  final List<Map<String, dynamic>> _folders = [
    {'name': 'Emirates ID'},
    {'name': 'Birth Certificates'},
    {'name': 'Health Insurance'},
    {'name': 'Passports'},
    {'name': 'Driving License'},
    {'name': 'Visa'},
  ];

  // ── Fake data for documents inside folders ──
  final Map<String, List<Map<String, dynamic>>> _folderDocuments = {
    'Emirates ID': [
      {
        'id': 1,
        'name': 'Emirates ID',
        'person_name': 'Ahmed Marwan Ahmed',
        'expiry_date': '2026-01-02',
        'thumbnail': 'assets/png/emitates_id.png',
        'is_editable': true,
      },
      {
        'id': 2,
        'name': 'Emirates ID',
        'person_name': 'Yassin Marwan Ahmed',
        'expiry_date': '2026-01-02',
        'thumbnail': 'assets/png/emitates_id.png',
        'is_editable': false,
      },
      {
        'id': 3,
        'name': 'Emirates ID',
        'person_name': 'Yassin Marwan Ahmed',
        'expiry_date': '2026-01-02',
        'thumbnail': 'assets/png/emitates_id.png',
        'is_editable': false,
      },
      {
        'id': 4,
        'name': 'Emirates ID',
        'person_name': 'Ahmed Marwan Ahmed',
        'expiry_date': '2026-01-03',
        'thumbnail': 'assets/png/emitates_id.png',
        'is_editable': true,
      },
      {
        'id': 5,
        'name': 'Emirates ID',
        'person_name': 'Yassin Marwan Ahmed',
        'expiry_date': '2026-01-02',
        'thumbnail': 'assets/png/emitates_id.png',
        'is_editable': false,
      },
      {
        'id': 6,
        'name': 'Emirates ID',
        'person_name': 'Yassin Marwan Ahmed',
        'expiry_date': '2026-01-02',
        'thumbnail': 'assets/png/emitates_id.png',
        'is_editable': false,
      },
      {
        'id': 7,
        'name': 'Emirates ID',
        'person_name': 'Yassin Marwan Ahmed',
        'expiry_date': '2026-01-03',
        'thumbnail': 'assets/png/emitates_id.png',
        'is_editable': false,
      },
    ],
    'Birth Certificates': [
      {
        'id': 10,
        'name': 'Birth Certificate',
        'person_name': 'Ahmed Marwan Ahmed',
        'expiry_date': '',
        'thumbnail': 'assets/png/other-documetns-icon.png',
        'is_editable': true,
      },
      {
        'id': 11,
        'name': 'Birth Certificate',
        'person_name': 'Yassin Marwan Ahmed',
        'expiry_date': '',
        'thumbnail': 'assets/png/other-documetns-icon.png',
        'is_editable': false,
      },
    ],
    'Health Insurance': [
      {
        'id': 20,
        'name': 'Health Insurance',
        'person_name': 'Ahmed Marwan Ahmed',
        'expiry_date': '2026-06-15',
        'thumbnail': 'assets/png/other-documetns-icon.png',
        'is_editable': true,
      },
    ],
    'Passports': [
      {
        'id': 30,
        'name': 'Passport',
        'person_name': 'Ahmed Marwan Ahmed',
        'expiry_date': '2028-03-20',
        'thumbnail': 'assets/png/passport.png',
        'is_editable': true,
      },
      {
        'id': 31,
        'name': 'Passport',
        'person_name': 'Yassin Marwan Ahmed',
        'expiry_date': '2027-11-10',
        'thumbnail': 'assets/png/passport.png',
        'is_editable': false,
      },
    ],
    'Driving License': [
      {
        'id': 40,
        'name': 'Driving License',
        'person_name': 'Ahmed Marwan Ahmed',
        'expiry_date': '2027-08-01',
        'thumbnail': 'assets/png/driving_license.png',
        'is_editable': true,
      },
    ],
    'Visa': [
      {
        'id': 50,
        'name': 'Visa',
        'person_name': 'Ahmed Marwan Ahmed',
        'expiry_date': '2027-04-15',
        'thumbnail': 'assets/png/other-documetns-icon.png',
        'is_editable': true,
      },
    ],
  };

  String _formatDate(dynamic raw) {
    if (raw == null || raw == false || raw.toString().trim().isEmpty) return '';
    try {
      final date = DateTime.parse(raw.toString());
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return raw.toString();
    }
  }

  void _openFolder(String folderName) {
    setState(() {
      _selectedFolder = folderName;
    });
    // TODO: Fetch real folder documents from API
    // _fetchFolderDocuments(folderName);
  }

  void _goBackToFolders() {
    setState(() {
      _selectedFolder = null;
    });
  }

  @override
  void didUpdateWidget(covariant FamilyDocumentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to folders view whenever user leaves Family tab.
    if (oldWidget.isActive && !widget.isActive) {
      _selectedFolder = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveDocs = _liveFamilyDocuments();

    if (liveDocs.isNotEmpty) {
      return _buildLiveDocumentsList(liveDocs);
    }

    return WillPopScope(
      onWillPop: () async {
        if (_selectedFolder != null) {
          _goBackToFolders();
          return false;
        }
        return true;
      },
      child:
          _selectedFolder != null ? _buildDocumentsList() : _buildFoldersList(),
    );
  }

  Widget _buildLiveDocumentsList(List<Map<String, dynamic>> docs) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20.w, top: 8.h, bottom: 8.h),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.18),
                border: Border.all(color: const Color(0xffD9D9D9)),
              ),
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 13.5.w, vertical: 8.5.h),
                child: Text(
                  'Files No.  |  ${docs.length + 1}',
                  style: GoogleFonts.aBeeZee(
                    fontSize: 11,
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
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: docs.length + 1,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: () => widget.onAddDocument?.call(),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
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

              final doc = docs[index - 1];
              final iconPath =
                  (doc['icon'] ?? 'assets/png/other-documetns-icon.png')
                      .toString();
              final docName =
                  (doc['name'] ?? doc['title'] ?? 'Document').toString();
              final expiryDateText = _formatDate(doc['expiry_date']);
              final issueDateText = _formatDate(doc['issue_date']);
              final dateText =
                  expiryDateText.isNotEmpty ? expiryDateText : issueDateText;

              var isExpired = false;
              final rawExpiry = doc['expiry_date'];
              if (rawExpiry != null && rawExpiry != false) {
                try {
                  final expiry = DateTime.parse(rawExpiry.toString());
                  isExpired = expiry.isBefore(DateTime.now());
                } catch (_) {
                  isExpired = false;
                }
              }

              return GestureDetector(
                onTap: () {
                  if (widget.onOpenDocument != null) {
                    unawaited(widget.onOpenDocument!(doc));
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isExpired
                          ? const Color(0xFFBA1719)
                          : const Color(0xffD9D9D9),
                      width: isExpired ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.asset(
                              iconPath,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.insert_drive_file_outlined,
                                size: 44.sp,
                                color: const Color(0xff949494),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          docName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.aBeeZee(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        if (dateText.isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Text(
                            dateText,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: GoogleFonts.aBeeZee(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w400,
                              color: isExpired
                                  ? const Color(0xFFBA1719)
                                  : const Color(0xff949494),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Folders Grid (Main view) ──
  Widget _buildFoldersList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: _folders.length,
      separatorBuilder: (context, index) => SizedBox(height: 15.h),
      itemBuilder: (context, index) {
        final folder = _folders[index];
        return GestureDetector(
          onTap: () => _openFolder(folder['name']),
          child: _buildFolderCard(folder),
        );
      },
    );
  }

  Widget _buildFolderCard(Map<String, dynamic> folder) {
    return SizedBox(
      height: 260.h,
      child: Stack(
        children: [
          // Folder image background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.asset(
                'assets/newapp/filedoc.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Folder name label at top-right
          Positioned(
            top: 8.h,
            right: 35.w,
            child: Text(
              folder['name'],
              style: GoogleFonts.aBeeZee(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Documents Grid (Inside folder view) ──
  Widget _buildDocumentsList() {
    final docs = _folderDocuments[_selectedFolder] ?? [];
    return Column(
      children: [
        // Files count
        Padding(
          padding: EdgeInsets.only(left: 20.w, top: 8.h, bottom: 8.h),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.18),
                border: Border.all(color: const Color(0xffD9D9D9)),
              ),
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 13.5.w, vertical: 8.5.h),
                child: Text(
                  'Files No.  |  ${docs.length + 1}',
                  style: GoogleFonts.aBeeZee(
                    fontSize: 11,
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
        // Documents grid
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: docs.length + 1, // +1 for add card
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              if (index == 0) {
                // Add new document card
                return GestureDetector(
                  onTap: () {
                    widget.onAddDocument?.call();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
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

              final doc = docs[index - 1];
              final bool isEditable = doc['is_editable'] == true;

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isEditable
                        ? const Color(0xFFBA1719)
                        : const Color(0xffD9D9D9),
                    width: isEditable ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Thumbnail
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.asset(
                                doc['thumbnail'],
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          // Document name
                          Text(
                            doc['name'] ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.aBeeZee(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          // Person name
                          if ((doc['person_name'] ?? '').isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              doc['person_name'],
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
                          // Date
                          if (_formatDate(doc['expiry_date']).isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              _formatDate(doc['expiry_date']),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: GoogleFonts.aBeeZee(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w400,
                                color: isEditable
                                    ? const Color(0xFFBA1719)
                                    : const Color(0xff949494),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Edit icon for editable docs
                    if (isEditable)
                      Positioned(
                        top: 8.h,
                        right: 8.w,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 14.sp,
                            color: appFontColor,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
