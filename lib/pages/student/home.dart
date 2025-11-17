import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:async'; // Needed for Future.delayed
import 'package:http/http.dart' as http;

// -------------------- NEW DATA MODELS --------------------

String formatDate(DateTime date) {
  const months = [
    "JAN", "FEB", "MAR", "APR", "MAY", "JUNE",
    "JULY", "AUG", "SEPT", "OCT", "NOV", "DEC"
  ];

  return "${date.year}-${months[date.month - 1]}-${date.day.toString().padLeft(2, '0')}";
}

/// Represents a single section of an exam's score breakdown
class SectionScore {
  final String sectionTitle;
  final double score;
  final double total;

  SectionScore({
    required this.sectionTitle,
    required this.score,
    required this.total,
  });

  factory SectionScore.fromJson(Map<String, dynamic> json) {
    return SectionScore(
      sectionTitle: json['sectionTitle'] ?? '',
      score: (json['score'] ?? 0).toDouble(), // Use toDouble()
      total: (json['total'] ?? 0).toDouble(), // Use toDouble()
    );
  }
}

class ExamDetails {
  final String id;
  final String title;
  final String subject;
  final String semester;
  final String schoolYear;
  final String date;
  final String status;
  final String? pdfUrl;
  final List<SectionScore> breakdown;
  final double score; // ✅ ADDED
  final double totalPoints; // ✅ ADDED

  ExamDetails({
    required this.id,
    required this.title,
    required this.subject,
    required this.semester,
    required this.schoolYear,
    required this.date,
    required this.status,
    required this.pdfUrl,
    required this.breakdown,
    required this.score, // ✅ ADDED
    required this.totalPoints, // ✅ ADDED
  });

  /// ✅ ADDED: A calculated property for the percentage
  double get percentage => totalPoints > 0 ? score / totalPoints : 0.0;

  factory ExamDetails.fromJson(Map<String, dynamic> json) {
    return ExamDetails(
      id: json['examId'] ?? '',
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      semester: json['semester'] ?? '',
      schoolYear: json['schoolYear'] ?? '',
      date: json['submitted_at'] ?? '',
      status: json['status']?.toString() ?? 'Failed',
      pdfUrl: json['pdfUrl'],
      breakdown: json['breakdown'] != null
          ? (json['breakdown'] as List)
              .map((e) => SectionScore.fromJson(e))
              .toList()
          : [],
      // ✅ ADDED: Parse score and total_points from the JSON
      // (Matches your ExamSubmission model)
      score: (json['score'] ?? 0).toDouble(),
      totalPoints: (json['total_points'] ?? 0).toDouble(),
    );
  }
}


// -------------------- MAIN STUDENT DASHBOARD --------------------
class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> with SingleTickerProviderStateMixin {
  String username = '';
  String email = "";
  String avatar = "";
  String fullAvatarUrl = "";
    late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  String searchQuery = "";

  List<ExamDetails> exams = [];

  // ✅ Add this
  bool isLoading = false;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _offsetAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    _loadUserData();
    _fetchStudentExams();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    username = prefs.getString('username') ?? "Student";
    email = prefs.getString('email') ?? "No email";
    avatar = prefs.getString('avatar') ?? "";

    // Convert relative Django media path -> full URL
    if (avatar.isNotEmpty) {
      fullAvatarUrl = "http://10.0.2.2:8000$avatar";
    }

