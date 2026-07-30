import 'package:flutter/material.dart';
import '../screens/auth_wrapper.dart';

class AuthNavigation {
  static Future<void> navigateAfterAuth(BuildContext context) async {
    if (!context.mounted) return;
    navigateToAuthRoot(context);
  }
}
