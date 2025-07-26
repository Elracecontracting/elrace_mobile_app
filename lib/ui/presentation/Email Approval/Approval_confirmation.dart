import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/Email%20Approval/widgets/file_binary.dart';
import 'package:el_race/utils/Util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:dio/dio.dart';
import 'widgets/approval_action_buttons.dart';

class ApprovalConfirmationScreen extends StatefulWidget {
  final LoginResponseModel loginResponseModel;
  final String requestId;
  final String type;

  const ApprovalConfirmationScreen({
    Key? key,
    required this.loginResponseModel,
    required this.requestId,
    required this.type,
  }) : super(key: key);

  @override
  State<ApprovalConfirmationScreen> createState() => _ApprovalConfirmationScreenState();
}

class _ApprovalConfirmationScreenState extends State<ApprovalConfirmationScreen> {
  bool isLoading = true;
  String error = '';
  int _currentPage = 0;
  late PageController _pageController;
  Map<String, dynamic>? formData;
  List<dynamic> tableView = [];
  List<dynamic> attachmentIds = [];
  List<dynamic> approvals = [];
  int selectedTab = 0;

  // Helper to check if current user is in approvals list
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
          return "https://test.elrace.com/api/get_hr_request_details";
        case 'RFQ':
          return "https://test.elrace.com/api/get_rfq_details";
        case 'INVOICE':
          return "https://test.elrace.com/api/get_invoice_details";
        case 'PETTYCASH':
          return "https://test.elrace.com/api/get_petty_cash_details";
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
      debugPrint("request_details: ${response.body}");
     
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result']['data'];
        debugPrint('approvals: ${result['approvals'] ?? []}');
        setState(() {
          formData = result['form_view'] ?? {};
          approvals = result['approvals'] ?? [];
          tableView = result['table_view'] ?? [];
          attachmentIds = result['attachment_ids'] ?? [];
        });
      
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load request details: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  List<Map<String, String>> get projects {
    return tableView.map<Map<String, String>>((item) => {
      "product": item["product"]?.toString() ?? "",
      "qty": item["qty"]?.toString() ?? "",
      "uom": item["uom"]?.toString() ?? "",
      "unit_price": item["unit_price"]?.toString() ?? "",
      "total": item["total"]?.toString() ?? "",
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Request Details', style: GoogleFonts.koulen()),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Center(
                    //   child: Text(
                    //     "REQUEST DETAILS",
                    //     style: GoogleFonts.koulen(
                    //       fontSize: 19,
                    //       fontWeight: FontWeight.w500,
                    //       color: appFontColor,
                    //       letterSpacing: 2,
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 20),
                    if (widget.type.toUpperCase() == 'HR') ...[
                      Row(
                        children: [
                          _buildTabButton("REQUEST DETAILS", 0, isLeft: true),
                          _buildTabButton("EMPLOYEE DETAILS", 1, isLeft: false),
                        ],
                      ),
                      selectedTab == 0 ? _buildHrRequestDetail() : _buildHrEmployeeDetail(),
                    ],
                    if (widget.type.toUpperCase() == 'RFQ') ...[
                      _buildDetailRow("Request Type :", formData?["request_type"] ?? "RFQ"),
                      _buildDetailRow("Ref No :", formData?["title"] ?? ""),
                      _buildDetailRow("Vendor :", formData?["vendor"] ?? ""),
                      _buildDetailRow("Client :", formData?["client"] ?? ""),
                      _buildDetailRow("WO :", formData?["wo"] ?? ""),
                      _buildDetailRow("Department :", formData?["department"] ?? ""),
                      _buildDetailRow("Material Type :", formData?["material_type"] ?? ""),
                    ],
                    const SizedBox(height: 12),
                    if (widget.type.toUpperCase() != 'HR') ...[
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios, size: 16),
                                onPressed: () {
                                  if (_currentPage > 0) {
                                    _pageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                              ),
                              Text(
                                "${_currentPage + 1}/${projects.length}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                onPressed: () {
                                  if (_currentPage < projects.length - 1) {
                                    _pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 150,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: projects.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final item = projects[index];
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black12, blurRadius: 4),
                                    ],
                                  ),
                                  child: SingleChildScrollView(
                                    physics: const NeverScrollableScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Project", style: GoogleFonts.koulen(fontSize: 10, letterSpacing: 1.0)),
                                        Text("${item["product"]}", style: GoogleFonts.koulen(fontWeight: FontWeight.w500, letterSpacing: 1.0)),
                                        const SizedBox(height: 3),
                                        Text("Amount", style: GoogleFonts.koulen(fontSize: 10, letterSpacing: 1.0)),
                                        Text("${item["unit_price"]}", style: GoogleFonts.koulen(fontWeight: FontWeight.w500, letterSpacing: 1.0)),
                                        const SizedBox(height: 3),
                                        Text("Remarks", style: GoogleFonts.koulen(fontSize: 10, letterSpacing: 1.0)),
                                        Text("${item["uom"]}", style: GoogleFonts.koulen(fontWeight: FontWeight.w500, letterSpacing: 1.0)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (widget.type.toUpperCase() != 'HR')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            "Total: AED ${formData?["amount_total"] != null ? double.parse(formData!["amount_total"].toString()).toStringAsFixed(2) : "0.00"}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (attachmentIds.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No attachment found.')),
                            );
                            return;
                          }
                          await _viewAttachement();
                        },
                        icon: const Icon(Icons.remove_red_eye, size: 16, color: Colors.white),
                        label: Text(
                          "VIEW ATTACHMENT",
                          style: GoogleFonts.koulen(
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade900,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                    // const SizedBox(height: 16),
                    // if (approvals.isNotEmpty) ...[
                    //   Text(
                    //     "Approval Status :",
                    //     style: GoogleFonts.koulen(
                    //       fontWeight: FontWeight.w500,
                    //       fontSize: 13,
                    //       letterSpacing: 1.0,
                    //       color: Colors.black,
                    //     ),
                    //   ),
                    //   const SizedBox(height: 10),
                    //   _buildStatusBar(),
                    // ],
                    // const SizedBox(height: 12),
                    // _buildApproverRow(),
                    const SizedBox(height: 30),
                    // Approval buttons with fade/disable logic
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: !isCurrentUserInApprovals
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('This validator not available for this request.')),
                                  );
                                }
                              : null,
                          child: AbsorbPointer(
                            absorbing: !isCurrentUserInApprovals,
                            child: ApprovalActionButtons(
                              requestId: widget.requestId,
                              type: widget.type,
                              onResult: (result) {
                                // After action, refresh details
                                _fetchRequestDetails();
                              },
                              disabled: !isCurrentUserInApprovals,
                              userIds: approvals.map((a) => a['id'].toString()).toList(),
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
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Text(
        "$label $value",
        style: GoogleFonts.koulen(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    if (approvals.isEmpty) {
      return const SizedBox(); // Or show a placeholder if needed
    }

    final approvedCount = approvals.where((a) => a['validation_status'] == true).length;
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
                approver['name']??'',
                style: TextStyle(fontSize: 10.sp),
                overflow: TextOverflow.ellipsis,),
            )
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHrEmployeeDetail() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundImage: AssetImage('assets/png/profile_1.png'),
          ),
          const SizedBox(height: 8),
          Text(formData?["employee_name"] ?? "",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(formData?["emp_code"]?.toString() ?? "",
              style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 12),
          _buildIconText(Icons.work_outline, formData?["job_id"]),
          _buildIconText(Icons.phone_android, formData?["mobile"]),
          _buildIconText(Icons.business, formData?["department"]),
          _buildIconText(Icons.email, formData?["work_email"]),
        ],
      ),
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
        borderRadius: BorderRadius.only(
          bottomLeft:Radius.circular(12) ,
          bottomRight: Radius.circular(12) ,
        ),      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHrField("Request no :", formData?["request_no"]),
          _buildHrField("Request type :", formData?["request_type"]),
          _buildHrField("Status :", formData?["status"]?.toString()),
          _buildHrField("Request date :", formData?["request_date"]),
          _buildHrField("Start Date :", formData?["start_date"]?.toString()),
          _buildHrField("Duration :", formData?["duration"]?.toString()),
          _buildHrField("Balance Leave :", formData?["balance_leave"]?.toString()),
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



  Widget _buildTabButton(String label, int index, {required bool isLeft}) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D1540) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: isLeft ? const Radius.circular(12) : Radius.zero,
              topRight: !isLeft ? const Radius.circular(12) : Radius.zero,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.koulen(
              fontSize: 12,
              color: isSelected ? Colors.white : appFontColor,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  _viewAttachement()async{
    final attachmentId = attachmentIds.first['attachment_id'] ?? attachmentIds.first;
    final token = SharedPref.getLoginData().result?.token;
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
    print('id: ${attachmentId}');
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
          path: 'https://test.elrace.com/api/get_attachment_details',
          headers: headers,
          data: data, // This is where you force the body
          responseType: ResponseType.json,
        ),
      );
      Navigator.of(context).pop(); // Remove loading
      final resData = response.data;
      final binaryBase64 = resData['result']['data']['attachment_binary_data']??'';
      final fileName = resData['result']['data']['attachment_name']??'';
      if (binaryBase64 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No binary data found.')),
        );
        return;
      }
      final pdfBytes = base64Decode(binaryBase64);
      Util.pushPage(AttachmentPdfViewer(pdfBytes: pdfBytes,attchmentName: fileName,), context);
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \n$e')),
      );
    }
  }
}




