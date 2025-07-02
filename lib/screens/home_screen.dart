import 'package:flutter/material.dart';
import 'chat_screenshot_screen.dart';
import 'pickup_line_screen.dart';
import 'bio_upgrader_screen.dart';
import 'zodiac_forecast_screen.dart';
import 'package:rizzexai/services/auth_service.dart';
import 'auth/sign_in_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF0000),
          title: const Text('RizzexAI - Your Flirty Wingman',
              style: TextStyle(color: Colors.white)),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFFFF0000), width: 2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFFFF0000)),
                  tooltip: 'Log Out',
                  onPressed: () async {
                    await AuthService.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const SignInScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
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
