import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/gemini_service.dart';

class PdfScreen extends StatefulWidget {
  const PdfScreen({super.key});

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  final GeminiService _gemini = GeminiService();
  String _output = "";
  bool _loading = false;

  Future<void> _pickAndSummarizePdf() async {
    setState(() => _loading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String text = await _gemini.extractTextFromPdf(file);
        String summary = await _gemini.summarizePdf(text);

        setState(() => _output = summary);
      } else {
        setState(() => _output = "No file selected.");
      }
    } catch (e) {
      setState(() => _output = "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF Summary Assistant")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _loading ? null : _pickAndSummarizePdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Upload and Summarize PDF"),
            ),
            const SizedBox(height: 20),
            if (_loading) const CircularProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_output, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
