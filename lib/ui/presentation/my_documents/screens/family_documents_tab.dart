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
    this.isLoading = false,
    this.onOpenDocument,
    this.onAddDocument,
  });

  final bool isActive;
  final List<Map<String, dynamic>> documents;
  final bool isLoading;
  final Future<void> Function(Map<String, dynamic> document)? onOpenDocument;
  final VoidCallback? onAddDocument;

  @override
  State<FamilyDocumentsTab> createState() => _FamilyDocumentsTabState();
}

class _FamilyDocumentsTabState extends State<FamilyDocumentsTab> {
  // Currently selected folder (null = show folders list)
  String? _selectedFolder;
  bool _folderSelectedByUser = false;
  DateTime _lastActivatedAt = DateTime.fromMillisecondsSinceEpoch(0);

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

  String _normalizeFolderName(String value) {
    return value.trim().toLowerCase();
  }

  String _folderNameFromLiveDoc(Map<String, dynamic> doc) {
    for (final candidate in [
      doc['title'],
      doc['document_type'],
      doc['type'],
      doc['name']
    ]) {
      final value = (candidate ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return 'Family Documents';
  }

  List<Map<String, dynamic>> _effectiveFolders(
      List<Map<String, dynamic>> liveDocs) {
    if (liveDocs.isEmpty) return const [];

    final grouped = <String, Map<String, dynamic>>{};
    for (final doc in liveDocs) {
      final folderName = _folderNameFromLiveDoc(doc);
      final key = _normalizeFolderName(folderName);
      final entry = grouped[key];
      if (entry == null) {
        grouped[key] = {
          'name': folderName,
          '_count': 1,
        };
      } else {
        entry['_count'] = ((entry['_count'] as int?) ?? 0) + 1;
      }
    }

    final result = grouped.values.toList(growable: false);
    result.sort((a, b) => (a['name'] as String)
        .toLowerCase()
        .compareTo((b['name'] as String).toLowerCase()));
    return result;
  }

  List<Map<String, dynamic>> _documentsForSelectedFolder(
      List<Map<String, dynamic>> liveDocs) {
    final selectedFolder = _selectedFolder;
    if (selectedFolder == null) return const [];

    if (liveDocs.isEmpty) return const [];

    final selectedKey = _normalizeFolderName(selectedFolder);
    return liveDocs
        .where((doc) =>
            _normalizeFolderName(_folderNameFromLiveDoc(doc)) == selectedKey)
        .toList(growable: false);
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

  void _openFolder(String folderName) {
    if (!widget.isActive) return;

    // Prevent accidental immediate open right after switching to Family tab.
    if (DateTime.now().difference(_lastActivatedAt) <
        const Duration(milliseconds: 300)) {
      return;
    }

    setState(() {
      _selectedFolder = folderName;
      _folderSelectedByUser = true;
    });
    // TODO: Fetch real folder documents from API
    // _fetchFolderDocuments(folderName);
  }

  void _goBackToFolders() {
    setState(() {
      _selectedFolder = null;
      _folderSelectedByUser = false;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _lastActivatedAt = DateTime.now();
    }
  }

  @override
  void didUpdateWidget(covariant FamilyDocumentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always reset to folders when Family tab becomes active.
    if (!oldWidget.isActive && widget.isActive) {
      _selectedFolder = null;
      _folderSelectedByUser = false;
      _lastActivatedAt = DateTime.now();
      return;
    }

    // Reset to folders view whenever user leaves Family tab.
    if (oldWidget.isActive && !widget.isActive) {
      _selectedFolder = null;
      _folderSelectedByUser = false;
      return;
    }

    // If data changed and selected folder no longer exists, go back to folders.
    final selectedFolder = _selectedFolder;
    if (selectedFolder != null) {
      final currentFolders = _effectiveFolders(_liveFamilyDocuments())
          .map((folder) => _normalizeFolderName(folder['name'].toString()))
          .toSet();
      if (!currentFolders.contains(_normalizeFolderName(selectedFolder))) {
        _selectedFolder = null;
        _folderSelectedByUser = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isActive && widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final liveDocs = _liveFamilyDocuments();

    final isFolderView = _selectedFolder != null && _folderSelectedByUser;

    return Navigator(
      pages: [
        MaterialPage(
          key: const ValueKey('family_folders'),
          child: _buildFoldersList(liveDocs),
        ),
        if (isFolderView)
          MaterialPage(
            key: ValueKey('family_docs_$_selectedFolder'),
            child: Builder(
              builder: (pageContext) =>
                  _buildDocumentsList(pageContext, liveDocs),
            ),
          ),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) return false;
        setState(() {
          _selectedFolder = null;
          _folderSelectedByUser = false;
        });
        return true;
      },
    );
  }

  Widget _buildLiveDocumentsList(BuildContext pageContext, List<Map<String, dynamic>> docs) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.w, right: 20.w, top: 8.h, bottom: 8.h),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(pageContext).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: const Color(0xFF27304E),
                tooltip: 'Back to folders',
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.18),
                    border: Border.all(color: const Color(0xffD9D9D9)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 13.5.w, vertical: 8.5.h),
                    child: Text(
                      '${_selectedFolder ?? 'Documents'}  |  ${docs.length + 1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            ],
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
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
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
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  if (isExpired)
                                    Padding(
                                      padding: EdgeInsets.only(top: 2.h),
                                      child: SizedBox(
                                        width: 22.w,
                                        height: 22.w,
                                        child: Image.asset(
                                          'assets/newapp/newicon/pencil_7754138 1.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.edit,
                                            size: 18.sp,
                                            color: const Color(0xFFBA1719),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (isExpired) SizedBox(height: 4.h),
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
                                ],
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
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Folders Grid (Main view) ──
  Widget _buildFoldersList(List<Map<String, dynamic>> liveDocs) {
    final folders = _effectiveFolders(liveDocs);

    if (folders.isEmpty) {
      return Center(
        child: Text(
          'No Documents found',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7A7A7A),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: folders.length,
      separatorBuilder: (context, index) => SizedBox(height: 15.h),
      itemBuilder: (context, index) {
        final folder = folders[index];
        return GestureDetector(
          onTap: () => _openFolder(folder['name'].toString()),
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
  Widget _buildDocumentsList(BuildContext pageContext, List<Map<String, dynamic>> liveDocs) {
    final docs = _documentsForSelectedFolder(liveDocs);
    if (liveDocs.isNotEmpty) {
      return _buildLiveDocumentsList(pageContext, docs);
    }

    return Column(
      children: [
        // Back button + Files count
        Padding(
          padding: EdgeInsets.only(left: 8.w, right: 20.w, top: 8.h, bottom: 8.h),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(pageContext).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: const Color(0xFF27304E),
                tooltip: 'Back to folders',
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.18),
                    border: Border.all(color: const Color(0xffD9D9D9)),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 13.5.w, vertical: 8.5.h),
                    child: Text(
                      '${_selectedFolder ?? 'Documents'}  |  ${docs.length + 1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            ],
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
