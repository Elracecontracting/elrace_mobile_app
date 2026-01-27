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
  int employeeId = 0;
  double balance = 0.0;
  double incoming = 0.0;
  double spent = 0.0;
  double paid = 0.0;
  int draftExpensesCount = 0;
  double draftExpensesTotal = 0.0;

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
      final token = SharedPref.getLoginData().result?.token;
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
        
        print('\n╔═══════════════════════════════════════════════════════════════');
        print('║ 📊 PETTY CASH RESPONSE DATA:');
        print('╠═══════════════════════════════════════════════════════════════');
        print('║ 👤 Employee ID: ${result['employee_id']}');
        print('║ 💰 Balance: ${result['balance']} AED');
        print('║ 📈 Incoming: ${result['incoming']} AED');
        print('║ 📉 Spent: ${result['spent']} AED');
        print('║ 💳 Paid: ${result['paid']} AED');
        print('║ 📝 Draft Count: ${result['draft_expenses_count']}');
        print('║ 💵 Draft Total: ${result['draft_expenses_total']} AED');
        print('║ 📋 Expense Sheets: ${result['expense_sheets']?.length ?? 0}');
        print('╚═══════════════════════════════════════════════════════════════\n');
        
        setState(() {
          employeeId = result['employee_id'] ?? 0;
          balance = (result['balance'] ?? 0).toDouble();
          incoming = (result['incoming'] ?? 0).toDouble();
          spent = (result['spent'] ?? 0).toDouble();
          paid = (result['paid'] ?? 0).toDouble();
          draftExpensesCount = result['draft_expenses_count'] ?? 0;
          draftExpensesTotal = (result['draft_expenses_total'] ?? 0).toDouble();
          expenseSheets =
              List<Map<String, dynamic>>.from(result['expense_sheets'] ?? []);
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

          // 📊 Petty Cash Summary Card
          if (!isLoading)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Balance
                  Text(
                    'Your Balance',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    balance.toStringAsFixed(0),
                    style: GoogleFonts.koulen(
                      fontSize: 40,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Incoming', incoming.toStringAsFixed(0)),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildStatItem('Spent', spent.toStringAsFixed(0)),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildStatItem('Paid', paid.toStringAsFixed(0)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  // Draft Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Draft Count', draftExpensesCount.toString(), isCount: true),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildStatItem('Draft Total', draftExpensesTotal.toStringAsFixed(0)),
                    ],
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

  Widget _buildStatItem(String label, String value, {bool isCount = false}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.koulen(
            fontSize: isCount ? 22 : 20,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
