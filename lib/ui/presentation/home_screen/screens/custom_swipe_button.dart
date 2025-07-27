import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/authenticate_face/views/authenticate_face_view.dart';
import 'package:el_race/ui/presentation/home_screen/repository/swipe_button_screen_repo.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:el_race/ui/widgets/horizontal_slider_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:location/location.dart';
import 'package:flutter_translate/flutter_translate.dart';

class CustomSwipeButton extends StatefulWidget {

  const CustomSwipeButton({Key? key,}) : super(key: key);

  @override
  State<CustomSwipeButton> createState() => _CustomSwipeButtonState();
}

class _CustomSwipeButtonState extends State<CustomSwipeButton> with TickerProviderStateMixin {
  bool isCheckedIn = false;
  double dragOffset = 0.0;
  bool isDragging = false;
  late AnimationController _arrowController;
  late Animation<double> _arrowScaleAnimation;

  final double buttonWidth = 270;
  final double buttonHeight = 49;
  final double knobSize = 40;

  void _resetPosition() {
    setState(() {
      dragOffset = isCheckedIn ? (buttonWidth - knobSize) : 0;
      isDragging = false;
      startSwipe = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCheckInState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _arrowScaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );

  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }


  _loadCheckInState() {
    final storedState = SharedPref().getPreferenceBoolean('isCheckedIn');
    setState(() {
      isCheckedIn = storedState;
      dragOffset = isCheckedIn ? (buttonWidth - knobSize) : 0;
    });
  }


// ✅ Add this inside _CustomSwipeButtonState
  void _onDragEnd() {
    final threshold = buttonWidth * 0.6;

    // If user dragged enough, animate to the end and show confirmation popup
    if ((!isCheckedIn && dragOffset >= threshold) ||
        (isCheckedIn && dragOffset <= (buttonWidth - knobSize - threshold))) {
      final targetOffset = isCheckedIn ? 0.0 : (buttonWidth - knobSize);
      animateTo(targetOffset, () {
        _showLeftToRightPopupClean(
          context: context,
          loginResponseModel: SharedPref.getLoginData(),
          isCheckedIn: isCheckedIn,
          onConfirmed: () {
            setState(() {
              isCheckedIn = !isCheckedIn;
              dragOffset = isCheckedIn ? (buttonWidth - knobSize) : 0;
              startSwipe = false;
            });
          },
          onCancelled: _resetPosition,
        );
      });
    } else {
      // Otherwise, animate back to original position
      animateTo(isCheckedIn ? (buttonWidth - knobSize) : 0.0, () {});
    }
  }

  void animateTo(double target, VoidCallback onComplete) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    late Animation<double> animation;
    animation = Tween<double>(begin: dragOffset, end: target).animate(controller);

    animation.addListener(() {
      setState(() {
        dragOffset = animation.value;
        if(dragOffset<2.0){
          startSwipe = false;
        }
      });
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onComplete();
        controller.dispose();
      }
    });

    controller.forward();
  }



