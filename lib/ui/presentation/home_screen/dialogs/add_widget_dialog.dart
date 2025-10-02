import 'package:el_race/ui/presentation/home_screen/data/widget_model.dart';
import 'package:el_race/ui/presentation/home_screen/services/widget_service.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/card_tile.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/custom_bullet_point.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:el_race/utils/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';

class AddWidgetDialog extends StatefulWidget {
  final Function() onWidgetAdded;

  const AddWidgetDialog({
    super.key,
    required this.onWidgetAdded,
  });

  @override
  State<AddWidgetDialog> createState() => _AddWidgetDialogState();
}

class _AddWidgetDialogState extends State<AddWidgetDialog> {
  List<WidgetModel> availableWidgets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableWidgets();
  }

  Future<void> _loadAvailableWidgets() async {
    final widgets = await WidgetService.getAvailableWidgetsWithState();
    final inactiveWidgets = widgets.where((w) => !w.isActive).toList();
    
    setState(() {
      availableWidgets = inactiveWidgets;
      isLoading = false;
    });
  }

  Future<void> _addWidget(String widgetId) async {
    await WidgetService.toggleWidget(widgetId);
    widget.onWidgetAdded();
    Navigator.of(context).pop();
  }

  Widget _buildWidgetPreview(WidgetModel widget) {
    switch (widget.id) {
      case 'time_sheet':
        return _buildTimeSheetPreview();
      case 'petty_cash':
        return _buildPettyCashPreview();
      case 'lpo':
        return _buildLPOPreview();
      case 'documents':
        return _buildDocumentsPreview();
      case 'my_notes':
        return _buildMyNotesPreview();
      case 'projects':
        return _buildProjectsPreview();
      case 'my_request':
        return _buildMyRequestPreview();
      case 'media':
        return _buildMediaPreview();
      case 'my_report':
        return _buildMyReportPreview();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTimeSheetPreview() {
    return GrayCardComponent(
      onClick: null,
      mainIcon: 'assets/png/time_sheet.png',
      cardTitle: translate('home.time_sheet'),
      backgroundImagePath: 'assets/png/gray_card.png',
      topPadding: true,
      topPaddingValue: 40,
      childWidget: Padding(
        padding: EdgeInsets.only(left: 150.w),
        child: Image.asset(
          'assets/png/time_sheet.png',
          width: SizeConfig().getWidth(140),
          height: SizeConfig().getHeight(140),
        ),
      ),
    );
  }

  Widget _buildPettyCashPreview() {
    return const GrayCardComponent(
      onClick: null,
      cardTitle: 'Petty Cash',
      backgroundImagePath: 'assets/png/pettycash_new_bg.png',
      childWidget: SizedBox.shrink(),
    );
  }

  Widget _buildLPOPreview() {
    return GrayCardComponent(
      onClick: null,
      mainIcon: 'assets/png/time_sheet.png',
      cardTitle: 'LPO',
      backgroundImagePath: 'assets/png/gray_card.png',
      topPadding: true,
      topPaddingValue: 40,
      childWidget: Padding(
        padding: EdgeInsets.only(left: 170.w),
        child: Image.asset(
          'assets/png/lpo.png',
          width: SizeConfig().getWidth(140),
          height: SizeConfig().getHeight(140),
        ),
      ),
    );
  }

  Widget _buildDocumentsPreview() {
    return Stack(
      children: [
        GrayCardComponent(
          onClick: null,
          cardTitle: translate('home.documents'),
          backgroundImagePath: 'assets/png/gray_card.png',
          childWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              DefaultTextStyle(
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: Color(0xFF1A1A53),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 52),
                  child: SizedBox(
                    width: SizeConfig().getWidth(270),
                    height: SizeConfig().getHeight(50),
                    child: Image.asset('assets/newapp/simple_cards.png'),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 6,
          top: 30,
          child: Image.asset('assets/png/icons/doc_icon.png'),
        ),
      ],
    );
  }

  Widget _buildMyNotesPreview() {
    return Stack(
      children: [
        GrayCardComponent(
          cardTitle: translate('my notes'),
          backgroundImagePath: 'assets/png/blue_card.png',
          onClick: null,
          topPadding: true,
          childWidget: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: SizeConfig().getWidth(40),
                  height: SizeConfig().getHeight(150),
                  child: Image.asset(
                    'assets/png/not_icon.png',
                    color: const Color(0xff1A1A53),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                const CountWidget(count: '200', countColor: Colors.black, width: 30),
              ],
            ),
          ),
        ),
        Positioned(
          right: 6,
          top: 30,
          child: Opacity(
            opacity: 0.20,
            child: Image.asset('assets/png/notes_icon.png'),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsPreview() {
    return Stack(
      children: [
        GrayCardComponent(
          cardTitle: translate('home.projects'),
          backgroundImagePath: 'assets/png/gray_card.png',
          onClick: null,
          childWidget: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: SizedBox(
                width: SizeConfig().getWidth(190),
                height: SizeConfig().getHeight(80),
                child: const Column(
                  children: [
                    CustomBulletPoint(
                      bulletColor: Color(0xFF009859),
                      text: 'In progress',
                      textColor: Colors.black,
                      countColor: Colors.black,
                      count: '15',
                    ),
                    SizedBox(height: 4),
                    CustomBulletPoint(
                      bulletColor: Color(0xFFBA1719),
                      text: 'Delay',
                      textColor: Colors.black,
                      countColor: Colors.black,
                      count: '2',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 30,
          child: Opacity(
            opacity: .12,
            child: Image.asset('assets/newapp/my_projects.png'),
          ),
        ),
      ],
    );
  }

  Widget _buildMyRequestPreview() {
    return Stack(
      children: [
        GrayCardComponent(
          cardTitle: translate('home.my_request'),
          backgroundImagePath: 'assets/png/gray_card.png',
          onClick: null,
          childWidget: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: SizedBox(
                width: SizeConfig().getWidth(190),
                height: SizeConfig().getHeight(80),
                child: Column(
                  children: [
                    CustomBulletPoint(
                      bulletColor: const Color(0xFF009859),
                      text: translate('Approved'),
                      textColor: Colors.black,
                      countColor: Colors.black,
                      count: '5',
                    ),
                    CustomBulletPoint(
                      bulletColor: const Color(0xFFBA1719),
                      text: translate('home.rejected'),
                      textColor: Colors.black,
                      countColor: Colors.black,
                      count: '5',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: -40,
          child: Image.asset('assets/png/my_request.png'),
        ),
      ],
    );
  }

  Widget _buildMediaPreview() {
    return Stack(
      children: [
        GrayCardComponent(
          cardTitle: translate('Media'),
          backgroundImagePath: 'assets/png/gray_card.png',
          onClick: null,
          childWidget: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: SizedBox(
                width: SizeConfig().getWidth(190),
                height: SizeConfig().getHeight(80),
                child: Column(
                  children: [
                    CustomBulletPoint(
                      bulletColor: const Color(0xFF009859),
                      text: translate('videos'),
                      textColor: Colors.black,
                      countColor: Colors.black,
                      count: '7',
                    ),
                    CustomBulletPoint(
                      bulletColor: const Color(0xFFBA1719),
                      text: translate('photos'),
                      textColor: Colors.black,
                      countColor: Colors.black,
                      count: '20',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 30,
          child: Opacity(
            opacity: .20,
            child: Image.asset('assets/png/icons/media_icon.png'),
          ),
        ),
      ],
    );
  }

  Widget _buildMyReportPreview() {
    return GrayCardComponent(
      mainIcon: 'assets/png/my_documents.png',
      cardTitle: translate('home.my_report'),
      backgroundImagePath: 'assets/png/notes_new_bg.png',
      onClick: null,
      topPadding: true,
      childWidget: Container(
        width: SizeConfig().getWidth(200),
        height: SizeConfig().getHeight(67),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: SizeConfig().getWidth(55),
              height: SizeConfig().getHeight(42.11),
              child: Image.asset('$imagePrefixIcons/id_card.png'),
            ),
            SizedBox(width: SizeConfig().getWidth(20)),
            SizedBox(
              width: SizeConfig().getWidth(55),
              height: SizeConfig().getHeight(44.40),
              child: Image.asset('$imagePrefixIcons/licnc.png'),
            ),
            SizedBox(width: SizeConfig().getWidth(20)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: black.withAlpha((0.1 * 255).toInt()),
              spreadRadius: 2,
              blurRadius: 10,
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Widget',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF000F42),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.close,
                      color: const Color(0xFF858585),
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              if (isLoading)
                const CircularProgressIndicator()
              else if (availableWidgets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'All widgets are already added',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFF858585),
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Column(
                  children: availableWidgets.map((widget) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _addWidget(widget.id),
                        child: Stack(
                          children: [
                            _buildWidgetPreview(widget),
                            Positioned(
                              right: 1.w,
                              top: 1.w,
                              child: Container(
                                width: 36.w,
                                height: 36.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A53),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: black.withAlpha((0.2 * 255).toInt()),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: white,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 