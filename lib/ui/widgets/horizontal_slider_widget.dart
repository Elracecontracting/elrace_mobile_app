import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/authenticate_face/views/authenticate_face_view.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_in_bloc/check_in_bloc.dart';
import 'dart:math';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_out_bloc/check_out_bloc.dart';
import 'package:location/location.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';


class GradientSliderWidget extends StatefulWidget {
  final Function(double) onValueChanged;
  final dynamic loginResponseModel;


  const GradientSliderWidget({Key? key, required this.onValueChanged,required this.loginResponseModel}) : super(key: key);

  @override
  GradientSliderState createState() => GradientSliderState();
}

class GradientSliderState extends State<GradientSliderWidget> {
  double _sliderValue = 0.0;
  Duration _remainingTime = const Duration(hours: 8);
  bool _isTimerRunning = false;
  late SharedPreferences _prefs;
  DateTime? _startTime;
  String? errorMessage;
  bool isSubmitting = false;



  final CheckInBloc _checkInBloc = CheckInBloc(); // Bloc instance for Check-In
  final CheckOutBloc _checkOutBloc = CheckOutBloc(); // Bloc instance for Check-Out

  @override
  void initState() {
    super.initState();
    _initializeTimerState(); // Load slider and timer states
  }

  Future<void> _initializeTimerState() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _sliderValue = _prefs.getDouble('sliderValue') ?? 0.0;
      _isTimerRunning = SharedPref().getPreferenceBoolean('isTimerRunning') ?? false;
      int seconds = _prefs.getInt('remainingTimeInSeconds') ?? 8 * 3600;
      _remainingTime = Duration(seconds: seconds);

      // Restore start time
      String? startTimeStr = _prefs.getString('startTime');
      if (startTimeStr != null) {
        _startTime = DateTime.parse(startTimeStr);
        _syncTimerWithBackground();
      }

