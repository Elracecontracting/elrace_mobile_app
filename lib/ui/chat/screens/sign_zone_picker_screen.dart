import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../chat/models/message.dart';

/// Screen for the sender to pick sign zones on a PDF before sending.
/// The user taps on the PDF to place "Sign Here" markers.
/// Returns a list of [SignZone] via Navigator.pop().
class SignZonePickerScreen extends StatefulWidget {
  final File pdfFile;
  final String fileName;

  const SignZonePickerScreen({
    super.key,
    required this.pdfFile,
    required this.fileName,
  });

  @override
  State<SignZonePickerScreen> createState() => _SignZonePickerScreenState();
}

class _SignZonePickerScreenState extends State<SignZonePickerScreen> {
  Uint8List? _pdfBytes;
  bool _loading = true;
  String? _error;
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfController;

  // Sign zones placed by the user
  final List<SignZone> _signZones = [];

  // true = tap to place stamp, false = scroll PDF normally
  bool _isPlaceMode = true;

  // PDF page dimensions (approximated from rendered view)
  Size _viewSize = Size.zero;
  int _pageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final bytes = await widget.pdfFile.readAsBytes();
      // Get page count from PDF
      try {
        final doc = PdfDocument(inputBytes: bytes);
        _pageCount = doc.pages.count;
        doc.dispose();
      } catch (_) {
        _pageCount = 1;
      }
      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading PDF: $e';
          _loading = false;
        });
      }
    }
  }

  void _addSignZone(Offset tapPosition) {
    if (_viewSize == Size.zero) return;

    // Convert tap position to relative coordinates (0..1)
    final relX = (tapPosition.dx / _viewSize.width).clamp(0.0, 1.0);
    final relY = (tapPosition.dy / _viewSize.height).clamp(0.0, 1.0);

    // Center the sign zone on tap point
    const zoneW = 0.30;
    const zoneH = 0.06;
    final x = (relX - zoneW / 2).clamp(0.0, 1.0 - zoneW);
    final y = (relY - zoneH / 2).clamp(0.0, 1.0 - zoneH);

    setState(() {
      _signZones.add(SignZone(
        page: _currentPage,
        x: x,
        y: y,
        width: zoneW,
        height: zoneH,
      ));
    });
  }

  void _removeSignZone(int index) {
    setState(() {
      _signZones.removeAt(index);
    });
  }

  void _confirm() {
    if (_signZones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one sign zone'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.pop(context, {
      'signZones': _signZones,
      'pageCount': _pageCount,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D2449),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Sign Zones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.fileName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check, color: Colors.white),
            label: Text(
              'Send (${_signZones.length})',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Instruction bar — mode-aware
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: _isPlaceMode
              ? const Color(0xFFFFF3CD)
              : const Color(0xFFD1ECF1),
          child: Row(
            children: [
              Icon(
                _isPlaceMode ? Icons.touch_app : Icons.swipe,
                size: 20,
                color: _isPlaceMode
                    ? const Color(0xFF856404)
                    : const Color(0xFF0C5460),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isPlaceMode
                      ? 'Tap to place sign zone'
                      : 'Scroll to browse \u2014 stamps hidden until you switch back',
                  style: TextStyle(
                    fontSize: 13,
                    color: _isPlaceMode
                        ? const Color(0xFF856404)
                        : const Color(0xFF0C5460),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_signZones.where((z) => z.page == _currentPage).isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _signZones.removeWhere((z) => z.page == _currentPage);
                    });
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // PDF viewer with overlay
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _viewSize = Size(constraints.maxWidth, constraints.maxHeight);
              return Stack(
                children: [
                  // Always the same widget tree so PDFView is never
                  // destroyed/recreated (which resets to page 1).
                  // absorbing=true in place-mode blocks native touches.
                  AbsorbPointer(
                    absorbing: _isPlaceMode,
                    child: _buildPdfView(),
                  ),

                  // Tap overlay — always present, ignored in scroll-mode
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !_isPlaceMode,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapUp: (details) =>
                            _addSignZone(details.localPosition),
                      ),
                    ),
                  ),

                  // Sign zone overlays — visible in place-mode,
                  // hidden in scroll-mode (can't track native scroll).
                  if (_isPlaceMode)
                    ...(_buildSignZoneOverlays()),

                  // Floating toggle button
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'mode_toggle',
                      backgroundColor: _isPlaceMode
                          ? const Color(0xFF1D2449)
                          : const Color(0xFFD4A843),
                      onPressed: () {
                        setState(() => _isPlaceMode = !_isPlaceMode);
                      },
                      child: Icon(
                        _isPlaceMode ? Icons.swipe : Icons.touch_app,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Page navigation + zone count
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          color: Colors.white,
          child: Row(
            children: [
              // Previous page button
              IconButton(
                onPressed: _currentPage > 0
                    ? () => _pdfController?.setPage(_currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
                visualDensity: VisualDensity.compact,
              ),
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Next page button
              IconButton(
                onPressed: _currentPage < _totalPages - 1
                    ? () => _pdfController?.setPage(_currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
                visualDensity: VisualDensity.compact,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _signZones.isEmpty
                      ? Colors.grey[200]
                      : const Color(0xFF1D2449),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_signZones.length} sign zone${_signZones.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _signZones.isEmpty ? Colors.grey[600] : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPdfView() {
    // enableSwipe & pageFling are always true — in place-mode
    // AbsorbPointer blocks the touches before they reach here.
    // Keeping these constant prevents native view recreation.
    return PDFView(
      pdfData: _pdfBytes,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      backgroundColor: Colors.grey[200]!,
      onViewCreated: (controller) {
        _pdfController = controller;
      },
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
        });
      },
      onPageChanged: (page, total) {
        setState(() {
          _currentPage = page ?? 0;
          _totalPages = total ?? 0;
        });
      },
    );
  }

  List<Widget> _buildSignZoneOverlays() {
    final zonesOnPage = <int, SignZone>{};
    for (int i = 0; i < _signZones.length; i++) {
      if (_signZones[i].page == _currentPage) {
        zonesOnPage[i] = _signZones[i];
      }
    }

    return zonesOnPage.entries.map((entry) {
      final zone = entry.value;
      final idx = entry.key;

      final left = zone.x * _viewSize.width;
      final top = zone.y * _viewSize.height;
      final width = zone.width * _viewSize.width;
      final height = zone.height * _viewSize.height;

      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: GestureDetector(
          onTap: () => _removeSignZone(idx),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD4A843).withValues(alpha: 0.25),
              border: Border.all(
                color: const Color(0xFFD4A843),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              children: [
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.draw, size: 12, color: Color(0xFF856404)),
                          SizedBox(width: 3),
                          Text(
                            'Sign Here',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF856404),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
