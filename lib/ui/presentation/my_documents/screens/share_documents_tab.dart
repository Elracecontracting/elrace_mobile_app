import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:file_picker/file_picker.dart';
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
  bool _isCreatingFolder = false;
  bool _isUploadingFiles = false;
  bool _isCreateDialogOpen = false;
  bool _isAddUserDialogOpen = false;
  String? _error;

  List<Map<String, dynamic>> _folders = <Map<String, dynamic>>[];
  Map<String, dynamic>? _selectedFolder;
  List<Map<String, dynamic>> _folderFiles = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _sharedUsers = <Map<String, dynamic>>[];

  static const int _defaultLimit = 10;
  static const int _defaultOffset = 0;

  void _rawLog(String message) {
    developer.log(message, name: 'ShareDocumentsTab');
    print(message);
  }

  void _debugPrintLong(String message) {
    const chunkSize = 800;
    for (var i = 0; i < message.length; i += chunkSize) {
      final end =
          (i + chunkSize < message.length) ? i + chunkSize : message.length;
      _rawLog(message.substring(i, end));
    }
  }

  void _logSharedRequest({
    required String label,
    required Uri url,
    required String method,
    required Map<String, String> headers,
    String? body,
  }) {
    _rawLog('============= SHARED DOCS REQUEST [$label] START =============');
    _rawLog('URL: $url');
    _rawLog('Method: $method');
    _debugPrintLong('Headers: ${jsonEncode(headers)}');
    if (body != null && body.isNotEmpty) {
      _debugPrintLong('Body: $body');
    }
    _rawLog('============== SHARED DOCS REQUEST [$label] END ==============');
  }

  void _logSharedResponse(String label, http.Response response) {
    _rawLog('============= SHARED DOCS RESPONSE [$label] START ============');
    _rawLog('Status: ${response.statusCode}');
    _debugPrintLong('Headers: ${jsonEncode(response.headers)}');
    _debugPrintLong('Body: ${response.body}');
    _rawLog('============== SHARED DOCS RESPONSE [$label] END =============');
  }

  void _logSharedException(
    String label,
    Object error,
    StackTrace stackTrace, {
    http.Response? response,
  }) {
    _rawLog('============= SHARED DOCS EXCEPTION [$label] START ===========');
    _rawLog('Error: $error');
    if (response != null) {
      _rawLog('Response Status: ${response.statusCode}');
      _debugPrintLong('Response Body: ${response.body}');
    }
    _debugPrintLong('StackTrace: $stackTrace');
    _rawLog('============== SHARED DOCS EXCEPTION [$label] END ============');
  }

  @override
  void initState() {
    super.initState();
    _fetchSharedFolders();
  }

  void _showSnackMessage(String message) {
    if (!mounted) return;
    final messenger =
        context.findRootAncestorStateOfType<ScaffoldMessengerState>() ??
            context.findAncestorStateOfType<ScaffoldMessengerState>();
    if (messenger == null) {
      _rawLog('SnackBar skipped (no ScaffoldMessenger): $message');
      return;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
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

  Map<String, dynamic> _extractResultMap(dynamic decoded) {
    if (decoded is! Map) return const <String, dynamic>{};
    final result = decoded['result'];
    if (result is! Map) return const <String, dynamic>{};
    return Map<String, dynamic>.from(result);
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

    final resolvedUrl = (mapped['public_url'] ??
            mapped['file_url'] ??
            mapped['download_url'] ??
            mapped['url'] ??
            mapped['attachment_url'] ??
            mapped['publicUrl'])
        ?.toString()
        .trim();
    if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
      mapped['public_url'] = resolvedUrl;
    }

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
      final candidate = data['allowed_users'] ??
          data['shared_users'] ??
          data['users'] ??
          data['members'] ??
          [];
      users = _toMapList(candidate);
    } else {
      users = const <Map<String, dynamic>>[];
    }

    return users.map((user) {
      final mapped = Map<String, dynamic>.from(user);
      mapped['employee_id'] =
          mapped['employee_id'] ?? mapped['employeeId'] ?? mapped['id'];
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
        'params': <String, dynamic>{
          'limit': _defaultLimit,
          'offset': _defaultOffset,
        },
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
    } catch (e, s) {
      _logSharedException('shared_folders', e, s);
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
        method: 'POST',
        headers: headers,
        body: body,
      );

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      _logSharedResponse('folder_details', response);
      final decoded = _decodeJsonResponse(response,
          fallbackError: 'Failed to load folder details');

      if (response.statusCode != 200 || !_isSuccessResult(decoded)) {
        throw Exception(
            _extractMessage(decoded, 'Failed to load folder details'));
      }

      final data = _extractResultMap(decoded);
      final files = _extractFiles(data);
      final users = _extractUsers(data);

      if (!mounted) return;
      setState(() {
        _folderFiles = files;
        _sharedUsers = users;
      });
    } catch (e, s) {
      _logSharedException('folder_details', e, s);
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
    if (_isAddUserDialogOpen) return;

    _isAddUserDialogOpen = true;

    final controller = TextEditingController();
    try {
      final employeeId = await showDialog<int>(
        context: context,
        useRootNavigator: true,
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
                    _showSnackMessage('Please enter a valid employee ID');
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

      if (employeeId == null) return;
      await _addUserToFolder(folder, employeeId);
    } finally {
      controller.dispose();
      _isAddUserDialogOpen = false;
    }
  }

  Future<void> _showCreateFolderDialog() async {
    if (_isCreateDialogOpen) return;
    _isCreateDialogOpen = true;

    final nameController = TextEditingController();

    try {
      final folderName = await showDialog<String>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Folder',
                    style: GoogleFonts.aBeeZee(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF27304E),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Add a clear name so team members can find documents quickly.',
                    style: GoogleFonts.aBeeZee(
                      fontSize: 11.sp,
                      color: const Color(0xFF7D8597),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      final name = nameController.text.trim();
                      if (name.isNotEmpty) {
                        Navigator.pop(ctx, name);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Example: Project ABC',
                      hintStyle: GoogleFonts.aBeeZee(fontSize: 11.sp),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 10.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.aBeeZee(
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              _showSnackMessage('Please enter folder name');
                              return;
                            }
                            Navigator.pop(ctx, name);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            backgroundColor: const Color(0xFF090A38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Create Folder',
                            style: GoogleFonts.aBeeZee(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      );

      if (folderName == null || folderName.trim().isEmpty) return;
      await _createFolder(folderName.trim());
    } finally {
      nameController.dispose();
      _isCreateDialogOpen = false;
    }
  }

  Future<void> _createFolder(String folderName) async {
    if (!mounted) return;
    setState(() {
      _isCreatingFolder = true;
    });

    http.Response? response;

    try {
      final token = SharedPref.getLoginData().result?.token ?? '';
      if (token.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      final url = Uri.parse('https://erp.elrace.com/api/cloud/folder/create');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'params': {
          'name': folderName,
        },
      });

      _logSharedRequest(
        label: 'folder_create',
        url: url,
        method: 'POST',
        headers: headers,
        body: body,
      );

      response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      _logSharedResponse('folder_create', response);

      final decoded = _decodeJsonResponse(response,
          fallbackError: 'Failed to create folder');

      if (response.statusCode != 200 || !_isSuccessResult(decoded)) {
        throw Exception(_extractMessage(decoded, 'Failed to create folder'));
      }

      if (!mounted) return;
      setState(() {
        _selectedFolder = null;
        _error = null;
        _folderFiles = <Map<String, dynamic>>[];
        _sharedUsers = <Map<String, dynamic>>[];
      });

      _showSnackMessage('Folder created successfully');

      await _fetchSharedFolders();
    } catch (e, s) {
      _logSharedException('folder_create', e, s, response: response);
      if (!mounted) return;
      _showSnackMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingFolder = false;
        });
      }
    }
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
        method: 'POST',
        headers: headers,
        body: body,
      );

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      _logSharedResponse('folder_add_user', response);
      final decoded =
          _decodeJsonResponse(response, fallbackError: 'Failed to add user');

      if (response.statusCode != 200 || !_isSuccessResult(decoded)) {
        throw Exception(_extractMessage(decoded, 'Failed to add user'));
      }

      if (!mounted) return;
      _showSnackMessage('User added successfully');
      await _openFolder(folder);
    } catch (e, s) {
      _logSharedException('folder_add_user', e, s);
      if (!mounted) return;
      _showSnackMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isAddingUser = false;
        });
      }
    }
  }

  Future<void> _openAttachment(Map<String, dynamic> file) async {
    final rawUrl = (file['public_url'] ??
            file['file_url'] ??
            file['download_url'] ??
            file['url'] ??
            file['attachment_url'] ??
            file['publicUrl'])
        ?.toString()
        .trim();

    if (rawUrl == null || rawUrl.isEmpty) {
      final callback = widget.onOpenDocument;
      final attachmentIds = file['attachment_ids'];
      final hasAttachmentIds =
          (attachmentIds is List && attachmentIds.isNotEmpty) ||
              attachmentIds is Map;

      if (callback != null && hasAttachmentIds) {
        await callback(file);
        return;
      }

      if (!mounted) return;
      _showSnackMessage('No attachment URL available');
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

  String _fileNameFrom(Map<String, dynamic> file) {
    final value =
        (file['name'] ?? file['file_name'] ?? 'Attachment').toString().trim();
    return value.isEmpty ? 'Attachment' : value;
  }

  String _fileExtensionFromName(String fileName) {
    final lower = fileName.toLowerCase();
    final index = lower.lastIndexOf('.');
    if (index == -1 || index == lower.length - 1) return '';
    return lower.substring(index + 1);
  }

  String _fileIconAsset(String extension) {
    if (extension == 'xls' || extension == 'xlsx' || extension == 'csv') {
      return 'assets/newapp/excel.png';
    }
    return 'assets/newapp/pdf.png';
  }

  String _userNameFrom(Map<String, dynamic> user) {
    final raw = (user['name'] ??
            user['employee_name'] ??
            user['display_name'] ??
            'User')
        .toString()
        .trim();
    return raw.isEmpty ? 'User' : raw;
  }

  String? _userAvatarUrlFrom(Map<String, dynamic> user) {
    final candidates = [
      user['image_1920'],
      user['image_url'],
      user['avatar'],
      user['photo'],
    ];
    for (final value in candidates) {
      final url = value?.toString().trim() ?? '';
      if (url.isNotEmpty) return url;
    }
    return null;
  }

  String _userInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed.substring(0, 1).toUpperCase();
  }

  int _projectIdFromFolder(Map<String, dynamic> folder) {
    final raw =
        folder['project_id'] ?? folder['projectId'] ?? folder['project'];
    final parsed = int.tryParse((raw ?? '').toString());
    return parsed ?? 0;
  }

  Future<void> _onUploadFilePressed() async {
    if (_isUploadingFiles) return;

    final folder = _selectedFolder;
    final folderId = folder == null ? null : _folderIdFrom(folder);
    if (folder == null || folderId == null) {
      _showSnackMessage('Please open a folder first');
      return;
    }

    try {
      final picked = await FilePicker.pickFiles(
        allowMultiple: true,
        withData: false,
      );

      if (picked == null || picked.files.isEmpty) {
        return;
      }

      if (!mounted) return;
      setState(() {
        _isUploadingFiles = true;
      });

      final filesData = <Map<String, String>>[];
      for (final file in picked.files) {
        final path = file.path;
        if (path == null || path.isEmpty) {
          continue;
        }

        final bytes = await File(path).readAsBytes();
        filesData.add({
          'file_name': file.name,
          'file_data': base64Encode(bytes),
        });
      }

      if (filesData.isEmpty) {
        _showSnackMessage('Unable to read selected files');
        return;
      }

      final token = SharedPref.getLoginData().result?.token ?? '';
      if (token.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      final url =
          Uri.parse('https://erp.elrace.com/api/upload_project_attachments');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'params': {
          'project_id': _projectIdFromFolder(folder),
          'folder_id': folderId,
          'shared': true,
          'files': filesData,
        },
      });

      _logSharedRequest(
        label: 'upload_project_attachments',
        url: url,
        method: 'POST',
        headers: headers,
        body: body,
      );

      final response = await http.post(url, headers: headers, body: body);
      _logSharedResponse('upload_project_attachments', response);

      final decoded = _decodeJsonResponse(response,
          fallbackError: 'Failed to upload shared documents');

      if (response.statusCode != 200 || !_isSuccessResult(decoded)) {
        throw Exception(
          _extractMessage(decoded, 'Failed to upload shared documents'),
        );
      }

      _showSnackMessage('Files uploaded successfully');
      await _openFolder(folder);
    } catch (e, s) {
      _logSharedException('upload_project_attachments', e, s);
      if (mounted) {
        _showSnackMessage(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingFiles = false;
        });
      }
    }
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
        Text(
          'Given Access',
          style: GoogleFonts.aBeeZee(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF949494),
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          height: 96.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _sharedUsers.length + 1,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _SharedUserAvatarItem(
                  label: _isAddingUser ? '...' : 'Add',
                  onTap: _isAddingUser ? null : _showAddUserDialog,
                  child: Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF222222),
                        width: 1.4,
                      ),
                    ),
                    child: Center(
                      child: _isAddingUser
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF090A38),
                              ),
                            )
                          : Icon(
                              Icons.add,
                              size: 22.sp,
                              color: const Color(0xFF090A38),
                            ),
                    ),
                  ),
                );
              }

              final user = _sharedUsers[index - 1];
              final name = _userNameFrom(user);
              final avatarUrl = _userAvatarUrlFrom(user);

              return _SharedUserAvatarItem(
                label: name,
                onTap: null,
                child: CircleAvatar(
                  radius: 26.r,
                  backgroundColor: const Color(0xFFF2F2F2),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          _userInitial(name),
                          style: GoogleFonts.aBeeZee(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF555555),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.18.r),
                  border: Border.all(color: const Color(0xffD9D9D9)),
                ),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 13.5.w, vertical: 8.5.h),
                  child: Text(
                    'Files No.  |  ${_folderFiles.length}',
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
            ElevatedButton(
              onPressed: _isUploadingFiles ? null : _onUploadFilePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF090A38),
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              child: _isUploadingFiles
                  ? SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Upload File',
                      style: GoogleFonts.aBeeZee(
                        fontSize: 11.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        if (_folderFiles.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 24.h),
            child: Text(
              'No files in this folder',
              textAlign: TextAlign.center,
              style: GoogleFonts.aBeeZee(
                fontSize: 11.sp,
                color: const Color(0xff949494),
              ),
            ),
          )
        else
          GridView.builder(
            itemCount: _folderFiles.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final file = _folderFiles[index];
              final fileName = _fileNameFrom(file);
              final ext = _fileExtensionFromName(fileName);

              return _SharedFileGridCard(
                fileName: fileName,
                iconAsset: _fileIconAsset(ext),
                onTap: () => _openAttachment(file),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFolderView = _selectedFolder != null;
    final count = isFolderView ? _folderFiles.length : _folders.length;

    return PopScope(
      canPop: !isFolderView,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedFolder != null && mounted) {
          setState(() {
            _selectedFolder = null;
            _error = null;
          });
        }
      },
      child: Column(
        children: [
          Padding(
            padding:
                EdgeInsets.only(left: 20.w, right: 20.w, top: 8.h, bottom: 8.h),
            child: Column(
              children: [
                Row(
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
                    SizedBox(width: 6.w),
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
                if (!isFolderView)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed:
                          _isCreatingFolder ? null : _showCreateFolderDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF090A38),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      child: _isCreatingFolder
                          ? SizedBox(
                              width: 14.w,
                              height: 14.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Create Folder',
                              style: GoogleFonts.aBeeZee(
                                fontSize: 11.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: isFolderView
                ? _buildFolderDetailsView()
                : _buildFolderListView(),
          ),
        ],
      ),
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

class _SharedUserAvatarItem extends StatelessWidget {
  const _SharedUserAvatarItem({
    required this.label,
    required this.child,
    this.onTap,
  });

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28.r),
      child: SizedBox(
        width: 62.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            SizedBox(height: 6.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.aBeeZee(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF151515),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedFileGridCard extends StatelessWidget {
  const _SharedFileGridCard({
    required this.fileName,
    required this.iconAsset,
    required this.onTap,
  });

  final String fileName;
  final String iconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1.2),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  iconAsset,
                  width: 86.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              fileName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.aBeeZee(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF151515),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
