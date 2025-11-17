import 'package:flutter/material.dart';

class SliderProvider extends ChangeNotifier {
  final List<String> sliderImages = [
    'assets/jpeg/slide_1_c.jpg',
    'assets/jpeg/slide_2_c.jpg',
    'assets/jpeg/slide_3_c.jpg',
    'assets/jpeg/slide_4_c.jpg',
  ];

  final List<String> titles = [
    "The much-anticipated project has officially reached completion...",
    "Successfully delivered on schedule, the project highlights...",
    "Stakeholders have praised the project for its efficiency and...",
    "A closing ceremony was held to commemorate the achievement...",
  ];

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
