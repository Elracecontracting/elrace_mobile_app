import 'package:el_race/report_module/core/constants/colors.dart';
import 'package:el_race/report_module/core/constants/text_styles.dart';
import 'package:el_race/report_module/data/models/folder_model.dart';
import 'package:el_race/report_module/presentation/screens/report_listing/folder_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FolderTile extends StatelessWidget {
  final FolderModel folder;
  final VoidCallback onMoreClicked;
  const FolderTile(
      {super.key, required this.folder, required this.onMoreClicked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FolderReportScreen(folder: folder)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: CustomColors.containerColor),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        folder.name,
                        style: CustomTextStyle.reportTitle,
                      ),
                    ),
                    InkWell(
                    onTap: onMoreClicked,
                    child: const Icon(Icons.more_vert_rounded)),
                  ],
                ),
                Text(
                  DateFormat("dd MMM yyyy HH:mma").format(folder.createdAt),
                  style: CustomTextStyle.smallGrey,
                ),
                if (folder.description != "")
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      folder.description,
                      style: CustomTextStyle.smallGrey,
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: CustomColors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                  child: Text(
                    "Folder",
                    style: CustomTextStyle.smallWhite,
                  ),
                )
              ],
            ),
            // Positioned(
            //     right: 0,
            //     top: 0,
            //     child: ))
          ],
        ),
      ),
    );
  }
}
