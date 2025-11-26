import 'package:flutter/material.dart';
import 'package:flutter_toast_notification/flutter_toast_notification.dart';

class AppToast {
  static final FlutterToast _toast = FlutterToast();

  static void showSuccess(BuildContext context, String message) {
    _toast.showSuccess(context, message);
  }

  static void showError(BuildContext context, String message) {
    _toast.showError(context, message);
  }

  static void showWarning(BuildContext context, String message) {
    _toast.showWarning(context, message);
  }

  static void showInfo(BuildContext context, String message) {
    _toast.showInfo(context, message);
  }
}
