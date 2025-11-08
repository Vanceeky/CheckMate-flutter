import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:async'; // Needed for Future.delayed

// -------------------- NEW DATA MODELS --------------------

/// Represents a single section of an exam's score breakdown
class SectionScore {
  final String sectionTitle;
  final int score;
  final int total;

  SectionScore({
    required this.sectionTitle,
    required this.score,
    required this.total,
  });
}

/// Represents the full details of a single exam (for the details page)
class ExamDetails {
  final String id;
  final String title;
  final String subject;
  final String semester;
  final String schoolYear;
  final String date;
  final String status;
  final String pdfUrl;
  final List<SectionScore> breakdown;

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
  });

  // Getters to calculate totals dynamically
  int get totalScore =>
      breakdown.fold(0, (sum, item) => sum + item.score);
  
  int get totalQuestions =>
      breakdown.fold(0, (sum, item) => sum + item.total);

  double get percentage =>
      totalQuestions > 0 ? totalScore / totalQuestions : 0.0;
}

/// Represents the summary of an exam (for the dashboard list)
class Exam {
  final String id;
  final String title;
  final String subject;
  final String semester;
  final String schoolYear;
  final String date;
  final int questions; // Total questions
  final int score;     // Total score
  final String status;

  Exam({
    required this.id,
    required this.title,
    required this.subject,
    required this.semester,
    required this.schoolYear,
    required this.date,
    required this.questions,
    required this.score,
    required this.status,
  });
}

// -------------------- DUMMY DATABASE --------------------
// This simulates your backend database. The `ExamDetailsPage` will
// "fetch" from this map using the exam ID.

final Map<String, ExamDetails> dummyExamDetailsDatabase = {
  'MATH-001': ExamDetails(
    id: 'MATH-001',
    title: 'Finals',
    subject: 'Introduction to Computer Programming',
    semester: '1st Semester',
    schoolYear: '2023-2024',
    date: '1/15/2024',
    status: 'Passed',
    pdfUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    breakdown: [
      SectionScore(sectionTitle: 'Multiple Choice', score: 40, total: 50),
      SectionScore(sectionTitle: 'Problem Solving', score: 30, total: 30),
      SectionScore(sectionTitle: 'Identification', score: 15, total: 20),
    ],
  ),
  'PHYS-002': ExamDetails(
    id: 'PHYS-002',
    title: 'Midterm',
    subject: 'Human Computer Interaction',
    semester: '1st Semester',
    schoolYear: '2023-2024',
    date: '1/12/2024',
    status: 'Passed',
    pdfUrl: 'https://www.africau.edu/images/default/sample.pdf', // Different PDF
    breakdown: [
      SectionScore(sectionTitle: 'Multiple Choice', score: 15, total: 20),
      SectionScore(sectionTitle: 'Essay', score: 5, total: 5),
    ],
  ),
  'CHEM-003': ExamDetails(
    id: 'CHEM-003',
    title: 'prelim',
    subject: 'Data Structures and Algorithms',
    semester: '1st Semester',
    schoolYear: '2023-2024',
    date: '1/10/2024',
    status: 'Passed',
    pdfUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    breakdown: [
      SectionScore(sectionTitle: 'Multiple Choice', score: 20, total: 30),
      SectionScore(sectionTitle: 'Laboratory', score: 15, total: 10), // Example: extra credit
    ],
  ),
};


// -------------------- MAIN STUDENT DASHBOARD --------------------
class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  String username = '';
  List<Exam> exams = [];

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadDummyExams();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Student';
    });
  }

  void _loadDummyExams() {
    // This data is now just for the *list*. The details are in the
    // `dummyExamDetailsDatabase`. We just need to make sure the IDs match.
    setState(() {
      exams = [
        Exam(
          id: 'MATH-001',
          title: 'Finals',
          subject: 'Introduction to Computer Programming',
          semester: '1st Semester',
          schoolYear: '2023-2024',
          date: '1/15/2024',
          questions: 100, // 50 + 30 + 20 from details
          score: 85,      // 40 + 30 + 15 from details
          status: 'Passed',
        ),
        Exam(
          id: 'PHYS-002',
          title: 'midterm',
          subject: 'Human Computer Interaction',
          semester: '1st Semester',
          schoolYear: '2023-2024',
          date: '1/12/2024',
          questions: 25, // 20 + 5 from details
          score: 20,     // 15 + 5 from details
          status: 'Passed',
        ),
        Exam(
          id: 'CHEM-003',
          title: 'prelim',
          subject: 'Data Structures and Algorithms',
          semester: '1st Semester',
          schoolYear: '2023-2024',
          date: '1/10/2024',
          questions: 40, // 30 + 10 from details
          score: 35,     // 20 + 15 from details
          status: 'Passed',
        ),
      ];
    });
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
              accountEmail: const Text('student@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    color: Color(0xFF0083B0),
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
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

  Widget _buildExamCard(BuildContext context, Exam exam) {
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
                      Text(exam.date, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 12),
                      Text('${exam.questions} questions',
                          style: const TextStyle(color: Colors.grey)),
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
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exam.status,
                    style: const TextStyle(
                      color: Colors.green,
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
    setState(() {
      isLoading = true;
    });

    // TODO: Uncomment and replace with your backend API call
    /*
    try {
      final response = await http.get(
        Uri.parse('https://your-api/exams/${widget.examId}'),
      );
      if (response.statusCode == 200) {
        // Parse the JSON response into your ExamDetails model
        final details = ExamDetails.fromJson(json.decode(response.body));
        setState(() {
          examDetails = details;
          isLoading = false;
        });
      } else {
        // Handle error
        setState(() { isLoading = false; });
      }
    } catch (e) {
      // Handle exception
      setState(() { isLoading = false; });
    }
    */

    // ----- DUMMY API CALL -----
    // Simulating a network delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      // Fetching from our dummy "database"
      examDetails = dummyExamDetailsDatabase[widget.examId];
      isLoading = false;
    });
    // --------------------------
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
                    Text(exam.date,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text('${exam.totalScore}',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0083B0))),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(exam.status,
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.w500)),
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
                      pdfUrl: exam.pdfUrl, // Use the specific URL
                      studentName: widget.studentName, // Pass the name
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
  Widget _progressBar(String title, int score, int total) {
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
              Text('$score / $total',
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