import 'dart:convert';

import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static final SharedPref preferences = SharedPref._internal();

  static late SharedPreferences sharedPreferences;

  factory SharedPref() {
    return preferences;
  }

  SharedPref._internal();

  ///Below method is to initialize the SharedPreference instance.
  Future instantiatePreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  ///Below method is to return the SharedPreference instance.
  SharedPreferences getPreferenceInstance() {
    return sharedPreferences;
  }

  ///Below method is to set the string value in the SharedPreferences.
  setPreferencesString(String key, String stringValue) {
    sharedPreferences.setString(key, stringValue);
  }

  ///Below method is to get the string value from the SharedPreferences.
  String getPreferenceString(String key) {
    return sharedPreferences.getString(key) ?? "";
  }

  ///Below method is to set the boolean value in the SharedPreferences.
  setPreferencesBoolean(String key, bool booleanValue) {
    sharedPreferences.setBool(key, booleanValue);
  }

  ///Below method is to get the boolean value from the SharedPreferences.
  bool getPreferenceBoolean(String key) {
    return sharedPreferences.getBool(key) ?? false;
  }

  ///Below method is to set the double value in the SharedPreferences.
  setPreferenceDouble(String key, double doubleValue) {
    sharedPreferences.setDouble(key, doubleValue);
  }

  ///Below method is to set the double value from the SharedPreferences.
  double getPreferenceDouble(String key) {
    return sharedPreferences.getDouble(key) ?? 0.0;
  }

  ///Below method is to set the int value in the SharedPreferences.
  setPreferenceInt(String key, int intValue) {
    sharedPreferences.setInt(key, intValue);
  }

  ///Below method is to get the int value from the SharedPreferences.
  int getPreferenceInt(String key) {
    return sharedPreferences.getInt(key) ?? 0;
  }

  ///Below method is to remove the received preference.
  removePreference(String key) {
    sharedPreferences.remove(key);
  }

  ///Below method is to check the availability of the received preference .
  bool containPreference(String key) {
    if (sharedPreferences.get(key) == null) {
      return false;
    } else {
      return true;
    }
  }

  ///Below method is to clear the SharedPreference.
  clearPreferences() async {
    await sharedPreferences.clear();
  }

  /// Set the app language code in SharedPreferences.
  Future<void> setAppLanguage(String languageCode) async {
    await sharedPreferences.setString('app_language', languageCode);
  }

  /// Get the app language code from SharedPreferences.
  String getAppLanguage() {
    return sharedPreferences.getString('app_language') ?? '';
  }

  bool isArabic() {
    return getAppLanguage() == 'ar';
  }

  ////[helper_functions]
  static bool isUserAuthenticated() {
    final data = checkLoginAndRegistration();
    final isRegistered = data['isRegistered'] as bool;
    final loginData = data['loginResponse'] as LoginResponseModel?;

    return isRegistered && loginData != null;
  }

  static LoginResponseModel getLoginData() {
    final data = checkLoginAndRegistration();
    final loginData = data['loginResponse'] as LoginResponseModel?;
    // Return empty model if not authenticated (for guest mode)
    return loginData ?? LoginResponseModel();
  }

  static LoginResponseModel? getLoginDataOrNull() {
    final data = checkLoginAndRegistration();
    return data['loginResponse'] as LoginResponseModel?;
  }

  static Map<String, dynamic> checkLoginAndRegistration() {
    final isRegistered = sharedPreferences.getBool('isRegistered') ?? false;

    // Try 'loginResponse' key first (new/correct key)
    String? loginJson = sharedPreferences.getString('loginResponse');

    // Fallback to 'LOGIN_RESPONSE' key if not found (old key for migration)
    if (loginJson == null || loginJson.isEmpty) {
      loginJson = sharedPreferences.getString('LOGIN_RESPONSE');
      // If found in old key, migrate it to new key
      if (loginJson != null && loginJson.isNotEmpty) {
        sharedPreferences.setString('loginResponse', loginJson);
      }
    }

    LoginResponseModel? loginResponse;
    if (loginJson != null) {
      loginResponse = LoginResponseModel.fromJson(jsonDecode(loginJson));
    }

    return {
      'isRegistered': isRegistered,
      'loginResponse': loginResponse,
    };
  }

  static int getSelectedCompany() {
    return sharedPreferences.getInt("selectedCompany") ?? 1;
  }

  static saveSelectedCompany(int id) {
    return sharedPreferences.setInt("selectedCompany", id);
  }

  getUserBase64Image() {
    final userJson = sharedPreferences.getString('loginResponse');
    if (userJson != null) {
      final parsed = json.decode(userJson);
      final imageBase64 = parsed['result']?['data']?['image_url'] ?? '';
      return imageBase64;
    }
    return '';
  }
}
