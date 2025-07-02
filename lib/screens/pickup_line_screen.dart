import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gemini_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PickupLineScreen extends StatefulWidget {
  const PickupLineScreen({super.key});

  @override
  State<PickupLineScreen> createState() => _PickupLineScreenState();
}

class _PickupLineScreenState extends State<PickupLineScreen> {
  final TextEditingController _controller = TextEditingController();
  String _pickupLine = '';
  bool _loading = false;

  Future<void> generatePickupLine() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _loading = true);

    try {
      final result = await GeminiService.generateReplies(
        "Give me a flirty and witty pick-up line based on this context: ${_controller.text}",
      );
      setState(() => _pickupLine = result);
    } catch (e) {
      setState(() => _pickupLine = "Failed to generate: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Important to avoid overflow
      appBar: AppBar(
        title: Text(
          'RizzezAI - Your Flirty Wingman',
          style: GoogleFonts.playfairDisplay(
            color: const Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Describe the situation or person',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: generatePickupLine,
                    child: const Text('Generate Pick-up Line'),
                  ),
                ),
                const SizedBox(height: 20),
                if (_loading) const Center(child: CircularProgressIndicator()),
                if (_pickupLine.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.only(top: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: MarkdownBody(
                        data: _pickupLine,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
