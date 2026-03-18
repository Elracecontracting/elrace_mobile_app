import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'attachment_viewer_screen.dart';

/// Share Documents Tab
class ShareDocumentsTab extends StatefulWidget {
  const ShareDocumentsTab({
    super.key,
    this.onOpenDocument,
  });

  final Future<void> Function(Map<String, dynamic> document)? onOpenDocument;

  @override
  State<ShareDocumentsTab> createState() => _ShareDocumentsTabState();
}

class _ShareDocumentsTabState extends State<ShareDocumentsTab> {
  bool _isLoadingFolders = false;
  bool _isLoadingDetails = false;
  bool _isAddingUser = false;
  String? _error;

  List<Map<String, dynamic>> _folders = <Map<String, dynamic>>[];
  Map<String, dynamic>? _selectedFolder;
  List<Map<String, dynamic>> _folderFiles = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _sharedUsers = <Map<String, dynamic>>[];

  void _debugPrintLong(String message) {
    const chunkSize = 800;
    for (var i = 0; i < message.length; i += chunkSize) {
      final end =
          (i + chunkSize < message.length) ? i + chunkSize : message.length;
      debugPrint(message.substring(i, end));
    }
  }

  void _logSharedRequest({
    required String label,
    required Uri url,
    required String method,
    required Map<String, String> headers,
    String? body,
  }) {
    debugPrint(
        '============= SHARED DOCS REQUEST [$label] START =============');
    debugPrint('URL: $url');
    debugPrint('Method: $method');
    _debugPrintLong('Headers: ${jsonEncode(headers)}');
    if (body != null && body.isNotEmpty) {
      _debugPrintLong('Body: $body');
    }
    debugPrint(
        '============== SHARED DOCS REQUEST [$label] END ==============');
  }

  void _logSharedResponse(String label, http.Response response) {
    debugPrint(
        '============= SHARED DOCS RESPONSE [$label] START ============');
    debugPrint('Status: ${response.statusCode}');
    _debugPrintLong('Headers: ${jsonEncode(response.headers)}');
    _debugPrintLong('Body: ${response.body}');
    debugPrint(
        '============== SHARED DOCS RESPONSE [$label] END =============');
  }

  @override
  void initState() {
    super.initState();
    _fetchSharedFolders();
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

  String _extractMessage(dynamic decoded, String fallback) {
    if (decoded is! Map) return fallback;
    final result = decoded['result'];
    if (result is Map) {
      final message = result['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }
    final error = decoded['error']?.toString();
    if (error != null && error.trim().isNotEmpty) {
      return error;
    }
    return fallback;
  }

  dynamic _extractResultData(dynamic decoded) {
    if (decoded is! Map) return null;
    final result = decoded['result'];
    if (result is! Map) return null;
    return result['data'];
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

  List<Map<String, dynamic>> _toMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }
    if (value is Map) {
      return <Map<String, dynamic>>[Map<String, dynamic>.from(value)];
    }
    return const <Map<String, dynamic>>[];
  }

  dynamic _folderIdFrom(Map<String, dynamic> folder) {
    final raw = folder['id'] ?? folder['folder_id'] ?? folder['folderId'];
    if (raw == null) return null;
    final parsed = int.tryParse(raw.toString());
    return parsed ?? raw;
  }

  String _folderNameFrom(Map<String, dynamic> folder) {
    final raw = folder['name'] ?? folder['folder_name'] ?? folder['title'];
    final name = raw?.toString().trim() ?? '';
    return name.isEmpty ? 'Folder' : name;
  }

  List<Map<String, dynamic>> _extractFolders(dynamic data) {
    List<Map<String, dynamic>> base;
    if (data is Map) {
      final candidate =
          data['folders'] ?? data['data'] ?? data['items'] ?? data['list'];
      base = _toMapList(candidate);
      if (base.isEmpty) {
        base = _toMapList(data);
      }
    } else {
      base = _toMapList(data);
    }

    return base
        .map((folder) {
          final mapped = Map<String, dynamic>.from(folder);
          mapped['id'] = _folderIdFrom(folder);
          mapped['name'] = _folderNameFrom(folder);
          return mapped;
        })
        .where((folder) => folder['id'] != null)
        .toList(growable: false);
  }

  Map<String, dynamic> _normalizeFile(Map<String, dynamic> file) {
    final mapped = Map<String, dynamic>.from(file);
    final fileName = (mapped['name'] ??
            mapped['file_name'] ??
            mapped['attachment_name'] ??
            mapped['attachment_filename'] ??
            mapped['title'] ??
            'Attachment')
        .toString();

    dynamic attachmentIds = mapped['attachment_ids'];
    final rawAttachmentId = mapped['attachment_id'] ?? mapped['attachmentId'];
    if ((attachmentIds == null ||
            (attachmentIds is List && attachmentIds.isEmpty)) &&
        rawAttachmentId != null &&
        rawAttachmentId.toString().isNotEmpty) {
      attachmentIds = <dynamic>[rawAttachmentId];
    }

    mapped['name'] = fileName;
    mapped['attachment_ids'] = attachmentIds ?? const <dynamic>[];
    return mapped;
  }

  List<Map<String, dynamic>> _extractFiles(dynamic data) {
    List<Map<String, dynamic>> files;
    if (data is Map) {
      final candidate = data['attachments'] ??
          data['files'] ??
          data['documents'] ??
          data['items'];
      files = _toMapList(candidate);
    } else {
      files = _toMapList(data);
    }
    return files.map(_normalizeFile).toList(growable: false);
  }

  List<Map<String, dynamic>> _extractUsers(dynamic data) {
    List<Map<String, dynamic>> users;
    if (data is Map) {
      final candidate =
          data['shared_users'] ?? data['users'] ?? data['members'] ?? [];
      users = _toMapList(candidate);
    } else {
      users = const <Map<String, dynamic>>[];
    }

    return users.map((user) {
      final mapped = Map<String, dynamic>.from(user);
      mapped['employee_id'] = mapped['employee_id'] ?? mapped['id'];
      mapped['name'] = (mapped['name'] ??
              mapped['employee_name'] ??
              mapped['display_name'] ??
              'User')
          .toString();
      return mapped;
    }).toList(growable: false);
  }

  Future<void> _fetchSharedFolders() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFolders = true;
      _error = null;
    });

