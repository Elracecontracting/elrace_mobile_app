import 'package:flutter/material.dart';

class SliderProvider extends ChangeNotifier {
  final List<String> sliderImages = [
    'assets/png/slider_2.png',
    'assets/png/slider_3.png',
    'assets/png/slider_4.png',
    'assets/png/slider.png',
  ];



  final List<String> titles = [
    "A Closing Ceremony Was Held To Communicate The Achievement",
    "A Closing Ceremony Was Held To Communicate The Achievement",
    "A Closing Ceremony Was Held To Communicate The Achievement",
    "A Closing Ceremony Was Held To Communicate The Achievement",
  ];

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
} 