import 'package:shared_preferences/shared_preferences.dart';

Future<int> getSelectedCompany() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return pref.getInt("selectedCompany") ?? 1;
}

Future<void> saveSelectedCompany(int id) async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  await pref.setInt("selectedCompany", id);
}
