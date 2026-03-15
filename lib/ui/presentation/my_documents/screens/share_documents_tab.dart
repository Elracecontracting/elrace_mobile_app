import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

/// Share Documents Tab
/// Fetches shared folders from GET /api/cloud/shared_folders
/// Opens folder via POST /api/cloud/folder/details
/// Adds user via POST /api/cloud/folder/add_user
class ShareDocumentsTab extends StatefulWidget {
  const ShareDocumentsTab({super.key});

  @override
  State<ShareDocumentsTab> createState() => _ShareDocumentsTabState();
}

class _ShareDocumentsTabState extends State<ShareDocumentsTab> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _folders = [];

  // Folder detail state
  Map<String, dynamic>? _selectedFolder;
  bool _detailLoading = false;
  String? _detailError;
  List<Map<String, dynamic>> _folderFiles = [];
  List<Map<String, dynamic>> _sharedUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchSharedFolders();
  }

  String get _token => SharedPref.getLoginData().result?.token ?? '';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  Future<void> _fetchSharedFolders() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final url = Uri.parse('https://erp.elrace.com/api/cloud/shared_folders');
      final body = jsonEncode({'jsonrpc': '2.0', 'params': {}});
      final response = await http.post(url, headers: _headers, body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['result'] != null &&
          data['result']['status'] == 'success') {
        final List list = (data['result']['data'] ?? []) as List;
        if (mounted) {
          setState(() {
            _folders = list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = data['result']?['message']?.toString() ??
                data['error']?.toString() ??
                'Failed to load shared folders';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _openFolder(Map<String, dynamic> folder) async {
    setState(() {
      _selectedFolder = folder;
      _detailLoading = true;
      _detailError = null;
      _folderFiles = [];
      _sharedUsers = [];
    });

    try {
      final folderId = folder['id'] ?? folder['folder_id'];
      final url = Uri.parse('https://erp.elrace.com/api/cloud/folder/details');
      final body = jsonEncode({'jsonrpc': '2.0', 'params': {'folder_id': folderId}});
      final response = await http.post(url, headers: _headers, body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['result'] != null &&
          data['result']['status'] == 'success') {
        final result = data['result']['data'] ?? data['result'];
        final attachments =
            result['attachments'] ?? result['files'] ?? result['data'] ?? [];
        final users = result['shared_users'] ??
            result['users'] ??
            result['members'] ??
            [];
        if (mounted) {
          setState(() {
            _folderFiles = (attachments as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            _sharedUsers = (users as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            _detailLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _detailError = data['result']?['message']?.toString() ??
                data['error']?.toString() ??
                'Failed to load folder details';
            _detailLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _detailError = e.toString();
          _detailLoading = false;
        });
      }
    }
  }

  Future<void> _addUserToFolder({
    required int folderId,
    required int employeeId,
  }) async {
    try {
      final url =
          Uri.parse('https://erp.elrace.com/api/cloud/folder/add_user');
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'params': {'folder_id': folderId, 'employee_id': employeeId},
      });
      final response = await http.post(url, headers: _headers, body: body);
      final data = jsonDecode(response.body);

      final success = response.statusCode == 200 &&
          data['result'] != null &&
          data['result']['status'] == 'success';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'User added to folder successfully'
                : (data['result']?['message']?.toString() ??
                    data['error']?.toString() ??
                    'Failed to add user'),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success && _selectedFolder != null) {
        await _openFolder(_selectedFolder!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddUserDialog() {
    final folderId = _selectedFolder?['id'] ?? _selectedFolder?['folder_id'];
    if (folderId == null) return;

    final employeeIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Add User to Folder',
          style: GoogleFonts.aBeeZee(
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the employee ID to share this folder with:',
              style: GoogleFonts.aBeeZee(fontSize: 13.sp),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: employeeIdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Employee ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF090A38),
            ),
            onPressed: () {
              final empId =
                  int.tryParse(employeeIdController.text.trim());
              if (empId == null) return;
              Navigator.of(ctx).pop();
              _addUserToFolder(
                folderId: int.tryParse(folderId.toString()) ?? 0,
                employeeId: empId,
              );
            },
            child: Text(
              'Add',
              style: GoogleFonts.aBeeZee(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goBackToFolderList() {
    setState(() {
      _selectedFolder = null;
      _folderFiles = [];
      _sharedUsers = [];
      _detailError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedFolder != null) {
      return _buildFolderDetail();
    }
    return _buildFolderList();
  }

  Widget _buildFolderList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.aBeeZee(fontSize: 13.sp, color: Colors.grey),
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: _fetchSharedFolders,
              child:
                  Text('Retry', style: GoogleFonts.aBeeZee(fontSize: 13.sp)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSharedFolders,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
                left: 20.w, right: 20.w, top: 8.h, bottom: 8.h),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.18.r),
                    border: Border.all(color: const Color(0xffD9D9D9)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 13.5.w, vertical: 8.5.h),
                    child: Text(
                      'Folders  |  ${_folders.length}',
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
              ],
            ),
          ),
          Expanded(
            child: _folders.isEmpty
                ? Center(
                    child: Text(
                      'No shared folders found',
                      style: GoogleFonts.aBeeZee(
                          fontSize: 14.sp, color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                        horizontal: 16.w, vertical: 4.h),
                    itemCount: _folders.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final folder = _folders[index];
                      final name = (folder['name'] ??
                              folder['folder_name'] ??
                              'Folder')
                          .toString();
                      final fileCount = (folder['file_count'] ??
                              folder['attachments_count'] ??
                              folder['count'] ??
                              0)
                          .toString();
                      return _ShareFolderCard(
                        name: name,
                        fileCount: fileCount,
                        onTap: () => _openFolder(folder),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderDetail() {
    final folderName =
        (_selectedFolder?['name'] ?? _selectedFolder?['folder_name'] ?? 'Folder')
            .toString();

    return Column(
      children: [
        // Header row
        Padding(
          padding:
              EdgeInsets.only(left: 8.w, right: 16.w, top: 8.h, bottom: 8.h),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: _goBackToFolderList,
              ),
              Expanded(
                child: Text(
                  folderName,
                  style: GoogleFonts.aBeeZee(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: _showAddUserDialog,
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF090A38),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add_outlined,
                          color: Colors.white, size: 16),
                      SizedBox(width: 6.w),
                      Text(
                        'Add User',
                        style: GoogleFonts.aBeeZee(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_detailLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_detailError != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _detailError!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.aBeeZee(
                        fontSize: 13.sp, color: Colors.grey),
                  ),
                  SizedBox(height: 12.h),
                  TextButton(
                    onPressed: () => _openFolder(_selectedFolder!),
                    child: Text('Retry',
                        style: GoogleFonts.aBeeZee(fontSize: 13.sp)),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Files section
                  Text(
                    'Files (${_folderFiles.length})',
                    style: GoogleFonts.aBeeZee(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF090A38),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  if (_folderFiles.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        'No files in this folder',
                        style: GoogleFonts.aBeeZee(
                            fontSize: 13.sp, color: Colors.grey),
                      ),
                    )
                  else
                    ..._folderFiles.map((file) {
                      final name = (file['name'] ??
                              file['attachment_name'] ??
                              file['filename'] ??
                              'File')
                          .toString();
                      return _FileListTile(name: name);
                    }),

                  SizedBox(height: 20.h),

                  // Shared users section
                  Text(
                    'Shared Users (${_sharedUsers.length})',
                    style: GoogleFonts.aBeeZee(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF090A38),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  if (_sharedUsers.isEmpty)
                    Text(
                      'No users have been shared yet',
                      style: GoogleFonts.aBeeZee(
                          fontSize: 13.sp, color: Colors.grey),
                    )
                  else
                    ..._sharedUsers.map((user) {
                      final name = (user['name'] ??
                              user['employee_name'] ??
                              user['display_name'] ??
                              'User')
                          .toString();
                      return _SharedUserTile(name: name);
                    }),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ShareFolderCard extends StatelessWidget {
  const _ShareFolderCard({
    required this.name,
    required this.fileCount,
    this.onTap,
  });

  final String name;
  final String fileCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(Icons.folder_rounded,
                  size: 40.sp, color: const Color(0xFFFFBC3B)),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.aBeeZee(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '$fileCount files',
                      style: GoogleFonts.aBeeZee(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xff949494),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xff949494)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileListTile extends StatelessWidget {
  const _FileListTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xffE5E5E5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined,
              size: 20, color: Color(0xffBA1719)),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.aBeeZee(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedUserTile extends StatelessWidget {
  const _SharedUserTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xffE5E5E5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundColor: const Color(0xFF090A38),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.aBeeZee(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.aBeeZee(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
