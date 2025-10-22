import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http; // Import http

import 'package:file_saver/file_saver.dart';

class ExamScannerPage extends StatefulWidget {
  const ExamScannerPage({super.key});

  @override
  State<ExamScannerPage> createState() => _ExamScannerPageState();
}

class _ExamScannerPageState extends State<ExamScannerPage> {
  List<String> scannedPages = [];
  bool isProcessing = false; // Combined loading state
  String? statusMessage; // For PDF generation or upload status

  /// Launches the document scanner
  Future<void> scanExamSheets() async {
    try {
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 20,
        isGalleryImportAllowed: false,
      );

      if (pictures != null && pictures.isNotEmpty) {
        setState(() => scannedPages.addAll(pictures));
        print("Scanned ${pictures.length} pages.");
        // Automatically show the modal after scanning
        if (mounted) {
          _showScannedPagesModal();
        }
      }
    } catch (e) {
      print('Error scanning exam sheets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning: $e')),
        );
      }
    }
  }

  /// Generates a PDF document from the list of image paths
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

    // Still use temp directory for the initial creation
    final outputDir = await getTemporaryDirectory();
    final pdfFile = File("${outputDir.path}/exam_scan.pdf");
    await pdfFile.writeAsBytes(await pdf.save());
    return pdfFile;
  }

  /// NEW FUNCTION: Copies the file to a user-visible directory
  Future<File> _savePdfToDevice(File tempPdfFile) async {
    // 1. Get the user-accessible documents directory
    final directory = await getApplicationDocumentsDirectory();

    // 2. Create a unique file name to avoid overwriting files
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String newPath = "${directory.path}/ExamScan_$timestamp.pdf";

    // 3. Copy the temporary file to the new, permanent path
    final File newFile = await tempPdfFile.copy(newPath);

    print("PDF saved to device: ${newFile.path}");
    return newFile;
  }

  /// Original upload logic, modified to update the modal's state
  Future<void> _uploadToBackend(File pdfFile, StateSetter setModalState) async {
    setModalState(() {
      isProcessing = true;
      statusMessage = "Uploading...";
    });

    try {
      final uri = Uri.parse("https://your-backend-api.com/upload");
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', pdfFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        setModalState(() => statusMessage = "✅ Uploaded Successfully!");
      } else {
        setModalState(
            () => statusMessage = "❌ Upload failed (${response.statusCode})");
      }
    } catch (e) {
      setModalState(() => statusMessage = "❌ Upload error: $e");
    }

    setModalState(() => isProcessing = false);
  }

  /// UPDATED FUNCTION: Now generates, saves, and (soon) uploads
/*   Future<void> _processAndUploadPdf(StateSetter setModalState) async {
    setModalState(() {
      isProcessing = true;
      statusMessage = "Generating PDF...";
    });

    try {
      // 1. Generate the PDF (this saves it to the temp directory)
      final pdfFile = await _generatePdf(scannedPages);

      // 2. NEW: Save a copy to the user's visible "Files" directory
      final savedFile = await _savePdfToDevice(pdfFile);

      // 3. (Future) Upload the PDF to your backend.
      // You can use either `pdfFile` (from temp) or `savedFile` (from docs)
      // for the upload. Using `pdfFile` is slightly cleaner.

      // --- UPLOAD LOGIC ---
      // Uncomment the line below when your backend API is ready
      // await _uploadToBackend(pdfFile, setModalState);
      // --- END UPLOAD LOGIC ---

      // 4. (Temporary) Show success message for PDF generation AND save
      // Remove this block when you uncomment the upload logic above
      setModalState(() {
        isProcessing = false;
        // Show the path of the *saved* file
        statusMessage = "✅ PDF Saved to your Files app!";
        print("PDF saved to: ${savedFile.path}");
      });
      // --- END TEMPORARY BLOCK ---
    } catch (e) {
      setModalState(() {
        statusMessage = "❌ Error processing PDF: $e";
        isProcessing = false;
      });
    }
  }
 */

