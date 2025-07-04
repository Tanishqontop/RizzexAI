import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/gemini_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatScreenshotScreen extends StatefulWidget {
  const ChatScreenshotScreen({super.key});

  @override
  State<ChatScreenshotScreen> createState() => _ChatScreenshotScreenState();
}

class _ChatScreenshotScreenState extends State<ChatScreenshotScreen> {
  File? _image;
  String _extractedText = '';
  String _responseText = '';
  bool _loading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (!mounted) return;
      setState(() {
        _image = File(image.path);
      });
      extractText(image.path);
    }
  }

  Future<void> extractText(String imagePath) async {
    setState(() => _loading = true);
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );
    await textRecognizer.close();
    setState(() {
      _extractedText = recognizedText.text;
      _loading = false;
    });
  }

  Future<void> getFlirtyReplies() async {
    if (_extractedText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a valid chat screenshot.")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await GeminiService.generateReplies(_extractedText);
      setState(() => _responseText = result);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => _loading = false);
    }
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Copied to clipboard!")));
  }

  Future<void> _refresh() async {
    setState(() {
      _image = null;
      _extractedText = '';
      _responseText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Chat Screenshot'),
            ),
            if (_image != null) ...[
              Image.file(_image!),
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_extractedText),
                ),
              ),
              ElevatedButton(
                onPressed: getFlirtyReplies,
                child: const Text('Generate Flirty Replies'),
              ),
            ],
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_responseText.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "AI-Generated Replies:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ..._responseText
                      .split('\n')
                      .where((line) => line.trim().isNotEmpty)
                      .map(
                        (reply) => ListTile(
                          title: MarkdownBody(
                            data: reply,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(fontSize: 16),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () => copyToClipboard(reply),
                          ),
                        ),
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
