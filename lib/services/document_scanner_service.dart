import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class DocumentScannerService {
  /// Scans documents using the native OS scanner.
  /// Returns a list of file paths to the scanned images.
  Future<List<String>> scanDocument() async {
    try {
      List<String>? pictures;
      try {
        pictures = await CunningDocumentScanner.getPictures();
      } catch (exception) {
        // Handle cancellation or error
        print('Error scanning document: $exception');
        return [];
      }
      
      return pictures ?? [];
    } catch (e) {
      print('Error in scanDocument: $e');
      return [];
    }
  }

  /// Generates a PDF from a list of image paths and saves it.
  /// Returns the path to the generated PDF.
  Future<String?> generatePdf(List<String> imagePaths) async {
    if (imagePaths.isEmpty) return null;

    final pdf = pw.Document();

    for (var path in imagePaths) {
      final image = pw.MemoryImage(
        File(path).readAsBytesSync(),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image),
            );
          },
        ),
      );
    }

    try {
      final output = await getApplicationDocumentsDirectory();
      final now = DateTime.now().millisecondsSinceEpoch;
      final file = File('${output.path}/scan_$now.pdf');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }

  /// Opens a file using the system default viewer.
  Future<void> openFile(String path) async {
    await OpenFile.open(path);
  }
}
