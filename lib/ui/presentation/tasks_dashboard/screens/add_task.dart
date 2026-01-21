import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({Key? key}) : super(key: key);

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  double _daysValue = 5;
  late TextEditingController _daysController;
  String _selectedProject = 'Alfoua - Abu Dhabi Police';
  String _selectedDepartment = 'Media Department';

  @override
  void initState() {
    super.initState();
    _daysController = TextEditingController(text: _daysValue.toInt().toString());
  }

  @override
  void dispose() {
    _daysController.dispose();
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
              _buildSectionLabel('Task\nTitle'),
              const SizedBox(height: 8),
              _buildTextField(hint: ''),
              const SizedBox(height: 20),

              // Project Name
              _buildSectionLabel('Project\nName'),
              const SizedBox(height: 8),
              _buildDropdown(
                value: _selectedProject,
                items: ['Alfoua - Abu Dhabi Police', 'Other Project'],
                onChanged: (value) {
                  setState(() {
                    _selectedProject = value!;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Task Department
              _buildSectionLabel('Task\nDepartment'),
              const SizedBox(height: 8),
              _buildDropdown(
                value: _selectedDepartment,
                items: ['Media Department', 'Development', 'Marketing'],
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value!;
                  });
                },
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
              _buildSectionLabel('Description'),
              const SizedBox(height: 8),
              _buildTextField(
                hint: 'This application is designed for super shops. By using this application they can enlist all their products in one place and then can get a one-stop solution for their inventory and sales management.',
                maxLines: 5,
              ),
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
              _buildSectionLabel('Following By'),
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
                  width: double.infinity,
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
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildTextField({String hint = '', int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
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

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
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
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
        color: Colors.white,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, size: 20, color: Colors.grey[700]),
          Text(
            'Add',
            style: GoogleFonts.poppins(
              fontSize: 8,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

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
}