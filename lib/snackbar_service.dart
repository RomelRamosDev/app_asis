import 'package:flutter/material.dart';

class NotificationService {
  static final GlobalKey<ScaffoldMessengerState> key =
      GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(String message) {
    key.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  static void showError(String message) {
    key.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  static void showWarning(String message) {
    key.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  static void showInfo(String message) {
    key.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