/// UPDATED FUNCTION: Generates PDF and opens a "Save As" dialog
Future<void> _processAndUploadPdf(StateSetter setModalState) async {
  setModalState(() {
    isProcessing = true;
    statusMessage = "Generating PDF...";
  });

  try {
    // 1. Generate the PDF (this saves it to the temp directory)
    final pdfFile = await _generatePdf(scannedPages);

    // 2. Read the bytes from the temporary file
    final Uint8List fileBytes = await pdfFile.readAsBytes();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // 3. Open a "Save As" dialog
    // This lets the user choose the save location (e.g., Downloads)
    // and handles all permissions automatically.
    setModalState(() => statusMessage = "Opening save dialog...");
    String? savedPath = await FileSaver.instance.saveAs(
      name: "ExamScan_$timestamp",
      bytes: fileBytes,
      mimeType: MimeType.pdf, fileExtension: 'pdf',
    );

    // 4. (Future) Upload the PDF to your backend.
    // You can still use `pdfFile` (from temp) for the upload.
    // Uncomment the line below when your backend API is ready
    // await _uploadToBackend(pdfFile, setModalState);
    // --- END UPLOAD LOGIC ---

    // 5. Show success message for the save
    setModalState(() {
      isProcessing = false;
      if (savedPath != null && savedPath.isNotEmpty) {
        statusMessage = "✅ PDF Saved successfully!";
        print("PDF saved to: $savedPath");
      } else {
        // This happens if the user cancels the save dialog
        statusMessage = "Save cancelled.";
      }
    });
  } catch (e) {
    setModalState(() {
      statusMessage = "❌ Error processing PDF: $e";
      isProcessing = false;
    });
  }
}
  /// Deletes a specific page from the list
  void _deletePage(int index, StateSetter setModalState) {
    setState(() {
      scannedPages.removeAt(index);
    });
    setModalState(() {}); // Update the modal's UI
    if (scannedPages.isEmpty) {
      Navigator.pop(context); // Close modal if all pages are deleted
    }
  }

  /// Clears all scanned pages
  void _clearAllPages(StateSetter setModalState) {
    setState(() {
      scannedPages.clear();
    });
    setModalState(() {}); // Update the modal's UI
    Navigator.pop(context); // Close modal
  }

  /// Shows the modal bottom sheet with a gallery of scanned pages
  void _showScannedPagesModal() {
    // Check if there are pages to show
    if (scannedPages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pages scanned yet. Tap the camera to start.'),
          backgroundColor: Colors.teal,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the modal to be taller
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        // StatefulBuilder allows the modal's content to update
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7, // Start at 70% height
              minChildSize: 0.4,
              maxChildSize: 0.9, // Allow dragging up to 90%
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xfff3f4f6), // Light background
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Drag Handle
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      // Modal Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Scanned Pages (${scannedPages.length})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.delete_sweep_outlined,
                                  color: Colors.redAccent),
                              label: const Text("Clear All",
                                  style: TextStyle(color: Colors.redAccent)),
                              onPressed: () => _clearAllPages(setModalState),
                            ),
                          ],
                        ),
                      ),
                      const Divider(indent: 16, endIndent: 16),
                      // Page Gallery
                      Expanded(
                        child: GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // 3 images per row
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: scannedPages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // The Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(scannedPages[index]),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                // Delete Button
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _deletePage(index, setModalState),
                                    child: const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.redAccent,
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      // "Finish & Upload" Button Area
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, -2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.upload_file,
                                      color: Colors.white),
                              label: Text(
                                isProcessing
                                    ? "Processing..."
                                    : "Finish & Upload",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              onPressed: isProcessing
                                  ? null
                                  // Call the new process and upload function
                                  : () => _processAndUploadPdf(setModalState),
                            ),
                            if (statusMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                statusMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: statusMessage!.startsWith('✅')
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a), // Dark background
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("Evaluate Exam Sheet"),
      ),
      // Use a Stack to overlay buttons on the camera preview
      body: Stack(
        children: [
          // Layer 1: Camera Preview Placeholder (fills the screen)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera, size: 80, color: Colors.white38),
                SizedBox(height: 16),
                Text(
                  "Live Camera Feed",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                Text(
                  "Position exam sheet in frame",
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          ),

          // Layer 2: UI Controls (Capture Button and Gallery)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24.0)
                  .copyWith(bottom: 40.0), // Extra padding at bottom
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gallery Thumbnail Button
                  _buildGalleryButton(),

                  // Capture Button
                  _buildCaptureButton(),

                  // Empty SizedBox to balance the Row
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget for the main Capture Button
  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: scanExamSheets,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: const Icon(
          Icons.camera_alt,
          color: Colors.teal,
          size: 36,
        ),
      ),
    );
  }

  /// Helper widget for the Gallery button with a badge
  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: _showScannedPagesModal,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The button/icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              color: Colors.white,
            ),
          ),
          // Badge with page count
          if (scannedPages.isNotEmpty)
            Positioned(
              top: -5,
              right: -5,
              child: CircleAvatar(
                radius: 11,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  scannedPages.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}