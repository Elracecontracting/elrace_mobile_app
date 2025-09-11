import 'dart:async';
import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/widgets/back_icon.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

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
      final url = Uri.parse('https://test.elrace.com/api/document_types');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final effectiveKeyword = (keyword ?? '').trim();
      final Map<String, dynamic> params = {};
      if (effectiveKeyword.isNotEmpty) {
        params['keyword'] = effectiveKeyword;
      }
      final body = jsonEncode({'jsonrpc': '2.0', 'params': params});

      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['result'] != null) {
        final List list = (data['result']['data'] ?? []) as List;
        final mapped = list.map<Map<String, dynamic>>((raw) {
          final map = raw as Map<String, dynamic>;
          final title = (map['title'] ??
                  map['type'] ??
                  map['document_type'] ??
                  'DOCUMENT')
              .toString();
          final name =
              (map['name'] ?? map['employee_name'] ?? map['holder_name'] ?? '')
                  .toString();
          String icon = 'assets/png/document_icon.png';
          final t = title.toLowerCase();
          if (t.contains('emirates'))
            icon = 'assets/png/emitates_id.png';
          else if (t.contains('passport'))
            icon = 'assets/png/passport.png';
          else if (t.contains('license'))
            icon = 'assets/png/driving_license.png';
          else if (t.contains('profile') || t.contains('id'))
            icon = 'assets/png/profile_image.png';

          return {
            'icon': icon,
            'title': title.toUpperCase(),
            'name': name,
            '_isFamily': _isFamilyDoc(map),
          };
        }).toList();

        setState(() {
          documents = mapped;
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['error']?.toString() ?? 'Failed to load documents';
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
    final base = documents.where((d) => currentIndex == 0
        ? (d['_isFamily'] != true)
        : (d['_isFamily'] == true));
    if (_query.isEmpty) return base.toList();
    return base.where((d) {
      final title = (d['title'] ?? '').toString().toLowerCase();
      final name = (d['name'] ?? '').toString().toLowerCase();
      return title.contains(_query) || name.contains(_query);
    }).toList();
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
                        return InkWell(
                          onTap: () => setState(() => currentIndex = index),
                          child: Container(
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: index == currentIndex
                                  ? appFontColor
                                  : greyText2,
                              // gradient: const LinearGradient(
                              //   colors: [Color(0xFFE6E6E6), ],
                              //   begin: Alignment.center,
                              //   end: Alignment.centerRight,
                              // ),
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
                            // child: Stack(
                            //   children: [
                            //     Column(
                            //       crossAxisAlignment: CrossAxisAlignment.start,
                            //       children: [
                            //         // Row(
                            //         //   mainAxisAlignment:
                            //         //       MainAxisAlignment.spaceBetween,
                            //         //   children: [
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  notificationIcon,
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
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //       horizontal: 8, vertical: 4),
                            //   decoration: BoxDecoration(
                            //     color: Colors.white,
                            //     borderRadius:
                            //         BorderRadius.circular(10),
                            //   ),
                            //   child: const Icon(
                            //     Icons.arrow_forward,
                            //     size: 16,
                            //     color: Color(0xFF2D2F81),
                            //   ),
                            // ),
                            //   ],
                            // ),
                            // const SizedBox(height: 6),
                            // Text(
                            //   translate(
                            //       'notification_screen.stay_updated'),
                            //   style: const TextStyle(
                            //     color: Colors.black87,
                            //     fontSize: 11,
                            //     fontWeight: FontWeight.bold,
                            //     height: 1.4,
                            //   ),
                            // ),
                            //       ],
                            //     ),
                            //   ],
                            // ),
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
                                'totla : ${_filteredDocs().length}',
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
                  Container(
                    width: 180.w,
                    height: 165.h,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.18),
                        border: Border.all(
                          color: const Color(0xffD9D9D9),
                        )),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/png/add_doc.svg'),
                        // Text(

                        //   style: GoogleFonts.koulen(
                        //     fontSize: 11.35,
                        //     fontWeight: FontWeight.w400,
                        //     letterSpacing: .10,
                        //     color: const Color(0xff949494),
                        //   ),
                        // ),
                        SizedBox(height: 10.h),
                        Text(
                          'Add New Document',
                          style: GoogleFonts.aBeeZee(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              letterSpacing: .10,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredDocs().length,
                      itemBuilder: (context, index) {
                        final item = _filteredDocs()[index];
                        return Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.18),
                              border: Border.all(
                                color: const Color(0xffD9D9D9),
                              )),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(item['icon']),
                              Text(
                                item['title'],
                                style: GoogleFonts.koulen(
                                  fontSize: 11.35,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: .10,
                                  color: const Color(0xff949494),
                                ),
                              ),
                              Text(
                                item['name'],
                                style: GoogleFonts.aBeeZee(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: .10,
                                    color: Colors.black),
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
                ],
              ),
            ),
          )
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
