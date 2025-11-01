import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import '../widgets/chat_bubble.dart';
import '../services/gemini_service.dart';
import '../services/pdf_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService gemini = GeminiService();
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? pdfText;
  String? _uploadedFileName;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _addWelcomeMessage();
    testSupabaseConnection();
  }

  Future<void> testSupabaseConnection() async {
    try {
      final response = await supabase.from('faqs').select().limit(1);
      debugPrint('✅ Supabase connected successfully: $response');
    } catch (e) {
      debugPrint('❌ Supabase connection failed: $e');
    }
  }

  Future<void> _saveMessageToSupabase(String sender, String message) async {
    try {
      await supabase.from('chats').insert({
        'sender': sender,
        'message': message,
      });
      debugPrint('💾 Message saved: [$sender] $message');
    } catch (e) {
      debugPrint('❌ Error saving message to Supabase: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        Message(
          text:
              "👋 Hello! I'm your IEEE AI Chatbot. You can ask me anything or upload a PDF document for analysis. How can I help you today?",
          isUser: false,
          type: MessageType.system,
        ),
      );
    });
    _animationController.forward();
  }

  String _cleanMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'\1')
        .replaceAll(RegExp(r'\*(.*?)\*'), r'\1')
        .replaceAll(RegExp(r'[*•\-\\]+\s*\d*\s*'), '')
        .replaceAll(RegExp(r'#+ '), '')
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .trim();
  }

  // ✅ Basic Gemini-only chat logic
  void _sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(text: text, isUser: true, type: MessageType.text));
      _isLoading = true;
    });
    _scrollToBottom();
    await _saveMessageToSupabase('user', text);

    try {
      final reply = await gemini.sendMessage(text);
      setState(() {
        _messages.add(
          Message(
            text: _cleanMarkdown(reply),
            isUser: false,
            type: MessageType.text,
          ),
        );
        _isLoading = false;
      });
      await _saveMessageToSupabase('bot', reply);
    } catch (e) {
      setState(() {
        _messages.add(
          Message(
            text: "Sorry, I encountered an error. Please try again.",
            isUser: false,
            type: MessageType.text,
          ),
        );
        _isLoading = false;
      });
      await _saveMessageToSupabase('bot', 'Error occurred while replying');
    }

    _controller.clear();
    _scrollToBottom();
  }

  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File pdfFile = File(result.files.single.path!);
        String fileName = result.files.single.name;

        setState(() {
          _isLoading = true;
          _uploadedFileName = fileName;
        });

        setState(() {
          _messages.add(
            Message(
              text: "📄 Uploaded: $fileName",
              isUser: true,
              type: MessageType.pdf,
              fileName: fileName,
            ),
          );
        });
        await _saveMessageToSupabase('user', "📄 Uploaded: $fileName");

        try {
          pdfText = await PdfService.extractTextFromPdf(pdfFile);
          final summary = await gemini.summarizePdf(pdfText!);

          setState(() {
            _messages.add(
              Message(
                text: "📄 PDF Analysis Complete!\n\n${_cleanMarkdown(summary)}",
                isUser: false,
                type: MessageType.text,
              ),
            );
            _isLoading = false;
          });
          await _saveMessageToSupabase(
            'bot',
            "📄 PDF Analysis Complete! $summary",
          );
        } catch (e) {
          setState(() {
            _messages.add(
              Message(
                text:
                    "❌ Error processing PDF. Please try again with a different file.",
                isUser: false,
                type: MessageType.text,
              ),
            );
            _isLoading = false;
          });
          await _saveMessageToSupabase('bot', "❌ Error processing PDF.");
        }
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error picking PDF file"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _askAboutPdf(String question) async {
    if (pdfText == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload a PDF first!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _messages.add(
        Message(text: question, isUser: true, type: MessageType.text),
      );
      _isLoading = true;
    });
    _scrollToBottom();
    await _saveMessageToSupabase('user', question);

    try {
      final answer = await gemini.answerFromPdf(pdfText!, question);
      setState(() {
        _messages.add(
          Message(
            text: _cleanMarkdown(answer),
            isUser: false,
            type: MessageType.text,
          ),
        );
        _isLoading = false;
      });
      await _saveMessageToSupabase('bot', answer);
    } catch (e) {
      setState(() {
        _messages.add(
          Message(
            text:
                "Sorry, I couldn't process your question about the PDF. Please try again.",
            isUser: false,
            type: MessageType.text,
          ),
        );
        _isLoading = false;
      });
      await _saveMessageToSupabase(
        'bot',
        "Error answering question about PDF.",
      );
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("IEEE AI Chatbot"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => Navigator.pushNamed(context, '/pdf'),
            tooltip: "PDF Summarizer",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ChatBubble(
                    message: message,
                    onPdfTap: (fileName) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Tapped on $fileName")),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: pdfText != null
                          ? "Ask about the PDF or general question..."
                          : "Type your message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: _pickPdf,
                  tooltip: "Upload PDF",
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                  tooltip: "Send Message",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
