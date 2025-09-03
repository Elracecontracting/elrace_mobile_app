import 'package:el_race/ui/presentation/lpo/widgets/lpo_card_widget.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class LpoListScreen extends StatefulWidget {
  const LpoListScreen({super.key});

  @override
  State<LpoListScreen> createState() => _LpoListScreenState();
}

class _LpoListScreenState extends State<LpoListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();

  // }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {}
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: Column(
        children: [
          // 🔹 Always-visible header
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              Row(
                children: [
                  SvgPicture.asset(
                    "assets/png/lpo_blue.svg",
                    height: 30.w,
                    width: 30.w,
                  ),
                  Text(
                    ' LPO',
                    style: GoogleFonts.koulen(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w500,
                      color: appFontColor,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {},
                  child: Image.asset(
                    'assets/png/search.png',
                    width: 35.w,
                    height: 35.w,
                  ),
                ),
              ),
            ],
          ),

          // 🔹 Expanded so list or loading takes remaining space
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 10),
              controller: _scrollController,
              itemCount: 5, // ✅ Removed header from list
              itemBuilder: (context, index) {
                return const LpoCardWidget();
              },
              separatorBuilder: (context, index) => const SizedBox(height: 10),
            ),
          ),
        ],
      ),
    );
  }
}
