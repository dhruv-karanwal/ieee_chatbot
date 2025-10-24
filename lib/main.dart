import 'package:flutter/material.dart';
import 'screens/chatbot_screen.dart';
import 'screens/pdf_screen.dart';

void main() {
  runApp(const IEEEChatbotApp());
}

class IEEEChatbotApp extends StatelessWidget {
  const IEEEChatbotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IEEE AI Chatbot',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const ChatScreen(),
      routes: {'/pdf': (context) => const PdfScreen()},
    );
  }
}
