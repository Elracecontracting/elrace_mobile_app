import 'dart:ui';

import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  bool _needsScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollNeeded();
    });
  }

  void _checkIfScrollNeeded() {
    if (!mounted) return;
    if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0) {
      setState(() {
        _needsScrolling = true;
      });
      _startScrolling();
    }
  }

  void _startScrolling() async {
    if (!mounted || !_needsScrolling) return;

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    while (mounted && _needsScrolling) {
      // Scroll to end slowly
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(
            milliseconds: (widget.text.length * 120).clamp(4000, 15000)),
        curve: Curves.linear,
      );

      if (!mounted) break;
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) break;

      // Jump back to start instantly (no animation)
      _scrollController.jumpTo(0);

      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
      ),
    );
  }
}

class LpoCardWidget extends StatelessWidget {
  const LpoCardWidget({
    super.key,
    this.name,
    this.vendorName,
    this.projectName,
    this.date,
    this.amount,
    this.attachments,
    this.lpoCount,
    this.clientPhoto,
    this.requestedByUserPhoto,
    this.requestedBy,
    this.requesterManager,
    this.state,
  });

  final String? name;
  final String? vendorName;
  final String? projectName;
  final String? date;
  final String? amount;
  final List<dynamic>? attachments;
  final String? lpoCount;
  final String? clientPhoto;
  final String? requestedByUserPhoto;
  final String? requestedBy;
  final String? requesterManager;
  final String? state;

  static final _amountFormat = NumberFormat('#,##0.00', 'en');

  String _formatAmount(String? raw) {
    if (raw == null || raw.isEmpty) return '-- AED';
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.,]'), '');
    final value = double.tryParse(cleaned.replaceAll(',', ''));
    if (value == null) return '${raw} AED';
    return '${_amountFormat.format(value)} AED';
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = _formatAmount(amount);
    final formattedDate = _formatDate(date);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF151544), Color(0xFF3535AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21.r),
          gradient: const LinearGradient(
            colors: [Color(0xFFD6D6D6), Color(0xFFADB2BD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Top row: Vendor logo and title section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT: Vendor Logo
                Container(
                  width: 62.w,
                  height: 62.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: clientPhoto != null && clientPhoto!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            clientPhoto!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildInitialsAvatar(),
                          ),
                        )
                      : _buildInitialsAvatar(),
                ),
                SizedBox(width: 16.w),
                // CENTER: Title + Vendor + Project
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      MarqueeText(
                        text: name ?? 'RCC-PO-XXXX',
                        style: GoogleFonts.koulen(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      _braceChip(vendorName ?? 'VENDOR NAME'),
                      SizedBox(height: 6.h),
                      _braceChip(projectName ?? 'PROJECT NAME'),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                SizedBox(width: 62.w), // Balance right side
              ],
            ),
            SizedBox(height: 14.h),
            // Bottom row: Amount + Avatar + Date (all aligned)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT: Amount with icon
                  Row(
                    children: [
                      Image.asset(
                        'assets/png/icons/Coin.png',
                        width: 24.w,
                        height: 24.w,
                        color: const Color(0xFF151544),
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.attach_money,
                          size: 24.w,
                          color: const Color(0xFF151544),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        formattedAmount,
                        style: GoogleFonts.koulen(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  // CENTER: User Avatar
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: requestedByUserPhoto != null &&
                              requestedByUserPhoto!.isNotEmpty
                          ? Image.network(
                              requestedByUserPhoto!,
                              fit: BoxFit.cover,
                              width: 40.w,
                              height: 40.w,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                size: 34.w,
                                color: appFontColor,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 34.w,
                              color: appFontColor,
                            ),
                    ),
                  ),
                  // RIGHT: Date with icon
                  Row(
                    children: [
                      Image.asset(
                        'assets/png/calender.png',
                        width: 24.w,
                        height: 24.w,
                        color: const Color(0xFF151544),
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.calendar_month,
                          size: 24.w,
                          color: const Color(0xFF151544),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Text(
      (vendorName != null && vendorName!.isNotEmpty)
          ? vendorName!.characters.take(2).toString().toUpperCase()
          : 'V',
      style: GoogleFonts.koulen(
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
        color: appFontColor,
      ),
    );
  }

  Widget _braceChip(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: Colors.white.withOpacity(0.25), // شفافية الزجاج
            border: Border.all(
              color: Colors.white.withOpacity(0.5), // إطار زجاجي
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: -2,
                offset: const Offset(-2, -2),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                spreadRadius: -2,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: MarqueeText(
            text: text,
            style: GoogleFonts.koulen(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

void showAttachmentDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: _buildDialogContent(context),
      );
    },
  );
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
                // TODO: Add your view attachment logic here
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
