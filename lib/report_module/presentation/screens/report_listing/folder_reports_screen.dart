import 'package:el_race/report_module/core/constants/colors.dart';
import 'package:el_race/report_module/core/constants/text_styles.dart';
import 'package:el_race/report_module/data/models/folder_model.dart';
import 'package:el_race/report_module/data/provider/reports_provider.dart';
import 'package:el_race/report_module/data/repositories/company_repository.dart';
import 'package:el_race/report_module/presentation/bottom_sheets/show_option_sheet.dart';
import 'package:el_race/report_module/presentation/dialogs/add_report.dart';
import 'package:el_race/report_module/presentation/dialogs/rename_report_dialog.dart';
import 'package:el_race/report_module/presentation/screens/report_listing/report_app_home_screen.dart';
import 'package:el_race/report_module/presentation/widgets/bottom_appbar.dart';
import 'package:el_race/report_module/presentation/widgets/square_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/report_tile.dart';

class FolderReportScreen extends StatefulWidget {
  final FolderModel folder;
  const FolderReportScreen({super.key, required this.folder});

  @override
  State<FolderReportScreen> createState() => _FolderReportScreenState();
}

class _FolderReportScreenState extends State<FolderReportScreen> {
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    _loading = true;
    setState(() {});
    await Future.delayed(const Duration(seconds: 1)); //todo remove
    await reportProvider.fetchAllReports(folderID: widget.folder.id.toString());
    print(widget.folder.id.toString());
    _loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ReportProvider reportProviderListener =
        Provider.of<ReportProvider>(context);
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Image.asset(
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
                await showAddNewReport(context,
                    type: 1, folderID: widget.folder.id.toString());
                setState(() {});
                return;
              },
            ),
          ),
        ],
        bottom: getBottomAppBar(context),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 20,
            color: CustomColors.blue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.folder.name,
                  style: CustomTextStyle.reportHeader,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount:
                  (_loading ? 10 : 0) + reportProviderListener.reports.length,
              itemBuilder: (context, index) {
                if (_loading) {
                  return showFolderOrReportLoader();
                } else {
                  return ReportTile(
                    report: reportProviderListener.reports[index],
                    onMoreClicked: () async {
                      int selectedOptionStatus = await showEditOptions(context,
                          options: ['rename', 'delete']);

                      if (selectedOptionStatus == 0) {
                        if (!context.mounted) return;
                        await showRenameReport(context,
                            report: reportProviderListener.reports[index]);
                        return;
                      }
                      if (selectedOptionStatus == 1) {
                        if (!context.mounted) return;
                        int deleteCodeStatus = await showEditOptions(context,
                            options: ['Confirm Delete', 'Cancel']);
                        if (deleteCodeStatus == 0) {
                          reportProvider.deleteReport(
                              reportId:
                                  reportProviderListener.reports[index].id);
                          return;
                        }
                      }
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
