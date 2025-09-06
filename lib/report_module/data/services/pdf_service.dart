import 'dart:io';

import 'package:el_race/report_module/data/models/company_model.dart';
import 'package:el_race/report_module/data/models/report_detail_model.dart';
import 'package:el_race/report_module/data/models/report_item_model.dart';
import 'package:el_race/report_module/data/repositories/company_repository.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../ui/presentation/call_screen/data/repository.dart';

class PdfService {
  Future<Uint8List> generateReportPdf({
    required ReportDetailModel report,
    required String projectName,
  }) async {
    final pdf = pw.Document();
    CompanyModel companyData = CompanyRepository.company!;
    LoginResponseModel? userData = (await userRepo.getLoginResponse());

    final imageMap = await loadReportImages(report.reportItems);
    Uint8List logo = await _loadAssetAsBytes(companyData.logo);
    final supportedFont =
        await rootBundle.load("assets/fonts/arbicsupport.ttf");
    final notoSanArabic = pw.Font.ttf(supportedFont);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin:
            const pw.EdgeInsets.only(left: 32, right: 32, bottom: 20, top: 5),
        header: (context) =>
            _buildHeader(context, logo, report, projectName, notoSanArabic),
        footer: (context) => _buildFooter(context),
        build: (context) => _buildBody(
            context, logo, report, imageMap, userData, notoSanArabic),
      ),
    );

    return pdf.save();
  }

  _buildHeader(context, logo, ReportDetailModel report, String projectName,
      pw.Font font) {
    CompanyModel companyData = CompanyRepository.company!;
    bool needToShowCover =
        (context.pageNumber == 1 && report.coverPage != null);
    if (needToShowCover) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Logo centered at the top.

        pw.Container(
          child: pw.Column(children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Image(pw.MemoryImage(logo), height: 50, width: 100),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text(
                    "Report",
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Container(height: 1, color: PdfColors.black),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black),
              ),
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  // if (companyData.employeeName != "")
                  // pw.Expanded(
                  //   child: pw.Column(
                  //       mainAxisAlignment: pw.MainAxisAlignment.start,
                  //       children: [
                  //         pw.Text(
                  //           "Subject:",
                  //           textAlign: pw.TextAlign.center,
                  //           style: pw.TextStyle(
                  //             fontSize: 13,
                  //             font: font,
                  //             fontWeight: pw.FontWeight.bold,
                  //           ),
                  //         ),
                  //         pw.SizedBox(height: 3),
                  //         pw.Text(
                  //           subject,
                  //           textAlign: pw.TextAlign.center,
                  //           textDirection:
                  //               RegExp(r'[\u0600-\u06FF]').hasMatch(subject)
                  //                   ? pw.TextDirection.rtl
                  //                   : pw.TextDirection.ltr,
                  //           style: pw.TextStyle(
                  //             fontSize: 13,
                  //             font: font,
                  //             fontWeight: pw.FontWeight.normal,
                  //           ),
                  //         ),
                  //       ]),
                  // ),
                  // pw.Container(width: 1, color: PdfColors.black, height: 44),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.SizedBox(height: 1),
                          pw.Text(
                            "Project Name",
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 14,
                              // font: font,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          // pw.SizedBox(height: 1),
                          pw.Text(
                            projectName,
                            textAlign: pw.TextAlign.center,
                            textDirection:
                                RegExp(r'[\u0600-\u06FF]').hasMatch(projectName)
                                    ? pw.TextDirection.rtl
                                    : pw.TextDirection.ltr,
                            style: pw.TextStyle(fontSize: 13, font: font),
                          )
                        ]),
                  ),
                  pw.Container(width: 1, color: PdfColors.black, height: 44),
                  pw.Expanded(
                    child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.SizedBox(height: 1),
                          pw.Text(
                            "Date:",
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 14,
                              // font: font,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          // pw.SizedBox(height: 1),
                          pw.Text(
                            " ${DateFormat("dd//MM/yyyy").format(DateTime.now())}",
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 13,
                            ),
                          )
                        ]),
                  ),
                ],
              ),
            ),
          ]),
        ),

        pw.SizedBox(height: 20),
        if (!needToShowCover) _buildTableHeader()
      ],
    );
  }

  Future<Map<String, pw.MemoryImage>> loadReportImages(
      List<ReportItemModel> items) async {
    final Map<String, pw.MemoryImage> imageMap = {};
    for (final item in items) {
      if (item.type == 'image') {
        imageMap[item.image] =
            pw.MemoryImage(await File(item.image).readAsBytes());
      }
    }
    return imageMap;
  }

  _buildBody(pw.Context context, logo, ReportDetailModel reportDetail,
      Map imageMap, LoginResponseModel? userData, pw.Font font) {
    List<pw.Widget> content = [];
    // CompanyModel companyData = CompanyRepository.company!;

    bool needToShowCover = (reportDetail.coverPage != null);

    if (reportDetail.coverPage != null) {
      content.add(pw.SizedBox(
        height: 650,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Image(
                pw.MemoryImage(logo),
                // width: 50,
                height: 150,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Container(
                      // width: 400,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black),
                      ),
                      padding: const pw.EdgeInsets.symmetric(vertical: 5),
                      child: pw.Column(children: [
                        pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Expanded(
                              child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.start,
                                  children: [
                                    pw.SizedBox(width: 12),
                                    pw.Text(
                                      "Employee Name:",
                                      textAlign: pw.TextAlign.center,
                                      style: pw.TextStyle(
                                        fontSize: 15,
                                        font: font,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.Text(
                                      " ${userData?.result?.data?.name}",
                                      textAlign: pw.TextAlign.center,
                                      style: pw.TextStyle(
                                        fontSize: 15,
                                        font: font,
                                      ),
                                    ),
                                  ]),
                            ),
                          ],
                        ),
                        pw.Container(
                            color: PdfColors.black,
                            height: 1,
                            margin: const pw.EdgeInsets.symmetric(vertical: 5)),
                        pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Expanded(
                              child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.start,
                                  children: [
                                    pw.SizedBox(width: 15),
                                    pw.Text(
                                      "Employee ID:",
                                      textAlign: pw.TextAlign.center,
                                      style: pw.TextStyle(
                                        fontSize: 15,
                                        font: font,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.Text(
                                      " ${userData?.result?.data?.uid}",
                                      textAlign: pw.TextAlign.center,
                                      style: pw.TextStyle(
                                        fontSize: 15,
                                        font: font,
                                      ),
                                    ),
                                  ]),
                            ),
                          ],
                        ),
                        pw.Container(
                            color: PdfColors.black,
                            height: 1,
                            margin: const pw.EdgeInsets.symmetric(vertical: 5)),
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            children: [
                              pw.SizedBox(width: 12),
                              pw.Text(
                                "Email:",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 15,
                                  font: font,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                " ${userData?.result?.data?.username}",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 15,
                                  font: font,
                                ),
                              ),
                            ]),
                        pw.Container(
                            color: PdfColors.black,
                            height: 1,
                            margin: const pw.EdgeInsets.symmetric(vertical: 5)),
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            children: [
                              pw.SizedBox(width: 12),
                              pw.Text(
                                "Project Name:",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 15,
                                  font: font,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                " ${reportDetail.report.name}",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 15,
                                  font: font,
                                ),
                              )
                            ]),
                        pw.Container(
                            color: PdfColors.black,
                            height: 1,
                            margin: const pw.EdgeInsets.symmetric(vertical: 5)),
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            children: [
                              pw.SizedBox(width: 12),
                              pw.Text(
                                "Date:",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 15,
                                  font: font,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                " ${DateFormat("dd//MM/yyyy").format(DateTime.now())}",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 15,
                                ),
                              )
                            ]),
                      ])),
                ),
                pw.SizedBox(height: 20),
                if (!needToShowCover) _buildTableHeader()
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(reportDetail.coverPage!.title,
                textDirection: RegExp(r'[\u0600-\u06FF]').hasMatch(
                  reportDetail.coverPage!.title!,
                )
                    ? pw.TextDirection.rtl
                    : pw.TextDirection.ltr,
                style: pw.TextStyle(
                    fontSize: 24, font: font, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            if (reportDetail.coverPage!.description != null)
              pw.Text(reportDetail.coverPage!.description!,
                  textDirection: RegExp(r'[\u0600-\u06FF]').hasMatch(
                    reportDetail.coverPage!.description!,
                  )
                      ? pw.TextDirection.rtl
                      : pw.TextDirection.ltr,
                  style: pw.TextStyle(
                    fontSize: 15,
                    font: font,
                  )),
          ],
        ),
      ));
      // content.add(pw.PageBreak());
    }
    content.add(buildTableBody(reportDetail, imageMap, font));
    return content;
  }

  _buildFooter(context) {
    CompanyModel companyData = CompanyRepository.company!;

    return pw.Container(
        decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(width: 2))),
        padding: const pw.EdgeInsets.only(top: 10, left: 20, right: 20),
        child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${companyData.employeeName}-${companyData.employeeID}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ]));
  }

  Future<Uint8List> _loadAssetAsBytes(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }

  pw.Widget buildTableBody(
      ReportDetailModel reportDetail, Map imageMap, pw.Font font) {
    const double rowHeight = 200;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        for (int i = 0; i < reportDetail.reportItems.length; i++)
          pw.TableRow(
            children: [
              pw.Container(
                height: rowHeight,
                alignment: pw.Alignment.center,
                child: pw.Text("${i + 1}"),
              ),
              pw.Container(
                height: rowHeight,
                alignment: pw.Alignment.center,
                child: (reportDetail.reportItems[i].type != "text")
                    ? pw.Image(imageMap[reportDetail.reportItems[i].image]!)
                    : pw.Text(""),
              ),
              pw.Container(
                height: rowHeight,
                alignment: pw.Alignment.bottomLeft,
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(reportDetail.reportItems[i].location,
                    textDirection: RegExp(r'[\u0600-\u06FF]')
                            .hasMatch(reportDetail.reportItems[i].location)
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                    style: pw.TextStyle(fontSize: 13, font: font)),
              ),
              // Content column with created date, title, and description.
              pw.Container(
                height: rowHeight,
                padding: const pw.EdgeInsets.all(4),
                alignment: pw.Alignment.bottomLeft,
                child: pw.Text(reportDetail.reportItems[i].description,
                    textDirection: RegExp(r'[\u0600-\u06FF]')
                            .hasMatch(reportDetail.reportItems[i].description)
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                    style: pw.TextStyle(fontSize: 13, font: font)),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildTableHeader() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.center,
              child: pw.Text("#",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.center,
              child: pw.Text("Photo",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.center,
              child: pw.Text("Location",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.center,
              child: pw.Text("Description",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}
