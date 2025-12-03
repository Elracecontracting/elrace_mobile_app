import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/screens/face_recognition_status_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FaceRecogenizeCheck extends StatefulWidget {
  const FaceRecogenizeCheck({super.key});

  @override
  State<FaceRecogenizeCheck> createState() => _FaceRecogenizeCheckState();
}

class _FaceRecogenizeCheckState extends State<FaceRecogenizeCheck> {
  bool _hasCheckedPending = false;

  @override
  void initState() {
    super.initState();
    // Check for pending face verification after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingFaceVerification();
    });
  }

  void _checkPendingFaceVerification() {
    if (_hasCheckedPending) return;
    _hasCheckedPending = true;

    final isPending =
        SharedPref().getPreferenceBoolean('pendingFaceVerification');
    if (isPending) {
      // Resume face verification - user must complete it
      context.read<HomeBloc>().add(
            const UpdateFaceRecognitionStatus(FaceRecognitionStatus.matching),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10.w,
      left: 0,
      right: 0,
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final status = context.read<HomeBloc>().faceRecognitionStatus;
          return FaceRecognitionStatusIcon(status: status);
        },
      ),
    );
  }
}
