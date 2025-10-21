import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey = "AIzaSyB3SJF1FXQqtIvXrF_Q_upKc14RPkxtKfI";

  final String context = """
  You are the official AI assistant of IEEE VIT Pune.
  You know about:
  - Club activities, team structure, and ongoing events.
  - IEEE’s mission, global initiatives, and technologies.
  - Basic tech concepts (AI, IoT, Robotics, etc.).

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
      final reply = data["candidates"][0]["content"]["parts"][0]["text"];
      return reply;
    } else {
      return "⚠️ Error ${response.statusCode}: ${response.body}";
    }
  }
}
