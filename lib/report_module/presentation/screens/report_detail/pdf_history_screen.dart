import 'dart:typed_data';

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
  const PdfCreationScreen({super.key, required this.reportDetailModel});

  @override
  State<PdfCreationScreen> createState() => _PdfCreationScreenState();
}

class _PdfCreationScreenState extends State<PdfCreationScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController subject = TextEditingController();
  TextEditingController projectName = TextEditingController();
  bool _generating = false;

  List<ReportPdfModel> _pdfs = [];

  @override
  void initState() {
    _loadPdfHistory();
    nameController =
        TextEditingController(text: widget.reportDetailModel.report.name);
    subject = TextEditingController(text: "Weekly");
    projectName = TextEditingController();
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
        bottom: getBottomAppBar(context, report: widget.reportDetailModel),
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
              controller: subject,
              inputType: TextInputType.text,
              hintText: "Subject",
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
              onPressed: _generateReport,
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
                                builder: (context) =>
                                    PdfDisplayScreen(link: pdf.reportLink)));
                      },
                      onMoreClicked: () async {
                        int status = await showEditOptions(context,
                            options: ['View', "Share"]);

                        if (status == 0) {
                          if (!context.mounted) return;

                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      PdfDisplayScreen(link: pdf.reportLink)));
                          return;
                        }

                        if (status == 1) {
                          await Share.shareUri(Uri.parse(pdf.reportLink));
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
    // if (_generating) return;
    _generating = true;
    setState(() {});

    if (_pdfs
        .where((p) => p.fileName == ("${nameController.text}.pdf"))
        .isNotEmpty) {
      _generating = false;
      setState(() {});
      showFlushBar(context,
          message:
              "A report with the same name already exists. Please change the name and try again.");
      return;
    }

    Uint8List pdfBytes = await PdfService().generateReportPdf(
      report: widget.reportDetailModel,
      subject: subject.text,
      projectName: widget.reportDetailModel.report.name,
    );

    bool status = await reportProvider.uploadReportPdf(
        empId: ReportProvider.empID,
        reportId: widget.reportDetailModel.report.id,
        folderId: widget.reportDetailModel.report.folderId,
        fileName: nameController.text,
        pdfBytes: pdfBytes);
    if (status) {
      _pdfs = await reportProvider.fetchReports(
          empId: ReportProvider.empID,
          reportId: widget.reportDetailModel.report.id,
          folderId: widget.reportDetailModel.report.folderId);
    }
    _generating = false;
    if (mounted) setState(() {});
  }
}
