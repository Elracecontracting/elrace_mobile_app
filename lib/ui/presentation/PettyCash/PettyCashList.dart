import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashPopUpScreen.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../widgets/header_widget.dart';

class PettyCashList extends StatefulWidget {
  const PettyCashList({super.key});

  @override
  _PettyCashListState createState() => _PettyCashListState();
}

class _PettyCashListState extends State<PettyCashList> {
  List<Map<String, dynamic>> expenseSheets = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _fetchPettyCashData();
  }

  Future<void> _fetchPettyCashData() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    try {
      // يمكنك تعديل طريقة جلب التوكن حسب مشروعك
      final token = await SharedPref.getLoginData().result?.token;
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };
      final url = Uri.parse("https://erp.elrace.com/api/petty_cash_home");
      final body = jsonEncode({
        "jsonrpc": "2.0",
        "params": {},
      });
      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result']['data'];
        setState(() {
          expenseSheets =
              List<Map<String, dynamic>>.from(result['expense_sheets']);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          error = 'Failed to load data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title (Fixed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
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
                Text(
                  translate('home.petty_cash'),
                  style: GoogleFonts.koulen(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: appFontColor,
                    letterSpacing: 2.2,
                  ),
                ),
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.add, color: appFontColor),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PettyCashPopUpScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ✅ Expense List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : expenseSheets.isEmpty
                    ? const Center(
                        child: Text("No record found.",
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: expenseSheets.length,
                        itemBuilder: (context, index) {
                          final sheet = expenseSheets[index];
                          final status = (sheet['state'] ?? 'Submitted')
                              .toString()
                              .toUpperCase();
                          final date = sheet['date']?.toString() ?? '';
                          final amount =
                              sheet['total_amount']?.toString() ?? '';
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6.0, horizontal: 6.0),
                            child: Container(
                              decoration: BoxDecoration(
                                image: const DecorationImage(
                                  image: AssetImage(
                                      'assets/png/item_bg_green.png'),
                                  fit: BoxFit.cover,
                                ),
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(30, 8, 15, 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          status,
                                          style: const TextStyle(
                                            fontSize: 14,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            translate(
                                                'request_permission.date'),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: appFontColor,
                                            ),
                                          ),
                                          Text(
                                            date,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: appFontColor,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            translate('home.amount'),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: appFontColor,
                                            ),
                                          ),
                                          Text(
                                            amount,
                                            style: const TextStyle(
                                              fontSize: 14,
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
                                      backgroundImage: AssetImage(
                                          'assets/png/tick-petty.png'),
                                    ),
                                    const SizedBox(width: 0),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
