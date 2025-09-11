import 'dart:convert';
import 'dart:io';

import 'package:el_race/core/utils/directory_operation.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/data/models/report_detail_item.dart';
import 'package:el_race/data/models/report_detail_model.dart';
import 'package:el_race/data/models/report_model.dart';
import 'package:el_race/data/repositories/company_repository.dart';
import 'package:el_race/data/repositories/report_repository.dart';
import 'package:el_race/data/services/pdf_service.dart';
import 'package:el_race/ui/presentation/My_task/screens/report_detail/camera_screen.dart';
import 'package:el_race/ui/presentation/My_task/screens/report_detail/pdf_preview_screen.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashAddExpense.dart'; // Import the login model
import 'package:el_race/utils/color_utils.dart'; // Import global colors
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../widgets/custom_slider_button.dart';
import '../../widgets/header_widget.dart';

class PettyCashPopUpScreen extends StatefulWidget {
  const PettyCashPopUpScreen({super.key});

  @override
  _PettyCashPopUpScreenState createState() => _PettyCashPopUpScreenState();
}

class _PettyCashPopUpScreenState extends State<PettyCashPopUpScreen> {
  bool isLoading = true;
  String error = '';
  List<dynamic> expenseSheets = [];
  double balance = 0;
  ReportModel? pettyCashReport;
  double draftAmount = 0;
  final ScrollController _scrollController = ScrollController();
  int fetchLimit = 15;
  int currentOffset = 0;
  bool isFetchingMore = false;
  bool hasMore = true;
  final GlobalKey<CustomSliderButtonState> _sliderKey = GlobalKey();
  bool isExpenseLoading = true;
  bool isDraftLoading = true;
  List<File> attachments = [];
  List<File> savedPdfs = [];
  List<int> draftExpenseIds = [];

