import 'package:el_race/core/services/auth_verification_service.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/home_screen/repository/swipe_button_screen_repo.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:el_race/ui/widgets/horizontal_slider_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:location/location.dart';

void showLeftToRightPopupClean({
  required BuildContext context,
  required LoginResponseModel loginResponseModel,
  required bool isCheckedIn,
  required VoidCallback onConfirmed,
  required VoidCallback onCancelled,
}) {
  // If checking out, use the saved project from check-in directly
  if (isCheckedIn) {
    _handleCheckOutWithSavedProject(
      context: context,
      onConfirmed: onConfirmed,
      onCancelled: onCancelled,
    );
    return;
  }

  // Check-in flow: show project selection dialog
  _showProjectSelectionDialog(
    context: context,
    loginResponseModel: loginResponseModel,
    isCheckedIn: isCheckedIn,
    onConfirmed: onConfirmed,
    onCancelled: onCancelled,
  );
}

/// Handles check-out using the saved project from check-in
void _handleCheckOutWithSavedProject({
  required BuildContext context,
  required VoidCallback onConfirmed,
  required VoidCallback onCancelled,
}) async {
  final savedProjectId = SharedPref().getPreferenceInt('checkInProjectId');
  final savedBranchId = SharedPref().getPreferenceInt('checkInBranchId');

  // Check if we have a saved project or branch
  if (savedProjectId == 0 && savedBranchId == 0) {
    // No saved project, show error and cancel
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('No check-in project found. Please check-in first.')),
    );
    onCancelled();
    return;
  }

  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final location = Location();
    final locationData = await location.getLocation();
    final projectIdToUse = savedProjectId != 0 ? savedProjectId : savedBranchId;

    final result = await CustomSwipeButtonRepo.validateUserLocation(
      projectIdToUse,
      locationData.latitude ?? 0,
      locationData.longitude ?? 0,
    );

    Navigator.pop(context); // Close loading dialog

    if (result['status'] != 'success') {
      // Force face recognition only - no other options
      // Set flag and proceed with face recognition
      SharedPref().setPreferencesBoolean('wasCheckedInBeforeFaceAuth', true);
      onConfirmed(); // This will trigger face verification in custom_swipe_button
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Validation failed.')),
      );
      onCancelled();
    }
  } catch (e) {
    Navigator.pop(context); // Close loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Something went wrong. Please try again.')),
    );
    onCancelled();
  }
}

/// Clears saved check-in project data
void _clearSavedCheckInProject() {
  SharedPref().setPreferenceInt('checkInProjectId', 0);
  SharedPref().setPreferencesString('checkInProjectName', '');
  SharedPref().setPreferenceInt('checkInBranchId', 0);
  SharedPref().setPreferencesString('checkInAuthMethod', '');
}

/// Shows PIN-only dialog for check-out when check-in was done with PIN
Future<AuthResult?> _showPinOnlyDialog(
    BuildContext context, AuthVerificationService authService) async {
  final pinController = TextEditingController();
  String? errorMessage;

  return showDialog<AuthResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text(
          'أدخل رمز PIN',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 48, color: Color(0xFF6C757D)),
            const SizedBox(height: 16),
            const Text(
              'يجب استخدام نفس طريقة المصادقة المستخدمة عند تسجيل الدخول',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              textAlign: TextAlign.center,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: '****',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.isEmpty) {
                setState(() => errorMessage = 'الرجاء إدخال رمز PIN');
                return;
              }
              final result = await authService.verifyPin(pinController.text);
              if (result.success) {
                Navigator.pop(context, result);
              } else {
                setState(() => errorMessage = result.message);
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    ),
  );
}

