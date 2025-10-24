import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  /// Extract text from a PDF file
  static Future<String> extractTextFromPdf(File file) async {
    final PdfDocument document = PdfDocument(
      inputBytes: await file.readAsBytes(),
    );

    final String text = PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
  }
}
