import 'dart:io';
import 'package:el_race/report_module/core/constants/text_styles.dart';
import 'package:el_race/report_module/core/utils/directory_operation.dart';
import 'package:el_race/report_module/data/models/report_item_model.dart';
import 'package:el_race/report_module/data/models/report_model.dart';
import 'package:el_race/report_module/data/provider/reports_provider.dart';
import 'package:el_race/report_module/data/repositories/company_repository.dart';
import 'package:el_race/report_module/presentation/screens/report_detail/pdf_history_screen.dart';
import 'package:el_race/report_module/core/constants/colors.dart';
import 'package:el_race/report_module/presentation/bottom_sheets/show_option_sheet.dart';
import 'package:el_race/report_module/presentation/screens/report_detail/add_cover_screen.dart';
import 'package:el_race/report_module/presentation/screens/report_detail/add_new_item.dart';
import 'package:el_race/report_module/presentation/screens/report_detail/camera_screen.dart';
import 'package:el_race/report_module/presentation/widgets/bottom_appbar.dart';
import 'package:el_race/report_module/presentation/widgets/report_item.dart';
import 'package:el_race/report_module/presentation/widgets/square_button.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../data/models/report_detail_model.dart';
import '../../widgets/cover_page.dart';

class ReportDetailScreen extends StatefulWidget {
  final ReportModel report;
  final String folderName;
  const ReportDetailScreen(
      {super.key, required this.report, required this.folderName});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  ReportDetailModel? reportDetail;

  @override
  void initState() {
    super.initState();
    _loadUpdatedRecord();
  }

  bool _loading = true;
  String loadingText = "";

