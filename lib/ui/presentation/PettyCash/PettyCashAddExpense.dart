import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../Attendace_list/repository/attendance_repository.dart';

// Number formatter with thousand separators
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters except decimal point
    String newText = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    // Ensure only one decimal point
    if (newText.split('.').length > 2) {
      return oldValue;
    }

    // Split into integer and decimal parts
    List<String> parts = newText.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Add thousand separators to integer part
    String formattedInteger = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formattedInteger = ',$formattedInteger';
      }
      formattedInteger = integerPart[i] + formattedInteger;
      count++;
    }

    // Combine with decimal part
    String formattedText = formattedInteger;
    if (parts.length > 1) {
      formattedText += '.$decimalPart';
    }

    // Calculate new cursor position
    int selectionIndex = formattedText.length;

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class PettyCashAddExpense extends StatefulWidget {
  const PettyCashAddExpense({super.key});

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
  String selectedExpenseType = 'EXPENSE TYPE';
  final List<String> expenseTypes = ['Petrol ', 'Hospitality ', 'Others'];
  String empID = '';
  String companyId = '';
  final String baseUrl = 'https://erp.elrace.com/api/';
  bool isSubmitting = false;

  // Text controllers
  final TextEditingController user = TextEditingController();
  final TextEditingController date = TextEditingController();
  final TextEditingController amout = TextEditingController();

  @override
  void initState() {
    super.initState();
    date.text = DateFormat('dd/MM/yyyy').format(selectedDate);
  }

  @override
  void dispose() {
    user.dispose();
    date.dispose();
    amout.dispose();
    super.dispose();
  }

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

      final url =
          Uri.parse("https://erp.elrace.com/api/get_petty_cash_records");
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
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  insetPadding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Select Petty Cash Holder',
                            style:
                                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: (value) {
                            setDialogState(() {
                              searchQuery = value;
                              filteredUsers = pettyCashUsers
                                  .where((user) => user['name']
                                      .toLowerCase()
                                      .contains(searchQuery.toLowerCase()))
                                  .take(4)
                                  .toList();
                            });
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 18),
                            hintText: 'Search user...',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        isLoading
                            ? const CircularProgressIndicator()
                            : filteredUsers.isEmpty
                                ? Text(translate('pettycash.no_users'))
                                : SizedBox(
                                    height: 200,
                                    child: ListView.separated(
                                      itemCount: filteredUsers.length,
                                      itemBuilder: (_, index) {
                                        final userItem = filteredUsers[index];
                                        return ListTile(
                                          title: Text(userItem['name'],
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                          tileColor:
                                              selectedUser?['id'] == userItem['id']
                                                  ? Colors.blue.shade100
                                                  : Colors.transparent,
                                          onTap: () => setDialogState(() {
                                            selectedUser = userItem;
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
                              onPressed: () => Navigator.pop(context),
                              child: Text(translate('pettycash.cancel')),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: selectedUser != null
                                  ? () {
                                      setState(() {
                                        user.text = "${selectedUser['name']}";
                                      });
                                      Navigator.pop(context);
                                      FocusScope.of(context).unfocus();
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
    empID =
        (await userRepo.getLoginResponse())!.result!.data!.emp_id.toString();
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
      setState(() {
        selectedDate = picked;
        date.text = DateFormat('dd/MM/yyyy').format(selectedDate);
      });
    }
  }

  Future<void> submitExpense() async {
    if (empID.isEmpty || companyId.isEmpty) {
      await init(base: baseUrl);
    }

    // Field validation
    if (selectedExpenseType == 'EXPENSE TYPE') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('home.Select_Expense_Type'))),
      );
      return;
    }

    if (selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('home.Select_Petty_Cash_Holder'))),
      );
      return;
    }

    if (amount.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('home.Enter_amount_in_AED'))),
      );
      return;
    }

    if (description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('home.DESCRIPTION'))),
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(decoded['result']['message'] ??
                  translate('pettycash.request_submitted'))),
        );
        Navigator.pop(context);
      } else {
        throw Exception(decoded['result']['message'] ??
            translate('pettycash.failed_to_submit'));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("${translate('pettycash.error')}: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: Colors.black,
      height: 1.1,
    );

    TextStyle fieldTextStyle(bool isPlaceholder) => TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isPlaceholder ? Colors.black.withOpacity(0.45) : Colors.black,
          height: 1.1,
        );

    InputDecoration pillDecoration({String? hintText, Widget? suffixIcon}) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: fieldTextStyle(true),
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.25), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.25), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.35), width: 1.2),
        ),
      );
    }

    Widget labeledField({required String label, required Widget child}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: 6),
          child,
        ],
      );
    }

    final isExpenseTypePlaceholder = selectedExpenseType == 'EXPENSE TYPE';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Center(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('+ ADD EXPENSE', style: labelStyle, textAlign: TextAlign.center),
                          const SizedBox(height: 18),

                          labeledField(
                            label: 'Amount',
                            child: TextField(
                              controller: amout,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [ThousandsSeparatorInputFormatter()],
                              textAlign: TextAlign.center,
                              style: fieldTextStyle(false),
                              onChanged: (value) => setState(() {
                                amount = value.replaceAll(',', '');
                              }),
                              decoration: pillDecoration(hintText: '0'),
                            ),
                          ),
                          const SizedBox(height: 14),

                          labeledField(
                            label: 'Pettycash holder',
                            child: TextField(
                              controller: user,
                              readOnly: true,
                              textAlign: TextAlign.center,
                              style: fieldTextStyle(user.text.trim().isEmpty),
                              onTap: _showPettyCashUserDialog,
                              decoration: pillDecoration(hintText: translate('pettycash.select_user')),
                            ),
                          ),
                          const SizedBox(height: 14),

                          labeledField(
                            label: 'Invoice Date',
                            child: TextField(
                              controller: date,
                              readOnly: true,
                              textAlign: TextAlign.center,
                              style: fieldTextStyle(false),
                              onTap: _pickDate,
                              decoration: pillDecoration(hintText: DateFormat('dd/MM/yyyy').format(selectedDate)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          labeledField(
                            label: 'Expense type',
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton2<String>(
                                value:
                                    isExpenseTypePlaceholder ? null : selectedExpenseType,
                                isExpanded: true,
                                hint: Center(
                                  child: Text(
                                    'Car petrol',
                                    style: fieldTextStyle(true),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                items: expenseTypes
                                    .map(
                                      (t) => DropdownMenuItem<String>(
                                        value: t,
                                        child: Text(
                                          t.trim(),
                                          style: fieldTextStyle(false),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                selectedItemBuilder: (context) {
                                  return expenseTypes
                                      .map(
                                        (t) => Center(
                                          child: Text(
                                            t.trim(),
                                            style: fieldTextStyle(false),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList();
                                },
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() {
                                    selectedExpenseType = v;
                                  });
                                },
                                buttonStyleData: ButtonStyleData(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.25),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                iconStyleData: const IconStyleData(
                                  icon: Icon(Icons.keyboard_arrow_down),
                                  iconSize: 22,
                                  iconEnabledColor: Colors.black54,
                                ),
                                dropdownStyleData: DropdownStyleData(
                                  maxHeight: 260,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: Colors.white,
                                  ),
                                  offset: const Offset(0, -6),
                                  scrollbarTheme: ScrollbarThemeData(
                                    radius: const Radius.circular(40),
                                    thickness: WidgetStateProperty.all(6),
                                    thumbVisibility:
                                        WidgetStateProperty.all(true),
                                  ),
                                ),
                                menuItemStyleData: const MenuItemStyleData(
                                  height: 44,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),
                          labeledField(
                            label: translate('pettycash.description'),
                            child: TextField(
                              maxLines: 3,
                              style: fieldTextStyle(false),
                              onChanged: (value) => setState(() => description = value),
                              decoration: pillDecoration(hintText: translate('pettycash.description')),
                            ),
                          ),

                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6E6E6E),
                                shape: const StadiumBorder(),
                                elevation: 0,
                              ),
                              onPressed: isSubmitting ? null : submitExpense,
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      '+ ADD EXPENSE',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
