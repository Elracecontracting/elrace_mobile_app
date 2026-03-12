import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Company Documents Tab
class CompanyDocumentsTab extends StatelessWidget {
  const CompanyDocumentsTab({
    super.key,
    this.onAddDocument,
  });

  final VoidCallback? onAddDocument;

  static const List<_CompanyDocumentItem> _documents = [
    _CompanyDocumentItem(
      title: 'Company Profile',
      fileName: 'company_profile.pdf',
    ),
    _CompanyDocumentItem(
      title: 'Trade License',
      fileName: 'trade_license.pdf',
    ),
    _CompanyDocumentItem(
      title: 'Memorandum of Association',
      fileName: 'memorandum_of_association.pdf',
    ),
    _CompanyDocumentItem(
      title: 'Tax Registration Certificate',
      fileName: 'tax_registration_certificate.pdf',
    ),
    _CompanyDocumentItem(
      title: 'Establishment Card',
      fileName: 'establishment_card.pdf',
    ),
    _CompanyDocumentItem(
      title: 'Corporate Bank Letter',
      fileName: 'corporate_bank_letter.pdf',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20.w, top: 8.h, bottom: 8.h),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.18.r),
                border: Border.all(color: const Color(0xffD9D9D9)),
              ),
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 13.5.w, vertical: 8.5.h),
                child: Text(
                  'Files No.  |  ${_documents.length}',
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
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _documents.length + 1,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: onAddDocument,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: const Color(0xffD9D9D9)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_add_outlined,
                          size: 48.sp,
                          color: const Color(0xff949494),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Add New',
                          style: GoogleFonts.aBeeZee(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xff949494),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return _CompanyDocumentCard(item: _documents[index - 1]);
            },
          ),
        ),
      ],
    );
  }
}

class _CompanyDocumentCard extends StatelessWidget {
  const _CompanyDocumentCard({required this.item});

  final _CompanyDocumentItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xffD9D9D9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 12.h),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  color: const Color(0xFFF4F6FB),
                  border: Border.all(color: const Color(0xffE5E8F3)),
                ),
                child: Text(
                  'PDF',
                  style: GoogleFonts.aBeeZee(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xffBA1719),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/newapp/pdf.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.aBeeZee(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              item.fileName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.aBeeZee(
                fontSize: 10.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xff949494),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyDocumentItem {
  const _CompanyDocumentItem({
    required this.title,
    required this.fileName,
  });

  final String title;
  final String fileName;
}
