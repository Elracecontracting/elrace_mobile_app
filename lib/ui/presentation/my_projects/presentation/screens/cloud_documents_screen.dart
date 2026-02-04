import 'package:el_race/ui/presentation/my_projects/data/datasources/project_remote_datasource.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/project_document_item_model.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen to display cloud folders and files for a project
class CloudDocumentsScreen extends StatefulWidget {
  final int projectId;
  final String? folderId;
  final String? folderName;

  const CloudDocumentsScreen({
    super.key,
    required this.projectId,
    this.folderId,
    this.folderName,
  });

  @override
  State<CloudDocumentsScreen> createState() => _CloudDocumentsScreenState();
}

class _CloudDocumentsScreenState extends State<CloudDocumentsScreen> {
  final ProjectRemoteDataSource _dataSource = ProjectRemoteDataSource();
  
  bool _isLoading = true;
  String? _error;
  List<ProjectDocumentItem> _items = [];
  List<ProjectDocumentItem> _folders = [];
  List<ProjectDocumentItem> _files = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.folderId != null) {
        // Load folder contents
        final response = await _dataSource.fetchFolderContents(
          widget.projectId,
          widget.folderId!,
        );
        _items = response.items;
      } else {
        // Load project root documents
        final response = await _dataSource.fetchProjectDocuments(
          widget.projectId,
        );
        _items = response.items;
      }

      // Separate folders and files
      _folders = _items.where((item) => item.isFolder).toList();
      _files = _items.where((item) => item.isFile).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _onFolderTap(ProjectDocumentItem folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CloudDocumentsScreen(
          projectId: widget.projectId,
          folderId: folder.id,
          folderName: folder.name,
        ),
      ),
    );
  }

  Future<void> _onFileTap(ProjectDocumentItem file) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get file details
      final response = await _dataSource.fetchFileDetails(
        widget.projectId,
        file.id,
      );

      // Hide loading
      Navigator.pop(context);

      // Open file URL
      if (response.viewUrl.isNotEmpty) {
        final uri = Uri.parse(response.viewUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Try download URL
          if (response.downloadUrl.isNotEmpty) {
            final downloadUri = Uri.parse(response.downloadUrl);
            await launchUrl(downloadUri, mode: LaunchMode.externalApplication);
          }
        }
      } else if (file.downloadUrl != null && file.downloadUrl!.isNotEmpty) {
        // Use download URL from list
        final uri = Uri.parse(file.downloadUrl!);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 24.w,
                        color: appFontColor,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          widget.folderName ?? 'FOLDERS',
                          style: GoogleFonts.koulen(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w500,
                            color: appFontColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48.w,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Error loading documents',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Text(
                        _error!,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_items.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_off,
                      size: 48.w,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No documents found',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Folders Section
            if (_folders.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Text(
                    'FOLDERS',
                    style: GoogleFonts.koulen(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF151544),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final folder = _folders[index];
                      return _buildFolderCard(folder);
                    },
                    childCount: _folders.length,
                  ),
                ),
              ),
            ],

            // Files Section (Attachments)
            if (_files.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Text(
                    'ATTACHMENTS',
                    style: GoogleFonts.koulen(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF151544),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final file = _files[index];
                      return _buildFileCard(file);
                    },
                    childCount: _files.length,
                  ),
                ),
              ),
            ],

            // Bottom padding
            SliverToBoxAdapter(
              child: SizedBox(height: 20.h),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFolderCard(ProjectDocumentItem folder) {
    return GestureDetector(
      onTap: () => _onFolderTap(folder),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Folder Icon
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Image.asset(
                'assets/png/folder.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.folder,
                    size: 40.w,
                    color: const Color(0xFFFFC107),
                  );
                },
              ),
            ),
            SizedBox(width: 12.w),
            // Folder Name
            Expanded(
              child: Text(
                folder.name,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF151544),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Arrow Icon
            Icon(
              Icons.chevron_right,
              size: 24.w,
              color: const Color(0xFF151544),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(ProjectDocumentItem file) {
    return GestureDetector(
      onTap: () => _onFileTap(file),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // File Icon based on type
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: _buildFileIcon(file),
            ),
            SizedBox(width: 12.w),
            // File Name
            Expanded(
              child: Text(
                file.name,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF151544),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Download Icon
            Icon(
              Icons.download,
              size: 24.w,
              color: const Color(0xFF151544),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon(ProjectDocumentItem file) {
    if (file.isPdf) {
      return Image.asset(
        'assets/png/pdf-icon.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                'PDF',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      );
    } else if (file.isExcel) {
      return Image.asset(
        'assets/png/excel-icon.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                'XLS',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      );
    } else if (file.isWord) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: Text(
            'DOC',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (file.isImage) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF9C27B0),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          Icons.image,
          size: 24.w,
          color: Colors.white,
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF607D8B),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          Icons.insert_drive_file,
          size: 24.w,
          color: Colors.white,
        ),
      );
    }
  }
}