// ✅ Paste this below inside the same state class
  void _showLeftToRightPopupClean({
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

            final List<dynamic> branchIds =
                SharedPref.getLoginData().result?.data?.userBranches?.allowedBranch ?? <dynamic>[];

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(
                  horizontal: 30, vertical: 24),
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
                                  ? translate('custom_swipe_button.search_project')
                                  : translate('custom_swipe_button.search_branch'),
                              hintStyle: const TextStyle(fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 14),

                      if (isLoading)
                        const SizedBox(height: 80, child: Center(
                            child: CircularProgressIndicator()))
                      else
                        if (projects.isEmpty && branchIds.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              translate('custom_swipe_button.no_projects_or_branches'),
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          )
                        else
                          if (projects.isNotEmpty)
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
                                        ? Colors.deepPurple.withAlpha((0.1 * 255).toInt())
                                        : Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            10)),
                                    onTap: () =>
                                        setState(() {
                                          selectedProject = project;
                                          selectedBranch = null;
                                        }),
                                  );
                                },
                                separatorBuilder: (_, __) =>
                                    Divider(height: 2,
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
                                      translate('custom_swipe_button.no_project_associated'),
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
                                    border: Border.all(
                                        color: Colors.grey.shade400),
                                  ),
                                  child: ListView.separated(
                                    itemCount: branchIds.length,
                                    itemBuilder: (context, index) {
                                      final branch = branchIds[index];
                                      final branchLabel = 'Branch ID: $branch';

                                      if (!branchLabel.toLowerCase().contains(
                                          searchQuery.toLowerCase()))
                                        return const SizedBox();

                                      return ListTile(
                                        dense: true,
                                        contentPadding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 12, vertical: 4),
                                        title: Text(
                                          (branch is List && branch.length > 1)
                                              ? branch[1].toString()
                                              : translate('custom_swipe_button.branch'),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        tileColor: selectedBranch == branch
                                            ? Colors.deepPurple.withAlpha((0.1 * 255).toInt())
                                            : Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                10)),
                                        onTap: () =>
                                            setState(() {
                                              selectedBranch = branch;
                                              selectedProject = null;
                                            }),
                                      );
                                    },
                                    separatorBuilder: (_, __) =>
                                        Divider(height: 2,
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
                                selectedBranch != null) && !isSubmitting
                                ? () async {
                              setState(() {
                                isSubmitting = true;
                                errorMessage = null;
                              });

                              try {
                                final location = Location();
                                final locationData = await location
                                    .getLocation();
                                final result = await CustomSwipeButtonRepo.validateUserLocation(
                                  selectedProject?.agreementId ??
                                      selectedBranch![0],
                                  locationData.latitude ?? 0,
                                  locationData.longitude ?? 0,
                                );

                                if (result['status'] != 'success') {
                                  Navigator.pop(context);
                                  onConfirmed(); // your existing OK logic
                                  
                                  SharedPref().setPreferencesBoolean('wasCheckedInBeforeFaceAuth', isCheckedIn);

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AuthenticateFaceView(
                                        loginResponseModel: loginResponseModel,
                                        isLeftToRight: !isCheckedIn,
                                        onCheckInStatusChanged: (bool checkedIn) async {
                                          SharedPref().setPreferencesBoolean('isCheckedIn', checkedIn);

                                          final wasCheckedInBeforeFaceAuth =
                                              SharedPref().getPreferenceBoolean('wasCheckedInBeforeFaceAuth');

                                          // 🔁 Reset only if face match failed AND it was a check-in attempt
                                          if (!checkedIn && !wasCheckedInBeforeFaceAuth) {
                                            _resetPosition();
                                          }
                                        },
                                      ),
                                    ),
                                  );

                                } else {
                                  setState(() =>
                                  errorMessage = result['message'] ??
                                      'Validation failed.');
                                }
                              } catch (e) {
                                setState(() =>
                                errorMessage =
                                "Something went wrong. Please try again.");
                              }

                              setState(() => isSubmitting = false);
                            }
                                : null,
                            child: isSubmitting
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
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

  bool startSwipe = false;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onHorizontalDragStart: (_) => setState(() => isDragging = true),
        onHorizontalDragUpdate: (details) {
          setState(() {
            dragOffset += details.delta.dx;
            dragOffset = dragOffset.clamp(0.0, buttonWidth - knobSize);
            if(dragOffset>2.0){
              startSwipe = true;
            }else{
              startSwipe = false;
            }
          });
        },
        onHorizontalDragEnd: (_) => _onDragEnd(),
        child: Stack(
          children: [
            // Main swipe button container
            Container(
              width: buttonWidth,
              height: buttonHeight,
              decoration: const BoxDecoration(
                color: Colors.transparent, // Remove solid color background
              ),
              child: Stack(
                children: [
                  
                  // Conditional background for both check-in and check-out
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            isCheckedIn
                                ? 'assets/png/swipe-bg-blue.png' // 👈 Checkout state
                                : 'assets/png/swipe-button-inner.png', // 👈 Checkin state
                          ),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  if (isDragging)
                  Positioned.fill(
                    child: Container(
                      width: buttonWidth,
                      height: buttonHeight,
                      decoration: BoxDecoration(
                        color: startSwipe? const Color(0xFF1E1E50):Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  // Center text
                  Center(
                    child: Text(
                      isCheckedIn ? translate('custom_swipe_button.swipe_to_check_out') : translate('custom_swipe_button.swipe_to_check_in'),
                      style: GoogleFonts.koulen(
                        color:   isCheckedIn || startSwipe ? Colors.white : const Color(0xFF1A1A53),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

            ),


           

            // Arrow icon
            Positioned(
              left: dragOffset + 19 - 16,
              top: (buttonHeight - 39) / 2,
              child: AnimatedBuilder(
                animation: _arrowController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _arrowScaleAnimation.value,
                    child: child,
                  );
                },
                child: Image.asset(
                  isCheckedIn ? 'assets/png/arrow_left.png' : 'assets/png/arrow_right.png',
                  height: 40,
                ),
              ),
            ),
          ],
        ),

      ),
    );
  }

  

}
