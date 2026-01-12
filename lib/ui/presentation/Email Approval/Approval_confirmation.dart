import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/resources/app_colors.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/approval_card_type_two.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/file_binary.dart';
import 'package:el_race/utils/Util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:el_race/utils/color_utils.dart';
import 'package:dio/dio.dart';
import 'widgets/approval_action_buttons.dart';

class ApprovalConfirmationScreen extends StatefulWidget {
  final String requestId;
  final String type;

  const ApprovalConfirmationScreen({
    super.key,
    required this.requestId,
    required this.type,
  });

  @override
  State<ApprovalConfirmationScreen> createState() =>
      _ApprovalConfirmationScreenState();
}

class _ApprovalConfirmationScreenState
    extends State<ApprovalConfirmationScreen> {
  bool isLoading = true;
  String error = '';
  final int _currentPage = 0;
  late PageController _pageController;
  Map<String, dynamic>? formData;
  List<dynamic> tableView = [];
  List<dynamic> attachmentIds = [];
  List<dynamic> approvals = [];

  bool get isCurrentUserInApprovals {
    final userId = SharedPref.getLoginData().result?.data?.uid;
    if (userId == null) return false;
    return approvals.any((a) => a['id'] == userId);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchRequestDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequestDetails() async {
    final token = SharedPref.getLoginData().result?.token;
    final userId = SharedPref.getLoginData().result?.data?.uid;
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
    String getApiUrl(String type) {
      switch (type.toUpperCase()) {
        case 'HR':
          return "https://erp.elrace.com/api/get_hr_request_details";
        case 'RFQ':
          return "https://erp.elrace.com/api/get_rfq_details";
        case 'INVOICE':
          return "https://erp.elrace.com/api/get_invoice_details";
        case 'PETTYCASH':
          return "https://erp.elrace.com/api/get_petty_cash_details";
        default:
          throw Exception("Invalid request type: ${widget.type}");
      }
    }

    String getParamKey(String type) {
      switch (type.toUpperCase()) {
        case 'HR':
          return "request_id";
        case 'RFQ':
          return "rfq_id";
        case 'INVOICE':
          return "invoice_id";
        case 'PETTYCASH':
          return "petty_cash_id";
        default:
          throw Exception("Invalid request type: ${widget.type}");
      }
    }

    final url = Uri.parse(getApiUrl(widget.type));
    final paramKey = getParamKey(widget.type);
    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        paramKey: int.tryParse(widget.requestId),
      },
    });
    final request = http.Request('GET', url)
      ..headers.addAll(headers)
      ..body = body;
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Print full response
      debugPrint("=========== FULL API RESPONSE START ===========");
      debugPrint(response.body);
      debugPrint("=========== FULL API RESPONSE END ===========");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result']['data'];

        // Print result structure
        debugPrint('=========== RESULT DATA START ===========');
        debugPrint('Result Keys: ${result?.keys?.toList()}');
        debugPrint('Result Data: $result');
        debugPrint('=========== RESULT DATA END ===========');

        setState(() {
          formData = result['form_view'] ?? {};
          approvals = result['approvals'] ?? [];
          tableView = result['table_view'] ?? [];
          attachmentIds = result['attachment_ids'] ?? [];
        });

        // Print formData to see available fields
        debugPrint('=========== FORM DATA START ===========');
        debugPrint('🔍 Form Data Keys: ${formData?.keys.toList()}');
        debugPrint('🔍 Full Form Data: $formData');
        debugPrint('📱 Mobile Phone: ${formData?["mobile_phone"]}');
        debugPrint('📱 Mobile: ${formData?["mobile"]}');
        debugPrint('📱 Phone: ${formData?["phone"]}');
        debugPrint('📧 Work Email: ${formData?["work_email"]}');
        debugPrint('📧 Email: ${formData?["email"]}');
        debugPrint('=========== FORM DATA END ===========');

        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception(
            "Failed to load request details: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  List<Map<String, String>> get projects {
    return tableView
        .map<Map<String, String>>((item) => {
              "product": item["product"]?.toString() ?? "",
              "qty": item["qty"]?.toString() ?? "",
              "uom": item["uom"]?.toString() ?? "",
              "unit_price": item["unit_price"]?.toString() ?? "",
              "total": item["total"]?.toString() ?? "",
            })
        .toList();
  }

  void _showEmployeeDetailsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Employee Details',
                      style: GoogleFonts.koulen(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                isLoading
                    ? Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      )
                    : (formData?["image_emp"] != null &&
                            formData?["image_emp"] is String &&
                            (formData?["image_emp"] as String).isNotEmpty &&
                            (formData?["image_emp"] as String).toLowerCase() !=
                                "false")
                        ? CircleAvatar(
                            radius: 28,
                            backgroundImage: MemoryImage(
                                base64Decode(formData!["image_emp"] as String)),
                          )
                        : const SizedBox(width: 56, height: 56),
                const SizedBox(height: 8),
                Center(
                  child: Text(formData?["employee_name"] ?? "",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Center(
                  child: Text(formData?["emp_code"]?.toString() ?? "",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 12),
                _buildIconText(Icons.work_outline,
                    formData?["job_id"] ?? formData?["job_title"]),
                _buildIconText(Icons.phone_android, formData?["phone"]),
                _buildIconText(Icons.business,
                    formData?["department_id"] ?? formData?["department"]),
                _buildIconText(Icons.email, formData?["email"]),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  ScrollController scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: EdgeInsets.all(10.w),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 10),
                if (widget.type.toUpperCase() == 'HR') ...[
                  InkWell(
                    onTap: _showEmployeeDetailsDialog,
                    child: Container(
                        width: 280.w,
                        padding: EdgeInsets.symmetric(
                            horizontal: 13.w, vertical: 5.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD6D6D6), Color(0xFFADB2BD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            isLoading
                                ? Container(
                                    width: 50.w,
                                    height: 50.w,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : (formData?["image_emp"] != null &&
                                        formData?["image_emp"] is String &&
                                        (formData?["image_emp"] as String)
                                            .isNotEmpty &&
                                        (formData?["image_emp"] as String)
                                                .toLowerCase() !=
                                            "false")
                                    ? CircleAvatar(
                                        radius: 25.w,
                                        backgroundImage: MemoryImage(
                                            base64Decode(formData!["image_emp"]
                                                as String)),
                                      )
                                    : SizedBox(width: 50.w, height: 50.w),
                            const SizedBox(width: 8),
                            Text(
                              'Employee Details',
                              style: GoogleFonts.koulen(
                                fontSize: 19.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Image.asset(
                              'assets/png/tap.png',
                              width: 40.w,
                              height: 40.w,
                            ),
                          ],
                        )),
                  ),
                ] else ...[
                  const SizedBox.shrink(),
                ],
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: EdgeInsets.only(
                        bottom: widget.type.toUpperCase() == 'HR' ? 60.w : 0),
                    padding: EdgeInsets.all(3.w),
                    decoration: const BoxDecoration(
                      color: red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
            Text(
              'Request Details',
              style: GoogleFonts.koulen(
                fontSize: 23.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: greyText),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  if (widget.type.toUpperCase() == 'HR') ...[
                                    _buildDetailRow("REQ NO",
                                        formData?["request_no"] ?? ""),
                                    _buildDetailRow("REQ TYPE",
                                        formData?["request_type"] ?? ""),
                                    _buildDetailRow("STATUS",
                                        formData?["status"]?.toString() ?? ""),
                                    _buildDetailRow("REQ DATE",
                                        formData?["request_date"] ?? ""),
                                    _buildDetailRow(
                                        "START DATE",
                                        formData?["start_date"]?.toString() ??
                                            ""),
                                    _buildDetailRow(
                                        "DURATION",
                                        formData?["duration"]?.toString() ??
                                            ""),
                                    _buildDetailRow(
                                        "BALANCE LEAVE",
                                        formData?["balance_leave"]
                                                ?.toString() ??
                                            ""),
                                  ],
                                  if (widget.type.toUpperCase() == 'RFQ') ...[
                                    _buildDetailRow("Request Type",
                                        formData?["request_type"] ?? "RFQ"),
                                    _buildDetailRow(
                                        "Ref No", formData?["title"] ?? ""),
                                    _buildDetailRow(
                                        "Vendor", formData?["vendor"] ?? ""),
                                    // _buildDetailRow("Client", formData?["client"] ?? ""),
                                    // _buildDetailRow("WO", formData?["wo"] ?? ""),
                                    _buildDetailRow("Material Type",
                                        formData?["material_type"] ?? ""),
                                    _buildDetailRow(
                                        "Total Amount",
                                        formData?["amount_total"] != null
                                            ? double.parse(
                                                    formData!["amount_total"]
                                                        .toString())
                                                .toStringAsFixed(2)
                                            : "0.00"),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (widget.type.toUpperCase() != 'HR') ...[
                              Column(
                                children: [
                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.center,
                                  //   children: [
                                  //     IconButton(
                                  //       icon: const Icon(Icons.arrow_back_ios, size: 16),
                                  //       onPressed: () {
                                  //         if (_currentPage > 0) {
                                  //           _pageController.previousPage(
                                  //             duration: const Duration(milliseconds: 300),
                                  //             curve: Curves.easeInOut,
                                  //           );
                                  //         }
                                  //       },
                                  //     ),
                                  //     Text(
                                  //       "${_currentPage + 1}/${projects.length}",
                                  //       style: const TextStyle(fontWeight: FontWeight.bold),
                                  //     ),
                                  //     IconButton(
                                  //       icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                  //       onPressed: () {
                                  //         if (_currentPage < projects.length - 1) {
                                  //           _pageController.nextPage(
                                  //             duration: const Duration(milliseconds: 300),
                                  //             curve: Curves.easeInOut,
                                  //           );
                                  //         }
                                  //       },
                                  //     ),
                                  //   ],
                                  // ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: greyText),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    height: projects.length > 3 ? 200.w : 150.w,
                                    child: Scrollbar(
                                      controller: scrollController,
                                      thumbVisibility: true,
                                      trackVisibility: true,
                                      interactive: true,
                                      child: ListView.builder(
                                        controller: scrollController,
                                        itemCount: projects.length,
                                        itemBuilder: (context, index) {
                                          final item = projects[index];
                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 5),
                                            padding: EdgeInsets.all(5.w),
                                            decoration: BoxDecoration(
                                              color: AppColors.separatorColor,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                InfoContainer(
                                                  text: "13/08/2025",
                                                  fontSize: 9.sp,
                                                  width: 75.w,
                                                  icon: Icon(Icons.date_range,
                                                      size: 14.w,
                                                      color: const Color(
                                                          0xFF1A1A53)),
                                                ),
                                                SizedBox(
                                                  width: 65.w,
                                                  child: Text(
                                                    "${item["product"]}",
                                                    style: GoogleFonts.koulen(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      letterSpacing: 1.0,
                                                      fontSize: 12.sp,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                  ),
                                                ),
                                                InfoContainer(
                                                  text: "${item["total"]} AED",
                                                  width: 90.w,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (attachmentIds.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('No attachment found.')),
                                    );
                                    return;
                                  }
                                  await _viewAttachement();
                                },
                                icon: Image.asset(
                                  'assets/png/attachment.png',
                                  width: 20.w,
                                  height: 20.w,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  "VIEW ATTACHMENT",
                                  style: GoogleFonts.koulen(
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A1A53),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  onTap: () {},
                                  child: AbsorbPointer(
                                    absorbing: isCurrentUserInApprovals,
                                    child: ApprovalActionButtons(
                                      requestId: widget.requestId,
                                      type: widget.type,
                                      onResult: (result) {
                                        _fetchRequestDetails();
                                      },
                                      disabled: isCurrentUserInApprovals,
                                      userIds: approvals
                                          .map((a) => a['id'].toString())
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          children: [
            Text(
              "●",
              style: GoogleFonts.koulen(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.koulen(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Container(
                width: 150.w,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.w),
                decoration: BoxDecoration(
                  color: AppColors.separatorColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  value,
                  style: GoogleFonts.koulen(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          ],
        ));
  }

  Widget _buildStatusBar() {
    if (approvals.isEmpty) {
      return const SizedBox();
    }

    final approvedCount =
        approvals.where((a) => a['validation_status'] == true).length;
    final totalCount = approvals.length;
    final progress = approvedCount / totalCount;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey.shade300,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
        minHeight: 8,
      ),
    );
  }

  Widget _buildApproverRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: approvals.map((approver) {
        final approved = approver['validation_status'] == true;

        return Column(
          children: [
            Icon(
              approved ? Icons.check_circle : Icons.cancel,
              color: approved ? Colors.green : Colors.red,
              size: 18,
            ),
            const SizedBox(height: 4),
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/png/profile_1.png'),
            ),
            SizedBox(
              width: 40.w,
              child: Text(
                approver['name'] ?? '',
                style: TextStyle(fontSize: 10.sp),
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        );
      }).toList(),
    );
  }

  Widget _buildIconText(IconData icon, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? "N/A",
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHrRequestDetail() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1540), Color(0xFF1E2A78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHrField("Request no :", formData?["request_no"]),
          _buildHrField("Request type :", formData?["request_type"]),
          _buildHrField("Status :", formData?["status"]?.toString()),
          _buildHrField("Request date :", formData?["request_date"]),
          _buildHrField("Start Date :", formData?["start_date"]?.toString()),
          _buildHrField("Duration :", formData?["duration"]?.toString()),
          _buildHrField(
              "Balance Leave :", formData?["balance_leave"]?.toString()),
        ],
      ),
    );
  }

  Widget _buildHrField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        "$label ${value ?? ''}",
        style: GoogleFonts.koulen(
          fontSize: 13,
          fontWeight: FontWeight.w300,
          color: Colors.white,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  _viewAttachement() async {
    final attachmentId =
        attachmentIds.first['attachment_id'] ?? attachmentIds.first;
    final token = SharedPref.getLoginData().result?.token;
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
    print('id: $attachmentId');
    final data = {
      "jsonrpc": "2.0",
      "params": {
        "attachment_id": attachmentId,
      }
    };
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final response = await Dio().fetch(
        RequestOptions(
          method: 'GET',
          path: 'https://erp.elrace.com/api/get_attachment_details',
          headers: headers,
          data: data,
          responseType: ResponseType.json,
        ),
      );
      Navigator.of(context).pop();
      final resData = response.data;
      final binaryBase64 =
          resData['result']['data']['attachment_binary_data'] ?? '';
      final fileName = resData['result']['data']['attachment_name'] ?? '';
      if (binaryBase64 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No binary data found.')),
        );
        return;
      }
      final pdfBytes = base64Decode(binaryBase64);
      Util.pushPage(
          AttachmentPdfViewer(
            pdfBytes: pdfBytes,
            attchmentName: fileName,
          ),
          context);
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \n$e')),
      );
    }
  }
}
