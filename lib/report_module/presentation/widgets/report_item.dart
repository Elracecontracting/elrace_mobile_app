import 'dart:io';

import 'package:el_race/report_module/core/constants/colors.dart';
import 'package:el_race/report_module/core/constants/text_styles.dart';
import 'package:el_race/report_module/data/models/report_item_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportItem extends StatelessWidget {
  final ReportItemModel item;
  final VoidCallback onMoreClicked;
  final VoidCallback onTap;
  final int index;
  const ReportItem(
      {super.key,
      required this.item,
      required this.onMoreClicked,
      required this.onTap,
      required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: CustomColors.containerColor),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                  color: CustomColors.white,
                                  borderRadius: BorderRadius.circular(8)),
                              child: item.type == "text"
                                  ? Center(
                                      child: Image.asset(
                                      "assets/png/text.png",
                                      height: 28,
                                      width: 28,
                                    ))
                                  : Image.file(
                                      File(item.image),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.location,
                                          style: CustomTextStyle.reportHeader
                                              .copyWith(
                                                  // fontWeight: FontWeight.w500,
                                                  color: CustomColors.black),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 20,
                                      )
                                    ],
                                  ),
                                  if (item.description != "")
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        item.description,
                                        style: CustomTextStyle.reportHeader
                                            .copyWith(
                                                fontWeight: FontWeight.normal,
                                                color: CustomColors.black),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                              onTap: onMoreClicked,
                              child: const Icon(Icons.more_vert_rounded)),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle_rounded),
                          )
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    DateFormat("dd MMM yyyy HH:mma").format(item.createdAt),
                    style: CustomTextStyle.smallGrey,
                  ),
                ],
              ),
              // Positioned(
              //     right: 0,
              //     top: 0,
              //     bottom: 0,
              //     child: )
            ],
          ),
        ),
      ),
    );
  }
}
