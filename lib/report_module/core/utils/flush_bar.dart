import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

Future<void> showFlushBar(context, {required String message}) async {
  Flushbar(
    margin: const EdgeInsets.all(16),
    borderRadius: BorderRadius.circular(8),
    message: message,
    duration: const Duration(seconds: 3),
  ).show(context);
}
