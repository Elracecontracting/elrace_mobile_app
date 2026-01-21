import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/ui/widgets/header_widget.dart';

class TaskDetailsScreen extends StatefulWidget {
  static const routeName = '/task-details';

  const TaskDetailsScreen({Key? key}) : super(key: key);

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/png/Tasks.svg",
                      height: 24.w,
                      width: 24.w,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'TASK DETAILS',
                      style: GoogleFonts.koulen(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w500,
                        color: appFontColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                
                // Task Title
                Text(
                  'CREATE NEW DESIGN FOR MOBILE',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description Section
                _buildBorderedFieldWithLabel(
                  label: 'Description',
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'This application is designed for super shops. By using this application they can enlist all their products in one place and can deliver. Customers will get a one-stop solution for their daily shopping.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Project Name
                _buildBorderedFieldWithLabel(
                  label: 'Project\nName',
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'Alfoua - Abu Dhabi Police',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Task Department
                _buildBorderedFieldWithLabel(
                  label: 'Task\nDepartment',
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'Media Department',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                  
                  // Task Progress Section
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CREATE NEW DESIGN FOR MOBILE',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        // Progress Bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: 0.20,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '20% complete',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        
                        // Task Items with white background
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              // Task Item 1 - Completed
                              _buildTaskItem(
                                icon: Icons.check_circle,
                                iconColor: Color(0xFF4CAF50),
                                title: 'Design PettyCash Page',
                                isCompleted: true,
                              ),
                              SizedBox(height: 12),
                              
                              // Task Item 2 - In Progress
                              _buildTaskItem(
                                icon: Icons.radio_button_checked,
                                iconColor: Color(0xFF4CAF50),
                                title: 'Edit Header of mobile',
                                isCompleted: false,
                              ),
                              SizedBox(height: 12),
                              
                              // Task Item 3 - Pending
                              _buildTaskItem(
                                icon: Icons.radio_button_unchecked,
                                iconColor: Colors.grey[400]!,
                                title: 'Remove menu bar',
                                isCompleted: false,
                              ),
                              SizedBox(height: 12),
                              
                              // Task Item 4 - Pending
                              _buildTaskItem(
                                icon: Icons.radio_button_unchecked,
                                iconColor: Colors.grey[400]!,
                                title: 'add search bar',
                                isCompleted: false,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // Last Updated Info
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage('assets/png/avatar1.png'),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) {},
                                ),
                                color: Colors.grey[300],
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Marwan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      'Last updated at',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(width: 40),
                                    Text(
                                      '15:00 pm',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '                              11/01/2026',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Attachments Section
                  Text(
                    'Attachments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12),
                  DottedBorder(
                    borderType: BorderType.RRect,
                    radius: Radius.circular(50),
                    color: Colors.black,
                    strokeWidth: 2,
                    dashPattern: [8, 4],
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildAttachmentIcon(Icons.folder_outlined, Colors.blue[300]!),
                          _buildAttachmentIcon(Icons.camera_alt_outlined, Colors.blue[300]!),
                          _buildAttachmentIcon(Icons.image_outlined, Colors.blue[300]!),
                          _buildAttachmentIcon(Icons.description_outlined, Colors.blue[300]!),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                
                // Add Member
                _buildSectionLabel('Add Member'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAddButton(),
                    const SizedBox(width: 12),
                    _buildMemberAvatar('Diao'),
                    const SizedBox(width: 12),
                    _buildMemberAvatar('Mostafa'),
                    const SizedBox(width: 12),
                    _buildMemberAvatar('Thoer'),
                    const SizedBox(width: 12),
                    _buildMemberAvatar('Sara'),
                  ],
                ),
                const SizedBox(height: 20),
                  
                // Following By
             _buildSectionLabel('Followed UP'),

                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAddButton(),
                    const SizedBox(width: 12),
                    _buildMemberAvatar('Marwan'),
                    const SizedBox(width: 12),
                    _buildMemberAvatar('Hassan'),
                    const SizedBox(width: 12),
                    _buildMemberAvatar('M.Soliman'),
                    const SizedBox(width: 12),
                    _buildMemberAvatar('M.Kadry'),
                  ],
                ),
                const SizedBox(height: 20),
                  
                  // Comments Section
                          _buildSectionLabel('Comments'),

                  SizedBox(height: 12),
                  _buildCommentItem(
                    'Marwan',
                    'Please edit the last files',
                    '15:00 pm\n11/01/2026',
                  ),
                  SizedBox(height: 8),
                  _buildCommentItem(
                    'Hassan',
                    'Need the last update please',
                    '15:00 pm\n11/01/2026',
                  ),
                  SizedBox(height: 8),
                  _buildCommentItem(
                    'M.Soliman',
                    'Need the last update please',
                    '15:00 pm\n11/01/2026',
                  ),
                  SizedBox(height: 16),
                  
                  // Write Comment Field
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Write a comment',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                            ),
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onLongPressStart: (_) {
                            setState(() {
                              _isRecording = true;
                            });
                            // Start recording logic here
                          },
                          onLongPressEnd: (_) {
                            setState(() {
                              _isRecording = false;
                            });
                            // Stop recording logic here
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              'assets/png/record.svg',
                              width: 24,
                              height: 24,
                              color: _isRecording ? Colors.red : Colors.grey[600],
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            // Send comment logic here
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              'assets/png/send.svg',
                              width: 24,
                              height: 24,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Completed Button
                  Center(
                    child: SizedBox(
                      width: 150,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'COMPLETED',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    final parts = label.split('\n');
    
    if (parts.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parts[0],
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(
            parts[1],
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      );
    } else {
      return Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );
    }
  }

  Widget _buildBorderedFieldWithLabel({required String label, required Widget child}) {
    final parts = label.split('\n');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parts.length > 1) ...[
            Text(
              parts[0],
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
            Text(
              parts[1],
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ] else ...[
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTaskItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentIcon(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF8BC6EC), Color(0xFF9599E2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildAddButton() {
    return Column(
      children: [
        DottedBorder(
          borderType: BorderType.Circle,
          color: Colors.black,
          strokeWidth: 2,
          dashPattern: [6, 4],
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(Icons.add, size: 25, color: Colors.black),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add',
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberAvatar(String name) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 2),
            color: Colors.grey[200],
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentItem(String name, String comment, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[300],
          child: Text(
            name[0],
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                comment,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}