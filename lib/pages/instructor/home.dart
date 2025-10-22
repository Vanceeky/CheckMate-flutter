import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import your new pages
import 'create_answer_key.dart'; 
import 'scan_upload_page.dart';
import 'view_results_page.dart';

class InstructorHome extends StatefulWidget {
  const InstructorHome({super.key});

  @override
  State<InstructorHome> createState() => _InstructorHomeState();
}

class _InstructorHomeState extends State<InstructorHome> {
  String username = 'Prof. Sarah Johnson';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Instructor';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Ensure navigation happens on a mounted widget
    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Lighter background
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(username),
              accountEmail: const Text('instructor@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  username.isNotEmpty ? username[0] : 'I',
                  style: const TextStyle(color: Color(0xFF0083B0)),
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
              title: const Text('Logout',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text(
          'CheckMate',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        // Match drawer gradient
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
            ),
          ),
        ),
        elevation: 1.0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Cards
            Row(
              children: [
                _analyticsCard(
                  'Total Exams',
                  '12',
                  Icons.article_outlined,
                  const Color(0xFF007BFF),
                  const Color(0xFFEBF5FF),
                ),
                _analyticsCard(
                  'Pending Scans',
                  '5',
                  Icons.schedule,
                  const Color(0xFFFFAA00),
                  const Color(0xFFFFF9E6),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _quickActionCard(
              'Create Answer Key',
              'Set up a new exam with correct answers',
              Icons.add,
              // Gradient for the CARD background
              [Color.fromARGB(255, 28, 184, 173), Color.fromARGB(255, 26, 117, 236)],
              // Special solid color for the ICON container
              iconContainerColor: Color.fromARGB(255, 80, 189, 174),
              onTapAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateAnswerKeyPage()), // Now imported!
                );
              },
            ),

            _quickActionCard(
              'Scan/Upload Exam Sheets',
              'Upload student exam sheets for evaluation',
              Icons.upload, 
              // Main color (blue-600)
              [const Color(0xFF007BFF), const Color(0xFF007BFF)],
              whiteBackground: true,
              onTapAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScanUploadPage()), // Now imported!
                );
              },
            ),

            _quickActionCard(
              'View Results',
              'Review student performance and scores',
              Icons.bar_chart,
              // Main color (green-600)
              [const Color(0xFF28A745), const Color(0xFF28A745)],
              whiteBackground: true,
              onTapAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewResultsPage()), // Now imported!
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Analytics Card (Unchanged)
  Widget _analyticsCard(
    String title,
    String value,
    IconData icon,
    Color contentColor,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: contentColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon on the left
            Icon(icon, color: contentColor, size: 32),
            const SizedBox(width: 8),
            // Texts on the right
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: contentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: contentColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED _quickActionCard to handle all 3 of your specific cases
  Widget _quickActionCard(
    String title,
    String subtitle,
    IconData icon,
    List<Color> colors, {
    bool whiteBackground = false,
    Color? iconContainerColor,
    required VoidCallback onTapAction,
  }) {
    // --- Define Colors based on Card Type ---

    // For Card 2 & 3 (White Background)
    final Color primaryColor = colors.first;
    final Color iconColor = whiteBackground ? primaryColor : Colors.white;
    final Color? iconBgColor = whiteBackground
        ? primaryColor.withOpacity(0.15) // Light tint (blue-200)
        : iconContainerColor; // Solid color for gradient card (e.g., #2dd4bf)
    
    // For Card 1 (Gradient Background)
    final Gradient? iconGradient =
        (whiteBackground || iconContainerColor != null)
            ? null // No gradient if white BG or if solid color is provided
            : LinearGradient(colors: colors); // Use gradient for icon container

    final Color cardTextColor =
        whiteBackground ? Colors.black87 : Colors.white;
    final Color cardSubtitleColor =
        whiteBackground ? Colors.black54 : Colors.white70;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        // Card Background: Use white if flag is true, otherwise use gradient
        color: whiteBackground ? Colors.white : null,
        gradient: whiteBackground ? null : LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(12),
              // Icon Container Background:
              color: iconBgColor,
              gradient: iconGradient,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: cardTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: cardSubtitleColor,
              fontSize: 13,
            ),
          ),
          onTap: onTapAction,
        ),
      ),
    );
  }
}

