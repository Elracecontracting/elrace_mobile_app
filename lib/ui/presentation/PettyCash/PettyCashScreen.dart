import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashAddExpense.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashList.dart';
import 'package:el_race/ui/presentation/PettyCash/PettyCashPopUpScreen.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../widgets/header_widget.dart';

class PettyCashScreen extends StatefulWidget {
  const PettyCashScreen({
    Key? key,
  }) : super(key: key);

  @override
  _PettyCashScreenState createState() => _PettyCashScreenState();
}

class _PettyCashScreenState extends State<PettyCashScreen> {
  bool isLoading = true;
  String error = '';
  double balance = 0.0;
  double incoming = 0.0;
  double spent = 0.0;
  List<Map<String, dynamic>> expenseSheets = [];
  bool isDraftLoading = true;
  double draftAmount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPettyCashData();
  }

  Future<void> _fetchDraftSummary() async {
    if (!mounted) return;

    try {
      final token = SharedPref.getLoginData().result?.token;

      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result']['data'];

        setState(() {
          balance = (result['total_balance'] ?? 0).toDouble();
          draftAmount = (result['total_draft_amount'] ?? 0).toDouble();
        });
      } else {
        throw Exception(
            "Failed to fetch draft summary: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
    }
  }

  Future<void> _fetchPettyCashData() async {
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

      final url = Uri.parse("https://test.elrace.com/api/petty_cash_home");
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
          balance = result['balance'].toDouble();
          incoming = result['incoming'].toDouble();
          spent = result['spent'].toDouble();
          expenseSheets =
              List<Map<String, dynamic>>.from(result['expense_sheets']);
          isLoading = false;
        });
      } else {
        throw Exception(
            "Failed to load petty cash data: ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      if (!mounted) return;
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Title (Fixed)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 10),
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

                // Everything else scrollable after Title
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // Circles Summary
                        SizedBox(
                          height: 190,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double screenWidth = constraints.maxWidth;
                              const double circleSize = 121;
                              final double sideOffset =
                                  screenWidth / 3 - circleSize / 1.5;

                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    top: 60,
                                    left: sideOffset,
                                    child: _buildCircleWithBackground(
                                      "BALANCE",
                                      balance.toString(),
                                      "assets/png/Wallet.png",
                                      "assets/png/balance_bg.png",
                                    ),
                                  ),
                                  Positioned(
                                    top: 60,
                                    right: sideOffset,
                                    child: _buildCircleWithBackground(
                                      "SPENT",
                                      spent.toString(),
                                      "assets/png/spent.png",
                                      "assets/png/spent_bg.png",
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    child: GestureDetector(
                                      onTap: () => _showIncomingPopup(context),
                                      child: _buildCircleWithBackground(
                                        "INCOMING",
                                        incoming.toString(),
                                        "assets/png/Profit.png",
                                        "assets/png/incoming_bg.png",
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),
                        _buildDraftSection(),
                        const SizedBox(height: 20),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 66),
                          child:
                              const Divider(color: Colors.grey, thickness: 1.5),
                        ),

                        const SizedBox(height: 10),

                        expenseSheets.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    "No record found.",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: expenseSheets.length,
                                itemBuilder: (context, index) {
                                  final sheet = expenseSheets[index];
                                  final status = (sheet['state'] ?? 'Submitted')
                                      .toString()
                                      .toUpperCase();
                                  final date = sheet['date'] == false
                                      ? 'N/A'
                                      : sheet['date'].toString();
                                  final amount = sheet['total_amount']
                                          ?.toStringAsFixed(2) ??
                                      '0.00';

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 12.0),
                                    child: _buildTransactionItem_2(
                                        status, date, amount),
                                  );
                                },
                              ),

                        const SizedBox(height: 20),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: 16.0, bottom: 16.0),
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PettyCashList(),
                                  ),
                                );
                              },
                              child: const Text(
                                "View All →",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDraftSection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PettyCashPopUpScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage("assets/png/draft_bg.png"),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Draft Text
            Text(
              "DRAFT",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: appFontColor,
              ),
            ),

            // Divider
            const SizedBox(
              height: 40,
              child: VerticalDivider(color: Colors.grey),
            ),

            // No of Bills (dynamic)
            Expanded(
              child: Column(
                children: [
                  Text(
                    "No of Bills",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: appFontColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat('#,###').format(draftAmount),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: appFontColor,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            const SizedBox(
              height: 40,
              child: VerticalDivider(color: Colors.grey),
            ),

            // Amount (dynamic)
            Expanded(
              child: Column(
                children: [
                  const Text(
                    "Amount",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: appFontColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    balance.toStringAsFixed(0), // 👈 dynamic data
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: appFontColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String status, String date, String amount) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.2 * 255).toInt()),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("Date: $date"),
                ],
              ),
            ],
          ),
          Text("Amount: $amount",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCircleWithBackground(
      String title, String amount, String iconPath, String backgroundPath) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundPath),
          fit: BoxFit.cover,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).toInt()),
            blurRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconPath, width: 37, height: 37),
          const SizedBox(height: 5),
          Text(
            title,
            style: GoogleFonts.koulen(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              letterSpacing: 1.9,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.koulen(
              fontSize: 16, // 2+ font from original 14
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 1.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem_2(String status, String date, String amount) {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage(
              'assets/png/item_bg_green.png'),
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
        padding: const EdgeInsets.fromLTRB(15, 8, 8, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: appFontColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 15),
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
                  Text(
                    'Date',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: appFontColor,
                    ),
                  ),
                  Text(
                    date,
                    style: GoogleFonts.inter(
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

  void _showIncomingPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPopupItem(),
                const SizedBox(height: 16),
                _buildPopupItem(), // You can remove this if only one message is needed
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupItem() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/png/info_icon.png', // Replace with your bulb/info icon
          width: 30,
          height: 30,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            translate('pettycash.received_message'),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
