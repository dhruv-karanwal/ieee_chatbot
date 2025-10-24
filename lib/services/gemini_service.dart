import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class GeminiService {
  final String apiKey = "AIzaSyB3SJF1FXQqtIvXrF_Q_upKc14RPkxtKfI";

  final String context = """
You are the official AI assistant of IEEE VIT Pune.
You know about:
- Club activities, team structure, and ongoing events.
- IEEE’s mission, global initiatives, and technologies.
- Basic tech concepts (AI, IoT, Robotics, etc.).
- You can also read PDFs and summarize or analyze them like research papers.
- Sumarize PDFs in the structure of a research paper:
  - Title and citation
  - Research objective / problem statement
  - Aim and scope
  - Background / literature review
  - Methodology / approach
  - Results / findings
  - Analysis / discussion
  - Conclusion
  - Future work / recommendations

Club data:
 - Chairperson: Vaibhav Pujari
 - Vice Chair: Unnati Vaidya
 - Upcoming Events: Tech Fest
 - Faculty Advisor: Prof. J.K Jabade
 - Secretary: Nainish Jaiswal and Rushikesh Gaikar
 - Finance Head: Vaibhav Panchal
 - Multi Media Head: Prerak Gadpayale and Janhavi Gattani
 - Curation Head: Nitesh Rajpurohit
 - Research Head: Yash Kale
 - Sponsorship Head: Sujal Thakur
 - Coding Club Head: Yogiraj Chaukhande and Dhanashree Petare
 - App Head: Vansh Bhatt
 - Web Head: Harsh Mehta
 - AI Head: Pratham Tomar
""";

  /// Send a general chat message
  Future<String> sendMessage(String userInput) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-latest:generateContent?key=$apiKey",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": "$context\nUser: $userInput\nAssistant:"},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"];
    } else {
      return "⚠️ Error ${response.statusCode}: ${response.body}";
    }
  }

  /// Extract text from PDF file
  Future<String> extractTextFromPdf(File file) async {
    final PdfDocument document = PdfDocument(
      inputBytes: await file.readAsBytes(),
    );
    final String text = PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
  }

  /// Summarize a given PDF content
  Future<String> summarizePdf(String pdfText) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-latest:generateContent?key=$apiKey",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "$context\nThe following is a PDF document. Summarize it as a research paper summary:\n\n$pdfText",
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"];
    } else {
      return "⚠️ Error ${response.statusCode}: ${response.body}";
    }
  }

  /// Answer a question based on a PDF's text
  Future<String> answerFromPdf(String pdfText, String question) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-latest:generateContent?key=$apiKey",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "$context\nThe following is a PDF document:\n$pdfText\nQuestion: $question\nAnswer:",
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"];
    } else {
      return "⚠️ Error ${response.statusCode}: ${response.body}";
    }
  }
}