    try {
      final token = SharedPref.getLoginData().result?.token ?? '';
      if (token.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      final url = Uri.parse('https://erp.elrace.com/api/cloud/shared_folders');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'params': <String, dynamic>{},
      });

      _logSharedRequest(
        label: 'shared_folders',
        url: url,
        method: 'GET',
        headers: headers,
        body: body,
      );

      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      _logSharedResponse('shared_folders', response);
      final decoded = _decodeJsonResponse(response,
          fallbackError: 'Failed to load shared folders');

      if (response.statusCode != 200 || !_isSuccessResult(decoded)) {
        throw Exception(
            _extractMessage(decoded, 'Failed to load shared folders'));
      }

      final data = _extractResultData(decoded);
      final folders = _extractFolders(data);

      if (!mounted) return;
      setState(() {
        _folders = folders;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFolders = false;
        });
      }
    }
  }

  Future<void> _openFolder(Map<String, dynamic> folder) async {
    final folderId = _folderIdFrom(folder);
    if (folderId == null) return;

    if (!mounted) return;
    setState(() {
      _selectedFolder = folder;
      _isLoadingDetails = true;
      _error = null;
      _folderFiles = <Map<String, dynamic>>[];
      _sharedUsers = <Map<String, dynamic>>[];
    });

    try {
      final token = SharedPref.getLoginData().result?.token ?? '';
      if (token.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      final url = Uri.parse('https://erp.elrace.com/api/cloud/folder/details');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'params': {
          'folder_id': folderId,
        },
      });

      _logSharedRequest(
        label: 'folder_details',
        url: url,
        method: 'GET',
        headers: headers,
        body: body,
      );

      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      _logSharedResponse('folder_details', response);
      final decoded = _decodeJsonResponse(response,
          fallbackError: 'Failed to load folder details');

      if (response.statusCode != 200 || !_isSuccessResult(decoded)) {
        throw Exception(
            _extractMessage(decoded, 'Failed to load folder details'));
      }

      final data = _extractResultData(decoded);
      final files = _extractFiles(data);
      final users = _extractUsers(data);

      if (!mounted) return;
      setState(() {
        _folderFiles = files;
        _sharedUsers = users;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  Future<void> _showAddUserDialog() async {
    final folder = _selectedFolder;
    if (folder == null) return;

    final controller = TextEditingController();
    final employeeId = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add User to Folder'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Employee ID',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid employee ID')),
                  );
                  return;
                }
                Navigator.pop(ctx, value);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (employeeId == null) return;
    await _addUserToFolder(folder, employeeId);
  }

  Future<void> _addUserToFolder(
    Map<String, dynamic> folder,
    int employeeId,
  ) async {
    final folderId = _folderIdFrom(folder);
    if (folderId == null) return;

    if (!mounted) return;
    setState(() {
      _isAddingUser = true;
    });

    try {
      final token = SharedPref.getLoginData().result?.token ?? '';
      if (token.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      final url = Uri.parse('https://erp.elrace.com/api/cloud/folder/add_user');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'params': {
          'folder_id': folderId,
          'employee_id': employeeId,
        },
      });

      _logSharedRequest(
        label: 'folder_add_user',
        url: url,
        method: 'GET',
        headers: headers,
        body: body,
      );

      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      _logSharedResponse('folder_add_user', response);
      final decoded =
          _decodeJsonResponse(response, fallbackError: 'Failed to add user');

      if (response.statusCode != 200 || !_isSuccessResult(decoded)) {
        throw Exception(_extractMessage(decoded, 'Failed to add user'));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added successfully')),
      );
      await _openFolder(folder);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingUser = false;
        });
      }
    }
  }

  Future<void> _openAttachment(Map<String, dynamic> file) async {
    final callback = widget.onOpenDocument;
    final attachmentIds = file['attachment_ids'];
    final hasAttachmentIds =
        (attachmentIds is List && attachmentIds.isNotEmpty) ||
            attachmentIds is Map;

    if (callback != null && hasAttachmentIds) {
      await callback(file);
      return;
    }

    final rawUrl = (file['public_url'] ?? file['download_url'] ?? file['url'])
        ?.toString()
        .trim();
    if (rawUrl == null || rawUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attachment URL available')),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttachmentViewerScreen(
          publicUrl: rawUrl,
          title: (file['name'] ?? 'Attachment').toString(),
        ),
      ),
    );
  }

  Widget _buildFolderListView() {
    if (_isLoadingFolders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                onPressed: _fetchSharedFolders,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_folders.isEmpty) {
      return Center(
        child: Text(
          'No shared folders found',
          style: GoogleFonts.aBeeZee(
            fontSize: 13.sp,
            color: const Color(0xff949494),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      itemCount: _folders.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final folder = _folders[index];
        return _ShareFolderCard(
          title: _folderNameFrom(folder),
          onTap: () => _openFolder(folder),
        );
      },
    );
  }

  Widget _buildFolderDetailsView() {
    if (_isLoadingDetails) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.aBeeZee(
              color: const Color(0xFFBA1719),
              fontSize: 12.sp,
            ),
          ),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Shared Users (${_sharedUsers.length})',
                style: GoogleFonts.aBeeZee(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF27304E),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isAddingUser ? null : _showAddUserDialog,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                backgroundColor: const Color(0xFF090A38),
              ),
              child: _isAddingUser
                  ? SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Add User',
                      style: GoogleFonts.aBeeZee(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        if (_sharedUsers.isEmpty)
          Text(
            'No shared users',
            style: GoogleFonts.aBeeZee(
              fontSize: 11.sp,
              color: const Color(0xff949494),
            ),
          )
        else
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _sharedUsers.map((user) {
              return Chip(
                label: Text(
                  '${user['name']} (${user['employee_id'] ?? '-'})',
                  style: GoogleFonts.aBeeZee(fontSize: 10.sp),
                ),
              );
            }).toList(growable: false),
          ),
        SizedBox(height: 14.h),
        Text(
          'Attachments (${_folderFiles.length})',
          style: GoogleFonts.aBeeZee(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF27304E),
          ),
        ),
        SizedBox(height: 8.h),
        if (_folderFiles.isEmpty)
          Text(
            'No files in this folder',
            style: GoogleFonts.aBeeZee(
              fontSize: 11.sp,
              color: const Color(0xff949494),
            ),
          )
        else
          ..._folderFiles.map((file) {
            return _SharedFileCard(
              fileName: (file['name'] ?? 'Attachment').toString(),
              onTap: () => _openAttachment(file),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFolderView = _selectedFolder != null;
    final count = isFolderView ? _folderFiles.length : _folders.length;

    return Column(
      children: [
        Padding(
          padding:
              EdgeInsets.only(left: 20.w, right: 20.w, top: 8.h, bottom: 8.h),
          child: Row(
            children: [
              if (isFolderView)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedFolder = null;
                      _error = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: const Color(0xFF27304E),
                  tooltip: 'Back to folders',
                ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.18.r),
                    border: Border.all(color: const Color(0xffD9D9D9)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 13.5.w, vertical: 8.5.h),
                    child: Text(
                      isFolderView
                          ? '${_folderNameFrom(_selectedFolder!)}  |  $count'
                          : 'Folders No.  |  $count',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              SizedBox(width: 8.w),
              IconButton(
                onPressed: isFolderView
                    ? () => _openFolder(_selectedFolder!)
                    : _fetchSharedFolders,
                icon: const Icon(Icons.refresh_rounded),
                color: const Color(0xFF27304E),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Expanded(
          child:
              isFolderView ? _buildFolderDetailsView() : _buildFolderListView(),
        ),
      ],
    );
  }
}

class _ShareFolderCard extends StatelessWidget {
  const _ShareFolderCard({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(
        height: 260.h,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Image.asset(
                  'assets/newapp/shared_documents_folder.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 8.h,
              right: 20.w,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.aBeeZee(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedFileCard extends StatelessWidget {
  const _SharedFileCard({
    required this.fileName,
    required this.onTap,
  });

  final String fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xffD9D9D9)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              color: const Color(0xFFBA1719),
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.aBeeZee(
                  fontSize: 11.sp,
                  color: const Color(0xFF27304E),
                ),
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: const Color(0xFF27304E),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}
