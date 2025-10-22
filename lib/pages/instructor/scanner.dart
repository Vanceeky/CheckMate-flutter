import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

class ExamScannerPage extends StatefulWidget {
  const ExamScannerPage({super.key});

  @override
  State<ExamScannerPage> createState() => _ExamScannerPageState();
}

class _ExamScannerPageState extends State<ExamScannerPage> {
  List<String> scannedPages = [];

  Future<void> scanExamSheets() async {
    try {
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 20, // maximum number of pages to scan
        isGalleryImportAllowed: false, // disable importing from gallery
      );

      if (pictures != null && pictures.isNotEmpty) {
        setState(() {
          scannedPages = pictures;
        });
        print("Scanned ${pictures.length} pages.");
      }
    } catch (e) {
      print('Error scanning exam sheets: $e');
    }
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Exam Sheets")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: scanExamSheets,
            child: const Text("Start Scanning"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scannedPages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.file(
                    File(scannedPages[index]),
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
