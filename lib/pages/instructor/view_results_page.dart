import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ViewResultsPage(),
  ));
}

// -------------------- PAGE 1: VIEW RESULTS (Modernized) --------------------
class ViewResultsPage extends StatefulWidget {
  const ViewResultsPage({super.key});

  @override
  State<ViewResultsPage> createState() => _ViewResultsPageState();
}


Future<List<Map<String, dynamic>>> fetchInstructorExams() async {
  final url = Uri.parse("http://10.0.2.2:8000/api/exams/instructor/");
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString("access");
  if (accessToken == null) {
    throw Exception("No access token found. User might not be logged in.");
  }

  final response = await http.get(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken",
    },
  );

  if (response.statusCode == 200) {
    // API already returns a List of maps like your sample
    final List<dynamic> data = jsonDecode(response.body);
    // Convert dynamic list to List<Map<String, dynamic>>
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } else {
    throw Exception("Failed to load exams: ${response.statusCode}");
  }
}

class _ViewResultsPageState extends State<ViewResultsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  String searchQuery = "";

  // Data is now nested. 'studentResults' is part of the 'exams' list.
  final List<Map<String, dynamic>> exams = [];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _offsetAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    
    _loadExams(); // fetch exams and set state
  }

bool _isLoading = true;

Future<void> _loadExams() async {
  setState(() => _isLoading = true); // Show loading spinner

  try {
    final data = await fetchInstructorExams(); // Fetch from API

    setState(() {
      exams.clear();
      exams.addAll(data); // Update the list
      _isLoading = false; // Hide loading spinner
    });
  } catch (e) {
    setState(() => _isLoading = false);
    debugPrint("Failed to load exams: $e");

    // Optionally, show error to user
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text("Failed to load exams. Please try again.\n$e"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredExams = exams
        .where((e) =>
            e['hasScannedSheets'] == true &&
            (searchQuery.isEmpty ||
                // --- MODIFIED --- Search subject or exam type
                e['subject']
                    .toString()
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                e['examType']
                    .toString()
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase())))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Results', style: TextStyle(color: Colors.white)),
        // --- FIX: Color ---
        backgroundColor: const Color(0xFF0083B0), // Use blue gradient color
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 🔍 Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search subject or exam type...', // --- MODIFIED ---
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                onChanged: (val) {
                  setState(() {
                    searchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredExams.isEmpty
                        ? const Center(
                            child: Text('No exams found.',
                                style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: filteredExams.length,
                        itemBuilder: (context, index) {
                          final exam = filteredExams[index];

                          // --- Stats ---
                          final List<dynamic> studentResults =
                              exam['studentResults'] ?? [];
                          final int studentCount = studentResults.length;

                          final double passingThreshold =
                              studentResults.isNotEmpty
                                  ? studentResults[0]['total'] * 0.75
                                  : 0;

                          final int passingCount = studentResults
                              .where((r) => r['score'] >= passingThreshold)
                              .length;

                          return SlideTransition(
                            position: _offsetAnimation,
                            child: AnimatedOpacity(
                              opacity: 1,
                              duration: Duration(milliseconds: 400 + (index * 100)),
                              child: Hero(
                                tag: exam['examId'],
                                child: Card(
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18)),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ExamResultsDetailPage(exam: exam),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF00B4DB),
                                            Color(0xFF0083B0)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // 📘 Title Row
                                          Row(
                                            children: [
                                              const Icon(Icons.class_outlined,
                                                  color: Colors.white, size: 22),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  exam['subject'] ?? 'No Subject',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          // 🎓 Semester + Badge
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              Text(
                                                exam['semester'] ?? '',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500),
                                              ),
                                              const Text('•', style: TextStyle(color: Colors.white54)),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  exam['examType'] ?? '',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),

                                          // 📅 School Year
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today_outlined,
                                                  size: 16, color: Colors.white),
                                              const SizedBox(width: 6),
                                              Text(
                                                'S.Y. ${exam['schoolYear'] ?? ''}',
                                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          // 👥 Scanned Sheets + ✅ Passing
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 12,
                                            runSpacing: 4,
                                            children: [
                                              const Icon(Icons.people_outline,
                                                  size: 16, color: Colors.white),
                                              Text(
                                                '$studentCount Scanned Sheets',
                                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                              ),
                                              const Text('•', style: TextStyle(color: Colors.white)),
                                              const Icon(Icons.check_circle_outline,
                                                  size: 16, color: Colors.white),
                                              Text(
                                                '$passingCount Passing',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// -------------------- PAGE 2: EXAM RESULTS DETAIL (with Search/Sort) --------------------

class ExamResultsDetailPage extends StatefulWidget {
  final Map<String, dynamic> exam;

  const ExamResultsDetailPage({super.key, required this.exam});

  @override
  State<ExamResultsDetailPage> createState() => _ExamResultsDetailPageState();
}

class _ExamResultsDetailPageState extends State<ExamResultsDetailPage> {
  String studentSearchQuery = "";
  bool sortDescending = true; // Start with highest score first

  @override
  Widget build(BuildContext context) {
    final List<dynamic> baseResults = widget.exam['studentResults'];

    final filteredResults = baseResults.where((r) {
      final name = r['name'].toString().toLowerCase();
      return name.contains(studentSearchQuery.toLowerCase());
    }).toList();

    // Sorting
    filteredResults.sort((a, b) {
      final scoreA = a['score'] as int;
      final scoreB = b['score'] as int;
      return sortDescending
          ? scoreB.compareTo(scoreA)
          : scoreA.compareTo(scoreB);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Results - ${widget.exam['subject']}',
            style: const TextStyle(color: Colors.white)),
        // --- FIX: Color ---
        backgroundColor: const Color(0xFF0083B0), // Use blue gradient color
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // --- CRASH FIX ---
      // The Hero widget must wrap a 'Material' widget on both pages.
      // Page 1 wraps a 'Card' (which is Material).
      // Page 2 must also wrap its child in a 'Material' widget.
      // This fixes the crash on navigation.
      body: Hero(
        tag: widget.exam['examId'],
        child: Material(
          type: MaterialType.canvas, // Use canvas to match scaffold background
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Student Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search student name...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    setState(() {
                      studentSearchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Sort Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Sort: ${sortDescending ? "Highest First" : "Lowest First"}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    IconButton(
                      icon: Icon(
                        sortDescending
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        // --- FIX: Color ---
                        color:
                            const Color(0xFF0083B0), // Use blue gradient color
                      ),
                      onPressed: () {
                        setState(() {
                          sortDescending = !sortDescending;
                        });
                      },
                    ),
                  ],
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: filteredResults.length,
                    itemBuilder: (context, index) {
                      final result = filteredResults[index];
                      final percentage =
                          ((result['score'] / result['total']) * 100).toStringAsFixed(1);

                      final double passingThreshold = result['total'] * 0.75;
                      final bool isPassing = result['score'] >= passingThreshold;

                      // Define your gradient
                      final LinearGradient gradient = LinearGradient(
                        colors: isPassing
                            ? [const Color(0xFF56CCF2), const Color(0xFF2F80ED)] // Blue tones
                            : [const Color(0xFFFF9A9E), const Color(0xFFF6416C)], // Red tones
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Card(
                          color: Colors.transparent, // let gradient show through
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.85),
                              child: Text(
                                result['name'][0],
                                style: TextStyle(
                                  color: isPassing
                                      ? Colors.blue.shade800
                                      : Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              result['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Score: ${result['score']} / ${result['total']} ($percentage%)',
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: IconTheme(
                                data: const IconThemeData(color: Colors.white),
                                child: IconButton(
                                  icon: const Icon(Icons.picture_as_pdf),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PDFViewerPage(
                                          pdfUrl: "http://10.0.2.2:8000${result['pdfUrl']}",
                                          studentName: result['name'],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------- PAGE 3: PDF VIEWER (No Changes) --------------------
class PDFViewerPage extends StatelessWidget {
  final String pdfUrl;
  final String studentName;

  const PDFViewerPage(
      {super.key, required this.pdfUrl, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanned Sheet - $studentName',
            style: const TextStyle(color: Colors.white)),
        // --- FIX: Color ---
        backgroundColor: const Color(0xFF0083B0), // Use blue gradient color
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}