import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/constants/colors.dart';

import '../../../../../data/repositories/company_repository.dart';
import '../../../../widgets/square_button.dart';

class PdfDisplayScreen extends StatefulWidget {
  final String path;
  const PdfDisplayScreen({super.key, required this.path});

  @override
  State<PdfDisplayScreen> createState() => _PdfDisplayScreenState();
}

class _PdfDisplayScreenState extends State<PdfDisplayScreen> {
  bool loading = true;
  late Uint8List bytes;

  loadFile() async {
    bytes = await File(widget.path).readAsBytes();
    await Future.delayed(const Duration(milliseconds: 1000));
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
              await Share.shareXFiles([XFile(widget.path)]);
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