      // Resume timer if it was running
      if (_isTimerRunning) {
        _startTimer();
      }
    });
  }

  Future<bool> compareFaceWithStoredImages(File capturedImage) async {
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true, // Enable facial landmarks
      ),
    );

    try {
      // Detect faces in the captured image
      final inputImage = InputImage.fromFile(capturedImage);
      final capturedFaces = await faceDetector.processImage(inputImage);

      if (capturedFaces.isEmpty) {
        return false; // No face detected in the captured image
      }

      // Extract landmarks from the captured face
      final capturedFace = capturedFaces.first;
      final capturedLandmarks = _extractLandmarks(capturedFace);

      // Retrieve stored selfies from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedPaths = prefs.getStringList('user_photos') ?? [];

      for (final path in storedPaths) {
        final storedImage = File(path);
        final storedInputImage = InputImage.fromFile(storedImage);
        final storedFaces = await faceDetector.processImage(storedInputImage);

        if (storedFaces.isNotEmpty) {
          // Extract landmarks from the stored face
          final storedFace = storedFaces.first;
          final storedLandmarks = _extractLandmarks(storedFace);

          // Compare landmarks using Euclidean distance
          if (_landmarksMatch(capturedLandmarks, storedLandmarks)) {
            return true; // Face match found
          }
        }
      }
    } catch (e) {
      print('Error during face comparison: $e');
    } finally {
      faceDetector.close();
    }
    return false; // No match found
  }

  Map<String, Point<int>> _extractLandmarks(Face face) {
    final landmarks = <String, Point<int>>{};

    // Extract landmarks using Point<int> values
    if (face.landmarks[FaceLandmarkType.leftEye] != null) {
      final position = face.landmarks[FaceLandmarkType.leftEye]!.position;
      landmarks['leftEye'] = Point(position.x, position.y);
    }
    if (face.landmarks[FaceLandmarkType.rightEye] != null) {
      final position = face.landmarks[FaceLandmarkType.rightEye]!.position;
      landmarks['rightEye'] = Point(position.x, position.y);
    }
    if (face.landmarks[FaceLandmarkType.noseBase] != null) {
      final position = face.landmarks[FaceLandmarkType.noseBase]!.position;
      landmarks['noseBase'] = Point(position.x, position.y);
    }

    // For mouth landmarks, check availability in FaceLandmarkType
    if (face.landmarks[FaceLandmarkType.leftMouth] != null) {
      final position = face.landmarks[FaceLandmarkType.leftMouth]!.position;
      landmarks['mouthLeft'] = Point(position.x, position.y);
    }
    if (face.landmarks[FaceLandmarkType.rightMouth] != null) {
      final position = face.landmarks[FaceLandmarkType.rightMouth]!.position;
      landmarks['mouthRight'] = Point(position.x, position.y);
    }

    return landmarks;
  }

  bool _landmarksMatch(Map<String, Point<int>> captured, Map<String, Point<int>> stored) {
    const double threshold = 50.0; // Define a similarity threshold (pixels)

    double calculateDistance(Point<int> p1, Point<int> p2) {
      return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
    }

    double totalDistance = 0;
    int count = 0;

    for (final key in captured.keys) {
      if (stored.containsKey(key)) {
        totalDistance += calculateDistance(captured[key]!, stored[key]!);
        count++;
      }
    }

    // Average distance
    final averageDistance = count > 0 ? totalDistance / count : double.infinity;
    return averageDistance < threshold; // Return true if below threshold
  }

  void _syncTimerWithBackground() {
    if (_startTime != null && _isTimerRunning) {
      final DateTime now = DateTime.now();
      final elapsedTime = now.difference(_startTime!);
      setState(() {
        _remainingTime = _remainingTime - elapsedTime;
        if (_remainingTime.isNegative) {
          _remainingTime = Duration.zero;
          _isTimerRunning = false;
        }
      });
      _startTime = DateTime.now(); // Reset the start time for future calculations
      _saveTimerState();
    }
  }

  void _startTimer() {
    _isTimerRunning = true;
    _startTime = DateTime.now();
    _saveTimerState(); // Save running state and start time
    Future.doWhile(() async {
      if (!_isTimerRunning || _remainingTime.inSeconds <= 0) return false;

      await Future.delayed(const Duration(seconds: 1));
      if (_isTimerRunning) {
        setState(() {
          _remainingTime -= const Duration(seconds: 1);
          if (_remainingTime.isNegative) {
            _remainingTime = Duration.zero;
            _isTimerRunning = false;
          }
        });
        _saveTimerState(); // Save remaining time
      }
      return true;
    });
  }

  void _stopTimer() {
    setState(() {
      _isTimerRunning = false;
    });
    _saveTimerState(); // Save running state
  }

  Future<void> _openCamera(Function() onSuccess, bool isLeftToRight) async {
    final currentContext = context;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraWithOverlay(
          overlayImage: 'assets/png/Attendance-verification.png',
          onCapture: (capturedFile) async {
            if (capturedFile != null) {
              final isMatched = await compareFaceWithStoredImages(capturedFile);

              if (isMatched) {

                showDialog(

                  context: currentContext,

                  barrierDismissible: false, // Prevent closing dialog by tapping outside

                  builder: (BuildContext context) {

                    return Stack(

                      children: [

                        // Background blur

                        Positioned.fill(

                          child: BackdropFilter(

                            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Blur effect

                            child: Container(color: Colors.black.withAlpha((0.5 * 255).toInt())), // Semi-transparent background

                          ),

                        ),

                        // Loader in the center

                        const Center(
                          child: CircularProgressIndicator(),
                        ),

                      ],

                    );

                  },

                );
                // Trigger appropriate API based on direction

                Future.delayed(const Duration(seconds: 2), () {

                  Navigator.of(currentContext).pop(); // Close the loader dialog

                  //onSuccess(); // Proceed with the timer or other logic

                });
                if (isLeftToRight) {
                  _checkInBloc.add(CheckInET()); // Trigger check-in API
                } else {
                  final checkInRecordId = _prefs.getInt('checkInRecordId') ?? 0;

                  if (checkInRecordId != 0) {
                    _checkOutBloc.add(CheckOutET(checkInRecordId)); // Trigger check-out API
                  } else {
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      const SnackBar(content: Text('Check-In Record ID not found. Please check in first.')),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  const SnackBar(content: Text('Face didn’t match. Please try again.')),
                );
                setState(() {
                  _sliderValue = isLeftToRight ? 0.0 : 1.0; // Reset slider
                });
              }
            } else {
              ScaffoldMessenger.of(currentContext).showSnackBar(
                const SnackBar(content: Text('Picture capture cancelled.')),
              );
            }
          },
        ),
      ),
    );
  }

  Future<List<Project>> _fetchProjects() async {
    try {
      // Get the token from login response
      final loginResponse = widget.loginResponseModel;
      final token = loginResponse.result.token;

      // Headers
      Map<String, String> headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token"
      };

      // Body
      Map<String, dynamic> body = {
        "jsonrpc": "2.0",
        "params": {}
      };

      // URL
      var url = Uri.parse("https://test.elrace.com/api/get_projects");

      // Build the GET request
      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = jsonEncode(body);

      // Send and convert to Response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Debug log (optional)
      // print('Response status: ${response.statusCode}');
      // print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List projectsData = data['result']['data'];
        return projectsData.map((json) => Project.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load projects: ${response.statusCode}");
      }
    } catch (e) {
      // Optional: log or handle error
      print('Error in _fetchProjects: $e');
      rethrow;
    }
  }

  void _showLeftToRightPopup() {
    Project? selectedProject;
    dynamic selectedBranch;
    bool isLoading = true;
    List<Project> projects = [];
    String searchQuery = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (isLoading) {
              _fetchProjects().then((result) {
                setState(() {
                  projects = result;
                  isLoading = false;
                });
              }).catchError((e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to fetch projects: $e")),
                );
                setState(() => _sliderValue = 0.0);
              });
            }

            List<Project> filteredProjects = projects
                .where((proj) => proj.name.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            final List<dynamic> branchIds = widget.loginResponseModel.result?.data?.userBranches?.allowedBranch ?? [];

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),

                      if (!isLoading && (projects.isNotEmpty || branchIds.isNotEmpty))
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
                            onChanged: (value) => setState(() => searchQuery = value),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search, size: 18),
                              hintText: projects.isNotEmpty ? 'Search Project...' : 'Search Branch...',
                              hintStyle: const TextStyle(fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 14),

                      if (isLoading)
                        const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
                      else if (projects.isEmpty && branchIds.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text("No projects or branches found.",
                            style: TextStyle(color: Colors.red, fontSize: 13),
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
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  title: Text(project.name, style: const TextStyle(fontSize: 12)),
                                  tileColor: selectedProject == project
                                      ? Colors.deepPurple.withAlpha((0.1 * 255).toInt())
                                      : Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  onTap: () => setState(() {
                                    selectedProject = project;
                                    selectedBranch = null;
                                  }),
                                );
                              },
                              separatorBuilder: (_, __) => Divider(height: 2, thickness: 1, color: Colors.grey.shade500),
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
                                    'No project is associated, that’s why branches are shown.',
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

                                    if (!branchLabel.toLowerCase().contains(searchQuery.toLowerCase())) return const SizedBox();

                                    return ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      title: Text(
                                        (branch is List && branch.length > 1) ? branch[1].toString() : 'Branch',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      tileColor: selectedBranch == branch
                                          ? Colors.deepPurple.withAlpha((0.1 * 255).toInt())
                                          : Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      onTap: () => setState(() {
                                        selectedBranch = branch;
                                        selectedProject = null;
                                      }),
                                    );
                                  },
                                  separatorBuilder: (_, __) => Divider(height: 2, thickness: 1, color: Colors.grey.shade500),
                                ),
                              ),
                            ],
                          ),

                      // 🔴 Error Message (inline)
                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            errorMessage!,
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Cancel
                          SizedBox(
                            width: 100,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => _sliderValue = 0.0);
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFBA1719),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),

                          // OK Button (Updated)
                          SizedBox(
                            width: 100,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: ((selectedProject != null || selectedBranch != null) &&
                                  (projects.isNotEmpty || branchIds.isNotEmpty) && !isSubmitting)
                                  ? () async {
                                setState(() {
                                  isSubmitting = true;
                                  errorMessage = null;
                                });

                                try {
                                  // Get location
                                  Location location = Location();
                                  LocationData locationData = await location.getLocation();
                                  double currentLat = locationData.latitude ?? 0.0;
                                  double currentLong = locationData.longitude ?? 0.0;

                                  int selectedProjectId = selectedProject?.agreementId ?? 0;

                                  if (selectedProjectId == 0) {
                                    setState(() {
                                      errorMessage = "Project ID is missing or invalid.";
                                      _sliderValue = 0.0;
                                      isSubmitting = false;
                                    });
                                    return;
                                  }

                                  // Call location validation API
                                  final result = await _validateUserLocation(selectedProjectId, currentLat, currentLong);

                                  if (result['status'] != 'success') {
                                    Navigator.of(context).pop();

                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AuthenticateFaceView(
                                          loginResponseModel: widget.loginResponseModel,
                                          isLeftToRight: true,
                                        ),
                                      ),
                                    );

                                  } else {
                                    setState(() {
                                      errorMessage = result['message'] ?? "Validation failed.";
                                      _sliderValue = 0.0;
                                      isSubmitting = false;
                                    });
                                  }
                                } catch (e) {
                                  setState(() {
                                    errorMessage = "Something went wrong. Please try again.";
                                    isSubmitting = false;
                                  });
                                }
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A1A53),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : const Text(
                                'OK',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
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

  Future<Map<String, dynamic>> _validateUserLocation(int projectId, double latitude, double longitude) async {
    final loginResponse = widget.loginResponseModel;
    final token = loginResponse.result.token;

    final url = Uri.parse("https://test.elrace.com/api/validate_user_location");

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "project_id": projectId,
        "check_in_lat": latitude,
        "check_in_long": longitude,
        "office": null
      }
    });
    print(body);
    try {
      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);
      return data['result'];
    } catch (e) {
      return {"status": "error", "message": "Failed to validate location: $e"};
    }
  }

  void _showRightToLeftPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Signing Off?'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _sliderValue = 1.0; // Move slider back to right
                });
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _openCamera(() {
                  _stopTimer(); // Stop the timer
                }, false); // Pass false for right-to-left
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveTimerState() async {
    await _prefs.setDouble('sliderValue', _sliderValue);
    await _prefs.setInt('remainingTimeInSeconds', _remainingTime.inSeconds);
    await _prefs.setBool('isTimerRunning', _isTimerRunning);
    if (_startTime != null) {
      await _prefs.setString('startTime', _startTime!.toIso8601String());
    }
  }

  void _showStyledDialog(BuildContext context, String title, String message, Color color, IconData icon, VoidCallback onPressed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
        title: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color, // Dynamic background color
            borderRadius: const BorderRadius.all(Radius.circular(0)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 26), // Icon based on status
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: onPressed,
            child: const Text('OK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF00D179),
            inactiveTrackColor: const Color(0xFFCDCDFF),
            trackHeight: 20.0,
            thumbColor: const Color(0xFF1A1A53),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 17.0),
            overlayColor: const Color(0x2900D179), // Translucent green overlay
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 15.0),
          ),
          child: Slider(
            value: _sliderValue,
            min: 0.0,
            max: 1.0,
            onChanged: (newValue) {
              setState(() {
                widget.onValueChanged(newValue);
                if (newValue >= 1.0 && _sliderValue < 1.0) {
                  _showLeftToRightPopup(); // Show Left-to-Right Dialog
                } else if (newValue <= 0.0 && _sliderValue > 0.0) {
                  _showRightToLeftPopup(); // Show Right-to-Left Dialog
                }
                _sliderValue = newValue; // Update the slider value
              });
            },
          ),
        ),
        const SizedBox(height: 10),



        BlocConsumer<CheckInBloc, CheckInState>(
          bloc: _checkInBloc,
          listener: (context, state) {
            if (state is CheckedInST) {
              _showStyledDialog(
                context,
                "Check-In Success",
                state.message,
                const Color(0xFF28A745), // Success Green
                Icons.check_circle, // Success Icon
                    () {
                  Navigator.of(context).pop();
                  setState(() {
                    _sliderValue = 1.0;
                    _startTimer();
                  });
                },
              );
            } else if (state is CheckInErrorST) {
              _showStyledDialog(
                context,
                "Error",
                state.errorMessage,
                const Color(0xFFDC3545), // Error Red
                Icons.error, // Error Icon
                    () {
                  Navigator.of(context).pop();
                  setState(() {
                    _sliderValue = 0.0;
                  });
                },
              );
            } else if (state is CheckInWarningST) {
              _showStyledDialog(
                context,
                "Warning",
                state.warningMessage,
                const Color(0xFFFFC107), // Warning Yellow
                Icons.warning, // Warning Icon
                    () {
                  Navigator.of(context).pop();
                  setState(() {
                    _sliderValue = 1.0;
                    _startTimer();
                  });
                },
              );
              _prefs.setInt('checkInRecordId', state.checkInRecordId);
            }
          },
          builder: (context, state) {
            return Container();
          },
        ),

        BlocConsumer<CheckOutBloc, CheckOutState>(
          bloc: _checkOutBloc,
          listener: (context, state) {
            if (state is CheckedOutST) {
              _showStyledDialog(
                context,
                "Check-Out Success",
                state.message,
                const Color(0xFF28A745), // Success Green
                Icons.check_circle, // Success Icon
                    () {
                  Navigator.of(context).pop();
                  setState(() {
                    _sliderValue = 0.0;
                    _stopTimer();
                  });
                },
              );
            } else if (state is CheckOutErrorST) {
              _showStyledDialog(
                context,
                "Error",
                state.errorMessage,
                const Color(0xFFDC3545), // Error Red
                Icons.error, // Error Icon
                    () {
                  Navigator.of(context).pop();
                  setState(() {
                    _sliderValue = 1.0;
                  });
                },
              );
            } else if (state is CheckOutWarningST) {
              _showStyledDialog(
                context,
                "Warning",
                state.warningMessage,
                const Color(0xFFFFC107), // Warning Yellow
                Icons.warning, // Warning Icon
                    () {
                  Navigator.of(context).pop();
                  setState(() {
                    _sliderValue = 0.0;
                    _stopTimer();
                  });
                },
              );
            }
          },
          builder: (context, state) {
            return Container();
          },
        ),



        Text(
          '${_remainingTime.inHours.toString().padLeft(2, '0')}:${(_remainingTime.inMinutes % 60).toString().padLeft(2, '0')}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class CameraWithOverlay extends StatefulWidget {
  final String overlayImage;
  final Function(File?) onCapture;

  const CameraWithOverlay({Key? key, required this.overlayImage, required this.onCapture}) : super(key: key);

  @override
  State<CameraWithOverlay> createState() => _CameraWithOverlayState();
}

