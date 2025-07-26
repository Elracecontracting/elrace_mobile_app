import 'dart:typed_data';

import 'package:el_race/report_module/core/constants/colors.dart';
import 'package:el_race/report_module/data/repositories/company_repository.dart';
import 'package:el_race/report_module/presentation/widgets/square_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class PdfDisplayScreen extends StatefulWidget {
  final String link;
  const PdfDisplayScreen({super.key, required this.link});

  @override
  State<PdfDisplayScreen> createState() => _PdfDisplayScreenState();
}

class _PdfDisplayScreenState extends State<PdfDisplayScreen> {
  bool loading = true;
  late Uint8List bytes;

  loadFile() async {
    var data = await http.get(Uri.parse(widget.link));
    bytes = data.bodyBytes;
    loading = false;
    setState(() {});
  }

  @override
  void initState() {
    loadFile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.containerColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: CustomColors.white,
        centerTitle: true,
        leadingWidth: 60,
        leading: Align(
          alignment: Alignment.centerRight,
          child: SquareButton(
            icon: Icons.keyboard_backspace,
            color: CustomColors.white,
            borderColor: CustomColors.black,
            onPressed: () async {
              Navigator.pop(context);
            },
          ),
        ),
        title: Image.asset(
          CompanyRepository.company!.logo,
          height: 60,
        ),
        actions: [
          SquareButton(
            icon: Icons.share_outlined,
            color: CustomColors.maroon,
            borderColor: CustomColors.white,
            onPressed: () async {
              await Share.shareXFiles([
                XFile.fromData(bytes,
                    name: "report.pdf", mimeType: "application/pdf")
              ]);
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: loading
          ? const Center(
              child: Text("Loading Pdf Please Wait..."),
            )
          : Column(
              children: [
                const Divider(
                  height: 1,
                ),
                Expanded(
                  child: PDFView(
                    pdfData: bytes,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: false,
                    pageFling: false,
                    backgroundColor: CustomColors.white,
                    onRender: (pages) {},
                    onError: (error) {
                      debugPrint(error.toString());
                    },
                    onPageError: (page, error) {
                      debugPrint('$page: ${error.toString()}');
                    },
                    onViewCreated: (PDFViewController pdfViewController) {
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
