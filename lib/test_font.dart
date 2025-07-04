import 'package:flutter/material.dart';

class FontTestScreen extends StatelessWidget {
  const FontTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Font Test',
          style: TextStyle(fontFamily: 'PlayfairDisplay', color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Playfair Display Regular',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 24,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Playfair Display Bold',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
