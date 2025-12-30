import 'package:el_race/ui/presentation/my_projects/domain/entities/attachment_entity.dart';
import 'package:el_race/utils/Util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AttachmentWidget extends StatelessWidget {
  final AttachmentEntity item;

  const AttachmentWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    String fileIcon = 'assets/newapp/pdf.png';

    if (!item.type.contains("pdf")) fileIcon = 'assets/newapp/excel.png';
    

    return GestureDetector(
      onTap: () => Util.openUrl('https://erp.elrace.com${item.url}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12,),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(width: 1,color: Colors.black26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(fileIcon, height: 60.w,width: 60.w,),
            const SizedBox(height: 12),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

