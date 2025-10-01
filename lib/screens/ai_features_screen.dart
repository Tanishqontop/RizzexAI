import 'package:flutter/material.dart';
import 'chat_screenshot_screen.dart';
import 'pickup_line_screen.dart';
import 'bio_upgrader_screen.dart';
import 'zodiac_forecast_screen.dart';
import 'notes_screen.dart';

class AIFeaturesScreen extends StatelessWidget {
  const AIFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF6B46C1),
          title: const Text('AI Features',
              style: TextStyle(color: Colors.white)),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFFFCDD2),
            tabs: [
              Tab(
                  icon: Icon(Icons.chat, color: Colors.white),
                  text: "Chat Screenshot"),
              Tab(
                  icon: Icon(Icons.bolt, color: Colors.white),
                  text: "Pick-up Line"),
              Tab(
                  icon: Icon(Icons.edit_note, color: Colors.white),
                  text: "Bio Upgrader"),
              Tab(
                  icon: Icon(Icons.star, color: Colors.white),
                  text: "Zodiac Forecast"),
              Tab(icon: Icon(Icons.note, color: Colors.white), text: "Notes"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ChatScreenshotScreen(),
            PickupLineScreen(),
            BioUpgraderScreen(),
            ZodiacForecastScreen(),
            NotesScreen(),
          ],
        ),
      ),
    );
  }
}
