import 'dart:ui';

import 'package:el_race/core/utils/shared_pref.dart';
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
    this.poId,
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
    this.onTap,
  });

  final int? poId;
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
  final VoidCallback? onTap;

  static final _amountFormat = NumberFormat('#,##0', 'en');

  String? _formatAmount(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.,]'), '');
    final value = double.tryParse(cleaned.replaceAll(',', ''));
    if (value == null) return raw;
    return _amountFormat.format(value);
  }

  String? _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = _formatAmount(amount);

    // Align header text (RQ/LPO number) with the start of the vendor/project text
    // column (to the right of: logo + gap + divider + gap).
    final headerStartPadding = 54.w + 14.w + 1.w + 14.w;

    final codeText = (name ?? '').trim().isNotEmpty
        ? name!.trim()
        : (poId != null)
            ? 'RCC/LPO/$poId'
            : 'RCC/LPO';

    final primaryTextRaw = (vendorName ?? '').trim().isNotEmpty
        ? vendorName!.trim()
        : (projectName ?? '').trim().isNotEmpty
            ? projectName!.trim()
            : '';

    final secondaryTextRaw = (vendorName ?? '').trim().isNotEmpty &&
            (projectName ?? '').trim().isNotEmpty
        ? projectName!.trim()
        : null;

    final primaryText = primaryTextRaw.toUpperCase();
    final secondaryText = secondaryTextRaw?.toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFB6B9C0), width: 1),
          gradient: const LinearGradient(
            colors: [Color(0xFFD8DADF), Color(0xFFC6C8CE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 48.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: headerStartPadding),
                      child: Text(
                        codeText,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0E3A76),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 54.w,
                        height: 54.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border:
                              Border.all(color: const Color(0xFFE6E7EA), width: 2),
                        ),
                        alignment: Alignment.center,
                        child: clientPhoto != null && clientPhoto!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  clientPhoto!,
                                  fit: BoxFit.contain,
                                  width: 54.w,
                                  height: 54.w,
                                  headers: {
                                    'Accept': 'image/*',
                                    'Authorization':
                                        'Bearer ${SharedPref.getLoginData().result?.token ?? ''}',
                                  },
                                  errorBuilder: (_, __, ___) =>
                                      _buildInitialsAvatar(),
                                ),
                              )
                            : _buildInitialsAvatar(),
                      ),
                      SizedBox(width: 14.w),
                      Container(
                        width: 1,
                        height: 54.h,
                        color: Colors.white.withOpacity(0.85),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              primaryText.isNotEmpty ? primaryText : '- ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                height: 1.1,
                              ),
                            ),
                            if (secondaryText != null)
                              Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: Text(
                                  secondaryText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6E6E6E),
                                    height: 1.1,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (formattedAmount != null && formattedAmount.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12.h,
                child: Center(
                  child: Text(
                    formattedAmount,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0E3A76),
                      letterSpacing: 0.3,
                    ),
                  ),
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
          : (name != null && name!.isNotEmpty)
              ? name!.characters.take(2).toString().toUpperCase()
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
