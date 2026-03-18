import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

/// Company Documents Tab
class CompanyDocumentsTab extends StatefulWidget {
  const CompanyDocumentsTab({
    super.key,
    this.onAddDocument,
    this.onOpenDocument,
  });

  final VoidCallback? onAddDocument;
  final Future<void> Function(Map<String, dynamic> document)? onOpenDocument;

  @override
  State<CompanyDocumentsTab> createState() => _CompanyDocumentsTabState();
}

class _CompanyDocumentsTabState extends State<CompanyDocumentsTab> {
  bool _isLoading = false;
  String? _error;
  List<_CompanyDocumentItem> _documents = const [];

  void _debugPrintLong(String message) {
    const chunkSize = 800;
    for (var i = 0; i < message.length; i += chunkSize) {
      final end =
          (i + chunkSize < message.length) ? i + chunkSize : message.length;
      debugPrint(message.substring(i, end));
    }
  }

  void _logCompanyRequest({
    required Uri url,
    required String method,
    required Map<String, String> headers,
    String? body,
  }) {
    debugPrint('=========== COMPANY DOCUMENTS REQUEST START ===========');
    debugPrint('URL: $url');
    debugPrint('Method: $method');
    _debugPrintLong('Headers: ${jsonEncode(headers)}');
    if (body != null && body.isNotEmpty) {
      _debugPrintLong('Body: $body');
    }
    debugPrint('============ COMPANY DOCUMENTS REQUEST END ============');
  }

  void _logCompanyResponse(http.Response response) {
    debugPrint('=========== COMPANY DOCUMENTS RESPONSE START ==========');
    debugPrint('Status: ${response.statusCode}');
    _debugPrintLong('Headers: ${jsonEncode(response.headers)}');
    _debugPrintLong('Body: ${response.body}');
    debugPrint('============ COMPANY DOCUMENTS RESPONSE END ===========');
  }

  dynamic _decodeJsonResponse(http.Response response,
      {required String fallbackError}) {
    final body = response.body.trim();
    if (body.isEmpty) {
      throw Exception('$fallbackError (empty response)');
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      final preview = body.length > 120 ? '${body.substring(0, 120)}...' : body;
      throw Exception('$fallbackError (invalid response: $preview)');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCompanyDocuments();
  }

  String _normalizeToken(dynamic value) {
    return (value ?? '').toString().trim().toLowerCase();
  }

  bool _isSuccessResult(dynamic decoded) {
    if (decoded is! Map) return false;
    final result = decoded['result'];
    if (result is! Map) return false;
    final status = _normalizeToken(result['status']);
    return status == 'success' || status == 'ok' || status == 'true';
  }

  List<Map<String, dynamic>> _extractFlatDocumentMaps(dynamic data) {
    final docs = <Map<String, dynamic>>[];

    void addRaw(Map raw) {
      final map = Map<String, dynamic>.from(raw);
      final nestedAttachments = map['attachments'];
      if (nestedAttachments is List && nestedAttachments.isNotEmpty) {
        for (final attachment in nestedAttachments) {
          if (attachment is! Map) continue;
          final merged = Map<String, dynamic>.from(map)
            ..addAll(Map<String, dynamic>.from(attachment));
          merged['attachment_ids'] =
              merged['attachment_ids'] ?? <dynamic>[attachment];
          docs.add(merged);
        }
        return;
      }
      docs.add(map);
    }

    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          addRaw(item);
        }
      }
      return docs;
    }

    if (data is Map) {
      for (final key in const ['documents', 'attachments', 'files', 'items']) {
        final candidate = data[key];
        if (candidate is List) {
          for (final item in candidate) {
            if (item is Map) {
              addRaw(item);
            }
          }
          return docs;
        }
      }
      addRaw(data);
    }

    return docs;
  }

  _CompanyDocumentItem _mapDocument(Map<String, dynamic> raw) {
    final title = (raw['document_type'] ??
            raw['type'] ??
            raw['category'] ??
            raw['title'] ??
            raw['name'] ??
            'Company Document')
        .toString();

    final fileName = (raw['attachment_name'] ??
            raw['attachment_filename'] ??
            raw['file_name'] ??
            raw['name'] ??
            'document.pdf')
        .toString();

    final normalized = Map<String, dynamic>.from(raw);
    dynamic attachmentIds = normalized['attachment_ids'];
    if (attachmentIds == null ||
        (attachmentIds is List && attachmentIds.isEmpty)) {
      final rawAttachmentId =
          normalized['attachment_id'] ?? normalized['attachmentId'];
      if (rawAttachmentId != null && rawAttachmentId.toString().isNotEmpty) {
        attachmentIds = <dynamic>[rawAttachmentId];
      }
    }
    normalized['attachment_ids'] = attachmentIds ?? const [];
    normalized['name'] = fileName;
    normalized['title'] = title;

    return _CompanyDocumentItem(
      title: title,
      fileName: fileName,
      raw: normalized,
    );
  }

  Future<void> _fetchCompanyDocuments() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = SharedPref.getLoginData().result?.token ?? '';
      if (token.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      final url = Uri.parse('https://erp.elrace.com/api/company/attachments');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'params': <String, dynamic>{},
      });

      _logCompanyRequest(url: url, method: 'GET', headers: headers, body: body);

      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      _logCompanyResponse(response);
      final decoded = _decodeJsonResponse(response,
          fallbackError: 'Failed to load company documents');

      if (response.statusCode != 200 || !_isSuccessResult(decoded)) {
        final message = decoded is Map
            ? (decoded['result']?['message']?.toString() ??
                decoded['error']?.toString() ??
                'Failed to load company documents')
            : 'Failed to load company documents';
        throw Exception(message);
      }

      final result = decoded['result'] as Map<String, dynamic>;
      final flatDocs = _extractFlatDocumentMaps(result['data']);
      final mapped = flatDocs.map(_mapDocument).toList(growable: false);

      if (!mounted) return;
      setState(() {
        _documents = mapped;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openDocument(_CompanyDocumentItem item) async {
    final hasAttachment = item.raw['attachment_ids'] is List
        ? (item.raw['attachment_ids'] as List).isNotEmpty
        : item.raw['attachment_ids'] is Map;

    if (!hasAttachment) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attachment available for this file')),
      );
      return;
    }

    final callback = widget.onOpenDocument;
    if (callback == null) return;
    await callback(item.raw);
  }

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
              const Spacer(),
              IconButton(
                onPressed: _isLoading ? null : _fetchCompanyDocuments,
                icon: const Icon(Icons.refresh_rounded),
                color: const Color(0xFF27304E),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.aBeeZee(
                        color: const Color(0xFFBA1719),
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    OutlinedButton(
                      onPressed: _fetchCompanyDocuments,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
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
                    onTap: widget.onAddDocument,
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

                final item = _documents[index - 1];
                return _CompanyDocumentCard(
                  item: item,
                  onTap: () => _openDocument(item),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CompanyDocumentCard extends StatelessWidget {
  const _CompanyDocumentCard({
    required this.item,
    required this.onTap,
  });

  final _CompanyDocumentItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.picture_as_pdf,
                      size: 48.sp,
                      color: const Color(0xFFBA1719),
                    ),
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
      ),
    );
  }
}

class _CompanyDocumentItem {
  const _CompanyDocumentItem({
    required this.title,
    required this.fileName,
    required this.raw,
  });

  final String title;
  final String fileName;
  final Map<String, dynamic> raw;
}
