import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bio_upgrader_service.dart';

class BioUpgraderScreen extends StatefulWidget {
  const BioUpgraderScreen({super.key});

  @override
  State<BioUpgraderScreen> createState() => _BioUpgraderScreenState();
}

class _BioUpgraderScreenState extends State<BioUpgraderScreen> {
  final TextEditingController _bioController = TextEditingController();
  String _upgradedBio = '';
  bool _loading = false;

  String _selectedStyle = 'Romantic';
  final List<String> _styles = ['Romantic', 'Funny', 'Confident'];

  Future<void> upgradeBio() async {
    setState(() => _loading = true);

    final result = await BioUpgraderService.generateUpgradedBio(
      _bioController.text,
      _selectedStyle,
    );

    setState(() {
      _upgradedBio = result;
      _loading = false;
    });
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Bio copied to clipboard!")));
  }

  Future<void> _refresh() async {
    setState(() {
      _bioController.clear();
      _upgradedBio = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Bio Upgrader",
          style: GoogleFonts.playfairDisplay(
            color: const Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Choose a style:"),
              DropdownButton<String>(
                value: _selectedStyle,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStyle = value);
                  }
                },
                items: _styles.map((style) {
                  return DropdownMenuItem<String>(
                    value: style,
                    child: Text(style),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Enter your current bio",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: upgradeBio,
                child: const Text("Upgrade My Bio"),
              ),
              const SizedBox(height: 16),
              if (_loading) const Center(child: CircularProgressIndicator()),
              if (_upgradedBio.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Upgraded Bio:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _upgradedBio,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => copyToClipboard(_upgradedBio),
                        tooltip: "Copy to clipboard",
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
