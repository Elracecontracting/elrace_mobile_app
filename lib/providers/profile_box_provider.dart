import 'package:flutter/material.dart';

class ProfileBoxProvider extends ChangeNotifier {
  bool _isProfileVisible = false;

  bool get isProfileVisible => _isProfileVisible;

  void toggleProfileBox() {
    _isProfileVisible = !_isProfileVisible;
    notifyListeners();
  }

  void hideProfileBox() {
    _isProfileVisible = false;
    notifyListeners();
  }
}
