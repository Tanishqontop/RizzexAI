import 'package:flutter/material.dart';
import 'package:rizzexai/theme/app_typography.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(fontFamily: AppFonts.family),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Geist Sans Test',
            style: AppFonts.display(fontSize: 32, color: Colors.white),
          ),
        ),
      ),
    ),
  );
}
