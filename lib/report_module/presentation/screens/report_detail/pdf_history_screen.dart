import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:el_race/report_module/core/constants/colors.dart';
import 'package:el_race/report_module/core/constants/text_styles.dart';
import 'package:el_race/report_module/core/utils/flush_bar.dart';
import 'package:el_race/report_module/data/models/report_detail_model.dart';
import 'package:el_race/report_module/data/models/report_pdf_model.dart';
import 'package:el_race/report_module/data/provider/reports_provider.dart';
import 'package:el_race/report_module/data/repositories/company_repository.dart';
import 'package:el_race/report_module/data/services/pdf_service.dart';
import 'package:el_race/report_module/presentation/bottom_sheets/show_option_sheet.dart';
import 'package:el_race/report_module/presentation/screens/report_detail/pdf_preview_screen.dart';
import 'package:el_race/report_module/presentation/widgets/bottom_appbar.dart';
import 'package:el_race/report_module/presentation/widgets/pdf_tile.dart';
import 'package:el_race/report_module/presentation/widgets/square_button.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../widgets/custom_textfield.dart';

class PdfCreationScreen extends StatefulWidget {
  final ReportDetailModel reportDetailModel;
  final String folderName;
  const PdfCreationScreen(
      {super.key, required this.reportDetailModel, required this.folderName});

  @override
  State<PdfCreationScreen> createState() => _PdfCreationScreenState();
}

class _PdfCreationScreenState extends State<PdfCreationScreen> {
  TextEditingController nameController = TextEditingController();
  // TextEditingController subject = TextEditingController();
  TextEditingController projectName = TextEditingController();
  bool _generating = false;
  double _generationProgress = 0;
  String _generationStatus = '';

  List<ReportPdfModel> _pdfs = [];

  @override
  void initState() {
    _loadPdfHistory();
    nameController =
        TextEditingController(text: widget.reportDetailModel.report.name);
    // subject = TextEditingController();
    projectName =
        TextEditingController(text: widget.reportDetailModel.report.name);
    super.initState();
  }

  _loadPdfHistory() async {
    _pdfs = await reportProvider.fetchReports(
        empId: ReportProvider.empID,
        reportId: widget.reportDetailModel.report.id,
        folderId: widget.reportDetailModel.report.folderId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.white,
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
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: Image.asset(
          CompanyRepository.company!.logo,
          height: 60,
        ),
        bottom: getBottomAppBar(context,
            report: widget.reportDetailModel, folderName: widget.folderName),
        actions: const [],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              maxCharacter: 100,
              showLabel: true,
              required: true,
              controller: projectName,
              inputType: TextInputType.text,
              hintText: "Project Name",
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomTextField(
              maxCharacter: 100,
              showLabel: true,
              required: true,
              controller: nameController,
              inputType: TextInputType.text,
              hintText: "Pdf File name",
            ),
          ),
          Center(
            child: MaterialButton(
              onPressed: _generating ? null : _generateReport,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: CustomColors.maroon,
              child: _generating
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: CustomColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Generate Report",
                      style: CustomTextStyle.reportTitle
                          .copyWith(color: CustomColors.white),
                    ),
            ),
          ),
          if (_generating)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: (_generationProgress.clamp(0, 100)) / 100,
                    color: CustomColors.maroon,
                    backgroundColor: Colors.black12,
                    minHeight: 6,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_generationStatus.isEmpty ? 'Processing...' : _generationStatus} ${_generationProgress.round()}%',
                    style: CustomTextStyle.reportTitle,
                  ),
                ],
              ),
            ),
          const Divider(height: 25),
          Expanded(
            child: ListView(
              children: [
                ..._pdfs.map((pdf) => PdfTile(
                      pdf: pdf,
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PdfDisplayScreen(
                                    link: pdf.reportLink,
                                    fileName: pdf.fileName)));
                      },
                      onMoreClicked: () async {
                        int status = await showEditOptions(context,
                            options: ['View', "Share"]);

                        if (status == 0) {
                          if (!context.mounted) return;

                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PdfDisplayScreen(
                                      link: pdf.reportLink,
                                      fileName: pdf.fileName)));
                          return;
                        }

                        if (status == 1) {
                          try {
                            final response =
                                await http.get(Uri.parse(pdf.reportLink));
                            if (response.statusCode == 200) {
                              final name = pdf.fileName.isEmpty
                                  ? 'report.pdf'
                                  : pdf.fileName;
                              await Share.shareXFiles([
                                XFile.fromData(response.bodyBytes,
                                    name: name.endsWith('.pdf')
                                        ? name
                                        : '$name.pdf',
                                    mimeType: 'application/pdf'),
                              ]);
                            }
                          } catch (_) {}
                          return;
                        }
                        if (status == 2) {
                          // await showFileRename(context, pdf: pdf);
                          // await _loadPdfHistory();
                          return;
                        }
                        if (status == 3) {
                          if (!context.mounted) return;
                          int status = await showEditOptions(context,
                              options: ['Confirm Delete', "Cancel"]);
                          if (status == 0) {
                            // await ReportRepository().deletePdf(pdf);
                            // await _loadPdfHistory();
                          }
                          return;
                        }
                      },
                    ))
              ],
            ),
          )
        ],
      ),
    );
  }

  _generateReport() async {
    // Hide keyboard if open
    FocusScope.of(context).unfocus();

    if (_generating) return;

    if (_pdfs
        .where((p) => p.fileName == ("${nameController.text}.pdf"))
        .isNotEmpty) {
      showFlushBar(context,
          message:
              "A report with the same name already exists. Please change the name and try again.");
      return;
    }

    _generating = true;
    _generationProgress = 10;
    _generationStatus = 'Preparing report...';
    if (mounted) setState(() {});

    try {
      _generationProgress = 45;
      _generationStatus = 'Generating PDF...';
      if (mounted) setState(() {});

      Uint8List pdfBytes = await PdfService().generateReportPdf(
        report: widget.reportDetailModel,
        projectName: projectName.text,
      );

      print('file_by: $pdfBytes');

      _generationProgress = 70;
      _generationStatus = 'Uploading PDF...';
      if (mounted) setState(() {});

      bool status = await reportProvider.uploadReportPdf(
        empId: ReportProvider.empID,
        reportId: widget.reportDetailModel.report.id,
        folderId: widget.reportDetailModel.report.folderId,
        fileName: nameController.text,
        pdfBytes: pdfBytes,
        onProgress: (uploadProgress) {
          if (!mounted) return;
          setState(() {
            _generationProgress =
                (70 + (uploadProgress * 30)).clamp(70.0, 100.0);
            _generationStatus = 'Uploading PDF...';
          });
        },
      );

      if (status) {
        _generationProgress = 100;
        _generationStatus = 'Completed';
        if (mounted) setState(() {});

        _pdfs = await reportProvider.fetchReports(
            empId: ReportProvider.empID,
            reportId: widget.reportDetailModel.report.id,
            folderId: widget.reportDetailModel.report.folderId);
      } else {
        showFlushBar(context, message: 'Failed to upload generated report.');
      }
    } finally {
      _generating = false;
      _generationProgress = 0;
      _generationStatus = '';
      if (mounted) setState(() {});
    }
  }
}