  Future<void> _loadUpdatedRecord() async {
    loadingText = "";
    _loading = true;
    setState(() {});
    reportDetail = ReportDetailModel(
      report: widget.report,
      coverPage: null,
      reportItems: [],
    );

    reportDetail = await reportProvider.getReportDetail(widget.report) ??
        ReportDetailModel(
          report: widget.report,
          coverPage: null,
          reportItems: [],
        );
    _loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: CustomColors.white,
        centerTitle: true,
        leadingWidth: 70,
        leading: SquareButton(
          icon: Icons.keyboard_backspace,
          color: CustomColors.white,
          borderColor: CustomColors.black,
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          CompanyRepository.company!.logo,
          height: 60,
        ),
        bottom: getBottomAppBar(context,
            folderName: widget.folderName, report: reportDetail),
        actions: [
          SquareButton(
            icon: Icons.share_outlined,
            color: CustomColors.maroon,
            borderColor: CustomColors.white,
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PdfCreationScreen(
                            reportDetailModel: reportDetail!,
                            folderName: widget.folderName,
                          )));
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      floatingActionButton: SquareButton(
        icon: Icons.add,
        color: CustomColors.maroon,
        borderColor: CustomColors.white,
        onPressed: _showAddOptions,
      ),
      body: reportDetail != null
          ? Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: 50),
                  children: [
                    if (reportDetail!.coverPage != null)
                      CoverPageTile(
                        data: reportDetail!.coverPage!,
                        onMoreClicked: () async {
                          int status = await showEditOptions(context,
                              options: ["Edit", "Delete"]);
                          if (status == 0) {
                            _addNewCover();
                            return;
                          }
                          if (status == 1) {
                            if (!context.mounted) return;
                            int status = await showEditOptions(context,
                                options: ["Confirm Delete", "Cancel"]);
                            if (status == 0) {
                              setState(() {});
                              bool status = await reportProvider
                                  .deleteCoverPage(reportDetail!);
                              if (status) {
                                reportDetail =
                                    reportDetail!.copyWith(coverPage: null);
                              }
                              return;
                            }
                          }
                        },
                      ),
                    ReorderableList(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) => ReportItem(
                            key: Key(reportDetail!.reportItems[index].id),
                            item: reportDetail!.reportItems[index],
                            index: index,
                            onTap: () {
                              _openItemDetail(reportDetail!.reportItems[index]);
                            },
                            onMoreClicked: () async {
                              await _deleteItems(
                                  reportDetail!.reportItems[index]);
                            }),
                        itemCount: reportDetail!.reportItems.length,
                        onReorder: (int oldIndex, int newIndex) async {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final ReportItemModel movedItem =
                                reportDetail!.reportItems.removeAt(oldIndex);
                            reportDetail!.reportItems
                                .insert(newIndex, movedItem);
                          });
                          await reportProvider
                              .updateReportDetail(reportDetail!);
                          _loadUpdatedRecord();
                        }),
                    if (_loading && loadingText == "") ...[
                      ...List.generate(
                          6,
                          (e) => Skeletonizer(
                                enabled: true,
                                child: ReportItem(
                                  item: ReportItemModel(
                                      id: "0",
                                      reportId: "reportId",
                                      type: "text",
                                      image: "text",
                                      location: "location",
                                      description: "description",
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now()),
                                  onMoreClicked: () {},
                                  onTap: () {},
                                  index: 0,
                                ),
                              ))
                    ]
                  ],
                ),
                if (!_loading &&
                    reportDetail != null &&
                    reportDetail!.coverPage == null &&
                    reportDetail!.reportItems.isEmpty)
                  Center(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showAddOptions,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Add item to report",
                            style:
                                CustomTextStyle.heading.copyWith(color: black),
                          ),
                          Image.asset("assets/png/icons/add_image.png")
                        ],
                      ),
                    ),
                  ),
                if (_loading && loadingText != "")
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: CustomColors.maroon,
                          borderRadius: BorderRadius.circular(8)),
                      height: 80,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          LinearProgressIndicator(
                            color: CustomColors.blue,
                          ),
                          Text(
                            loadingText,
                            style: CustomTextStyle.reportHeader,
                          ),
                          LinearProgressIndicator(
                            color: CustomColors.blue,
                          ),
                        ],
                      ),
                      // width: 600,
                    ),
                  )
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  //adding options for report start
  _showAddOptions([bool insideSection = false]) async {
    List<String> options = [
      "Image From Gallery",
      "Image From Camera",
      // "Add New Section",
      // "Add Text Block",
      // "Add Cover Page",
    ];
    if (insideSection) {
      options = [
        "Image From Gallery",
        "Image From Camera",
        // "Add Text Block",
      ];
    }

    int selectedOptionIndex = await showEditOptions(context, options: options);
    if (selectedOptionIndex == 0) {
      _addGalleryImage();
      return;
    }
    if (selectedOptionIndex == 1) {
      _addCameraImage();
      return;
    }
    if (selectedOptionIndex == 2) {
      _addNewText();
      return;
    }
    if (selectedOptionIndex == 3) {
      _addNewCover();
      return;
    }
  }

  Future<void> _addNewCover() async {
    var result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AddCoverScreen(
                  reportDetail: reportDetail!,
                  folderName: widget.folderName,
                )));
    if (result != null) {
      reportDetail = result;
    }
    setState(() {});
    await _loadUpdatedRecord();
  }

  Future<void> _addCameraImage() async {
    var result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const CustomCameraScreen(
                  onePicture: false,
                )));

    if (result.isNotEmpty) {
      loadingText = "";

      _loading = true;
      setState(() {});
      for (XFile image in result) {
        loadingText = "images is uploading";
        ReportItemModel _newItem = ReportItemModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            reportId: reportDetail!.report.id,
            type: "image",
            image: await saveImageToAppStorage(
                File(image.path),
                reportDetail!.report.folderId.toString() +
                    reportDetail!.report.folderId.toString()),
            location: "",
            description: "",
            createdAt: DateTime.now(),
            updatedAt: DateTime.now());

        await reportProvider.updateReportDetail(
          reportDetail!.copyWith(
            reportItems: [...reportDetail!.reportItems, _newItem],
          ),
        );
        reportDetail = reportDetail!.copyWith(
          reportItems: [...reportDetail!.reportItems, _newItem],
        );
        setState(() {});
      }
      _loading = false;
      setState(() {});
      await _loadUpdatedRecord();
    }
  }

  Future<void> _addGalleryImage() async {
    ImagePicker imagePicker = ImagePicker();
    List<XFile>? result = await imagePicker.pickMultiImage(imageQuality: 60);
    if (result.isNotEmpty) {
      _loading = true;
      setState(() {});
      for (XFile image in result) {
        loadingText =
            "${result.indexWhere((e) => image == e)} of ${result.length} images is uploading";

        ReportItemModel _newItem = ReportItemModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            reportId: reportDetail!.report.id,
            type: "image",
            image: await saveImageToAppStorage(
                File(image.path),
                reportDetail!.report.folderId.toString() +
                    reportDetail!.report.folderId.toString()),
            location: "",
            description: "",
            createdAt: DateTime.now(),
            updatedAt: DateTime.now());

        await reportProvider.updateReportDetail(
          reportDetail!.copyWith(
            reportItems: [...reportDetail!.reportItems, _newItem],
          ),
        );

        reportDetail = reportDetail!.copyWith(
          reportItems: [...reportDetail!.reportItems, _newItem],
        );
        setState(() {});
      }
      _loading = false;
      loadingText = "";

      setState(() {});
      await _loadUpdatedRecord();
    }
  }

  Future<void> _addNewText() async {
    ReportItemModel? item = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AddNewItem(
                  report: reportDetail!,
                  folderName: widget.folderName,
                )));
    if (item != null) {
      List<ReportItemModel> items = reportDetail!.reportItems;
      items.add(item);
      reportDetail = reportDetail!.copyWith(reportItems: items);
      setState(() {});
    }
    await _loadUpdatedRecord();
  }

  _openItemDetail(ReportItemModel item) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AddNewItem(
                  report: reportDetail!,
                  item: item,
                  folderName: widget.folderName,
                )));
    await _loadUpdatedRecord();
  }

  _deleteItems(ReportItemModel item) async {
    int deleteStatus =
        await showEditOptions(context, options: ['Delete', 'Cancel']);
    if (!mounted || deleteStatus == 1 || deleteStatus == -1) return;
    int deleteCodeStatus =
        await showEditOptions(context, options: ['Confirm Delete', 'Cancel']);
    if (deleteCodeStatus == 0) {
      List<ReportItemModel> items = reportDetail!.reportItems;
      items.removeWhere((e) => e.id == item.id);
      reportDetail = reportDetail!.copyWith(reportItems: items);
      await reportProvider.updateReportDetail(reportDetail!);
      setState(() {});

      await _loadUpdatedRecord();
      return;
    }
  }
}