/// Shows the project selection dialog for check-in
void _showProjectSelectionDialog({
  required BuildContext context,
  required LoginResponseModel loginResponseModel,
  required bool isCheckedIn,
  required VoidCallback onConfirmed,
  required VoidCallback onCancelled,
}) {
  Project? selectedProject;
  List<Project> projects = [];
  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;
  String searchQuery = '';
  dynamic selectedBranch;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          if (isLoading) {
            CustomSwipeButtonRepo.fetchProjects().then((result) {
              setState(() {
                projects = result;
                isLoading = false;
              });
            }).catchError((e) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to fetch projects: $e")),
              );
            });
          }

          List<Project> filteredProjects = projects
              .where((proj) =>
                  proj.name.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          final loginData = SharedPref.getLoginDataOrNull();
          final List<dynamic> branchIds =
              loginData?.result?.data?.userBranches?.allowedBranch ??
                  <dynamic>[];

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),

                    if (!isLoading &&
                        (projects.isNotEmpty || branchIds.isNotEmpty))
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha((0.1 * 255).toInt()),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: TextField(
                          onChanged: (value) =>
                              setState(() => searchQuery = value),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 18),
                            hintText: projects.isNotEmpty
                                ? translate(
                                    'custom_swipe_button.search_project')
                                : translate(
                                    'custom_swipe_button.search_branch'),
                            hintStyle: const TextStyle(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 14),

                    if (isLoading)
                      const SizedBox(
                          height: 80,
                          child: Center(child: CircularProgressIndicator()))
                    else if (projects.isEmpty && branchIds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          translate(
                              'custom_swipe_button.no_projects_or_branches'),
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      )
                    else if (projects.isNotEmpty)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: ListView.separated(
                          itemCount: filteredProjects.length,
                          itemBuilder: (context, index) {
                            final project = filteredProjects[index];
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              title: Text(project.name,
                                  style: const TextStyle(fontSize: 12)),
                              tileColor: selectedProject == project
                                  ? Colors.deepPurple
                                      .withAlpha((0.1 * 255).toInt())
                                  : Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              onTap: () => setState(() {
                                selectedProject = project;
                                selectedBranch = null;
                              }),
                            );
                          },
                          separatorBuilder: (_, __) => Divider(
                              height: 2,
                              thickness: 1,
                              color: Colors.grey.shade500),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Center(
                              child: Text(
                                translate(
                                    'custom_swipe_button.no_project_associated'),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: ListView.separated(
                              itemCount: branchIds.length,
                              itemBuilder: (context, index) {
                                final branch = branchIds[index];
                                final branchLabel = 'Branch ID: $branch';

                                if (!branchLabel
                                    .toLowerCase()
                                    .contains(searchQuery.toLowerCase()))
                                  return const SizedBox();

                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  title: Text(
                                    (branch is List && branch.length > 1)
                                        ? branch[1].toString()
                                        : translate(
                                            'custom_swipe_button.branch'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  tileColor: selectedBranch == branch
                                      ? Colors.deepPurple
                                          .withAlpha((0.1 * 255).toInt())
                                      : Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  onTap: () => setState(() {
                                    selectedBranch = branch;
                                    selectedProject = null;
                                  }),
                                );
                              },
                              separatorBuilder: (_, __) => Divider(
                                  height: 2,
                                  thickness: 1,
                                  color: Colors.grey.shade500),
                            ),
                          ),
                        ],
                      ),

                    // 🔴 Error Message (inline)
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          errorMessage ?? '',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),
// Add after SizedBox(height: 30)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            onCancelled(); // your existing cancel function
                            Navigator.of(context).pop();
                          },
                          child: Text(translate('custom_swipe_button.cancel')),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: (selectedProject != null ||
                                      selectedBranch != null) &&
                                  !isSubmitting
                              ? () async {
                                  setState(() {
                                    isSubmitting = true;
                                    errorMessage = null;
                                  });

                                  try {
                                    final location = Location();
                                    final locationData =
                                        await location.getLocation();
                                    final result = await CustomSwipeButtonRepo
                                        .validateUserLocation(
                                      selectedProject?.agreementId ??
                                          selectedBranch![0],
                                      locationData.latitude ?? 0,
                                      locationData.longitude ?? 0,
                                    );

                                    if (result['status'] != 'success') {
                                      // Force face recognition only - no other options
                                      // Save selected project/branch with face recognition method
                                      _saveSelectedProject(
                                          selectedProject, selectedBranch,
                                          authMethod: 'faceRecognition');
                                      Navigator.pop(context);
                                      SharedPref().setPreferencesBoolean(
                                          'wasCheckedInBeforeFaceAuth',
                                          isCheckedIn);
                                      onConfirmed();
                                    } else {
                                      setState(() => errorMessage =
                                          result['message'] ??
                                              'Validation failed.');
                                    }
                                  } catch (e) {
                                    setState(() => errorMessage =
                                        "Something went wrong. Please try again.");
                                  }

                                  setState(() => isSubmitting = false);
                                }
                              : null,
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(translate('custom_swipe_button.ok')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Saves the selected project or branch for use during check-out
void _saveSelectedProject(Project? project, dynamic branch,
    {String? authMethod}) {
  if (project != null) {
    SharedPref().setPreferenceInt('checkInProjectId', project.agreementId);
    SharedPref().setPreferencesString('checkInProjectName', project.name);
    SharedPref().setPreferenceInt('checkInBranchId', 0);
  } else if (branch != null) {
    SharedPref().setPreferenceInt('checkInProjectId', 0);
    SharedPref().setPreferencesString('checkInProjectName', '');
    if (branch is List && branch.isNotEmpty) {
      SharedPref().setPreferenceInt(
          'checkInBranchId', branch[0] is int ? branch[0] : 0);
    } else if (branch is int) {
      SharedPref().setPreferenceInt('checkInBranchId', branch);
    }
  }
  // Save the authentication method used for check-in
  if (authMethod != null) {
    SharedPref().setPreferencesString('checkInAuthMethod', authMethod);
  }
}
