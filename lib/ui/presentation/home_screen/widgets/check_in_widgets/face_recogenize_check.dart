import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/screens/face_recognition_status_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FaceRecogenizeCheck extends StatelessWidget {
  const FaceRecogenizeCheck({super.key});

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