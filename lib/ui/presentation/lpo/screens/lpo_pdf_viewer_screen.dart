import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

/// Simple PDF viewer for LPO reports - loads PDF from URL and displays in-app.
class LpoPdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String? title;

  const LpoPdfViewerScreen({
    super.key,
    required this.pdfUrl,
    this.title,
  });

  @override
  State<LpoPdfViewerScreen> createState() => _LpoPdfViewerScreenState();
}

class _LpoPdfViewerScreenState extends State<LpoPdfViewerScreen> {
  bool _loading = true;
  String? _error;
  Uint8List? _pdfBytes;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        setState(() {
          _pdfBytes = response.bodyBytes;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load PDF (HTTP ${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading PDF: $e';
        _loading = false;
      });
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    
    final fileName = widget.title?.replaceAll(RegExp(r'[^\w\-]'), '_') ?? 'lpo_report';
    await Share.shareXFiles([
      XFile.fromData(
        _pdfBytes!,
        name: '$fileName.pdf',
        mimeType: 'application/pdf',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFD0D2D8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0E3A76)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title ?? 'LPO Report',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0E3A76),
          ),
        ),
        centerTitle: true,
        actions: [
          if (_pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.share, color: Color(0xFF0E3A76)),
              onPressed: _sharePdf,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF0E3A76),
            ),
            SizedBox(height: 16.h),
            Text(
              'Loading PDF...',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.w,
                color: Colors.red[400],
              ),
              SizedBox(height: 16.h),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadPdf();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E3A76),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfBytes == null) {
      return const Center(child: Text('No PDF data'));
    }

    return Column(
      children: [
        Expanded(
          child: PDFView(
            pdfData: _pdfBytes,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            backgroundColor: Colors.grey[200]!,
            onRender: (pages) {
              setState(() {
                _totalPages = pages ?? 0;
              });
            },
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = (page ?? 0) + 1;
                _totalPages = total ?? 0;
              });
            },
            onError: (error) {
              debugPrint('PDFView error: $error');
            },
            onPageError: (page, error) {
              debugPrint('PDFView page $page error: $error');
            },
          ),
        ),
        if (_totalPages > 0)
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Page $_currentPage of $_totalPages',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
