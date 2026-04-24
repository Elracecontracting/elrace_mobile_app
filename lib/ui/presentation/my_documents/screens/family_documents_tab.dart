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
    required this.statTotal,
    required this.statRequested,
    required this.statExpiringSoon,
    required this.statExpired,
    required this.selectedDocType,
    required this.recentActivities,
    this.isLoading = false,
    this.onDocTypeSelected,
    this.onOpenDocument,
    this.onAddDocument,
    this.onAddNewRequest,
  });

  final bool isActive;
  final List<Map<String, dynamic>> documents;
  final String statTotal;
  final String statRequested;
  final String statExpiringSoon;
  final String statExpired;
  final String? selectedDocType;
  final List<Map<String, dynamic>> recentActivities;
  final bool isLoading;
  final ValueChanged<String?>? onDocTypeSelected;
  final Future<void> Function(Map<String, dynamic> document)? onOpenDocument;
  final VoidCallback? onAddDocument;
  final VoidCallback? onAddNewRequest;

  @override
  State<FamilyDocumentsTab> createState() => _FamilyDocumentsTabState();
}

class _FamilyDocumentsTabState extends State<FamilyDocumentsTab> {
  // Currently selected folder (null = show folders list)
  String? _selectedFolder;
  bool _folderSelectedByUser = false;
  DateTime _lastActivatedAt = DateTime.fromMillisecondsSinceEpoch(0);
  final PageController _folderPageController =
      PageController(viewportFraction: 0.82);
  final PageController _statsPageController =
      PageController(viewportFraction: 0.355);

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
  void dispose() {
    _folderPageController.dispose();
    _statsPageController.dispose();
    super.dispose();
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
    return WillPopScope(
      onWillPop: () async {
        if (!widget.isActive) return true;

        // In filtered mode, back should clear filter first.
        if (widget.selectedDocType != null) {
          widget.onDocTypeSelected?.call(null);
          return false;
        }

        // In folder details mode, back should return to folders first.
        if (_selectedFolder != null && _folderSelectedByUser) {
          _goBackToFolders();
          return false;
        }

        return true;
      },
      child: Builder(
        builder: (context) {
          if (widget.isActive && widget.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final liveDocs = _liveFamilyDocuments();
          final selectedDocType = widget.selectedDocType;

          if (selectedDocType != null) {
            return _buildFilteredMode(liveDocs, selectedDocType);
          }

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
        },
      ),
    );
  }

  bool _isExpiredDocument(Map<String, dynamic> doc) {
    final rawExpiry = doc['expiry_date'];
    if (rawExpiry == null || rawExpiry == false) return false;
    final parsed = DateTime.tryParse(rawExpiry.toString());
    if (parsed == null) return false;
    return parsed.isBefore(DateTime.now());
  }

  Map<String, dynamic> _selectedStatMeta(String docType) {
    switch (docType) {
      case 'expired':
        return {
          'label': 'Expired',
          'value': widget.statExpired,
          'background': const Color(0xFFE2F3E9),
          'labelColor': const Color(0xFFBA1719),
          'valueColor': const Color(0xFFBA1719),
          'icon': Icons.error_outline_rounded,
          'iconColor': const Color(0xFFBA1719),
        };
      case 'requested':
        return {
          'label': 'Requested',
          'value': widget.statRequested,
          'background': const Color(0xFFF6CC1B),
          'labelColor': Colors.black,
          'valueColor': Colors.black,
          'icon': Icons.assignment_outlined,
          'iconColor': Colors.black,
        };
      case 'expiry_soon':
        return {
          'label': 'Expired soon',
          'value': widget.statExpiringSoon,
          'background': const Color(0xFF8B2AB3),
          'labelColor': Colors.white,
          'valueColor': Colors.white,
          'icon': Icons.access_time_rounded,
          'iconColor': Colors.white,
        };
      default:
        return {
          'label': 'Total',
          'value': widget.statTotal,
          'background': const Color(0xFF2F6AD8),
          'labelColor': Colors.white,
          'valueColor': Colors.white,
          'icon': Icons.insert_drive_file_outlined,
          'iconColor': Colors.white,
        };
    }
  }

  Widget _buildFilteredMode(
      List<Map<String, dynamic>> liveDocs, String selectedDocType) {
    if (selectedDocType == 'requested') {
      return _buildRequestedMode(liveDocs);
    }

    final meta = _selectedStatMeta(selectedDocType);
    final forceRedBorder =
        selectedDocType == 'expired' || selectedDocType == 'expiry_soon';

    return ListView(
      padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 14.h, bottom: 8.h),
      children: [
        Container(
          height: 96.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: meta['background'] as Color,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      meta['icon'] as IconData,
                      size: 32.sp,
                      color: meta['iconColor'] as Color,
                    ),
                    SizedBox(width: 10.w),
                    Flexible(
                      child: Text(
                        meta['label'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 30.sp / 2,
                          fontWeight: FontWeight.w700,
                          color: meta['labelColor'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                (meta['value'] ?? '-').toString(),
                style: GoogleFonts.poppins(
                  fontSize: 88.sp / 2,
                  fontWeight: FontWeight.w700,
                  color: meta['valueColor'] as Color,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        if (liveDocs.isEmpty)
          _buildEmptyState(
            icon: Icons.folder_off_rounded,
            title: 'No Documents',
            subtitle: 'There are no documents for this filter.',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: liveDocs.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              mainAxisExtent: 270.h,
            ),
            itemBuilder: (context, index) {
              final doc = liveDocs[index];
              final iconPath =
                  (doc['icon'] ?? 'assets/png/other-documetns-icon.png')
                      .toString();
              final title = (doc['title'] ?? '').toString();
              final name = (doc['name'] ?? '').toString();
              final isExpired = _isExpiredDocument(doc);
              final useRedBorder = forceRedBorder || isExpired;

              return GestureDetector(
                onTap: () {
                  if (widget.onOpenDocument != null) {
                    unawaited(widget.onOpenDocument!(doc));
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: useRedBorder
                          ? const Color(0xFFBA1719)
                          : const Color(0xffD9D9D9),
                      width: useRedBorder ? 2 : 1,
                    ),
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 90.h,
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
                        SizedBox(height: 8.h),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF727272),
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: null,
                          overflow: TextOverflow.visible,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (useRedBorder) ...[
                          SizedBox(height: 8.h),
                          Container(
                            constraints: BoxConstraints(minHeight: 24.h),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF1B1F26),
                                  Color(0xFF717171),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12.w,
                                  height: 12.w,
                                  child: Image.asset(
                                    'assets/newapp/newicon/change_document_icon.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.swap_horiz_rounded,
                                      color: Colors.white,
                                      size: 12.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'Change',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                              ],
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
      ],
    );
  }

  String _requestedPersonName(Map<String, dynamic> doc) {
    for (final key in [
      'person_name',
      'family_member_name',
      'name',
      'title',
    ]) {
      final value = (doc[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return 'Family Member';
  }

  String _requestedRelation(Map<String, dynamic> doc) {
    final raw = (doc['relation'] ??
            doc['family_member_label'] ??
            doc['family_member'] ??
            '')
        .toString()
        .trim();
    if (raw.isEmpty) return 'Family';

    final low = raw.toLowerCase();
    if (low == 'spouse') return 'Spouse';
    if (low == 'wife') return 'Spouse';
    if (low.contains('daughter') || low.contains('female')) return 'Daughter';
    if (low.contains('son') || low.contains('male')) return 'Son';
    if (low.startsWith('child_') || low == 'child') return 'Son';

    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => '${e[0].toUpperCase()}${e.substring(1)}')
        .join(' ');
  }

  Color _relationColor(String relation) {
    final low = relation.toLowerCase();
    if (low.contains('spouse')) return const Color(0xFF1EA7E1);
    if (low.contains('son')) return const Color(0xFFF2A100);
    if (low.contains('daughter')) return const Color(0xFF5B39D6);
    return const Color(0xFF1EA7E1);
  }

  String _stringField(Map<String, dynamic> doc, List<String> keys,
      {String fallback = '-'}) {
    for (final key in keys) {
      final value = (doc[key] ?? '').toString().trim();
      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return fallback;
  }

  String _requestedPassportNo(Map<String, dynamic> doc) => _stringField(
        doc,
        const ['passport_no', 'passport_number', 'passport'],
      );

  String _requestedEidNo(Map<String, dynamic> doc) => _stringField(
        doc,
        const ['eid_no', 'emirates_id_no', 'eid_number', 'emirates_id'],
      );

  String _requestedNationality(Map<String, dynamic> doc) => _stringField(
        doc,
        const ['nationality', 'family_member_nationality', 'nationality_name'],
      );

  String _requestedBirthDate(Map<String, dynamic> doc) {
    final raw = _stringField(
      doc,
      const ['birth_date', 'family_member_dob', 'dob'],
      fallback: '',
    );
    if (raw.isEmpty) return '-';
    return _formatDate(raw);
  }

  String _requestedPassportExpiry(Map<String, dynamic> doc) {
    final raw = _stringField(
      doc,
      const ['passport_expiry_date', 'passport_expiry', 'expiry_date'],
      fallback: '',
    );
    if (raw.isEmpty) return '-';
    return _formatDate(raw);
  }

  String _requestedEidExpiry(Map<String, dynamic> doc) {
    final raw = _stringField(
      doc,
      const [
        'eid_expiry_date',
        'emirates_id_expiry_date',
        'eid_expiry',
        'expiry_date'
      ],
      fallback: '',
    );
    if (raw.isEmpty) return '-';
    return _formatDate(raw);
  }

  String? _requestedPhoto(Map<String, dynamic> doc) {
    for (final key in ['photo', 'image_url', 'avatar', 'image']) {
      final value = (doc[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  Widget _buildRequestedSummaryCard() {
    return Container(
      height: 96.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF6CC1B),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_ind_outlined,
                size: 30.sp,
                color: Colors.black,
              ),
              SizedBox(width: 10.w),
              Text(
                'Requested',
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          Text(
            widget.statRequested,
            style: GoogleFonts.poppins(
              fontSize: 44.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewRequestCard() {
    return GestureDetector(
      onTap: () {
        final callback = widget.onAddNewRequest ?? widget.onAddDocument;
        if (callback != null) {
          callback();
        }
      },
      child: Container(
        height: 64.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFBEBEBE), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_add,
              size: 24.sp,
              color: const Color(0xFF8C8C8C),
            ),
            SizedBox(width: 8.w),
            Text(
              'Add New Request',
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestedCard(Map<String, dynamic> doc) {
    final personName = _requestedPersonName(doc);
    final relation = _requestedRelation(doc);
    final relationColor = _relationColor(relation);
    final passportNo = _requestedPassportNo(doc);
    final eidNo = _requestedEidNo(doc);
    final nationality = _requestedNationality(doc);
    final birthDate = _requestedBirthDate(doc);
    final passportExpiry = _requestedPassportExpiry(doc);
    final eidExpiry = _requestedEidExpiry(doc);
    final photo = _requestedPhoto(doc);

    return GestureDetector(
      onTap: () {
        if (widget.onOpenDocument != null) {
          unawaited(widget.onOpenDocument!(doc));
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFFD1D1D1),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 21.r,
                  backgroundColor: const Color(0xFFE7E7E7),
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  child: photo == null
                      ? Text(
                          personName.isEmpty
                              ? 'F'
                              : personName[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5F5F5F),
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        relation,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: relationColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _requestedInfoRow('Passport No', passportNo),
                      SizedBox(height: 4.h),
                      _requestedInfoRow('EID No', eidNo),
                      SizedBox(height: 4.h),
                      _requestedInfoRow('Nationality', nationality),
                      SizedBox(height: 4.h),
                      _requestedInfoRow('Birth of date', birthDate),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                SizedBox(
                  width: 126.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _requestedExpiryText(passportExpiry),
                      SizedBox(height: 11.h),
                      _requestedExpiryText(eidExpiry),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestedInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 62.w,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        Text(
          '|',
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _requestedExpiryText(String dateText) {
    return Text(
      'Expiry date | $dateText',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFCC3A3A),
      ),
    );
  }

  Widget _buildRequestedMode(List<Map<String, dynamic>> docs) {
    return ListView(
      padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 14.h, bottom: 8.h),
      children: [
        _buildRequestedSummaryCard(),
        SizedBox(height: 12.h),
        _buildAddNewRequestCard(),
        SizedBox(height: 12.h),
        if (docs.isEmpty)
          _buildEmptyState(
            icon: Icons.folder_off_rounded,
            title: 'No Requested Documents',
            subtitle: 'There are no family document requests yet.',
          )
        else
          ...docs.map((doc) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _buildRequestedCard(doc),
              )),
      ],
    );
  }

  Widget _buildLiveDocumentsList(
      BuildContext pageContext, List<Map<String, dynamic>> docs) {
    return Column(
      children: [
        Padding(
          padding:
              EdgeInsets.only(left: 8.w, right: 20.w, top: 8.h, bottom: 8.h),
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
                      maxLines: null,
                      overflow: TextOverflow.visible,
                      style: GoogleFonts.poppins(
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
                          style: GoogleFonts.poppins(
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
                              maxLines: null,
                              overflow: TextOverflow.visible,
                              style: GoogleFonts.poppins(
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
                                maxLines: null,
                                style: GoogleFonts.poppins(
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

    return ListView(
      padding: EdgeInsets.only(left: 6.w, right: 6.w, top: 16.h, bottom: 4.h),
      children: [
        _buildSummaryCards(),
        SizedBox(height: 12.h),
        if (folders.isEmpty)
          _buildEmptyState(
            icon: Icons.folder_off_rounded,
            title: 'No Family Documents',
            subtitle:
                'There are no family documents yet. Tap Add Document to create the first one.',
          )
        else ...[
          SizedBox(
            height: 220.h,
            child: PageView.builder(
              controller: _folderPageController,
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: GestureDetector(
                    onTap: () => _openFolder(folder['name'].toString()),
                    child: _buildFolderCard(folder),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 14.h),
        ],
        Text(
          'RECENT ACTIVITY',
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: const Color(0xFF7C7C7C),
          ),
        ),
        SizedBox(height: 10.h),
        ..._buildRecentActivityTiles(),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final cards = [
      {
        'label': 'Total',
        'value': widget.statTotal,
        'docType': null,
        'background': const Color(0xFF2F6AD8),
        'valueColor': Colors.white,
        'labelColor': Colors.white,
        'icon': 'assets/newapp/newicon/document_total.com.png',
      },
      {
        'label': 'Requested',
        'value': widget.statRequested,
        'docType': 'requested',
        'background': const Color(0xFFF6CC1B),
        'valueColor': Colors.black,
        'labelColor': Colors.black,
        'icon': 'assets/newapp/newicon/document_requested.png',
      },
      {
        'label': 'Expired',
        'value': widget.statExpired,
        'docType': 'expired',
        'background': const Color(0xFFE2F3E9),
        'valueColor': const Color(0xFFBA1719),
        'labelColor': const Color(0xFFBA1719),
        'icon': 'assets/newapp/newicon/document_Expired.png',
      },
      {
        'label': 'Expired soon',
        'value': widget.statExpiringSoon,
        'docType': 'expiry_soon',
        'background': const Color(0xFF8B2AB3),
        'valueColor': Colors.white,
        'labelColor': Colors.white,
        'icon': '',
        'useClockIcon': true,
      },
    ];

    Widget card({
      required String label,
      required String value,
      required Color color,
      required Color labelColor,
      required String? docType,
      required String iconPath,
      bool useClockIcon = false,
      Color valueColor = Colors.black,
    }) {
      final selected = widget.selectedDocType == docType ||
          (docType == null && widget.selectedDocType == null);
      return GestureDetector(
        onTap: docType == null
            ? null
            : () => widget.onDocTypeSelected?.call(docType),
        child: Container(
          height: 138.h,
          width: 156.w,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 28.sp / 2,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                    height: 1,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 62.sp / 2,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    height: 1,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: useClockIcon
                    ? Icon(
                        Icons.access_time_rounded,
                        size: 30.sp,
                        color: Colors.white,
                      )
                    : Image.asset(
                        iconPath,
                        width: 30.w,
                        height: 30.w,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.insert_drive_file_outlined,
                          size: 30.sp,
                          color: labelColor,
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 138.h,
          child: PageView.builder(
            controller: _statsPageController,
            padEnds: false,
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final item = cards[index];
              return Padding(
                padding:
                    EdgeInsets.only(left: index == 0 ? 0 : 6.w, right: 6.w),
                child: card(
                  label: item['label'] as String,
                  value: item['value'] as String,
                  color: item['background'] as Color,
                  labelColor: item['labelColor'] as Color,
                  docType: item['docType'] as String?,
                  iconPath: item['icon'] as String,
                  useClockIcon: (item['useClockIcon'] as bool?) ?? false,
                  valueColor: item['valueColor'] as Color,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      child: Column(
        children: [
          Icon(
            icon,
            size: 60.sp,
            color: const Color(0xFF98A0AE),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3B4352),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7B8290),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentActivityTiles() {
    if (widget.recentActivities.isEmpty) {
      return [
        _buildEmptyState(
          icon: Icons.history_toggle_off_rounded,
          title: 'No Recent Activity',
          subtitle: 'There are no requested family document activities yet.',
        ),
      ];
    }

    String relative(String raw) {
      if (raw.trim().isEmpty) return '';
      final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
      if (parsed == null) return raw;
      final diff = DateTime.now().difference(parsed);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }

    return widget.recentActivities.take(6).map((item) {
      final title = (item['title'] ?? '').toString();
      final state = (item['state'] ?? '').toString().toLowerCase();
      final time = relative((item['time'] ?? '').toString());
      final accepted = state.contains('approve') || state.contains('accept');
      final rejected = state.contains('reject') || state.contains('cancel');

      final dotColor = accepted
          ? const Color(0xFF13A65D)
          : rejected
              ? const Color(0xFFCA1122)
              : const Color(0xFF13A65D);

      return Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Container(
              width: 15.w,
              height: 15.w,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF222222),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                color: const Color(0xFF595959),
              ),
            ),
          ],
        ),
      );
    }).toList(growable: false);
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
              style: GoogleFonts.poppins(
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
  Widget _buildDocumentsList(
      BuildContext pageContext, List<Map<String, dynamic>> liveDocs) {
    final docs = _documentsForSelectedFolder(liveDocs);
    if (liveDocs.isNotEmpty) {
      return _buildLiveDocumentsList(pageContext, docs);
    }

    return Column(
      children: [
        // Back button + Files count
        Padding(
          padding:
              EdgeInsets.only(left: 8.w, right: 20.w, top: 8.h, bottom: 8.h),
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
                      maxLines: null,
                      overflow: TextOverflow.visible,
                      style: GoogleFonts.poppins(
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
                          style: GoogleFonts.poppins(
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
                            maxLines: null,
                            overflow: TextOverflow.visible,
                            style: GoogleFonts.poppins(
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
                              maxLines: null,
                              overflow: TextOverflow.visible,
                              style: GoogleFonts.poppins(
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
                              maxLines: null,
                              style: GoogleFonts.poppins(
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
