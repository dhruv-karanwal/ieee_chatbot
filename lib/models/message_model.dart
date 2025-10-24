import 'dart:io';

class Message {
  final String text;
  final bool isUser;
  final String? fileName;
  final String? filePath;
  final DateTime timestamp;
  final MessageType type;

  Message({
    required this.text,
    required this.isUser,
    this.fileName,
    this.filePath,
    DateTime? timestamp,
    this.type = MessageType.text,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum MessageType {
  text,
  pdf,
  image,
  system,
}