class _CameraWithOverlayState extends State<CameraWithOverlay> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  late SharedPreferences _prefs;
  int _selectedCameraIndex = 0; // Default to front camera

  @override
  void initState() {
    super.initState();
    initializeCamera();
    _initializePreferences();
  }
  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }
  Future<void> initializeCamera() async {
    _cameras = await availableCameras();

    // Default to the front camera if available
    _selectedCameraIndex = _cameras.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    if (_selectedCameraIndex == -1) {
      _selectedCameraIndex = 0; // Fallback to the first camera
    }

    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
    );

    await _cameraController!.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  void switchCamera() async {
    if (_cameras.isEmpty) return;

    // Switch between front and back cameras
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;

    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
    );

    await _cameraController!.initialize();
    setState(() {});
  }

  Future<void> captureImage() async {
    if (!_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();
      widget.onCapture(File(image.path));
      Navigator.of(context).pop();
    } catch (e) {
      print('Error capturing image: $e');
      widget.onCapture(null);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Fullscreen Overlay Image
          Positioned.fill(
            child: Opacity(
              opacity: 1, // Adjust the transparency of the overlay
              child: Image.asset(
                widget.overlayImage, // Use the provided overlay image
                fit: BoxFit.cover, // Ensures the image covers the full screen
              ),
            ),
          ),

          // Capture Button
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () async {
                  // Ensure the camera is initialized before capturing the image
                  if (_cameraController != null &&
                      _cameraController!.value.isInitialized) {
                    await captureImage();
                  } else {
                    // Handle case where camera is not initialized
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Camera is not ready!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(15),
                  backgroundColor: Colors.green,
                ),
                child: const Icon(Icons.check, size: 17, color: Colors.white),
              ),
            ),
          ),

          // Switch Camera Button (Optional)
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              onPressed: switchCamera,
              icon: const Icon(Icons.cameraswitch, color: Colors.white),
              iconSize: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class Project {
  final int partnerId;
  final int agreementId;
  final String name;

  Project({
    required this.partnerId,
    required this.agreementId,
    required this.name,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      partnerId: json['partner_id'],
      agreementId: json['project_id'],
      name: json['name'],
    );
  }
}