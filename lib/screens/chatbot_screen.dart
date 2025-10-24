import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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

  void _sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(text: text, isUser: true, type: MessageType.text));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await gemini.sendMessage(text);
      setState(() {
        _messages.add(
          Message(text: reply, isUser: false, type: MessageType.text),
        );
        _isLoading = false;
      });
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

        // Add PDF upload message
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

        try {
          pdfText = await PdfService.extractTextFromPdf(pdfFile);
          final summary = await gemini.summarizePdf(pdfText!);

          setState(() {
            _messages.add(
              Message(
                text: "📄 PDF Analysis Complete!\n\n$summary",
                isUser: false,
                type: MessageType.text,
              ),
            );
            _isLoading = false;
          });
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

    try {
      final answer = await gemini.answerFromPdf(pdfText!, question);
      setState(() {
        _messages.add(
          Message(text: answer, isUser: false, type: MessageType.text),
        );
        _isLoading = false;
      });
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "IEEE AI Chatbot",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_uploadedFileName != null)
                  Text(
                    "📄 (_uploadedFileName!)",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              onPressed: _pickPdf,
              tooltip: "Upload PDF",
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: ChatBubble(message: _messages[index]),
                        );
                      },
                    ),
                  ),
          ),

          // Loading Indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "AI is thinking...",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // Input Area
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // PDF Upload Button
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.attach_file,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        onPressed: _pickPdf,
                        tooltip: "Upload PDF",
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Text Input
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: pdfText != null
                                ? "Ask about the PDF or type a message..."
                                : "Type your message...",
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.6),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          style: theme.textTheme.bodyLarge,
                          onSubmitted: (text) {
                            final trimmedText = text.trim();
                            if (trimmedText.isNotEmpty) {
                              if (pdfText != null &&
                                  trimmedText.contains("?")) {
                                _askAboutPdf(trimmedText);
                              } else {
                                _sendMessage(trimmedText);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Send Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          final text = _controller.text.trim();
                          if (text.isNotEmpty) {
                            if (pdfText != null && text.contains("?")) {
                              _askAboutPdf(text);
                            } else {
                              _sendMessage(text);
                            }
                          }
                        },
                        tooltip: "Send message",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.primaryContainer.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Welcome to IEEE AI Chatbot",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Start a conversation or upload a PDF document\nto get started with AI-powered assistance",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _pickPdf,
            icon: const Icon(Icons.upload_file),
            label: const Text("Upload PDF"),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
