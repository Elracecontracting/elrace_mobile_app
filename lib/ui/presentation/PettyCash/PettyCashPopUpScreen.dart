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
import 'package:el_race/ui/presentation/Attendace_list/repository/attendance_repository.dart';
import 'package:el_race/utils/color_utils.dart'; // Import global colors
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
        "params": {"last_limit": 6400, "last_limit_date": "2025-04-28"},
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

  void _showAddExpenseDialog() {
    // Dialog state variables
    String description = '';
    DateTime selectedDate = DateTime.now();
    List<dynamic> pettyCashUsers = [];
    List<dynamic> filteredUsers = [];
    String searchQuery = '';
    bool isLoading = false;
    dynamic selectedUser;
    String amount = '';
    String selectedExpenseType = 'EXPENSE TYPE';
    bool dropdownOpen = false;
    final List<String> expenseTypes = ['Petrol ', 'Hospitality ', 'Others'];
    String empID = '';
    final String baseUrl = 'https://test.elrace.com/api/';
    bool isSubmitting = false;

    TextEditingController userController = TextEditingController();
    TextEditingController dateController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> showPettyCashUserDialog() async {
              setDialogState(() {
                isLoading = true;
              });

              try {
                final token = SharedPref.getLoginData().result?.token;
                final headers = {
                  "Content-Type": "application/json",
                  "Accept": "application/json",
                  "Authorization": "Bearer $token",
                };

                final url = Uri.parse(
                    "https://test.elrace.com/api/get_petty_cash_records");
                final body = jsonEncode({"jsonrpc": "2.0", "params": {}});

                final request = http.Request('POST', url)
                  ..headers.addAll(headers)
                  ..body = body;

                final streamedResponse = await request.send();
                final response =
                    await http.Response.fromStream(streamedResponse);

                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  final users = data["result"]["data"];

                  setDialogState(() {
                    pettyCashUsers = users;
                    filteredUsers = users.take(4).toList();
                    isLoading = false;
                  });

                  showDialog(
                    context: context,
                    builder: (BuildContext ctx) {
                      return StatefulBuilder(
                        builder: (context, setUserDialogState) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                      translate(
                                          'pettycash.select_petty_cash_holder'),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  TextField(
                                    onChanged: (value) {
                                      setUserDialogState(() {
                                        searchQuery = value;
                                        filteredUsers = pettyCashUsers
                                            .where((user) => user['name']
                                                .toLowerCase()
                                                .contains(
                                                    searchQuery.toLowerCase()))
                                            .take(4)
                                            .toList();
                                      });
                                    },
                                    decoration: InputDecoration(
                                      prefixIcon:
                                          const Icon(Icons.search, size: 18),
                                      hintText:
                                          translate('pettycash.search_user'),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    height: 200,
                                    child: ListView.separated(
                                      itemCount: filteredUsers.length,
                                      itemBuilder: (_, index) {
                                        final user = filteredUsers[index];
                                        return ListTile(
                                          title: Text(user['name'],
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                          tileColor:
                                              selectedUser?['id'] == user['id']
                                                  ? Colors.blue.shade100
                                                  : Colors.transparent,
                                          onTap: () => setUserDialogState(() {
                                            selectedUser = user;
                                          }),
                                        );
                                      },
                                      separatorBuilder: (_, __) =>
                                          Divider(color: Colors.grey.shade400),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child:
                                            Text(translate('pettycash.cancel')),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: selectedUser != null
                                            ? () {
                                                setDialogState(() {
                                                  userController.text =
                                                      selectedUser['name'];
                                                });
                                                Navigator.pop(ctx);
                                              }
                                            : null,
                                        child: Text(translate('pettycash.ok')),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              } catch (e) {
                setDialogState(() {
                  isLoading = false;
                });
              }
            }

            Future<void> pickDate() async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setDialogState(() {
                  selectedDate = picked;
                  dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                });
              }
            }

            Future<void> submitExpense() async {
              if (empID.isEmpty) {
                empID = (await userRepo.getLoginResponse())!
                    .result!
                    .data!
                    .emp_id
                    .toString();
              }

              if (selectedExpenseType == 'EXPENSE TYPE') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(translate('home.Select_Petty_Cash_Holder'))),
                );
                return;
              }

              if (selectedUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(translate('home.Select_Petty_Cash_Holder'))),
                );
                return;
              }

              if (amountController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(translate('home.Enter_amount_in_AED'))),
                );
                return;
              }

              if (description.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(translate('home.DESCRIPTION'))),
                );
                return;
              }

              setDialogState(() => isSubmitting = true);

              try {
                final token = SharedPref.getLoginData().result?.token;
                final headers = {
                  "Content-Type": "application/json",
                  "Accept": "application/json",
                  "Authorization": "Bearer $token",
                };

                String getExpenseTypeApiValue(String label) {
                  switch (label.toLowerCase()) {
                    case 'fuel':
                      return 'fuel';
                    case 'hospitality':
                      return 'hospitality';
                    case 'site material':
                      return 'site';
                    case 'others':
                      return 'other';
                    default:
                      return 'other';
                  }
                }

                final body = jsonEncode({
                  "jsonrpc": "2.0",
                  "params": {
                    "project_id": null,
                    "employee_id": int.parse(empID),
                    "petty_cash_id": selectedUser['id'],
                    "unit_amount":
                        double.tryParse(amountController.text) ?? 0.0,
                    "name": description,
                    "x_expense_type":
                        getExpenseTypeApiValue(selectedExpenseType),
                    "state": "draft",
                  }
                });

                final response = await http.post(
                  Uri.parse('${baseUrl}create_hr_expense'),
                  headers: headers,
                  body: body,
                );

                final decoded = jsonDecode(response.body);

                if (decoded['result']['status'] == 'success') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(decoded['result']['message'] ??
                            translate('pettycash.request_submitted'))),
                  );
                  Navigator.pop(dialogContext);
                  _fetchDraftSummary(); // Refresh the list
                } else {
                  throw Exception(decoded['result']['message'] ??
                      translate('pettycash.failed_to_submit'));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          "${translate('pettycash.error')}: ${e.toString()}")),
                );
              } finally {
                setDialogState(() => isSubmitting = false);
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title Image
                      Image.asset(
                        'assets/png/add_expense_title.png',
                        width: 240,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),

                      // Expense Type Dropdown (uses OverlayEntry for proper z-order)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Builder(builder: (ctx) {
                          // Overlay state variables inside dialog
                          OverlayEntry? expenseOverlay;
                          final headerKey = GlobalKey();
                          bool overlayVisible = false;

                          OverlayEntry _createOverlay() {
                            final renderBox = headerKey.currentContext!
                                .findRenderObject() as RenderBox;
                            final size = renderBox.size;
                            final offset = renderBox.localToGlobal(Offset.zero);

                            final left = offset.dx +
                                (size.width / 2) -
                                130; // center - half overlay width (260/2)
                            final top = offset.dy + size.height + 8;

                            return OverlayEntry(builder: (context) {
                              return StatefulBuilder(
                                  builder: (context, overlaySetState) {
                                return Positioned(
                                  left: left,
                                  top: top,
                                  width: 260,
                                  child: Material(
                                    color: Colors.white,
                                    elevation: 4,
                                    borderRadius: BorderRadius.circular(22),
                                    child: AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 450),
                                      curve: Curves.easeInOut,
                                      opacity: overlayVisible ? 1.0 : 0.0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.08),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: List.generate(
                                              expenseTypes.length, (i) {
                                            return Column(
                                              children: [
                                                GestureDetector(
                                                  onTap: () async {
                                                    // fade out animation
                                                    overlayVisible = false;
                                                    expenseOverlay
                                                        ?.markNeedsBuild();
                                                    await Future.delayed(
                                                        const Duration(
                                                            milliseconds: 450));
                                                    // update dialog state and remove overlay
                                                    setDialogState(() {
                                                      selectedExpenseType =
                                                          expenseTypes[i];
                                                    });
                                                    expenseOverlay?.remove();
                                                    expenseOverlay = null;
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 14,
                                                        horizontal: 20),
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      expenseTypes[i],
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (i !=
                                                    expenseTypes.length - 1)
                                                  Divider(
                                                      height: 1,
                                                      color:
                                                          Colors.grey.shade300)
                                              ],
                                            );
                                          }),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              });
                            });
                          }

                          return Column(
                            children: [
                              GestureDetector(
                                key: headerKey,
                                onTap: () async {
                                  if (expenseOverlay == null) {
                                    // Create and insert overlay with opacity 0
                                    overlayVisible = false;
                                    expenseOverlay = _createOverlay();
                                    Overlay.of(ctx)!.insert(expenseOverlay!);
                                    // Trigger fade in animation
                                    await Future.delayed(
                                        const Duration(milliseconds: 50));
                                    overlayVisible = true;
                                    expenseOverlay?.markNeedsBuild();
                                  } else {
                                    // Fade out animation before removing
                                    overlayVisible = false;
                                    expenseOverlay?.markNeedsBuild();
                                    await Future.delayed(
                                        const Duration(milliseconds: 450));
                                    expenseOverlay?.remove();
                                    expenseOverlay = null;
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B1464),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          selectedExpenseType,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_drop_down,
                                          color: Colors.white, size: 24),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        }),
                      ),

                      const SizedBox(height: 24),

                      // Date Field
                      InkWell(
                        onTap: pickDate,
                        child: Row(
                          children: [
                            Image.asset('assets/png/calendar_icon.png',
                                width: 40, height: 40),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateController.text.isEmpty
                                        ? DateFormat('dd/MM/yyyy')
                                            .format(selectedDate)
                                        : dateController.text,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Supplier Field
                      InkWell(
                        onTap: showPettyCashUserDialog,
                        child: Row(
                          children: [
                            Image.asset('assets/png/supplier_icon.png',
                                width: 40, height: 40),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Supplier',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userController.text.isEmpty
                                        ? 'Select Supplier'
                                        : userController.text,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Amount Field
                      Row(
                        children: [
                          Image.asset('assets/png/money_icon.png',
                              width: 40, height: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Amount',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: amountController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '0 AED',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Description
                      const Center(
                        child: Text(
                          'DESCRIPTIONS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey
                                        .withAlpha((0.3 * 255).toInt()),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(2, 3),
                                  ),
                                ],
                                image: const DecorationImage(
                                  image: AssetImage('assets/png/desc_box.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: TextField(
                                maxLines: 2,
                                onChanged: (value) =>
                                    setDialogState(() => description = value),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    borderSide: const BorderSide(
                                        color: Colors.grey, width: 0.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    borderSide: const BorderSide(
                                        color: Colors.grey, width: 0.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    borderSide: const BorderSide(
                                        color: Colors.blue, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 18, horizontal: 12),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 6,
                              right: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${description.trim().isEmpty ? 1 : description.trim().split(RegExp(r'\s+')).length}/50',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const Text(
                                    'Max words',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B1464),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: isSubmitting ? null : submitExpense,
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Text(
                                      'Save',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFBA1719),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        iconSize: 34,
                        icon: const Icon(
                          Icons.arrow_back,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'DRAFT',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: appFontColor),
                      ),
                      const SizedBox(width: 40), // Spacer for alignment
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
                                    width: 40, height: 40),
                                Positioned(
                                  top: -10,
                                  left: -3,
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
                    ],
                  ),
                ),

                // if (attachments.isNotEmpty)
                //   Padding(
                //     padding: const EdgeInsets.symmetric(vertical: 16),
                //     child: Center(
                //       child: ElevatedButton(
                //         onPressed: _generateAttachmentPdf,
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: Colors.redAccent,
                //           shape: RoundedRectangleBorder(
                //             borderRadius: BorderRadius.circular(8),
                //           ),
                //           padding: const EdgeInsets.symmetric(
                //               horizontal: 24, vertical: 12),
                //         ),
                //         child: Text(
                //           "Generate Report",
                //           style: const TextStyle(
                //               color: Colors.white,
                //               fontWeight: FontWeight.bold,
                //               fontSize: 16),
                //         ),
                //       ),
                //     ),
                //   ),
                //
                // if (savedPdfs.isNotEmpty)
                //   Padding(
                //     padding: const EdgeInsets.all(16.0),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         const Text(
                //           "Generated Reports",
                //           style: TextStyle(
                //               fontWeight: FontWeight.bold, fontSize: 18),
                //         ),
                //         const SizedBox(height: 10),
                //         ListView.builder(
                //           shrinkWrap: true,
                //           physics: const NeverScrollableScrollPhysics(),
                //           itemCount: savedPdfs.length,
                //           itemBuilder: (context, index) {
                //             final file = savedPdfs[index];
                //             final filename = file.path.split('/').last;
                //             return ListTile(
                //               title: Text(filename),
                //               trailing: const Icon(Icons.picture_as_pdf,
                //                   color: Colors.red),
                //               onTap: () {
                //                 _openPdf(file.path);
                //               },
                //             );
                //           },
                //         ),
                //       ],
                //     ),
                //   ),
                //
                // // Add Expense Button (unchanged)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 26.0, vertical: 20.0),
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
                      _showAddExpenseDialog();
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

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 12.0),
                          child: _buildTransactionItem_2(
                            state is String
                                ? capitalize(state)
                                : state.toString(),
                            date is String ? date : 'Date not available',
                            total != null ? total.toString() : '0',
                          ),
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
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).toInt()),
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 10, 15, 14),
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
                      fontSize: 12,
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
                      fontSize: 12,
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