  Future<void> _addCameraImageForAttachment() async {
    var result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const CustomCameraScreen(
                  onePicture: false,
                )));

    if (result != null && result is List<XFile> && result.isNotEmpty) {
      for (var image in result) {
        attachments.add(File(image.path));
      }
      setState(() {}); // Refresh the UI
    }
  }

  @override
  void initState() {
    super.initState();

    // Step 1: Fetch the Draft & Balance immediately
    _fetchDraftSummary();
  }

  void _showErrorDialog(String message) {
    _sliderKey.currentState?.resetSlider(); // ⬅️ Reset on catch
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(translate('pettycash.error')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(translate('pettycash.ok')),
          ),
        ],
      ),
    );
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _fetchDraftSummary() async {
    if (!mounted) return;

    // setState(() {
    //   isDraftLoading = true;
    // });

    try {
      final token = SharedPref.getLoginData().result?.token;

      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token", // ✅ Use dynamic token
      };

      final url = Uri.parse("https://test.elrace.com/api/draft_summary");
      final body = jsonEncode({
        "jsonrpc": "2.0",
        "params": {},
      });

      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("Draft summary response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result']?['data'];

        if (result == null) {
          throw Exception("Invalid data in response.");
        }

        final newItems = result['draft_expenses'] ?? [];
        expenseSheets.clear();
        draftExpenseIds.clear();
        setState(() {
          balance = (result['total_balance'] ?? 0).toDouble();
          draftAmount = (result['total_draft_amount'] ?? 0).toDouble();
          expenseSheets.addAll(newItems);
          isDraftLoading = false;
          draftExpenseIds =
              newItems.map<int>((item) => item['id'] as int).toList();
        });
      } else {
        throw Exception(
            "Failed to fetch draft summary: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching draft summary: $e");
      if (!mounted) return;
      setState(() {
        isDraftLoading = false;
      });
    }
  }

  Future<void> _submitExpense() async {
    try {
      final token = SharedPref.getLoginData().result?.token;

      print("_submitExpense");

      if (token == null) {
        _showErrorDialog(translate('pettycash.failed_to_submit'));
        _sliderKey.currentState
            ?.resetSlider(); // ⬅️ Reset on validation failure
        return;
      }

      if (attachments.isEmpty) {
        _showErrorDialog(translate('pettycash.please_add_images'));
        _sliderKey.currentState
            ?.resetSlider(); // ⬅️ Reset on validation failure
        return;
      }

      if (draftExpenseIds.isEmpty) {
        _showErrorDialog(translate('pettycash.failed_to_submit'));
        _sliderKey.currentState
            ?.resetSlider(); // ⬅️ Reset on validation failure
        return;
      }

      // Ensure company info is loaded
      if (CompanyRepository.company == null) {
        CompanyRepository.company = await CompanyRepository().getCompany();
      }

      final logoPath = CompanyRepository.company?.logo ?? '';
      try {
        await rootBundle.load(logoPath);
      } catch (_) {
        _showErrorDialog(
            "${translate('pettycash.error')}: Company logo asset not found: $logoPath");
        _sliderKey.currentState?.resetSlider(); // ⬅️ Reset on error
        return;
      }

      // Validate actual files
      final validAttachments = attachments.where((file) {
        return file.path.isNotEmpty && File(file.path).existsSync();
      }).toList();

      if (validAttachments.isEmpty) {
        _showErrorDialog("No valid attachment files found.");
        _sliderKey.currentState
            ?.resetSlider(); // ⬅️ Reset on validation failure
        return;
      }

      // Prepare report and details
      pettyCashReport ??= ReportModel(
        id: const Uuid().v4(),
        name: "PettyCashReport_${DateTime.now().millisecondsSinceEpoch}",
        description: "",
        companyID: "",
        report: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final reportItems = validAttachments.map((file) {
        return ReportDetailItem(
          id: const Uuid().v4(),
          title: "Attachment",
          description: "Petty cash attachment",
          image: file.path,
          type: "image",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now().toIso8601String(),
          sectionName: "PettyCash",
        );
      }).toList();

      final detailModel = ReportDetailModel(
        id: const Uuid().v4(),
        items: reportItems,
        sections: ["PettyCash"],
        coverPage: null,
      );

      print("Generating PDF with ${reportItems.length} items...");

      // Generate PDF
      Uint8List pdfBytes;
      try {
        pdfBytes = await PdfService().generateReportPdf(
          report: pettyCashReport!,
          reportDetail: detailModel,
          subject: "Petty Cash Attachments",
          projectName: pettyCashReport!.name,
        );
      } catch (e) {
        print("PDF generation failed: $e");
        _showErrorDialog(translate('pettycash.failed_to_generate_pdf',
            args: {'error': e.toString()}));
        _sliderKey.currentState?.resetSlider(); // ⬅️ Reset on error
        return;
      }

      final base64Pdf = base64Encode(pdfBytes);

      final body = jsonEncode({
        "jsonrpc": "2.0",
        "params": {
          "expense_line_ids": draftExpenseIds,
          "attachment_data": base64Pdf,
        },
      });

      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Call API
      final response = await http.post(
        Uri.parse("https://test.elrace.com/api/submit_expense"),
        headers: headers,
        body: body,
      );

      Navigator.pop(context); // ⬅️ Dismiss loading dialog

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 &&
          data["result"]?['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate('pettycash.request_submitted'))),
        );
        Navigator.pop(context, true); // ✅ Back with success
      } else {
        final message = data['result']?['message'] ??
            translate('pettycash.failed_to_submit');
        _sliderKey.currentState?.resetSlider(); // ⬅️ Reset on error
        _showErrorDialog(message);
      }
    } catch (e) {
      Navigator.pop(context); // Ensure dialog closes
      print("Submit error: $e");
      _sliderKey.currentState?.resetSlider(); // ⬅️ Reset on catch
      _showErrorDialog(translate('request.error_occurred'));
    }
  }

  Future<void> _generateAttachmentPdf() async {
    if (attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add images first!')),
      );
      return;
    }

    // ✅ Ensure company data is initialized
    if (CompanyRepository.company == null) {
      try {
        CompanyRepository.company = await CompanyRepository().getCompany();
      } catch (e) {
        print("Failed to load company: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load company information.')),
        );
        return;
      }
    }

    pettyCashReport = ReportModel(
      id: const Uuid().v4(),
      name: "PettyCashReport",
      description: "",
      companyID: "",
      report: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    List<ReportDetailItem> reportItems = attachments.map((file) {
      return ReportDetailItem(
        id: const Uuid().v4(),
        title: "Attachment",
        description: "Petty cash attachment",
        image: file.path,
        type: "image",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now().toIso8601String(),
        sectionName: "PettyCash",
      );
    }).toList();

    ReportDetailModel dummyDetailModel = ReportDetailModel(
      id: const Uuid().v4(),
      items: reportItems,
      sections: ["PettyCash"],
      coverPage: null,
    );

    try {
      Uint8List pdfBytes = await PdfService().generateReportPdf(
        report: pettyCashReport!,
        reportDetail: dummyDetailModel,
        subject: "Petty Cash Attachments",
        projectName: pettyCashReport!.name,
      );

      String fileName =
          "PettyCashReport_${DateTime.now().millisecondsSinceEpoch}";

      final directory = await getAppDirectory();
      final folder = Directory("${directory.path}/PettyCashReports");

      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final file = File("${folder.path}/$fileName.pdf");
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated and opened!')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfDisplayScreen(path: file.path),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    }
  }

  Future<void> _loadSavedPdfs() async {
    if (pettyCashReport == null) return;

    List pdfModels = await ReportRepository().getReportPdfs(pettyCashReport!);
    pdfModels.sort((a, b) => b.date.compareTo(a.date));

    savedPdfs = pdfModels.map((pdfModel) => File(pdfModel.path)).toList();
    setState(() {});
  }

  void _openPdf(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfDisplayScreen(path: path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchDraftSummary();
        await _loadSavedPdfs();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const HeaderWidget(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section (unchanged)

                const SizedBox(height: 10),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BackButton(),
                      Text(
                        'ADD EXPENSE',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: appFontColor),
                      ),
                      SizedBox(width: 40), // Spacer for alignment
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Draft Section (unchanged)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: -18,
                            right: -90,
                            child: _buildDraftInfo(
                              "DRAFT",
                              draftAmount.toStringAsFixed(0),
                              'assets/png/draft_bg_1.png',
                              'assets/png/draft_icon.png',
                              appFontColor,
                            ),
                          ),
                          _buildDraftInfo(
                            "BALANCE",
                            balance.toStringAsFixed(0),
                            'assets/png/balance_bg.png',
                            'assets/png/balance_icon.png',
                            Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Attachment Section (unchanged)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _addCameraImageForAttachment,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Image.asset('assets/png/document_icon.png',
                                    width: 30, height: 30),
                                Positioned(
                                  top: -3,
                                  right: -3,
                                  child: CircleAvatar(
                                    radius: 8,
                                    backgroundColor: Colors.red,
                                    child: Text(
                                      attachments.length.toString(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 5),
                            Image.asset('assets/png/Attached_icon.png',
                                width: 25, height: 25),
                            const SizedBox(width: 8),
                            const Text(
                              "Attachment",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: appFontColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap:
                            _generateAttachmentPdf, // when clicking on pdf icon
                        child: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                if (attachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _generateAttachmentPdf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          "Generate Report",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ),

                if (savedPdfs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Generated Reports",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: savedPdfs.length,
                          itemBuilder: (context, index) {
                            final file = savedPdfs[index];
                            final filename = file.path.split('/').last;
                            return ListTile(
                              title: Text(filename),
                              trailing: const Icon(Icons.picture_as_pdf,
                                  color: Colors.red),
                              onTap: () {
                                _openPdf(file.path);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                // Add Expense Button (unchanged)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 26.0, vertical: 10.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PettyCashAddExpense()),
                      );
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage('assets/png/bg_petty.png'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/png/plus_icon_1.png',
                                width: 20, height: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "ADD EXPENSE",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: appFontColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Transaction List with Dynamic Data
                Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      controller: _scrollController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: expenseSheets.length,
                      itemBuilder: (context, index) {
                        var expense = expenseSheets[index];
                        const state = "DRAFT";
                        final date = expense['date'];
                        final total = expense['amount'];
                        final id = expense['id'];

                        return _buildTransactionItem_2(
                          state is String
                              ? capitalize(state)
                              : state.toString(),
                          date is String ? date : 'Date not available',
                          total != null ? total.toString() : '0',
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Notice Section (unchanged)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/png/notice_icon.png',
                        width: 34,
                        height: 34,
                      ),
                      const SizedBox(width: 5),
                      const Expanded(
                        child: Text(
                          'Please be aware that No of attachments & draft invoices should be the same.',
                          style: TextStyle(
                            color: appFontColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Slider Button (unchanged)
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CustomSliderButton(
                      key: _sliderKey, // ✅ <-- this is critical
                      onSlideComplete: _submitExpense,
                      loginResponseModel: SharedPref.getLoginData(),
                    )),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable widget for transaction items
  Widget _buildTransactionItem_2(String status, String date, String amount) {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/png/item_bg_yellow.png'),
          fit: BoxFit.cover,
        ),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).toInt()),
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 8, 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: appFontColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 5),
            const SizedBox(
              height: 30,
              child: VerticalDivider(
                color: Colors.grey,
                thickness: 2,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: appFontColor,
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 30,
              child: VerticalDivider(
                color: Colors.grey,
                thickness: 2,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: appFontColor,
                    ),
                  ),
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 0),
            const CircleAvatar(
              radius: 10,
              backgroundImage: AssetImage('assets/png/tick-petty.png'),
            ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftInfo(String label, String amount, String bgImage,
      String iconImage, Color textColor) {
    return Container(
      width: 120, // Ensures uniform circle size
      height: 120,
      margin: const EdgeInsets.fromLTRB(0, 0, 70, 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(bgImage), // Background image for the circle
          fit: BoxFit.cover, // Ensures the image covers the circle
        ),
        boxShadow: const [
          const BoxShadow(color: Colors.black26, blurRadius: 5)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Centers content
        children: [
          Image.asset(iconImage,
              width: 25, height: 25), // Image instead of icon
          const SizedBox(height: 3), // Adjusts spacing
          Text(label,
              style: TextStyle(
                  color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(amount,
              style: TextStyle(
                  color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
