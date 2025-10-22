import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:http/http.dart' as http;

class ExamSheetScanner extends StatefulWidget {
  const ExamSheetScanner({super.key});

  @override
  State<ExamSheetScanner> createState() => _ExamSheetScannerState();
}

class _ExamSheetScannerState extends State<ExamSheetScanner> {
  List<String> scannedPages = [];

  Future<void> scanExamSheets() async {
    try {
      final result = await CunningDocumentScanner.scanDocument(
        maxNumOfDocuments: 20, // allow multiple pages
        source: ScannerSource.CAMERA,
        multiPageEnabled: true,
        enableTorch: true,
        enableFilters: true, // clean scanned page
      );

      if (result != null && result.isNotEmpty) {
        setState(() {
          scannedPages = result;
        });
      }
    } catch (e) {
      print('Error scanning exam sheets: $e');
    }
  }

  Future<void> uploadToBackend() async {
    if (scannedPages.isEmpty) return;

    var uri = Uri.parse('https://your-backend.com/api/upload-exam');
    var request = http.MultipartRequest('POST', uri);

    // add scanned images
    for (var pagePath in scannedPages) {
      request.files.add(await http.MultipartFile.fromPath('files', pagePath));
    }

    // add metadata if needed
    request.fields['student_id'] = '123456';
    request.fields['exam_id'] = 'midterm_1';

    var response = await request.send();

    if (response.statusCode == 200) {
      print('Exam sheet uploaded successfully');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploaded exam sheet successfully')));
    } else {
      print('Upload failed with status: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${response.statusCode}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Exam Sheets')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: scanExamSheets,
              child: const Text('Scan Exam Sheets'),
            ),
            const SizedBox(height: 20),
            scannedPages.isEmpty
                ? const Text('No scanned pages yet.')
                : Expanded(
                    child: ListView.builder(
                      itemCount: scannedPages.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Image.file(File(scannedPages[index])),
                      ),
                    ),
                  ),
            if (scannedPages.isNotEmpty)
              ElevatedButton(
                onPressed: uploadToBackend,
                child: const Text('Upload to Backend'),
              ),
          ],
        ),
      ),
    );
  }
}
