import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AttachmentViewerScreen extends StatelessWidget {
  const AttachmentViewerScreen({
    super.key,
    required this.publicUrl,
    required this.title,
  });

  final String publicUrl;
  final String title;

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
      body: SfPdfViewer.network(
        publicUrl,
        canShowPaginationDialog: true,
        canShowScrollHead: true,
        canShowScrollStatus: true,
      ),
    );
  }
}
