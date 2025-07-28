import 'dart:convert';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/screens/home_screen.dart';
import 'package:el_race/ui/presentation/my_request/bloc/requests_bloc.dart';
import 'package:el_race/ui/presentation/my_request/bloc/requests_event.dart';
import 'package:el_race/ui/widgets/custom_toast.dart';
import 'package:el_race/utils/custom_navigate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show BlocProvider;
import 'package:flutter_translate/flutter_translate.dart';

class Util {
  static fetchHomeScreenData(cxt){
    BlocProvider.of<HomeBloc>(cxt, listen: false)
    .add(const FetchLastMonthAttendanceSummary());


    BlocProvider.of<RequestsBloc>(cxt, listen: false)
    .add(const FetchRequestsCount());
  }

  static Future<void> saveAndChangeLocale(BuildContext context, String languageCode) async {
    await SharedPref().setAppLanguage(languageCode);
    await changeLocale(context, languageCode);
    pushPage(const HomeScreen(), context);
  }

  static pushPage(Widget route, BuildContext cxt) {
    return Navigator.push(
      cxt,
      CustomPageRoute(child: route),
    );
  }

  static pushPageAndRemoveRoutes(Widget pushRoute, BuildContext cxt) {
    Navigator.of(cxt).pushAndRemoveUntil(
      CustomPageRoute(child: pushRoute),
      (route) => false,
    );
  }



  static String monthName(int month) {
    const monthNames = [
      "Jan", "Feb", "Mar", "Apr", "May", "June", "July", "Aug", "Sept", "Oct", "Nov", "Dec"
    ];
    return month >= 1 && month <= 12 ? monthNames[month - 1] : "";
  }
  static void hideKeyBoard(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  static void showToast(String body) {
    CustomToast().showToast(body);
  }

  static bool isValidBase64(String str) {
    try {
      if (str.trim().isEmpty || str.length % 4 != 0) return false;
      base64Decode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

}

