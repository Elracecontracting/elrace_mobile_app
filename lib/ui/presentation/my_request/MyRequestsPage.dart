import 'dart:async';
import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/my_request/RequestEffectiveDate.dart';
import 'package:el_race/ui/presentation/my_request/RequestJobMissionPage.dart';
import 'package:el_race/ui/presentation/my_request/RequestLeavePage.dart';
import 'package:el_race/ui/presentation/my_request/RequestPermission.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../widgets/header_widget.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({
    Key? key,
  }) : super(key: key);

  @override
  _MyRequestsPageState createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  String selectedRequestType = "Choose your request";
  bool isDropdownOpen = false;
  bool isLoading = true;
  Set<int> expandedItems = {};
  String error = '';
  List<dynamic> requests = [];
  List<dynamic> _allRequests = [];

  final List<String> requestOptions = [
    'Leave',
    'Job Mission',
    'Effective Date',
    'Temporary Permission',
  ];
  TextEditingController searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchRequests();
    searchController.addListener(() {
      final text = searchController.text.trim();
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        if (text.isEmpty) {
          setState(() {
            requests = List<dynamic>.from(_allRequests);
          });
        } else {
          // Prefer server-side search if available
          _fetchRequests(keyword: text);
        }
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests({String keyword = ""}) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final token = SharedPref.getLoginData().result?.token;

      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      final body = jsonEncode({
        "jsonrpc": "2.0",
        "params": {"keyword": keyword},
      });

      final url = Uri.parse("https://test.elrace.com/api/my_requests");
      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint("response: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['result']['data'];

        if (!mounted) return; // ✅ Check again after async call
        setState(() {
          if (keyword.isEmpty) {
            _allRequests = List<dynamic>.from(items);
            requests = List<dynamic>.from(items);
          } else {
            // If backend supports keyword, it already filtered; still guard locally
            requests = items;
          }
          isLoading = false;
        });
      } else {
        throw Exception(
            "Failed to load requests: ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        error = "Something went wrong. Please try again.";
      });
    }
  }

  void _showRequestTypeDialog() {
    String dialogSelectedRequest = selectedRequestType;
    bool isDropdownOpen = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 28),
                        GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              isDropdownOpen = !isDropdownOpen;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/png/dropdown_bg.png'),
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dialogSelectedRequest,
                                  style: GoogleFonts.koulen(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    letterSpacing:
                                        1.2, // Adjust this value as needed
                                  ),
                                ),
                                Icon(
                                  isDropdownOpen
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isDropdownOpen)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(18),
                                bottomRight: Radius.circular(18),
                              ),
                              border:
                                  Border.all(color: Colors.grey, width: 0.3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withAlpha((0.1 * 255).toInt()),
                                  blurRadius: 4,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: List.generate(
                                  requestOptions.length * 2 - 1, (index) {
                                if (index.isEven) {
                                  final option = requestOptions[index ~/ 2];
                                  return GestureDetector(
                                    onTap: () async {
                                      setState(  () => selectedRequestType = option);
                                      Navigator.of(context).pop();

                                      bool? shouldRefresh;

                                      if (option == 'Leave') {
                                        shouldRefresh = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RequestDetailsPage(
                                                loginResponseModel:
                                                    SharedPref.getLoginData()),
                                          ),
                                        );
                                      } else if (option == 'Job Mission') {
                                        shouldRefresh = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                RequestJobMissionPage(
                                                    loginResponseModel:
                                                        SharedPref
                                                            .getLoginData()),
                                          ),
                                        );
                                      } else if (option == 'Effective Date') {
                                        shouldRefresh = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EffectiveDatePage(
                                                loginResponseModel:
                                                    SharedPref.getLoginData()),
                                          ),
                                        );
                                      } else if (option ==
                                          'Temporary Permission') {
                                        shouldRefresh = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RequestPermission(
                                                loginResponseModel:
                                                    SharedPref.getLoginData()),
                                          ),
                                        );
                                      }

                                      if (shouldRefresh == true) {
                                        _fetchRequests(); // 🔁 Refresh the list
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 16),
                                      child: Text(
                                        option,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: dialogSelectedRequest == option
                                              ? Colors.blue
                                              : appFontColor,
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return const Divider(
                                    height: 1,
                                    color: Colors.grey,
                                    thickness: 0.4,
                                    indent: 16,
                                    endIndent: 16,
                                  );
                                }
                              }),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info,
                                size: 14, color: appFontColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                translate('notification.pending_approval'),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: appFontColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withAlpha((0.2 * 255).toInt()),
                              blurRadius: 6,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.close, size: 18, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestItem(Map item, int index) {
    final bool isExpanded = expandedItems.contains(index);
    final String status = (item['status'] ?? '').toString().toLowerCase();
    final String statusLabel = status.toUpperCase();

    // 🎨 Status-based styling
    String backgroundImage = 'assets/png/item_bg_green.png'; // Default fallback
    Color textColor = Colors.white;

    switch (status) {
      case 'approve':
      case 'approved':
        backgroundImage = 'assets/png/item_bg_green.png';
        textColor = Colors.green;
        break;
      case 'pending':
        backgroundImage = 'assets/png/item_bg_yellow.png';
        textColor = Colors.amber;
        break;
      case 'cancel':
      case 'cancelled':
      case 'rejected':
      case 'reject':
        backgroundImage = 'assets/png/item_bg_red.png';
        textColor = Colors.red;
        break;
      default:
        backgroundImage = 'assets/png/item_bg_green.png';
        textColor = Colors.white;
    }

    Color bgStart = const Color(0xFF0F0C29);
    Color bgEnd = const Color(0xFF302B63);

    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded ? expandedItems.remove(index) : expandedItems.add(index);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          switchInCurve: Curves.easeOutExpo,
          transitionBuilder: (child, animation) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          child: isExpanded
              ? Container(
                  height: 70.w,
                  key: const ValueKey("expanded"),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [bgStart, bgEnd]),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: bgEnd.withAlpha((0.3 * 255).toInt()),
                        blurRadius: 6,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                )
              : Container(
                  key: const ValueKey("collapsed"),
                  height: 70.w,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 19.w,)+EdgeInsets.only(bottom: 6.w),
                  // padding: EdgeInsets.fromLTRB(15.w, 8.w, 1.w, 20.w),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(backgroundImage),
                      fit: BoxFit.fill,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.08 * 255).toInt()),
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Date
                      SizedBox(
                        width: 80.w,
                        child: Text(
                          item['create_date'] ?? '',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: appFontColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 0),
                      const SizedBox(
                        height: 30,
                        child:
                            VerticalDivider(color: Colors.grey, thickness: 2),
                      ),
                      const SizedBox(width: 5),

                      // REQ NO
                      SizedBox(
                        width: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'REQ NO',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: appFontColor,
                              ),
                            ),
                            Text(
                              item['name'] ?? '',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      const SizedBox(
                        height: 30,
                        child:
                            VerticalDivider(color: Colors.grey, thickness: 2),
                      ),
                      const SizedBox(width: 0),

                      // Request Type
                      Expanded(
                        child: Text(
                          item['request_type_name']?.trim() ?? '',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: appFontColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _showStatusDialog(Map item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildStatusPill(item['status'] ?? 'unknown'),
              const SizedBox(height: 20),
              Text(
                "Date: ${item['create_date']}",
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                "Request No: ${item['name']}",
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                "Type: ${item['request_type_name']}",
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildStatusPill(String status) {
    Color bgColor;
    Color textColor = Colors.white;

    switch (status.toLowerCase()) {
      case 'approve':
        bgColor = Colors.green;
        break;
      case 'draft':
        bgColor = Colors.grey;
        break;
      case 'pending':
        bgColor = Colors.amber;
        break;
      default:
        bgColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [bgColor.withValues(alpha: 0.8), bgColor]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: bgColor.withAlpha((0.3 * 255).toInt()),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchRequests();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const HeaderWidget(),
        body: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                      Text(
                        translate('home.my_request'),
                        style: GoogleFonts.koulen(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: appFontColor,
                          letterSpacing: 1.9, // ⬅️ adjust value as needed
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 25,
                        decoration: const BoxDecoration(
                            color: appFontColor, shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.add,
                              size: 20, color: Colors.white),
                          onPressed: _showRequestTypeDialog,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/png/bg_atten.png'),
                        fit: BoxFit.none,
                      ),
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(29),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha((0.2 * 255).toInt()),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: translate('home.Find_your_request'),
                        hintStyle: const TextStyle(
                            fontSize: 12,
                            color: appFontColor), // Reduced font size
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(
                              8.0), // Adjust padding to control icon size
                          child: Icon(Icons.menu,
                              size: 18,
                              color: appFontColor), // Reduced icon size
                        ),
                        suffixIcon: const Icon(Icons.search,
                            size: 18, color: appFontColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10), // Adjust padding
                      ),
                      onChanged: (query) {},
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error.isNotEmpty
                      ? Center(child: Text(error))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          itemCount: requests.length,
                          itemBuilder: (context, index) =>
                              _buildRequestItem(requests[index], index),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