    setState(() {});
  }
  Future<void> _fetchStudentExams() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) throw Exception("No access token found");

      final url = Uri.parse("http://10.0.2.2:8000/api/exams/student/");
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          // Use ExamDetails instead of Exam
          exams = data.map((e) => ExamDetails.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        throw Exception("Failed to fetch exams");
      }
    } catch (e) {
      setState(() => isLoading = false);
      print(e);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: const Color(0xFF00B4DB),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(username),
              accountEmail: Text(email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                    fullAvatarUrl.isNotEmpty ? NetworkImage(fullAvatarUrl) : null,
                child: fullAvatarUrl.isEmpty
                    ? Text(
                        username.isNotEmpty ? username[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Color(0xFF0083B0),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      )
                    : null,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              children: [
                const Text(
                  'Recent Exams',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B4DB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${exams.length} Total',
                    style: const TextStyle(
                      color: Color(0xFF0083B0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
              ...exams.map((exam) => _buildExamCard(context, exam)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, ExamDetails exam) {
    return GestureDetector(
      onTap: () {
        // MODIFIED: Pass the ID and studentName to the details page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamDetailsPage(
              examId: exam.id,
              studentName: username, // Pass the loaded username
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏷️ Exam Title Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getBadgeColor(exam.title),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      exam.title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 🧠 Subject
                  Text(
                    exam.subject,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 📘 Semester and School Year
                  Text(
                    '${exam.semester} · ${exam.schoolYear}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),

                  // 📅 Date and Questions
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),

                      Text(
                        formatDate(DateTime.parse(exam.date)),   // ← formatted output
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(width: 12),

                      Text(
                        '${exam.totalPoints.toInt()} points',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                ],
              ),
            ),

            // 📊 Score + Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${exam.score}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0083B0),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getBadgeBackground(exam.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exam.status,
                    style: TextStyle(
                      color: _getBadgeText(exam.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- EXAM DETAILS PAGE --------------------
// MODIFIED: Converted to StatefulWidget to fetch details
class ExamDetailsPage extends StatefulWidget {
  final String examId;
  final String studentName;

  const ExamDetailsPage({
    super.key,
    required this.examId,
    required this.studentName,
  });

  @override
  State<ExamDetailsPage> createState() => _ExamDetailsPageState();
}

class _ExamDetailsPageState extends State<ExamDetailsPage> {
  ExamDetails? examDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExamDetails();
  }

Future<void> _fetchExamDetails() async {
  setState(() => isLoading = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) throw Exception("No access token found");

    final url = Uri.parse("http://10.0.2.2:8000/api/exams/student/${widget.examId}/");
    final response = await http.get(url, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        examDetails = ExamDetails.fromJson(data);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      throw Exception("Failed to fetch exam details");
    }
  } catch (e) {
    setState(() => isLoading = false);
    print(e);
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Exam Result'),
        backgroundColor: const Color(0xFF00B4DB),
      ),
      // MODIFIED: Removed the FloatingActionButton
      body: buildBody(),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (examDetails == null) {
      return const Center(
        child: Text(
          'Error: Could not load exam details.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    // If we have data, show the list
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _examCard(examDetails!),
          const SizedBox(height: 16),
          _scoreBreakdown(examDetails!),
        ],
      ),
    );
  }

  Widget _examCard(ExamDetails exam) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${exam.subject}: ${exam.title}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${exam.semester}, S.Y. ${exam.schoolYear}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    
                    Text(formatDate(DateTime.parse(exam.date)),
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text('${exam.score.toInt()}',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0083B0))),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBadgeBackground(exam.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exam.status,
                  style: TextStyle(
                    color: _getBadgeText(exam.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreBreakdown(ExamDetails exam) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFF0083B0)),
              SizedBox(width: 6),
              Text(
                'Score Breakdown',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // MODIFIED: Dynamically generate progress bars from the breakdown
          ...exam.breakdown.map((section) {
            return _progressBar(
              section.sectionTitle,
              section.score,
              section.total,
            );
          }).toList(),

          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        // MODIFIED: Dynamic value
                        value: exam.percentage,
                        strokeWidth: 8,
                        color: const Color(0xFF0083B0),
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    // MODIFIED: Dynamic text
                    Text('${(exam.percentage * 100).toInt()}%',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Overall Performance',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // MODIFIED: Added "View PDF" button here
          // ✅ FIXED: Conditionally show the "View PDF" button
          if (exam.pdfUrl != null && exam.pdfUrl!.isNotEmpty)
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('View Scanned Sheet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0083B0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PDFViewerPage(
                        pdfUrl: exam.pdfUrl!, // Use the ! (null-assert)
                        studentName: widget.studentName,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // MODIFIED: Updated signature to take real scores
Widget _progressBar(String title, double score, double total) { // ✅ FIXED
  final double value = total > 0 ? score / total : 0.0;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            Text('${score.toInt()} / ${total.toInt()}', // ✅ FIXED
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            minHeight: 8,
            color: Colors.black87,
            backgroundColor: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(value * 100).toInt()}%',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// -------------------- PDF VIEWER PAGE --------------------
// This page is mostly unchanged, but now dynamically receives
// the student name and the correct PDF URL.

class PDFViewerPage extends StatelessWidget {
  final String pdfUrl;
  final String studentName;

  const PDFViewerPage({
    super.key,
    required this.pdfUrl,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$studentName’s Scanned Sheet'),
        backgroundColor: const Color(0xFF00B4DB),
      ),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}

// helper method
Color _getBadgeColor(String title) {
  switch (title.toLowerCase()) {
    case 'prelim':
      return Colors.blue;
    case 'midterm':
      return Colors.orange;
    case 'finals':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

Color _getBadgeText(String title) {
  switch (title.toLowerCase()) {
    case 'passed':
      return Colors.green;
    case 'failed':
      return Colors.redAccent;
    default:
      return Colors.grey;
  }
}


// helper method
Color _getBadgeBackground(String title) {
  switch (title.toLowerCase()) {
    case 'passed':
      return Colors.green.shade100;
    case 'failed':
      return Colors.red.shade100;
    default:
      return Colors.grey.shade300;
  }
}
