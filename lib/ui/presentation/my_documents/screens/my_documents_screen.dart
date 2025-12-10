import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:file_picker/file_picker.dart';
import 'package:el_race/ui/widgets/back_icon.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../widgets/custom_slider_button.dart';

class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({
    super.key,
  });

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  int currentIndex = 0;
  List<Map<String, dynamic>> documents = [];
  bool _loading = false;
  String? _error;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _showSearch = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetchMyDocuments();

    _searchController.addListener(() {
      final text = _searchController.text.trim();
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() {
          _query = text.toLowerCase();
        });
        // Server-side search
        _fetchMyDocuments(keyword: text);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool _isFamilyDoc(Map<String, dynamic> raw) {
    final map = raw;
    final typeStr =
        (map['type'] ?? map['document_type'] ?? map['category'] ?? '')
            .toString()
            .toLowerCase();
    final titleStr = (map['title'] ?? '').toString().toLowerCase();
    final isFamilyFlag = map['is_family'] == true || map['family'] == true;
    return isFamilyFlag ||
        typeStr.contains('family') ||
        titleStr.contains('family');
  }

  Future<void> _fetchMyDocuments({String? keyword}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = SharedPref.getLoginData().result?.token ?? '';
      final url =
          Uri.parse('https://test.elrace.com/api/get_employee_documents');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Determine family_only based on currentIndex (0 = personal, 1 = family)
      final bool familyOnly = currentIndex == 1;

      final Map<String, dynamic> params = {
        'family_only': familyOnly,
      };

      final body = jsonEncode({'jsonrpc': '2.0', 'params': params});

      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['result'] != null &&
          data['result']['status'] == 'success') {
        final List list = (data['result']['data'] ?? []) as List;
        final mapped = list.map<Map<String, dynamic>>((raw) {
          final map = raw as Map<String, dynamic>;
          final type = (map['type'] ?? 'DOCUMENT').toString();
          final name = (map['name'] ?? '').toString();

          String icon = 'assets/png/document_icon.png';
          final t = type.toLowerCase();
          if (t.contains('emirates') || t.contains('id'))
            icon = 'assets/png/emitates_id.png';
          else if (t.contains('passport'))
            icon = 'assets/png/passport.png';
          else if (t.contains('license') || t.contains('labor'))
            icon = 'assets/png/driving_license.png';
          else if (t.contains('profile')) icon = 'assets/png/profile_image.png';

          return {
            'id': map['id'],
            'icon': icon,
            'title': type.toUpperCase(),
            'name': name,
            'issue_date': map['issue_date'],
            'expiry_date': map['expiry_date'],
            'description': map['description'],
            'attachment_ids': map['attachment_ids'] ?? [],
            '_isFamily': familyOnly,
          };
        }).toList();

        // Apply search filter if keyword is provided
        final filteredMapped = keyword != null && keyword.trim().isNotEmpty
            ? mapped.where((d) {
                final title = (d['title'] ?? '').toString().toLowerCase();
                final name = (d['name'] ?? '').toString().toLowerCase();
                final searchTerm = keyword.toLowerCase();
                return title.contains(searchTerm) || name.contains(searchTerm);
              }).toList()
            : mapped;

        setState(() {
          documents = filteredMapped;
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['result']?['message']?.toString() ??
              data['error']?.toString() ??
              'Failed to load documents';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filteredDocs() {
    // Documents are already filtered by family_only from API
    // Just return them as is since filtering happens server-side
    return documents;
  }

  Widget _buildInlineSearchField() {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/png/bg_atten.png'),
          fit: BoxFit.none,
        ),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(29.w),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.2 * 255).toInt()),
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Find document',
          prefixIcon: Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.search, size: 18, color: appFontColor),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        ),
      ),
    );
  }

  // @override
  // void initState() {
  //   super.initState();
  //   Future.delayed(const Duration(seconds: 5), () {
  //     if (mounted) showBabyGirlPopup(context);
  //   });
  // }

  final List<Map<String, dynamic>> notificationType = [
    {
      'icon': 'assets/png/folder.png',
      'title': translate('home.documents'),
    },
    {
      'icon': 'assets/png/family.png',
      'title': translate('home.family_document'),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderWidget(),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const BackIcon(),
              if (!_showSearch)
                Text(
                  translate('home.documents'),
                  style: GoogleFonts.koulen(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w600,
                    color: appFontColor,
                    letterSpacing: 1.5,
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildInlineSearchField(),
                ),
              Positioned(
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        _searchController.clear();
                        _query = '';
                        // fetch all when closing search
                        _fetchMyDocuments(keyword: '');
                      }
                    });
                  },
                  child: Image.asset('assets/png/search.png',
                      width: 35.w, height: 35.w),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(
                    height: 55.w,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      itemCount: notificationType.length,
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        String notificationIcon =
                            notificationType[index]['icon'];
                        String notificationTitle =
                            notificationType[index]['title'];

                        // Select icon based on selection state
                        String displayIcon;
                        if (index == 0) {
                          // My Documents tab
                          displayIcon = index == currentIndex
                              ? notificationIcon
                              : 'assets/png/folder_unfocus.png';
                        } else {
                          // Family Documents tab
                          displayIcon = index == currentIndex
                              ? 'assets/png/family_focus.png'
                              : notificationIcon;
                        }

                        return InkWell(
                          onTap: () {
                            setState(() => currentIndex = index);
                            _fetchMyDocuments(); // Re-fetch with new family_only value
                          },
                          child: Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: index == currentIndex
                                  ? appFontColor
                                  : greyText2,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withAlpha((0.1 * 255).toInt()),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  displayIcon,
                                  height: 25.w,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  notificationTitle.toUpperCase(),
                                  style: GoogleFonts.koulen(
                                    color: index == currentIndex
                                        ? Colors.white
                                        : const Color(0xFF1A237E),
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(
                        width: 10,
                      ),
                    ),
                  ),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: List.generate(3, (dotIndex) {
                  //     return Container(
                  //       margin: const EdgeInsets.symmetric(horizontal: 4),
                  //       width: 8,
                  //       height: 8,
                  //       decoration: BoxDecoration(
                  //         shape: BoxShape.circle,
                  //         color: dotIndex == currentIndex ? Colors.black : Colors.grey[400],
                  //       ),
                  //     );
                  //   }),
                  // ),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.only(left: 20.w),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.18),
                          border: Border.all(
                            color: const Color(0xffD9D9D9),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 13.5.w,
                                vertical: 8.5.h,
                              ),
                              child: Text(
                                'total : ${_filteredDocs().length}',
                                style: GoogleFonts.aBeeZee(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: .10,
                                  color: const Color(0xff949494),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15.h),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Center(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredDocs().length +
                            1, // +1 for Add New Document card
                        itemBuilder: (context, index) {
                          // First item is "Add New Document"
                          if (index == 0) {
                            return GestureDetector(
                              onTap: () {
                                showDocumentDialog(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30.18),
                                  border: Border.all(
                                    color: const Color(0xffD9D9D9),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset('assets/png/add_doc.svg'),
                                    SizedBox(height: 10.h),
                                    Text(
                                      'Add New Document',
                                      style: GoogleFonts.aBeeZee(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.italic,
                                        letterSpacing: .10,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Regular document cards
                          final item = _filteredDocs()[index - 1];

                          // Check if document is expired
                          bool isExpired = false;
                          if (item['expiry_date'] != null &&
                              item['expiry_date'] != false) {
                            try {
                              final expiryDate = DateTime.parse(
                                  item['expiry_date'].toString());
                              isExpired = expiryDate.isBefore(DateTime.now());
                            } catch (e) {
                              // If parsing fails, not expired
                              isExpired = false;
                            }
                          }

                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.18),
                              border: Border.all(
                                color: isExpired
                                    ? const Color(0xFFBA1719)
                                    : const Color(0xffD9D9D9),
                                width: isExpired ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(item['icon']),
                                SizedBox(height: 8.h),
                                Text(
                                  item['title'],
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.koulen(
                                    fontSize: 11.35,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: .10,
                                    color: const Color(0xff949494),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  item['name'],
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.aBeeZee(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: .10,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 30,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void showDocumentDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: const DocumentDialog(),
        );
      },
    );

    // If document was added successfully, refresh the list
    if (result == true) {
      print('🔄 Refreshing documents list...');
      _fetchMyDocuments();
    }
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: -0.8, // in radians (not degrees)
                child: const Icon(
                  Icons.attachment,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "ATTACHMENTS",
                style: GoogleFonts.koulen(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  //letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 🔸 LPO No
          Row(
            children: [
              const Icon(Icons.tag, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                "LPO NO",
                style: GoogleFonts.koulen(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 🔸 Vendor Name
          Row(
            children: [
              const Icon(Icons.handshake, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                "VENDOR NAME",
                style: GoogleFonts.koulen(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 🔸 Project Name
          Row(
            children: [
              const Icon(Icons.business_center, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Text(
                "PROJECT NAME",
                style: GoogleFonts.koulen(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // 🔘 Button
          Center(
            child: SizedBox(
              width: 180,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF191F52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: -0.8, // in radians (not degrees)
                      child: const Icon(
                        Icons.attachment,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "VIEW ATTACHMENT",
                      style: GoogleFonts.koulen(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
//   void showBabyGirlPopup(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       barrierColor: Colors.black.withAlpha((0.5 * 255).toInt()),
//       builder: (BuildContext context) {
//         return Dialog(
//           backgroundColor: Colors.white.withAlpha((0.95 * 255).toInt()),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(28),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   "🎉 Congratulations ✨",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w800,
//                     color: Colors.black,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   "Congratulations to",
//                   style: TextStyle(fontSize: 13, color: Colors.black),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 5),
//                 const Text(
//                   "Eng. Hassan Abuebied",
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 14),
//                 const Text(
//                   "on the arrival of his baby girl! 🎀✨ Wishing her a life filled with love, joy, and endless blessings. May she bring happiness and prosperity to the family! 💖👶🏼",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 13,
//                     height: 1.5,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Image.asset(
//                   'assets/png/Baby_girl.png',
//                   height: 80,
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
}

class DocumentDialog extends StatefulWidget {
  const DocumentDialog({Key? key}) : super(key: key);

  @override
  State<DocumentDialog> createState() => _DocumentDialogState();
}

class _DocumentDialogState extends State<DocumentDialog> {
  final TextEditingController _idController = TextEditingController();
  DateTime? _expiryDate;
  String? _selectedType;
  List<String> _types = [
    'Passport',
    'Labor Card',
    'Medical Insurance',
    'Emirates ID ',
    'photo',
    'CV',
    'Certifications',
  ]; // adjust
  String? _attachedFileName;
  String? _attachedFilePath;
  bool _isUploading = false;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 50)),
      lastDate: DateTime(now.year + 50),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.blueGrey, // header background
            onPrimary: Colors.white, // header text
            onSurface: Colors.black, // body text
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFileName = result.files.single.name;
          _attachedFilePath = result.files.single.path;
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  Future<void> _submit() async {
    // Validate required fields (only document type and ID number)
    final id = _idController.text.trim();
    if ((_selectedType ?? '').isEmpty || id.isEmpty) {
      print('❌ Validation failed: Missing required fields');
      _showErrorDialog('Please fill in document type and ID number.');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final token = SharedPref.getLoginData().result?.token ?? '';
      final userName = SharedPref.getLoginData().result?.data?.name ?? '';
      final url =
          Uri.parse('https://test.elrace.com/api/upload_employee_document');

      // Debug: Check values before sending
      print('🔍 Debug - userName: "$userName"');
      print('🔍 Debug - selectedType: "$_selectedType"');
      print('🔍 Debug - id: "$id"');

      if (userName.isEmpty) {
        print('❌ Error: userName is empty!');
        return;
      }

      if (_selectedType == null || _selectedType!.isEmpty) {
        print('❌ Error: selectedType is null or empty!');
        return;
      }

      // Map document type to document_type_id
      final Map<String, int> documentTypeIds = {
        'Passport': 1,
        'Labor Card': 2,
        'Medical Insurance': 3,
        'Emirates ID': 4,
        'photo': 5,
        'CV': 6,
        'Certifications': 7,
      };

      final documentTypeId = documentTypeIds[_selectedType] ?? 1;

      // Read file and convert to base64
      final file = File(_attachedFilePath!);
      final bytes = await file.readAsBytes();
      final base64File = base64Encode(bytes);

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final params = {
        'name': id, // Using ID number as name field
        'document_type_id': documentTypeId,
        'issue_date': _expiryDate?.toIso8601String().split('T')[0],
        'expiry_date': _expiryDate?.toIso8601String().split('T')[0],
        'description': 'Document uploaded via mobile app',
        'attachment': base64File,
        'attachment_filename': _attachedFileName,
      };
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'params': params,
      });

      print('📤 Uploading document...');
      print(
          '📦 Request params: ${jsonEncode(params..remove('file_data'))}'); // Don't print file_data (too long)
      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);

      print('📥 Upload response: ${response.body}');

      if (response.statusCode == 200 &&
          data['result'] != null &&
          data['result']['status'] == 'success') {
        print('✅ Document uploaded successfully!');
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        final errorMessage = data['result']?['message'] ??
            data['error']?['message'] ??
            'Upload failed';
        if (mounted) {
          _sliderKey.currentState?.resetSlider();
          _showErrorDialog(errorMessage);
        }
      }
    } catch (e) {
      print('❌ Upload error: $e');
      if (mounted) {
        _sliderKey.currentState?.resetSlider();
        _showErrorDialog('An error occurred while uploading the document.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Document uploaded successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context)
                  .pop(true); // Close DocumentDialog and refresh
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    // Close the DocumentDialog first
    Navigator.of(context).pop();

    // Then show the error dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  final GlobalKey<CustomSliderButtonState> _sliderKey = GlobalKey();
  Future<void> _submitExpense() async {
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    final expiryText = _expiryDate == null
        ? 'Expiry date'
        : DateFormat.yMMMd().format(_expiryDate!);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            image: const DecorationImage(
                image: AssetImage("assets/png/documents_back.png"),
                fit: BoxFit.fill),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MY DOCUMENTS',
                style: GoogleFonts.koulen(
                  color: HexColor("#002E6B"),
                  fontWeight: FontWeight.w400,
                  fontSize: 20,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16), // Document type dropdown
              _buildFieldWrapper(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Center(
                      child: const Text(
                        'document type',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    value: _selectedType,
                    items: _types
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                t,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedType = v),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ID Number field
              _buildFieldWrapper(
                child: TextField(
                  controller: _idController,
                  textAlign: TextAlign.center,
                  onTapOutside: (v) {
                    FocusScope.of(context).unfocus();
                  },
                  decoration: const InputDecoration(
                    hintText: 'ID Number',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Expiry date field with icon
              GestureDetector(
                onTap: _pickDate,
                child: _buildFieldWrapper(
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            expiryText,
                            style: TextStyle(
                              color: _expiryDate == null
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today_outlined, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Attach files
              InkWell(
                onTap: _pickFile,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/png/Upload cloud.png',
                        width: 20, height: 20),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        Text(
                          _attachedFileName == null
                              ? 'Attach Files'
                              : _attachedFileName!,
                          style: GoogleFonts.koulen(
                            color: HexColor("#002E6B"),
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                        if (_attachedFileName == null)
                          Container(
                            height: 1.5,
                            width: 80,
                            color: HexColor("#002E6B"),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18), // Submit button

              CustomSliderButton(
                key: _sliderKey,
                onSlideComplete: _submitExpense,
                loginResponseModel: SharedPref.getLoginData(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldWrapper({required Widget child}) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // small shadow for the inset feel
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
