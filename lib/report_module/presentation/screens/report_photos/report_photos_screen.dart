import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';

import 'package:el_race/report_module/data/models/report_model.dart';
import 'package:el_race/report_module/data/models/report_detail_model.dart';
import 'package:el_race/report_module/data/models/report_item_model.dart';
import 'package:el_race/report_module/data/provider/reports_provider.dart';
import 'package:el_race/report_module/data/services/pdf_service.dart';
import 'package:el_race/report_module/presentation/screens/report_detail/image_editing_screen.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:http/http.dart' as http;
import 'package:el_race/report_module/core/utils/directory_operation.dart';
import 'package:el_race/report_module/data/models/report_pdf_model.dart';
import 'package:el_race/report_module/presentation/screens/report_detail/pdf_preview_screen.dart';
import 'package:el_race/report_module/presentation/bottom_sheets/show_option_sheet.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ReportPhotosScreen extends StatefulWidget {
  final ReportModel report;
  final String folderName;
  final String folderId;
  final VoidCallback? onReportUpdated;

  const ReportPhotosScreen({
    super.key,
    required this.report,
    required this.folderName,
    required this.folderId,
    this.onReportUpdated,
  });

  @override
  State<ReportPhotosScreen> createState() => _ReportPhotosScreenState();
}

class _ReportPhotosScreenState extends State<ReportPhotosScreen> {
  bool _isLoading = true;
  bool _isButtonExpanded = false;
  final ImagePicker _picker = ImagePicker();
  List<_PhotoItem> _photoItems = [];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<ReportProvider>(context, listen: false);
      final detail =
          await provider.fetchReportDetailFromApi(widget.report.id);
      if (detail != null && detail.reportItems.isNotEmpty) {
        _photoItems = detail.reportItems.map((item) {
          final p = _PhotoItem();
          p.itemId = item.id;
          p.imagePath = item.image.isNotEmpty ? item.image : null;
          p.location = item.location.isNotEmpty ? item.location : null;
          p.locationController.text = item.location;
          p.description = item.description;
          p.descriptionController.text = item.description;
          return p;
        }).toList();
      } else {
        _photoItems = [];
      }
    } catch (_) {
      _photoItems = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  /// Save modified items to API. Uses the API response to update local state
  /// instead of re-fetching (which can return stale data).
  Future<void> _saveItemsAndReload() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final provider =
        Provider.of<ReportProvider>(context, listen: false);
    for (int i = 0; i < _photoItems.length; i++) {
      final item = _photoItems[i];
      if (item.imagePath == null || item.imagePath!.isEmpty) continue;
      final isNetwork = item.imagePath!.startsWith('http');
      debugPrint('📤 Saving item[$i] id=${item.itemId} '
          'loc=${item.location} desc="${item.description}" '
          'isNetwork=$isNetwork');
      if (item.itemId != null) {
        try {
          final result = await provider.updateReportItem(
            reportId: widget.report.id,
            itemId: item.itemId!,
            location: item.location ?? '',
            description: item.description,
            imageFile: isNetwork ? null : File(item.imagePath!),
            index: i,
          );
          debugPrint('📤 Item[$i] update result: $result');
          // Update image URL from server response (important for newly uploaded images)
          if (result != null && result.image.isNotEmpty) {
            item.imagePath = result.image;
          }
        } catch (e) {
          debugPrint('📤 Item[$i] update ERROR: $e');
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
    widget.onReportUpdated?.call();
    Fluttertoast.showToast(
      msg: 'Report Updated',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  // ── Camera / Gallery picker ──
  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Photo',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF27304E),
                ),
              ),
              SizedBox(height: 20.h),
              ListTile(
                leading:
                    const Icon(Icons.camera_alt, color: Color(0xFF27304E)),
                title: Text(
                  'Take Photo',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: Color(0xFF27304E)),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 60,
    );
    if (image == null) return;

    final savedPath = await saveImageToAppStorage(
      File(image.path),
      widget.folderId + widget.folderId,
    );
    if (savedPath.isEmpty) return;

    // Add item and upload
    setState(() => _isLoading = true);
    try {
      final provider =
          Provider.of<ReportProvider>(context, listen: false);
      await provider.addReportItem(
        reportId: widget.report.id,
        imageFile: File(savedPath),
        location: '',
        description: '',
        index: _photoItems.length,
      );
      await _loadPhotos();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openPdfGenerationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PdfGenerationPage(
          reportId: widget.report.id,
          folderId: widget.folderId,
          folderName: widget.folderName,
          reportItemsCount: _photoItems.length,
        ),
      ),
    );
  }

  void _openPhotoDetailDialog(int index) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _PhotoDetailDialog(
        photoItems: _photoItems,
        initialIndex: index,
        reportId: widget.report.id,
        folderId: widget.folderId,
      ),
    ).then((_) {
      // Sync descriptions and locations from controllers after dialog is dismissed
      // (whether via X button, back gesture, or barrier tap).
      for (final item in _photoItems) {
        item.description = item.descriptionController.text;
        item.location = item.locationController.text;
      }
      _saveItemsAndReload();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isButtonExpanded) setState(() => _isButtonExpanded = false);
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        appBar: const HeaderWidget(),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(height: 14.h),
              // Header row: "Photos" + "+" button
              Padding(
                padding: EdgeInsets.only(left: 20.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Photos',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF878B98),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (!_isButtonExpanded) {
                          setState(() => _isButtonExpanded = true);
                        } else {
                          _showImageSourceDialog();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        width: _isButtonExpanded ? 170.w : 44.w,
                        height: 42.h,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: const Color(0xFF27304E),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(14.r),
                            bottomLeft: Radius.circular(
                                _isButtonExpanded ? 0 : 14.r),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Row(
                          children: [
                            Icon(Icons.add,
                                size: 22.w, color: Colors.white),
                            Expanded(
                              child: ClipRect(
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.centerRight,
                                  widthFactor: _isButtonExpanded ? 1 : 0,
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.only(start: 4.w),
                                    child: Text(
                                      'Add Photos',
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Expanded menu option (Generate PDF)
              if (_isButtonExpanded)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 170.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF27304E),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(14.r),
                      ),
                    ),
                    child: _menuButton('Generate PDF', () {
                      setState(() => _isButtonExpanded = false);
                      _openPdfGenerationPage();
                    }),
                  ),
                ),
              SizedBox(height: 12.h),
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _photoItems.isEmpty
                        ? _buildEmptyState()
                        : _buildPhotoGrid(),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Text(
          label,
          textAlign: TextAlign.right,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80.w,
              color: const Color(0xFFBFC2CC),
            ),
            SizedBox(height: 12.h),
            Text(
              'Add Pictures',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9AA0A6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      itemCount: _photoItems.length,
      itemBuilder: (context, index) {
        final item = _photoItems[index];
        if (item.imagePath == null || item.imagePath!.isEmpty) {
          return const SizedBox.shrink();
        }

        final isNetwork = item.imagePath!.startsWith('http');
        return GestureDetector(
          onTap: () => _openPhotoDetailDialog(index),
          child: Container(
            margin: EdgeInsets.only(bottom: 14.h),
            height: 200.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border:
                  Border.all(color: const Color(0xFF2C3454), width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                isNetwork
                    ? Image.network(
                        item.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, size: 40)),
                      )
                    : Image.file(
                        File(item.imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, size: 40)),
                      ),
                // Hamburger icon top-right
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Icon(
                    Icons.menu,
                    size: 22.w,
                    color: const Color(0xFF27304E),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

// ═══════════════════════════════════════════════════════════
// PDF Generation Page (File Name + Generate + Recent Files)
// ═══════════════════════════════════════════════════════════

class _PdfGenerationPage extends StatefulWidget {
  final String reportId;
  final String folderId;
  final String folderName;
  final int reportItemsCount;

  const _PdfGenerationPage({
    required this.reportId,
    required this.folderId,
    required this.folderName,
    required this.reportItemsCount,
  });

  @override
  State<_PdfGenerationPage> createState() => _PdfGenerationPageState();
}

class _PdfGenerationPageState extends State<_PdfGenerationPage> {
  late TextEditingController _nameController;
  bool _isGenerating = false;
  List<ReportPdfModel> _pdfs = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folderName);
    _loadPdfHistory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadPdfHistory() async {
    try {
      _pdfs = await reportProvider.fetchReports(
        empId: ReportProvider.empID,
        reportId: widget.reportId,
        folderId: widget.folderId,
      );
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _generate() async {
    if (_isGenerating) return;
    FocusScope.of(context).unfocus();
    final fileName = _nameController.text.trim();
    if (fileName.isEmpty) return;

    if (_pdfs.any((p) => p.fileName == '$fileName.pdf')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('A report with the same name already exists.')),
        );
      }
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final provider =
          Provider.of<ReportProvider>(context, listen: false);
      final detail =
          await provider.fetchReportDetailFromApi(widget.reportId);
      if (detail == null) {
        if (mounted) setState(() => _isGenerating = false);
        return;
      }

      final pdfBytes = await PdfService().generateReportPdf(
        report: detail,
        projectName: widget.folderName,
      );

      final uploaded = await reportProvider.uploadReportPdf(
        empId: ReportProvider.empID,
        reportId: widget.reportId,
        folderId: widget.folderId,
        fileName: fileName,
        pdfBytes: pdfBytes,
      );

      if (uploaded) await _loadPdfHistory();
    } catch (_) {} finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _onPdfMoreTap(ReportPdfModel pdf) async {
    final status =
        await showEditOptions(context, options: ['View', 'Share']);
    if (status == 0) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfDisplayScreen(link: pdf.reportLink),
        ),
      );
    } else if (status == 1) {
      await Share.shareUri(Uri.parse(pdf.reportLink));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: const HeaderWidget(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.image_outlined,
                    color: const Color(0xFFAEAEAE),
                    size: 22.w,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    widget.reportItemsCount.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFAEAEAE),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type of Report',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6A6D78),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _buildReportTypeButton('Site report'),
                  SizedBox(height: 8.h),
                  _buildReportTypeButton('Transfer report'),
                  SizedBox(height: 8.h),
                  _buildReportTypeButton('Incident report'),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Divider(
                color: const Color(0xFFA7A7A7),
                thickness: 0.8,
                height: 1,
              ),
            ),
            SizedBox(height: 14.h),
            // ── File Name field ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File Name',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6A6D78),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(
                                color: const Color(0xFFD0D0D0), width: .9),
                          ),
                          padding:
                              EdgeInsets.symmetric(horizontal: 16.w),
                          child: TextField(
                            controller: _nameController,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: const Color(0xFF27304E),
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: '',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: const Color(0xFFB0B0B0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      GestureDetector(
                        onTap: _isGenerating ? null : _generate,
                        child: Container(
                          width: 34.w,
                          height: 34.h,
                          child: _isGenerating
                              ? Padding(
                                  padding: EdgeInsets.all(8.w),
                                  child:
                                      const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF27304E),
                                  ),
                                )
                              : Icon(Icons.arrow_downward_rounded,
                                  color: const Color(0xFF27304E), size: 34.w),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),
            // ── Recent Files section ──
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF27304E),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 10.h),
                      child: Text(
                        'Recent Files',
                        style: GoogleFonts.inter(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _pdfs.isEmpty
                          ? Center(
                              child: Text(
                                'No generated PDFs yet',
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  color: Colors.white54,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w),
                              itemCount: _pdfs.length,
                              itemBuilder: (context, index) {
                                final pdf = _pdfs[index];
                                return _buildPdfTile(pdf);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfTile(ReportPdfModel pdf) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfDisplayScreen(link: pdf.reportLink),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 58.w,
              height: 58.w,
              child: Image.asset(
                _isPdfFile(pdf)
                    ? 'assets/png/pdf-icon.png'
                    : 'assets/png/text.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  _isPdfFile(pdf)
                      ? Icons.picture_as_pdf
                      : Icons.insert_drive_file,
                  color: _isPdfFile(pdf) ? Colors.red : Colors.white,
                  size: 32.w,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pdf.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _formatPdfDate(pdf.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _onPdfMoreTap(pdf),
              child:
                  Icon(Icons.more_vert, color: Colors.white, size: 22.w),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeButton(String title) {
    return SizedBox(
      width: 205.w,
      height: 36.h,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF27304E), width: 1.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          backgroundColor: Colors.white,
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF27304E),
          ),
        ),
      ),
    );
  }

  bool _isPdfFile(ReportPdfModel pdf) {
    final fileName = pdf.fileName.toLowerCase();
    final link = pdf.reportLink.toLowerCase();
    return fileName.endsWith('.pdf') || link.contains('.pdf');
  }

  String _formatPdfDate(String raw) {
    try {
      final normalized = raw.replaceAll('/', '-').replaceFirst(' ', 'T');
      final parsed = DateTime.tryParse(normalized);
      if (parsed == null) return raw;
      final formatted = DateFormat('dd/MM/yyyy  \"At\" hh:mm a').format(parsed);
      return formatted.replaceAll('AM', 'Am').replaceAll('PM', 'Pm');
    } catch (_) {
      return raw;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// Photo Detail Dialog (Location + Description + navigation)
// ═══════════════════════════════════════════════════════════

class _PhotoDetailDialog extends StatefulWidget {
  final List<_PhotoItem> photoItems;
  final int initialIndex;
  final String reportId;
  final String folderId;

  const _PhotoDetailDialog({
    required this.photoItems,
    required this.initialIndex,
    required this.reportId,
    required this.folderId,
  });

  @override
  State<_PhotoDetailDialog> createState() => _PhotoDetailDialogState();
}

class _PhotoDetailDialogState extends State<_PhotoDetailDialog> {
  late int _currentIndex;
  bool _isPopped = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  _PhotoItem get _current => widget.photoItems[_currentIndex];

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Replace Photo',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF27304E),
                ),
              ),
              SizedBox(height: 20.h),
              ListTile(
                leading:
                    const Icon(Icons.camera_alt, color: Color(0xFF27304E)),
                title: Text('Take Photo',
                    style: GoogleFonts.inter(fontSize: 14.sp)),
                onTap: () {
                  Navigator.pop(ctx);
                  _replaceImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: Color(0xFF27304E)),
                title: Text('Choose from Gallery',
                    style: GoogleFonts.inter(fontSize: 14.sp)),
                onTap: () {
                  Navigator.pop(ctx);
                  _replaceImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _replaceImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: source, imageQuality: 60);
    if (image == null) return;
    final savedPath = await saveImageToAppStorage(
      File(image.path),
      widget.folderId + widget.folderId,
    );
    if (savedPath.isNotEmpty && mounted) {
      setState(() => _current.imagePath = savedPath);
    }
  }

  void _deleteImage() {
    setState(() => _current.imagePath = null);
  }

  Future<void> _drawOnPhoto(_PhotoItem item) async {
    if (item.imagePath == null) return;

    String localPath = item.imagePath!;

    // If it's a network image, download it first
    if (localPath.startsWith('http')) {
      try {
        final response = await http.get(Uri.parse(localPath));
        if (response.statusCode == 200) {
          final dir = await getTemporaryDirectory();
          final file = File(
              '${dir.path}/temp_edit_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await file.writeAsBytes(response.bodyBytes);
          localPath = file.path;
        } else {
          return;
        }
      } catch (_) {
        return;
      }
    }

    if (!mounted) return;
    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => ImageEditingScreen(image: localPath),
      ),
    );
    if (result != null && mounted) {
      final dir = await getTemporaryDirectory();
      final newPath =
          '${dir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(newPath).writeAsBytes(result);
      imageCache.clear();
      imageCache.clearLiveImages();
      setState(() => item.imagePath = newPath);
    }
  }

  void _saveAndClose() {
    if (_isPopped) return;
    _isPopped = true;
    // Sync description and location from every controller before closing.
    for (final item in widget.photoItems) {
      item.description = item.descriptionController.text;
      item.location = item.locationController.text;
    }
    // Pop immediately – saving happens on the parent via showDialog.then().
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final item = _current;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => _saveAndClose(),
                child: Padding(
                  padding: EdgeInsets.only(right: 14.w, top: 14.h),
                  child: Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE81E25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close,
                        color: Colors.white, size: 18.w),
                  ),
                ),
              ),
            ),
            // Action icons — camera above image, draw/delete below
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  _iconBtn(Icons.camera_alt_outlined,
                      () => _showImageSourceDialog()),
                  SizedBox(width: 8.w),
                  _iconBtn(Icons.edit_outlined, () => _drawOnPhoto(item)),
                  SizedBox(width: 8.w),
                  _iconBtn(Icons.delete_outline, _deleteImage,
                      color: const Color(0xFFE81E25)),
                ],
              ),
            ),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    // Image
                    Container(
                      width: double.infinity,
                      height: 200.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: const Color(0xFFE0E0E0), width: 1),
                      ),
                      child: item.imagePath == null
                          ? Center(
                              child: Icon(Icons.photo,
                                  size: 50.w,
                                  color: const Color(0xFFB0B0B0)),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16.r),
                              child: item.imagePath!.startsWith('http')
                                  ? Image.network(item.imagePath!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity)
                                  : Image.file(File(item.imagePath!),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity),
                            ),
                    ),

                    SizedBox(height: 16.h),

                    // Location
                    _buildLocationCard(item),

                    SizedBox(height: 16.h),

                    // Description
                    _buildDescriptionCard(item),

                    SizedBox(height: 20.h),

                    // Navigation arrows
                    if (widget.photoItems.length > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _currentIndex > 0
                                ? () => setState(() => _currentIndex--)
                                : null,
                            icon: Icon(
                              Icons.keyboard_double_arrow_left,
                              size: 28.w,
                              color: _currentIndex > 0
                                  ? const Color(0xFF27304E)
                                  : const Color(0xFFD0D0D0),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Items no ${_currentIndex + 1}/${widget.photoItems.length}',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6A6D78),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          IconButton(
                            onPressed:
                                _currentIndex < widget.photoItems.length - 1
                                    ? () =>
                                        setState(() => _currentIndex++)
                                    : null,
                            icon: Icon(
                              Icons.keyboard_double_arrow_right,
                              size: 28.w,
                              color: _currentIndex <
                                      widget.photoItems.length - 1
                                  ? const Color(0xFF27304E)
                                  : const Color(0xFFD0D0D0),
                            ),
                          ),
                        ],
                      ),

                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap,
      {Color color = const Color(0xFF6A6D78)}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, size: 20.w, color: color),
      ),
    );
  }

  Widget _buildLocationCard(_PhotoItem item) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF272A36),
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            child: TextField(
              controller: item.locationController,
              onChanged: (v) => item.location = v,
              style: GoogleFonts.inter(
                  fontSize: 13.sp, color: const Color(0xFF272A36)),
              decoration: InputDecoration(
                hintText: 'Enter location...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13.sp, color: const Color(0xFFB0B0B0)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(_PhotoItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Description',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF272A36),
                ),
              ),
              Row(
                children: [
                  _fmtBtn(Icons.format_align_center, () {}),
                  SizedBox(width: 6.w),
                  _fmtBtn(Icons.format_list_numbered,
                      () => _formatNumberedList(item)),
                  SizedBox(width: 6.w),
                  _fmtBtn(Icons.format_list_bulleted,
                      () => _formatBulletList(item)),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            child: TextField(
              controller: item.descriptionController,
              maxLines: 4,
              onChanged: (v) {
                item.description = v;
              },
              style: GoogleFonts.inter(
                  fontSize: 13.sp, color: const Color(0xFF272A36)),
              decoration: InputDecoration(
                hintText: 'Enter description...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13.sp, color: const Color(0xFFB0B0B0)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fmtBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        width: 30.w,
        height: 30.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: const Color(0xFFD0D0D0)),
        ),
        child: Icon(icon, size: 17.w, color: const Color(0xFF6A6D78)),
      ),
    );
  }

  void _formatBulletList(_PhotoItem item) {
    final text = item.descriptionController.text;
    if (text.isEmpty) return;
    final lines = text.split('\n');
    final formatted = lines
        .where((l) => l.trim().isNotEmpty)
        .map((l) {
          final t = l.trim();
          if (t.startsWith('• ')) return t;
          if (RegExp(r'^\d+\.\s').hasMatch(t)) {
            return '• ${t.replaceFirst(RegExp(r'^\d+\.\s'), '')}';
          }
          return '• $t';
        })
        .join('\n');
    item.descriptionController.text = formatted;
    item.descriptionController.selection =
        TextSelection.fromPosition(TextPosition(offset: formatted.length));
    item.description = formatted;
  }

  void _formatNumberedList(_PhotoItem item) {
    final text = item.descriptionController.text;
    if (text.isEmpty) return;
    final lines = text.split('\n');
    int n = 1;
    final formatted = lines
        .where((l) => l.trim().isNotEmpty)
        .map((l) {
          final t = l.trim();
          if (t.startsWith('• ')) return '${n++}. ${t.substring(2)}';
          if (RegExp(r'^\d+\.\s').hasMatch(t)) {
            return '${n++}. ${t.replaceFirst(RegExp(r'^\d+\.\s'), '')}';
          }
          return '${n++}. $t';
        })
        .join('\n');
    item.descriptionController.text = formatted;
    item.descriptionController.selection =
        TextSelection.fromPosition(TextPosition(offset: formatted.length));
    item.description = formatted;
  }
}

class _PhotoItem {
  String? itemId;
  String? imagePath;
  String? location;
  String description = '';
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
}
