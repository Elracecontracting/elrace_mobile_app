import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({Key? key}) : super(key: key);

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  double _daysValue = 5;
  late TextEditingController _daysController;
  late TextEditingController _descriptionController;
  String _selectedProject = 'Alfoua - Abu Dhabi Police';
  String _selectedDepartment = 'Media Department';

  @override
  void initState() {
    super.initState();
    _daysController = TextEditingController(text: _daysValue.toInt().toString());
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _daysController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Title
              _buildBorderedFieldWithLabel(
                label: 'Task\nTitle',
                child: _buildTextField(hint: ''),
              ),
              const SizedBox(height: 20),

              // Project Name
              _buildBorderedFieldWithLabel(
                label: 'Project\nName',
                child: _buildDropdown(
                  value: _selectedProject,
                  items: ['Alfoua - Abu Dhabi Police', 'Other Project'],
                  onChanged: (value) {
                    setState(() {
                      _selectedProject = value!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Task Department
              _buildBorderedFieldWithLabel(
                label: 'Task\nDepartment',
                child: _buildDropdown(
                  value: _selectedDepartment,
                  items: ['Media Department', 'Development', 'Marketing'],
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value!;
                    });
                  },
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
                  _buildMemberAvatar('Diao', 'assets/png/avatar1.png'),
                  const SizedBox(width: 12),
                  _buildMemberAvatar('Mostafa', 'assets/png/avatar2.png'),
                  const SizedBox(width: 12),
                  _buildMemberAvatar('Thoer', 'assets/png/avatar3.png'),
                  const SizedBox(width: 12),
                  _buildMemberAvatar('Sara', 'assets/png/avatar4.png'),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              _buildDescriptionSection(),
              const SizedBox(height: 20),

              // Days Section with Dates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Days TextField
                  Container(
                    width: 120,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Color(0xFFD0D0D0), width: 1.5),
                    ),
                    child: Center(
                      child: TextField(
                        controller: _daysController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              _daysValue = double.tryParse(value) ?? 5;
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  // Start Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'START DATE',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '14 JAN 2026',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),

                  // Divider
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),

                  // End Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'END DATE',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '19 JAN 2026',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Following By
  Center(
                child:             _buildSectionLabel('Following By'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildAddButton(),
                  const SizedBox(width: 12),
                  _buildMemberAvatar('Ahmed', 'assets/png/avatar5.png'),
                  const SizedBox(width: 12),
                  _buildMemberAvatar('Hassan', 'assets/png/avatar6.png'),
                  const SizedBox(width: 12),
                  _buildMemberAvatar('M.Soliman', 'assets/png/avatar7.png'),
                  const SizedBox(width: 12),
                  _buildMemberAvatar('M.Kadry', 'assets/png/avatar8.png'),
                ],
              ),
              const SizedBox(height: 20),

              // Attachments
              _buildSectionLabel('Attachments'),
              const SizedBox(height: 12),
              _buildAddButton(),
              const SizedBox(height: 30),

              // Submit Button
              Center(
                child: Container(
                  width: 220,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8BC6EC), Color(0xFF9599E2)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8BC6EC).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // Submit task logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'SUBMIT TASK',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    final parts = label.split('\n');
    
    if (parts.length > 1) {
      // Two-line label (first line gray, second line black bold)
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
      // Single-line label (black bold)
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

  Widget _buildTextField({String hint = '', int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[400],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: GoogleFonts.poppins(fontSize: 14),
      ),
    );
  }

  Widget _buildLabeledInputField({required String label, String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        value: value,
        isExpanded: true,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(Icons.keyboard_arrow_down),
          iconSize: 24,
          iconEnabledColor: Colors.black54,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          offset: const Offset(0, -5),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(40),
            thickness: WidgetStateProperty.all(6),
            thumbVisibility: WidgetStateProperty.all(true),
          ),
        ),
        menuItemStyleData: MenuItemStyleData(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
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
        child:            Icon(Icons.add, size: 25, color: Colors.black),

        
        
       
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


  /*   Text(
              'Add',
              style: GoogleFonts.poppins(
                fontSize: 8,
                color: Colors.black
              ),
            ),*/

  Widget _buildMemberAvatar(String name, String imagePath) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 2),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              onError: (exception, stackTrace) {},
            ),
            color: Colors.grey[200],
          ),
          child: imagePath.isEmpty
              ? Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                )
              : null,
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

  Widget _buildDateLabel(String label, String date, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with label and icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  _buildIconButton(Icons.format_align_left, _formatAlignLeft),
                  const SizedBox(width: 8),
                  _buildIconButton(Icons.format_list_bulleted, _formatBulletList),
                  const SizedBox(width: 8),
                  _buildIconButton(Icons.format_list_numbered, _formatNumberedList),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Text field
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            onChanged: _handleDescriptionChange,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Enter task description...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[400],
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  void _formatAlignLeft() {
    // Format text alignment - for now just showing the action
    setState(() {});
  }

  void _handleDescriptionChange(String value) {
    // Auto-add bullet point when pressing Enter after a bulleted line
    if (value.endsWith('\n')) {
      final lines = value.split('\n');
      if (lines.length >= 2) {
        final previousLine = lines[lines.length - 2].trim();
        
        // Check if previous line starts with bullet point
        if (previousLine.startsWith('• ')) {
          final newText = value + '• ';
          _descriptionController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.fromPosition(
              TextPosition(offset: newText.length),
            ),
          );
          return;
        }
        
        // Check if previous line starts with number
        final numberMatch = RegExp(r'^(\d+)\.\s').firstMatch(previousLine);
        if (numberMatch != null) {
          final nextNumber = int.parse(numberMatch.group(1)!) + 1;
          final newText = value + '$nextNumber. ';
          _descriptionController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.fromPosition(
              TextPosition(offset: newText.length),
            ),
          );
          return;
        }
      }
    }
  }

  void _formatBulletList() {
    final text = _descriptionController.text;
    if (text.isEmpty) return;
    
    final lines = text.split('\n');
    final formattedLines = lines.where((line) => line.trim().isNotEmpty).map((line) {
      final trimmed = line.trim();
      if (trimmed.startsWith('• ')) return trimmed;
      if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        return '• ${trimmed.replaceFirst(RegExp(r'^\d+\.\s'), '')}';
      }
      return '• $trimmed';
    }).join('\n');
    
    _descriptionController.text = formattedLines;
    _descriptionController.selection = TextSelection.fromPosition(
      TextPosition(offset: formattedLines.length),
    );
  }

  void _formatNumberedList() {
    final text = _descriptionController.text;
    if (text.isEmpty) return;
    
    final lines = text.split('\n');
    int number = 1;
    final formattedLines = lines.where((line) => line.trim().isNotEmpty).map((line) {
      final trimmed = line.trim();
      if (trimmed.startsWith('• ')) {
        return '${number++}. ${trimmed.substring(2)}';
      }
      if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        return '${number++}. ${trimmed.replaceFirst(RegExp(r'^\d+\.\s'), '')}';
      }
      return '${number++}. $trimmed';
    }).join('\n');
    
    _descriptionController.text = formattedLines;
    _descriptionController.selection = TextSelection.fromPosition(
      TextPosition(offset: formattedLines.length),
    );
  }
}