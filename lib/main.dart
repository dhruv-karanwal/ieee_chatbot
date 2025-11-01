import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/chatbot_screen.dart';
import 'screens/pdf_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:
        'https://oojdbkinkewpbclcumvj.supabase.co', // replace with your project URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9vamRia2lua2V3cGJjbGN1bXZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwMTU0MzgsImV4cCI6MjA3NzU5MTQzOH0.HHDcuciiUicL5bxlvLlYIC8Bcx8Jpeh09DsknWgTv7M', // replace with your anon/public key
  );

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
