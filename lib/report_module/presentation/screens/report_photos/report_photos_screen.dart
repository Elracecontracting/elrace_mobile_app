import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';

import 'package:el_race/report_module/data/models/report_model.dart';
import 'package:el_race/report_module/data/models/report_detail_model.dart';
import 'package:el_race/report_module/data/models/report_item_model.dart';
import 'package:el_race/report_module/data/provider/reports_provider.dart';
import 'package:el_race/report_module/data/services/pdf_service.dart';
import 'package:el_race/report_module/presentation/screens/report_detail/image_editing_screen.dart';
import 'package:el_race/report_module/presentation/screens/report_photos/multi_capture_camera_screen.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      final detail = await provider.fetchReportDetailFromApi(widget.report.id);
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
  // Saves order/index changes silently (no loading spinner) — used after reorder
  Future<void> _saveOrderSilently() async {
    if (!mounted) return;
    final provider = Provider.of<ReportProvider>(context, listen: false);
    for (int i = 0; i < _photoItems.length; i++) {
      final item = _photoItems[i];
      if (item.imagePath == null || item.imagePath!.isEmpty) continue;
      if (item.itemId == null) continue;
      try {
        await provider.updateReportItem(
          reportId: widget.report.id,
          itemId: item.itemId!,
          location: item.location ?? '',
          description: item.description,
          imageFile: null,
          index: i,
        );
      } catch (e) {
        debugPrint('📤 Silent reorder save error: $e');
      }
    }
  }

  Future<void> _saveItemsAndReload() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final provider = Provider.of<ReportProvider>(context, listen: false);
    for (int i = 0; i < _photoItems.length; i++) {
      final item = _photoItems[i];
      if (item.imagePath == null || item.imagePath!.isEmpty) continue;
      final isNetwork = item.imagePath!.startsWith('http');
      final hasEdited = item.editedBytes != null;
      debugPrint('📤 Saving item[$i] id=${item.itemId} '
          'loc=${item.location} desc="${item.description}" '
          'isNetwork=$isNetwork hasEdited=$hasEdited '
          'path=${item.imagePath}');
      if (item.itemId != null) {
        try {
          // Determine the image file to upload:
          // - If editedBytes exists, always write fresh file & upload
          // - If local path (not network), upload existing file
          // - If network URL (unchanged), send null (no re-upload needed)
          File? imageFile;
          if (hasEdited) {
            final dir = await getTemporaryDirectory();
            final uploadPath =
                '${dir.path}/upload_${item.itemId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            await File(uploadPath).writeAsBytes(item.editedBytes!);
            imageFile = File(uploadPath);
            debugPrint('📤 Item[$i] uploading edited bytes as $uploadPath');
          } else if (!isNetwork) {
            imageFile = File(item.imagePath!);
            debugPrint('📤 Item[$i] uploading local file ${item.imagePath}');
          }

          final result = await provider.updateReportItem(
            reportId: widget.report.id,
            itemId: item.itemId!,
            location: item.location ?? '',
            description: item.description,
            imageFile: imageFile,
            index: i,
          );
          debugPrint('📤 Item[$i] update result: $result');
          // Update image URL from server response (important for newly uploaded images)
          if (result != null && result.image.isNotEmpty) {
            item.imagePath = result.image;
            item.editedBytes =
                null; // Clear local bytes, server URL is now canonical
            debugPrint('📤 Item[$i] updated imagePath to ${result.image}');
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
      barrierColor: Colors.black45,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SizedBox(
          width: 200.w,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B1F26), Color(0xFF1A1A53)],
                stops: [0.72, 1.0],
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/camera_svgrepo.svg',
                          width: 36.sp,
                          height: 36.sp,
                          colorFilter: const ColorFilter.mode(
                              Colors.white, BlendMode.srcIn),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Camera',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/gallery_svgrepo.svg',
                          width: 36.sp,
                          height: 36.sp,
                          colorFilter: const ColorFilter.mode(
                              Colors.white, BlendMode.srcIn),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Gallery',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      // Open custom multi-capture camera screen
      final List<String>? paths = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => const MultiCaptureCameraScreen(),
        ),
      );
      if (paths == null || paths.isEmpty) return;

      setState(() => _isLoading = true);
      final provider = Provider.of<ReportProvider>(context, listen: false);

      // Save all images to storage in parallel, then upload all in parallel
      final savedPaths = await Future.wait(
        paths.map((path) => saveImageToAppStorage(
              File(path),
              widget.folderId + widget.folderId,
            )),
      );

      await Future.wait(
        savedPaths
            .asMap()
            .entries
            .where((e) => e.value.isNotEmpty)
            .map((e) => provider
                .addReportItem(
                  reportId: widget.report.id,
                  imageFile: File(e.value),
                  location: '',
                  description: '',
                  index: _photoItems.length + e.key,
                )
                .catchError((_) => null)),
      );

      if (mounted) await _loadPhotos();
    } else {
      // Gallery: single pick
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
      );
      if (image == null) return;

      final savedPath = await saveImageToAppStorage(
        File(image.path),
        widget.folderId + widget.folderId,
      );
      if (savedPath.isEmpty) return;

      setState(() => _isLoading = true);
      try {
        final provider = Provider.of<ReportProvider>(context, listen: false);
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
  }

  void _openPdfGenerationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfGenerationPage(
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
        if (_isButtonExpanded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isButtonExpanded = false);
          });
        }
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
              // Header row: "Photos" + button(s)
              Padding(
                padding: EdgeInsets.only(left: 20.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Photos',
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF878B98),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isButtonExpanded)
                          // "+" button
                          GestureDetector(
                            onTap: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted)
                                  setState(() => _isButtonExpanded = true);
                              });
                            },
                            child: Container(
                              width: 44.w,
                              height: 42.h,
                              decoration: BoxDecoration(
                                color: const Color(0xFF27304E),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(14.r),
                                  bottomLeft: Radius.circular(14.r),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(Icons.add,
                                  size: 22.w, color: Colors.white),
                            ),
                          )
                        else
                          // Two action buttons
                          IntrinsicWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF27304E),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(14.r),
                                      bottomLeft: Radius.circular(14.r),
                                    ),
                                  ),
                                  child: _menuButton('Add Photos', () {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (mounted)
                                        setState(
                                            () => _isButtonExpanded = false);
                                      _showImageSourceDialog();
                                    });
                                  }),
                                ),
                                SizedBox(height: 6.h),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF27304E),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(14.r),
                                      bottomLeft: Radius.circular(14.r),
                                    ),
                                  ),
                                  child: _menuButton('Generate Report', () {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (mounted)
                                        setState(
                                            () => _isButtonExpanded = false);
                                      _openPdfGenerationPage();
                                    });
                                  }),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Text(
          label,
          textAlign: TextAlign.right,
          style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
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
    // Filter out items with no image for display, but keep original indices for reorder
    final validIndices = <int>[];
    for (int i = 0; i < _photoItems.length; i++) {
      if (_photoItems[i].imagePath != null &&
          _photoItems[i].imagePath!.isNotEmpty) {
        validIndices.add(i);
      }
    }

    return ReorderableListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      cacheExtent: 2000, // keep off-screen items alive
      proxyDecorator: (child, index, animation) => Material(
        color: Colors.transparent,
        elevation: 0,
        child: child,
      ),
      itemCount: validIndices.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        final orig = validIndices[oldIndex];
        final dest = validIndices[newIndex];
        setState(() {
          final item = _photoItems.removeAt(orig);
          _photoItems.insert(dest, item);
        });
        _saveOrderSilently();
      },
      itemBuilder: (context, listIndex) {
        final index = validIndices[listIndex];
        final item = _photoItems[index];
        final isNetwork = item.imagePath!.startsWith('http');

        return GestureDetector(
          key: ValueKey(item),
          onTap: () => _openPhotoDetailDialog(index),
          child: Container(
            margin: EdgeInsets.only(bottom: 14.h),
            height: 200.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: const Color(0xFF2C3454), width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                item.editedBytes != null
                    ? Image.memory(
                        item.editedBytes!,
                        key: ValueKey(item.editedBytes.hashCode),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, size: 40)),
                      )
                    : isNetwork
                        ? Image.network(
                            item.imagePath!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            cacheWidth: 600,
                            errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, size: 40)),
                          )
                        : Image.file(
                            File(item.imagePath!),
                            key: ValueKey(item.imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, size: 40)),
                          ),
                // Drag handle — top-right corner
                Positioned(
                  top: 6.h,
                  right: 6.w,
                  child: ReorderableDragStartListener(
                    index: listIndex,
                    child: Container(
                      padding: EdgeInsets.all(5.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.menu,
                        size: 20.w,
                        color: const Color(0xFF27304E),
                      ),
                    ),
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

class PdfGenerationPage extends StatefulWidget {
  final String reportId;
  final String folderId;
  final String folderName;
  final int reportItemsCount;

  const PdfGenerationPage({
    super.key,
    required this.reportId,
    required this.folderId,
    required this.folderName,
    required this.reportItemsCount,
  });

  @override
  State<PdfGenerationPage> createState() => _PdfGenerationPageState();
}

class _PdfGenerationPageState extends State<PdfGenerationPage> {
  late TextEditingController _nameController;
  bool _isGenerating = false;
  double _generationProgress = 0;
  String _generationStatus = '';
  bool _isLoadingPdfs = false;
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
    if (mounted) setState(() => _isLoadingPdfs = true);
    try {
      _pdfs = await reportProvider.fetchReports(
        empId: ReportProvider.empID,
        reportId: widget.reportId,
        folderId: widget.folderId,
      );
    } catch (_) {}
    if (mounted) setState(() => _isLoadingPdfs = false);
  }

  Future<void> _generate() async {
    if (_isGenerating) return;
    FocusScope.of(context).unfocus();
    final fileName = _nameController.text.trim();
    if (fileName.isEmpty) return;

    if (_pdfs.length >= 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Maximum 3 PDF files allowed. Please delete one first.')),
        );
      }
      return;
    }

    if (_pdfs.any((p) => p.fileName == '$fileName.pdf')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('A report with the same name already exists.')),
        );
      }
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationProgress = 10;
      _generationStatus = 'Preparing report...';
    });

    try {
      final provider = Provider.of<ReportProvider>(context, listen: false);

      if (mounted) {
        setState(() {
          _generationProgress = 20;
          _generationStatus = 'Loading report data...';
        });
      }

      final detail = await provider.fetchReportDetailFromApi(widget.reportId);
      if (detail == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to load report details.')),
          );
        }
        if (mounted) setState(() => _isGenerating = false);
        return;
      }

      if (mounted) {
        setState(() {
          _generationProgress = 45;
          _generationStatus = 'Generating PDF...';
        });
      }

      final pdfBytes = await PdfService().generateReportPdf(
        report: detail,
        projectName: widget.folderName,
      );

      if (mounted) {
        setState(() {
          _generationProgress = 70;
          _generationStatus = 'Uploading PDF...';
        });
      }

      final uploaded = await reportProvider.uploadReportPdf(
        empId: ReportProvider.empID,
        reportId: widget.reportId,
        folderId: widget.folderId,
        fileName: fileName,
        pdfBytes: pdfBytes,
        onProgress: (uploadProgress) {
          if (!mounted) return;
          final mapped = (70 + (uploadProgress * 30)).clamp(70.0, 100.0);
          setState(() {
            _generationProgress = mapped;
            _generationStatus = 'Uploading PDF...';
          });
        },
      );

      if (uploaded != null) {
        if (mounted) {
          setState(() {
            _generationProgress = 100;
            _generationStatus = 'Completed';
          });
        }
        await _loadPdfHistory();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload PDF report.')),
          );
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generationProgress = 0;
          _generationStatus = '';
        });
      }
    }
  }

  Future<void> _onPdfMoreTap(ReportPdfModel pdf) async {
    // Replaced by PopupMenuButton inline in _buildPdfTile
  }

  Future<void> _renamePdf(ReportPdfModel pdf) async {
    final controller =
        TextEditingController(text: pdf.fileName.replaceAll('.pdf', ''));
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Rename File',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: const Color(0xFF27304E))),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'File name',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Rename')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    // Match by fileId so we always get the latest enriched object (with integer id)
    final idx = _pdfs.indexWhere((p) => p.fileId == pdf.fileId);
    if (idx < 0) return;
    final current = _pdfs[idx]; // may have id populated after enrichment
    // Update on server first
    final success = await reportProvider.renameReportPdf(
      fileId: current.id.isNotEmpty ? current.id : current.fileId,
      newFileName: '$newName.pdf',
    );
    // Always apply locally so rename feels instant;
    // if server fails it will revert on next load
    if (mounted) {
      setState(() {
        _pdfs[idx] = ReportPdfModel(
          fileId: current.fileId,
          id: current.id,
          fileName: '$newName.pdf',
          createdAt: current.createdAt,
          reportLink: current.reportLink,
        );
      });
    }
    if (!success) {
      debugPrint(
          'renameReportPdf: server did not confirm, change is local only');
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
                    style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
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
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: TextField(
                            controller: _nameController,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: const Color(0xFF27304E),
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: '',
                              hintStyle: GoogleFonts.poppins(
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
                                  child: const CircularProgressIndicator(
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
                  if (_isGenerating) ...[
                    SizedBox(height: 10.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: LinearProgressIndicator(
                        value: (_generationProgress.clamp(0, 100)) / 100,
                        minHeight: 6.h,
                        color: const Color(0xFF27304E),
                        backgroundColor: const Color(0xFFD9D9D9),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '${_generationStatus.isEmpty ? 'Processing...' : _generationStatus} ${_generationProgress.round()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6A6D78),
                      ),
                    ),
                  ],
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
                      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 10.h),
                      child: Text(
                        'Recent Files',
                        style: GoogleFonts.poppins(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _isLoadingPdfs
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : _pdfs.isEmpty
                              ? Center(
                                  child: Text(
                                    'No generated PDFs yet',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.sp,
                                      color: Colors.white54,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.w),
                                  itemCount:
                                      _pdfs.length > 3 ? 3 : _pdfs.length,
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
                    maxLines: null,
                    overflow: TextOverflow.visible,
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _formatPdfDate(pdf.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white, size: 22.w),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
              elevation: 4,
              onSelected: (value) async {
                if (value == 'share') {
                  try {
                    final response = await http.get(Uri.parse(pdf.reportLink));
                    if (response.statusCode == 200) {
                      final name =
                          pdf.fileName.isEmpty ? 'report.pdf' : pdf.fileName;
                      final fileName = name.endsWith('.pdf') ? name : '$name.pdf';
                      final dir = await getTemporaryDirectory();
                      final file = File('${dir.path}/$fileName');
                      await file.writeAsBytes(response.bodyBytes);
                      final box = context.findRenderObject() as RenderBox?;
                      await Share.shareXFiles(
                        [XFile(file.path, mimeType: 'application/pdf')],
                        sharePositionOrigin: box != null
                            ? box.localToGlobal(Offset.zero) & box.size
                            : const Rect.fromLTWH(0, 0, 100, 100),
                      );
                    }
                  } catch (e) {
                    debugPrint('Share error: $e');
                  }
                } else if (value == 'rename') {
                  await _renamePdf(pdf);
                } else if (value == 'delete') {
                  final fresh = _pdfs.firstWhere(
                    (p) => p.fileId == pdf.fileId,
                    orElse: () => pdf,
                  );
                  final success = await reportProvider.deleteReportPdf(
                    fileId: fresh.id.isNotEmpty ? fresh.id : fresh.fileId,
                  );
                  if (success && mounted) {
                    setState(
                        () => _pdfs.removeWhere((p) => p.fileId == pdf.fileId));
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined,
                          size: 18.sp, color: const Color(0xFF27304E)),
                      SizedBox(width: 10.w),
                      Text('Share',
                          style: GoogleFonts.poppins(
                              fontSize: 14.sp, color: const Color(0xFF27304E))),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.drive_file_rename_outline,
                          size: 18.sp, color: const Color(0xFF27304E)),
                      SizedBox(width: 10.w),
                      Text('Rename',
                          style: GoogleFonts.poppins(
                              fontSize: 14.sp, color: const Color(0xFF27304E))),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18.sp, color: Colors.red),
                      SizedBox(width: 10.w),
                      Text('Delete',
                          style: GoogleFonts.poppins(
                              fontSize: 14.sp, color: Colors.red)),
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
          style: GoogleFonts.poppins(
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
      // Server stores UTC – interpret as UTC then convert to device local time
      final utc = DateTime.utc(parsed.year, parsed.month, parsed.day,
          parsed.hour, parsed.minute, parsed.second);
      final local = utc.toLocal();
      final formatted = DateFormat('dd/MM/yyyy  \"At\" hh:mm a').format(local);
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
      barrierColor: Colors.black45,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SizedBox(
          width: 200.w,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B1F26), Color(0xFF1A1A53)],
                stops: [0.72, 1.0],
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _replaceImage(ImageSource.camera);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/camera_svgrepo.svg',
                          width: 36.sp,
                          height: 36.sp,
                          colorFilter: const ColorFilter.mode(
                              Colors.white, BlendMode.srcIn),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Camera',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _replaceImage(ImageSource.gallery);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/gallery_svgrepo.svg',
                          width: 36.sp,
                          height: 36.sp,
                          colorFilter: const ColorFilter.mode(
                              Colors.white, BlendMode.srcIn),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Gallery',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
      // evict old image from Flutter's file cache
      await FileImage(File(item.imagePath ?? newPath)).evict();
      setState(() {
        item.editedBytes = result; // show immediately via Image.memory
        item.imagePath = newPath; // used for upload
      });
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
                    child: Icon(Icons.close, color: Colors.white, size: 18.w),
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
                      key: ValueKey(item.imagePath),
                      width: double.infinity,
                      height: 260.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: const Color(0xFFE0E0E0), width: 1),
                      ),
                      child: item.imagePath == null
                          ? Center(
                              child: Icon(Icons.photo,
                                  size: 50.w, color: const Color(0xFFB0B0B0)),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16.r),
                              child: item.editedBytes != null
                                  ? Image.memory(
                                      item.editedBytes!,
                                      key: ValueKey(item.editedBytes.hashCode),
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : item.imagePath!.startsWith('http')
                                      ? Image.network(item.imagePath!,
                                          key: ValueKey(item.imagePath),
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                          height: double.infinity)
                                      : Image.file(File(item.imagePath!),
                                          key: ValueKey(item.imagePath),
                                          fit: BoxFit.contain,
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
                                ? () => WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (mounted)
                                        setState(() => _currentIndex--);
                                    })
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
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6A6D78),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          IconButton(
                            onPressed:
                                _currentIndex < widget.photoItems.length - 1
                                    ? () => WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (mounted)
                                            setState(() => _currentIndex++);
                                        })
                                    : null,
                            icon: Icon(
                              Icons.keyboard_double_arrow_right,
                              size: 28.w,
                              color:
                                  _currentIndex < widget.photoItems.length - 1
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
            style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
                  fontSize: 13.sp, color: const Color(0xFF272A36)),
              decoration: InputDecoration(
                hintText: 'Enter location...',
                hintStyle: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
                  fontSize: 13.sp, color: const Color(0xFF272A36)),
              decoration: InputDecoration(
                hintText: 'Enter description...',
                hintStyle: GoogleFonts.poppins(
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
    final formatted = lines.where((l) => l.trim().isNotEmpty).map((l) {
      final t = l.trim();
      if (t.startsWith('• ')) return t;
      if (RegExp(r'^\d+\.\s').hasMatch(t)) {
        return '• ${t.replaceFirst(RegExp(r'^\d+\.\s'), '')}';
      }
      return '• $t';
    }).join('\n');
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
    final formatted = lines.where((l) => l.trim().isNotEmpty).map((l) {
      final t = l.trim();
      if (t.startsWith('• ')) return '${n++}. ${t.substring(2)}';
      if (RegExp(r'^\d+\.\s').hasMatch(t)) {
        return '${n++}. ${t.replaceFirst(RegExp(r'^\d+\.\s'), '')}';
      }
      return '${n++}. $t';
    }).join('\n');
    item.descriptionController.text = formatted;
    item.descriptionController.selection =
        TextSelection.fromPosition(TextPosition(offset: formatted.length));
    item.description = formatted;
  }
}

class _PhotoItem {
  String? itemId;
  String? imagePath;
  Uint8List? editedBytes; // stored after drawing — bypasses file cache
  String? location;
  String description = '';
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
}
