import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AttachmentViewerScreen extends StatelessWidget {
  const AttachmentViewerScreen({
    super.key,
    required this.publicUrl,
    required this.title,
    this.attachmentType,
  });

  final String publicUrl;
  final String title;
  final String? attachmentType;

  bool get _isPdf {
    final type = (attachmentType ?? '').toLowerCase();
    if (type.contains('pdf')) return true;
    return publicUrl.toLowerCase().contains('.pdf');
  }

  bool get _isImage {
    final type = (attachmentType ?? '').toLowerCase();
    if (type.startsWith('image/')) return true;

    final url = publicUrl.toLowerCase();
    return url.contains('.jpg') ||
        url.contains('.jpeg') ||
        url.contains('.png') ||
        url.contains('.webp') ||
        url.contains('.gif') ||
        url.contains('.bmp');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          title.isEmpty ? 'Attachment' : title,
          maxLines: null,
          overflow: TextOverflow.visible,
        ),
      ),
      body: _isPdf
          ? SfPdfViewer.network(
              publicUrl,
              canShowPaginationDialog: true,
              canShowScrollHead: true,
              canShowScrollStatus: true,
            )
          : _isImage
              ? InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      publicUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text('Failed to load image attachment'),
                      ),
                    ),
                  ),
                )
              : const Center(
                  child: Text('Unsupported attachment type'),
                ),
    );
  }
}
