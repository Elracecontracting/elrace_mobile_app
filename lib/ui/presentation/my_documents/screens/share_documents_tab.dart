import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Share Documents Tab
class ShareDocumentsTab extends StatelessWidget {
  const ShareDocumentsTab({super.key});

  static const List<String> _fakeFolders = [
    'Estimations',
    'Floorplane',
    'Estimations',
    'Shop Drawings',
    'Contracts',
    'Quotations',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              EdgeInsets.only(left: 20.w, right: 20.w, top: 8.h, bottom: 8.h),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.18.r),
                  border: Border.all(color: const Color(0xffD9D9D9)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 13.5.w,
                    vertical: 8.5.h,
                  ),
                  child: Text(
                    'Files No.  |  ${_fakeFolders.length}',
                    style: GoogleFonts.aBeeZee(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      letterSpacing: .10,
                      color: const Color(0xff949494),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  // Placeholder until create-folder API is wired.
                },
                borderRadius: BorderRadius.circular(30.r),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF090A38),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Text(
                    'Create Folder',
                    style: GoogleFonts.aBeeZee(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            itemCount: _fakeFolders.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              return const _ShareFolderCard();
            },
          ),
        ),
      ],
    );
  }
}

class _ShareFolderCard extends StatelessWidget {
  const _ShareFolderCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 20.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.asset(
                'assets/newapp/Share Document file.png',
                fit: BoxFit.fill,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
