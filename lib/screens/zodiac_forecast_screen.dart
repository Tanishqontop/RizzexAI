import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/zodiac_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ZodiacForecastScreen extends StatefulWidget {
  const ZodiacForecastScreen({super.key});

  @override
  State<ZodiacForecastScreen> createState() => _ZodiacForecastScreenState();
}

class _ZodiacForecastScreenState extends State<ZodiacForecastScreen> {
  String? _selectedSign;
  String _forecast = '';
  bool _loading = false;

  final List<String> zodiacSigns = [
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces',
  ];

  Future<void> getForecast() async {
    if (_selectedSign == null) return;
    setState(() => _loading = true);
    final result = await ZodiacService.getRizzForecast(_selectedSign!);
    setState(() {
      _forecast = result;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _selectedSign = null;
      _forecast = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Zodiac Forecast',
          style: GoogleFonts.playfairDisplay(
            color: const Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Select your Zodiac sign",
                border: OutlineInputBorder(),
              ),
              value: _selectedSign,
              onChanged: (value) => setState(() => _selectedSign = value),
              items: zodiacSigns.map((sign) {
                return DropdownMenuItem(value: sign, child: Text(sign));
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: getForecast,
              child: const Text("Get My Rizz Forecast"),
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (_forecast.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: MarkdownBody(
                  data: _forecast,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
