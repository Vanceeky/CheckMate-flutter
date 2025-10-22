import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ExamScannerPage extends StatefulWidget {
  const ExamScannerPage({super.key});

  @override
  State<ExamScannerPage> createState() => _ExamScannerPageState();
}

class _ExamScannerPageState extends State<ExamScannerPage> {
  List<String> scannedPages = [];
  bool isUploading = false;
  String? uploadedPdfUrl;

  Future<void> scanExamSheets() async {
    try {
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 20,
        isGalleryImportAllowed: false,
      );

      if (pictures != null && pictures.isNotEmpty) {
        setState(() => scannedPages = pictures);
        print("Scanned ${pictures.length} pages.");
      }
    } catch (e) {
      print('Error scanning exam sheets: $e');
    }
  }

  Future<File> _generatePdf(List<String> images) async {
    final pdf = pw.Document();

    for (final imagePath in images) {
      final image = pw.MemoryImage(File(imagePath).readAsBytesSync());
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }

    final outputDir = await getTemporaryDirectory();
    final pdfFile = File("${outputDir.path}/exam_scan.pdf");
    await pdfFile.writeAsBytes(await pdf.save());
    return pdfFile;
  }

  Future<void> _uploadToBackend(File pdfFile) async {
    setState(() => isUploading = true);

    final uri = Uri.parse("https://your-backend-api.com/upload");
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', pdfFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      setState(() => uploadedPdfUrl = "✅ Uploaded Successfully!");
    } else {
      setState(() => uploadedPdfUrl = "❌ Upload failed (${response.statusCode})");
    }

    setState(() => isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("Evaluate Exam Sheet"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Camera Preview Placeholder
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.camera_alt_outlined, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        "Camera Preview",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xff0f172a),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera, size: 48, color: Colors.white70),
                          SizedBox(height: 8),
                          Text(
                            "Live Camera Feed",
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            "Position exam sheet in frame",
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Capture Page Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text(
                "Capture Page",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              onPressed: scanExamSheets,
            ),

            const SizedBox(height: 20),

            // Show Captured Pages
            if (scannedPages.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: scannedPages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(scannedPages[index]), fit: BoxFit.contain),
                      ),
                    );
                  },
                ),
              ),

            if (scannedPages.isNotEmpty)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file, color: Colors.white),
                label: Text(
                  isUploading ? "Uploading..." : "Finish & Upload PDF",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: isUploading
                    ? null
                    : () async {
                        final pdfFile = await _generatePdf(scannedPages);
                        await _uploadToBackend(pdfFile);
                      },
              ),

            if (uploadedPdfUrl != null) ...[
              const SizedBox(height: 8),
              Text(
                uploadedPdfUrl!,
                style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
