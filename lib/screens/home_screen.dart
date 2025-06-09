import 'package:flutter/material.dart';
import 'chat_screenshot_screen.dart';
import 'pickup_line_screen.dart';
import 'bio_upgrader_screen.dart';
import 'zodiac_forecast_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('RizzexAI - Your Flirty Wingman'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.chat), text: "Chat Screenshot"),
              Tab(icon: Icon(Icons.bolt), text: "Pick-up Line"),
              Tab(icon: Icon(Icons.edit_note), text: "Bio Upgrader"),
              Tab(icon: Icon(Icons.star), text: "Zodiac Forecast"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ChatScreenshotScreen(),
            PickupLineScreen(),
            BioUpgraderScreen(),
            ZodiacForecastScreen(),
          ],
        ),
      ),
    );
  }
}
