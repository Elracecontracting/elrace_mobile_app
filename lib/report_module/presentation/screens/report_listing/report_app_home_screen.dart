import 'package:el_race/report_module/core/constants/colors.dart';
import 'package:el_race/report_module/core/constants/text_styles.dart';
import 'package:el_race/report_module/core/utils/flush_bar.dart';
import 'package:el_race/report_module/data/models/folder_model.dart';
import 'package:el_race/report_module/data/provider/reports_provider.dart';
import 'package:el_race/report_module/data/repositories/company_repository.dart';
import 'package:el_race/report_module/presentation/bottom_sheets/show_option_sheet.dart';
import 'package:el_race/report_module/presentation/dialogs/add_report.dart';
import 'package:el_race/report_module/presentation/screens/company/company_screen.dart';
import 'package:el_race/report_module/presentation/widgets/bottom_appbar.dart';
import 'package:el_race/report_module/presentation/widgets/square_button.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../widgets/folder_tile.dart';

class ReportAppHomeScreen extends StatefulWidget {
  const ReportAppHomeScreen({super.key});

  @override
  State<ReportAppHomeScreen> createState() => _ReportAppHomeScreenState();
}

class _ReportAppHomeScreenState extends State<ReportAppHomeScreen> {
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getData();
    });
  }

  getData() async {
    await CompanyRepository().getCompany(); // ✅ Ensure company is set
    ReportProvider().init(base: "https://test.elrace.com");
    isLoading = true;
    setState(() {});
    await reportProvider.fetchAllFolders();
    isLoading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ReportProvider reportProviderListener =
        Provider.of<ReportProvider>(context);
    return Scaffold(
      backgroundColor: CustomColors.white,
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 70,
        leading: SquareButton(
          icon: Icons.keyboard_backspace,
          color: CustomColors.white,
          borderColor: CustomColors.black,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: CustomColors.white,
        title: CompanyRepository.company == null
            ? const SizedBox(height: 60) // Or a placeholder
            : Image.asset(
                CompanyRepository.company!.logo,
                height: 60,
              ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SquareButton(
              icon: Icons.add,
              color: CustomColors.blue,
              borderColor: CustomColors.white,
              onPressed: () async {
                int selectedOptionStatus =
                    await showEditOptions(context, options: ['Add Folder']);

                if (selectedOptionStatus == 0) {
                  if (!context.mounted) return;
                  await showAddNewReport(context, type: 2);
                  if (!mounted) return;
                  setState(() {});
                  return;
                }
              },
            ),
          ),
        ],
        bottom: getBottomAppBar(context, edit: true, onClick: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CompanyInfoScreen()));
          await CompanyRepository().getCompany();
          reportProvider.fetchAllFolders();
          setState(() {});
        }),
      ),
      body: reportProviderListener.folders.isEmpty && !isLoading
          ? Center(
              child: Text(
                "No Report Added Yet",
                style:
                    CustomTextStyle.heading.copyWith(color: CustomColors.black),
              ),
            )
          : !isLoading && reportProviderListener.folders.length == 0
              ? Center(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      int selectedOptionStatus = await showEditOptions(context,
                          options: ['Add Folder']);

                      if (selectedOptionStatus == 0) {
                        if (!context.mounted) return;
                        await showAddNewReport(context, type: 2);
                        if (!mounted) return;
                        setState(() {});
                        return;
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "New Folder",
                          style: CustomTextStyle.heading.copyWith(color: black),
                        ),
                        Image.asset("assets/png/icons/add_folder.png")
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: (isLoading ? 10 : 0) +
                      reportProviderListener.folders.length,
                  itemBuilder: (context, index) {
                    return isLoading
                        ? showFolderOrReportLoader()
                        : FolderTile(
                            folder: reportProviderListener.folders[index],
                            onMoreClicked: () async {
                              int selectedOptionStatus = await showEditOptions(
                                  context,
                                  options: ['rename', 'delete']);
                              if (selectedOptionStatus == 0) {
                                if (!context.mounted) return;
                                showFlushBar(context,
                                    message:
                                        "Rename function for folder is not available at the moment");
                                return;
                              }
                              if (selectedOptionStatus == 1) {
                                if (!context.mounted) return;
                                int deleteCodeStatus = await showEditOptions(
                                    context,
                                    options: ['Confirm Delete', 'Cancel']);
                                if (deleteCodeStatus == 0) {
                                  showFlushBar(context,
                                      message:
                                          "Delete function for folder is not available at the moment.");
                                  return;
                                }
                              }
                            },
                          );
                  },
                ),
    );
  }
}

Skeletonizer showFolderOrReportLoader() {
  return Skeletonizer(
    enabled: true,
    child: FolderTile(
      folder: FolderModel(
        name: "name",
        createdAt: DateTime.now(),
        companyId: 1,
        description: '',
        updatedAt: DateTime.now(),
        id: "1",
      ),
      onMoreClicked: () async {},
    ),
  );
}
