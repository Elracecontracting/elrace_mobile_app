import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:http/http.dart' as http;
import '../Attendace_list/repository/attendance_repository.dart';

class PettyCashAddExpense extends StatefulWidget {

  const PettyCashAddExpense({Key? key}) : super(key: key);

  @override
  _PettyCashAddExpenseState createState() => _PettyCashAddExpenseState();
}


class _PettyCashAddExpenseState extends State<PettyCashAddExpense> {
  String description = '';
  DateTime selectedDate = DateTime.now();
  String error = '';
  List<dynamic> pettyCashUsers = [];
  List<dynamic> filteredUsers = [];
  String searchQuery = '';
  bool isLoading = false;
  String? errorMessage;
  dynamic selectedUser;
  String amount = '';
  String selectedExpenseType = 'EXPENSE TYPE'; // Default display text
  final List<String> expenseTypes = ['Fuel', 'Hospitality', 'Site Material','Others'];
  String empID = '';
  String companyId = '';
  final String baseUrl = 'https://test.elrace.com/api/';
  bool isSubmitting = false;


  Future<void> _showPettyCashUserDialog() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = SharedPref.getLoginData().result?.token;

      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      final url = Uri.parse("https://test.elrace.com/api/get_petty_cash_records");
      final body = jsonEncode({
        "jsonrpc": "2.0",
        "params": {},
      });

      final request = http.Request('POST', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final users = data["result"]["data"];

        setState(() {
          pettyCashUsers = users;
          filteredUsers = users.take(4).toList();
          isLoading = false;
        });

        // Now show the dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Select Petty Cash Holder", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        TextField(
                          onChanged: (value) {
                            setDialogState(() {
                              searchQuery = value;
                              filteredUsers = pettyCashUsers
                                  .where((user) => user['name'].toLowerCase().contains(searchQuery.toLowerCase()))
                                  .take(4)
                                  .toList();
                            });
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 18),
                            hintText: 'Search user...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),

                        const SizedBox(height: 14),

                        isLoading
                            ? const CircularProgressIndicator()
                            : filteredUsers.isEmpty
                            ? const Text("No users found.")
                            : SizedBox(
                          height: 200,
                          child: ListView.separated(
                            itemCount: filteredUsers.length,
                            itemBuilder: (_, index) {
                              final user = filteredUsers[index];
                              return ListTile(
                                title: Text(user['name'], style: const TextStyle(fontSize: 13)),
                                tileColor: selectedUser?['id'] == user['id']
                                    ? Colors.blue.shade100
                                    : Colors.transparent,
                                onTap: () => setDialogState(() {
                                  selectedUser = user;
                                }),
                              );
                            },
                            separatorBuilder: (_, __) => Divider(color: Colors.grey.shade400),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: selectedUser != null
                                  ? () {
                                setState(() {
                                  // Use selectedUser['name'] or ['id'] as needed
                                });
                                Navigator.pop(context);
                              }
                                  : null,
                              child: const Text("OK"),
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
      } else {
        throw Exception("Failed to fetch users: ${response.body}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> init({required String base}) async {
    empID = (await userRepo.getLoginResponse())!.result!.data!.emp_id.toString();
  }

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


  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Widget _buildInfoRow(String imagePath, String title, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 34, height: 34, fit: BoxFit.contain),
            const SizedBox(width: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 12, color: Colors.black)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> submitExpense() async {
    if (empID.isEmpty || companyId.isEmpty) {
      await init(base: baseUrl);
    }

    // 🔍 Field validation
    if (selectedExpenseType == 'EXPENSE TYPE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an expense type.")),
      );
      return;
    }

    if (selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a petty cash holder.")),
      );
      return;
    }

    if (amount.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an amount.")),
      );
      return;
    }

    if (description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a description.")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final token = SharedPref.getLoginData().result?.token;
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      final body = jsonEncode({
        "jsonrpc": "2.0",
        "params": {
          "project_id": null,
          "employee_id": int.parse(empID),
          "petty_cash_id": selectedUser['id'],
          "unit_amount": double.tryParse(amount) ?? 0.0,
          "name": description,
          "x_expense_type": getExpenseTypeApiValue(selectedExpenseType),
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
          SnackBar(content: Text(decoded['result']['message'] ?? 'Expense submitted')),
        );
        Navigator.pop(context);
      } else {
        throw Exception(decoded['result']['message'] ?? 'Submission failed.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            const SizedBox(height: 10),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Center(
                    child: Image.asset(
                      'assets/png/add_expense_title.png',
                      width: 180,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Center(
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    selectedExpenseType = value;
                  });
                },
                position: PopupMenuPosition.under,
                itemBuilder: (BuildContext context) => expenseTypes.map((String type) {
                  return PopupMenuItem<String>(
                    value: type,
                    child: Text(
                      type,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  );
                }).toList(),
                color: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  width: 240, // Optional: adjust to your design
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 36),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
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
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),




            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('assets/png/calendar_icon.png', 'Date', formattedDate, onTap: _pickDate),
                  _buildInfoRow(
                    'assets/png/supplier_icon.png',
                    'Petty Cash Holder',
                    selectedUser?['name'] ?? 'Select user',
                    onTap: _showPettyCashUserDialog,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/png/money_icon.png',
                          width: 34,
                          height: 34,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Amount',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  // You can parse or validate here
                                  setState(() {
                                    amount = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Enter amount in AED',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 20),
            // Description Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Adjust padding as needed
              child: Align(
                alignment: Alignment.center, // Align text to the left
                child: Text(
                  'DESCRIPTION',
                  style: _infoTextStyle_1(),
                  textAlign: TextAlign.center, // Ensures left alignment
                ),
              ),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                          spreadRadius: 1, // Reduced shadow spread
                          blurRadius: 5, // Reduced blur
                          offset: const Offset(2, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      maxLines: 3, // Reduced height
                      onChanged: (value) => setState(() => description = value),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22), // Adjust border radius
                          borderSide: const BorderSide(color: Colors.grey, width: 0.5), // Add border
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: Colors.grey, width: 0.5), // Normal state border
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: Colors.blue, width: 2), // Highlight border when focused
                        ),
                        filled: true,
                        fillColor: Colors.grey[300], // Keep background white
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12), // Reduce padding
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 10,
                    child: Column(
                      children: [
                        Text(
                          '${description.split(' ').length}/50',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Max words',
                          style: TextStyle(fontSize: 10, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appFontColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isSubmitting ? null : submitExpense,
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 15), // Adds spacing between buttons
                  Expanded(child: _buildButton('Cancel', const Color(0xFFBA1719))),
                ],
              ),
            ),


            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget _buildInfoRow(String imagePath, String title, String value) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         Image.asset(
  //           imagePath,
  //           width: 34, // Ensure it matches the icon size
  //           height: 34,
  //           fit: BoxFit.contain,
  //         ),
  //         const SizedBox(width: 22), // Adjusted spacing for alignment
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               title,
  //               style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
  //             ),
  //             Text(
  //               value,
  //               style: const TextStyle(fontSize: 12, color: Colors.black),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildButton(String text, Color color) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {},
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
  TextStyle _infoTextStyle_1() => const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: appFontColor);

}
