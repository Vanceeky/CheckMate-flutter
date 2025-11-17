import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; // For json.encode
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// --- Data Models (Unchanged from previous) ---

/// Holds the controllers for a single answer key item.
class AnswerKeyItem {
  final TextEditingController answerController;
  final TextEditingController pointsController;

  AnswerKeyItem()
      : answerController = TextEditingController(),
        pointsController = TextEditingController(text: '1');

  void dispose() {
    answerController.dispose();
    pointsController.dispose();
  }
}

/// Represents a full section of the exam (e.g., "Identification").
class ExamSection {
  final String type;
  final List<AnswerKeyItem> items;
  final int totalPoints;

  ExamSection({required this.type, List<AnswerKeyItem>? items, this.totalPoints = 0})
      : this.items = items ?? [AnswerKeyItem()];

  void dispose() {
    for (var item in items) {
      item.dispose();
    }
  }
}

// --- Main Page Widget ---

class CreateAnswerKeyPage extends StatefulWidget {
  const CreateAnswerKeyPage({super.key});

  @override
  State<CreateAnswerKeyPage> createState() => _CreateAnswerKeyPageState();
}

class _CreateAnswerKeyPageState extends State<CreateAnswerKeyPage> {
  // --- State Variables ---

  int _currentStep = 0;
  bool _isLoading = false;

  // --- Step 1: Basic Info State ---
  final _step1FormKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _schoolYearController = TextEditingController();
  String? _selectedExamType;
  String? _selectedSemester;

  final List<String> _examTypes = ['Prelim', 'Midterm', 'Finals', 'Quiz'];
  final List<String> _semesters = ['1st Semester', '2nd Semester', 'Summer'];

  // --- Step 2: Answer Key State ---
  final List<String> _allSectionTypes = [
    'Identification',
    'Multiple Choice',
    'True/False',
    'Enumeration',
  ];
  final Map<String, IconData> _sectionIcons = {
    'Identification': Icons.edit_note_rounded,
    'Multiple Choice': Icons.rule_rounded,
    'True/False': Icons.check_circle_outline_rounded,
    'Enumeration': Icons.format_list_numbered_rounded,
  };

  final List<ExamSection> _sections = [];
  String? _selectedSectionType;
  final Set<String> _addedSectionTypes = {};

  // --- Step 3: Review State ---
  Map<String, dynamic>? _preparedData;
  int _totalExamPoints = 0;

  @override
  void initState() {
    super.initState();
    if (_allSectionTypes.isNotEmpty) {
      _selectedSectionType = _allSectionTypes.first;
    }
    _schoolYearController.text =
        '${DateTime.now().year}-${DateTime.now().year + 1}';
  }

  @override
  void dispose() {
    for (var section in _sections) {
      section.dispose();
    }
    _subjectController.dispose();
    _schoolYearController.dispose();
    super.dispose();
  }

  // --- Helper Methods ---

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- Step 2: Answer Key Methods ---

  void _addSection() {
    if (_selectedSectionType != null &&
        !_addedSectionTypes.contains(_selectedSectionType!)) {
      setState(() {
        _sections.add(ExamSection(type: _selectedSectionType!));
        _addedSectionTypes.add(_selectedSectionType!);
        _selectedSectionType = _allSectionTypes
            .firstWhere((type) => !_addedSectionTypes.contains(type),
                orElse: () => '');
      });
    }
  }

  void _removeSection(int sectionIndex) {
    setState(() {
      String removedType = _sections[sectionIndex].type;
      _sections[sectionIndex].dispose();
      _sections.removeAt(sectionIndex);
      _addedSectionTypes.remove(removedType);
      if (_selectedSectionType == null) {
        _selectedSectionType = removedType;
      }
    });
  }

  void _addQuestion(int sectionIndex) {
    setState(() {
      _sections[sectionIndex].items.add(AnswerKeyItem());
    });
  }

  void _removeQuestion(int sectionIndex, int itemIndex) {
    setState(() {
      _sections[sectionIndex].items[itemIndex].dispose();
      _sections[sectionIndex].items.removeAt(itemIndex);
    });
  }

  // --- Stepper Navigation & Data Handling ---

  void _onStepContinue() {
    switch (_currentStep) {
      case 0:
        if (_step1FormKey.currentState!.validate()) {
          setState(() => _currentStep = 1);
        }
        break;
      case 1:
        if (_validateStep2()) {
          _prepareDataForReview();
          setState(() => _currentStep = 2);
        }
        break;
      case 2:
        _saveData();
        break;
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  bool _validateStep2() {
    if (_sections.isEmpty) {
      _showErrorSnackBar('Please add at least one exam section.');
      return false;
    }
    for (var section in _sections) {
      if (section.items.isEmpty) {
        _showErrorSnackBar('Section "${section.type}" has no questions.');
        return false;
      }
      for (var item in section.items) {
        if (item.answerController.text.trim().isEmpty) {
          _showErrorSnackBar(
              'An answer in "${section.type}" is empty.');
          return false;
        }
        final points = int.tryParse(item.pointsController.text);
        if (points == null || points <= 0) {
          _showErrorSnackBar(
              'Invalid points in "${section.type}". Points must be > 0.');
          return false;
        }
      }
    }
    return true;
  }

  void _prepareDataForReview() {
    setState(() {
      _isLoading = true;
      _preparedData = null;
      _totalExamPoints = 0;
    });

    final basicInfo = {
      'examType': _selectedExamType,
      'semester': _selectedSemester,
      'subject': _subjectController.text.trim(),
      'schoolYear': _schoolYearController.text.trim(),
    };

    final answerKey = _sections.map((section) {
      int sectionTotalPoints = 0;
      final items = section.items.asMap().entries.map((entry) {
        final points = int.tryParse(entry.value.pointsController.text) ?? 0;
        sectionTotalPoints += points;
        return {
          'questionNumber': entry.key + 1,
          'answer': entry.value.answerController.text.trim(),
          'points': points,
        };
      }).toList();

      _totalExamPoints += sectionTotalPoints;
      return {
        'sectionType': section.type,
        'totalPoints': sectionTotalPoints,
        'items': items,
      };
    }).toList();

    setState(() {
      _preparedData = {
        'basicInfo': basicInfo,
        'answerKey': answerKey,
        'totalExamPoints': _totalExamPoints,
      };
      _isLoading = false;
    });
  }

Future<void> _saveData() async {
  if (_preparedData == null) return;

  setState(() => _isLoading = true);

  final url = Uri.parse("http://10.0.2.2:8000/api/exams/create/");

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");

  if (token == null) {
    debugPrint("❌ ERROR: No access token found. User not logged in.");
    setState(() => _isLoading = false);
    return;
  }

  try {
    debugPrint('--- SENDING TO BACKEND ---');
    debugPrint(jsonEncode(_preparedData));

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(_preparedData),
    );

    debugPrint("STATUS CODE: ${response.statusCode}");
    debugPrint("RESPONSE BODY: ${response.body}");

    setState(() => _isLoading = false);

    if (response.statusCode == 201 || response.statusCode == 200) {
      // SUCCESS
      final res = jsonDecode(response.body);
      final examId = res["examId"] ?? "";
      final passingScore = res["passingScore"] ?? "";
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Success!'),
          content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(res["message"] ?? "Exam created successfully!"),
            const SizedBox(height: 12),
            Text(
              "Exam ID: $examId",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "Passing Score: $passingScore",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );

    } else {
      // ERROR FROM BACKEND
      final res = jsonDecode(response.body);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text(
            res["error"] ?? "Something went wrong. Please try again.",
          ),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    setState(() => _isLoading = false);

    debugPrint("ERROR: $e");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Network Error"),
        content: Text("Failed to connect to server: $e"),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

/*   Future<void> _saveData() async {
    if (_preparedData == null) return;

    setState(() => _isLoading = true);
    final jsonData = json.encode(_preparedData);

    debugPrint('--- SAVING ANSWER KEY (JSON PAYLOAD) ---');
    debugPrint(jsonData);
    await Future.delayed(const Duration(seconds: 2)); 
    
    setState(() => _isLoading = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success!'),
        content:
            const Text('The new answer key has been successfully created.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); 
              Navigator.of(context).pop(); 
            },
          ),
        ],
      ),
    );
  }
 */
  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Processing...',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                // MODIFICATION: Removed the introductory text from here
                Expanded(
                  child: Stepper(
                    type: StepperType.horizontal,
                    currentStep: _currentStep,
                    onStepTapped: (step) {
                      if (step < _currentStep) {
                        setState(() => _currentStep = step);
                      } else if (step == 1 &&
                          _step1FormKey.currentState!.validate()) {
                        setState(() => _currentStep = step);
                      } else if (step == 2 && _validateStep2()) {
                        _prepareDataForReview();
                        setState(() => _currentStep = step);
                      }
                    },
                    controlsBuilder: (context, details) =>
                        const SizedBox.shrink(),
                    steps: _buildSteps(),
                  ),
                ),
                _buildFixedControls(),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Create Answer Key',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF20D4C7), Color(0xFF12A1B1)],
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 4,
    );
  }

  Widget _buildFixedControls() {
    final bool isLastStep = _currentStep == _buildSteps().length - 1;
    final bool isFirstStep = _currentStep == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isFirstStep)
            TextButton.icon(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              onPressed: _onStepCancel,
            ),
          if (isFirstStep) const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isLastStep
                  ? const Color(0xFF10b981)
                  : const Color(0xFF12A1B1),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            onPressed: _onStepContinue,
            child: Text(
              isLastStep ? 'Save & Submit' : 'Continue',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Info'),
        content: _buildStep1Form(), // MODIFIED: Content now has description
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Answer Key'),
        content: _buildStep2Form(), // MODIFIED: Content now has description
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Review'),
        content: _buildStep3Review(), // MODIFIED: Content now has description
        isActive: _currentStep >= 2,
        state: _currentStep == 2 ? StepState.editing : StepState.indexed,
      ),
    ];
  }

  /// Builds the Form for Step 1.
  Widget _buildStep1Form() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
        children: [
          // NEW: Added introductory text inside the step content
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF12A1B1).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFF12A1B1).withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: const Color(0xFF12A1B1), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Follow the steps to set up basic information for your new exam answer key.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24), // Spacer

          // --- Original Form Fields ---
          _buildDropdown(
            label: 'Exam Type',
            icon: Icons.assignment_turned_in_outlined,
            value: _selectedExamType,
            items: _examTypes,
            onChanged: (val) => setState(() => _selectedExamType = val),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Semester',
            icon: Icons.calendar_view_day_outlined,
            value: _selectedSemester,
            items: _semesters,
            onChanged: (val) => setState(() => _selectedSemester = val),
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _subjectController,
            label: 'Subject',
            icon: Icons.book_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _schoolYearController,
            label: 'School Year (e.g., 2024-2025)',
            icon: Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }

  /// Helper for a styled DropdownButtonFormField.
  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF12A1B1)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Please select a $label' : null,
    );
  }

  /// Helper for a styled TextFormField.
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF12A1B1)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (val) =>
          val == null || val.trim().isEmpty ? 'Please enter a $label' : null,
    );
  }

  /// Builds the content for Step 2.
  Widget _buildStep2Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NEW: Added description for Step 2
        Text(
          'Add Exam Sections',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Create different sections for your exam (e.g., Identification, Multiple Choice).',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        _buildAddSectionUI(),
        const Divider(height: 24, thickness: 1),
        _buildSectionList(),
      ],
    );
  }

  /// The top row with the Dropdown and "Add Section" button.
  Widget _buildAddSectionUI() {
    final availableTypes = _allSectionTypes
        .where((type) => !_addedSectionTypes.contains(type))
        .toList();

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedSectionType,
            hint: const Text('Select Section Type'),
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: availableTypes.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Row(
                  children: [
                    Icon(
                      _sectionIcons[value] ?? Icons.help_outline,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(value),
                  ],
                ),
              );
            }).toList(),
            onChanged: availableTypes.isEmpty
                ? null
                : (newValue) => setState(() => _selectedSectionType = newValue),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF12A1B1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onPressed: _selectedSectionType == null ? null : _addSection,
        ),
      ],
    );
  }

  /// The list of section cards.
  Widget _buildSectionList() {
if (_sections.isEmpty) {
  return const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.library_books_outlined, // 📘 Choose an icon that fits your theme
            size: 64,
            color: Color(0xFF12A1B1),
          ),
          SizedBox(height: 16),
          Text(
            'No exam sections added yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Choose an exam type above to get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    ),
  );
}
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: _sections.length,
      itemBuilder: (context, sectionIndex) {
        return _buildSectionCard(_sections[sectionIndex], sectionIndex);
      },
    );
  }

  /// A single Card representing one exam section.
Widget _buildSectionCard(ExamSection section, int sectionIndex) {
  final questionCount = section.items.length;
  final questionText =
      '$questionCount ${questionCount == 1 ? "question" : "questions"}';

  return Card(
    elevation: 3,
    margin: const EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Container(
          color: Colors.grey[100],
          child: ListTile(
           contentPadding: const EdgeInsets.only(left: 16, right: 0), // 👈 tighten right side
            leading: Icon(
              _sectionIcons[section.type] ?? Icons.help_outline,
              color: const Color(0xFF12A1B1),
            ),
            title: Row(
              children: [
                Text(
                  section.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF12A1B1),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '·', // middle dot separator
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  questionText,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_forever, color: Colors.red[400]),
              onPressed: () => _removeSection(sectionIndex),
              tooltip: 'Remove Section',
            ),
          ),
        ),
        ..._buildAnswerItemList(sectionIndex),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Question'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF12A1B1),
            ),
            onPressed: () => _addQuestion(sectionIndex),
          ),
        ),
      ],
    ),
  );
}

  /// Generates the list of Q/A/Points rows for a section.
  List<Widget> _buildAnswerItemList(int sectionIndex) {
    final items = _sections[sectionIndex].items;
    if (items.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No questions added.',
              style: TextStyle(color: Colors.grey)),
        )
      ];
    }
    return items.asMap().entries.map((entry) {
      int itemIndex = entry.key;
      AnswerKeyItem item = entry.value;
      return _buildAnswerItemRow(sectionIndex, itemIndex, item);
    }).toList();
  }

  /// A single row for Q#, Answer, and Points.
  Widget _buildAnswerItemRow(
      int sectionIndex, int itemIndex, AnswerKeyItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Q${itemIndex + 1}:',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextField(
              controller: item.answerController,
              decoration: InputDecoration(
                labelText: 'Answer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextField(
              controller: item.pointsController,
              decoration: InputDecoration(
                labelText: 'Points',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
            onPressed: () => _removeQuestion(sectionIndex, itemIndex),
            tooltip: 'Remove Question',
          ),
        ],
      ),
    );
  }

  /// Builds the summary/review widget for Step 3.
  Widget _buildStep3Review() {
    if (_preparedData == null) {
      return const Center(
        child: Text('Preparing review...'),
      );
    }

    final info = _preparedData!['basicInfo'];
    final sections = _preparedData!['answerKey'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NEW: Added description for Step 3
        Text(
          'Review & Save',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          'Verify your exam details and answer keys before saving.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        // Total Points
        Text(
          'Total Exam Points: $_totalExamPoints',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // --- NEW: REDESIGNED Exam Details ---
        const Text(
          'Exam Details:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0, // Horizontal space between chips
          runSpacing: 8.0, // Vertical space between lines of chips
          children: [
            _buildReviewInfoChip(Icons.book_outlined, info['subject']),
            _buildReviewInfoChip(
                Icons.assignment_turned_in_outlined, info['examType']),
            _buildReviewInfoChip(
                Icons.calendar_view_day_outlined, info['semester']),
            _buildReviewInfoChip(
                Icons.calendar_today_outlined, info['schoolYear']),
          ],
        ),
        // --- End of REDESIGN ---
        
        const SizedBox(height: 24), // More spacing
        const Text(
          'Answer Key Summary:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Answer Key Sections (Unchanged, user liked this)
        ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            final items = section['items'] as List;
            return ExpansionTile(
              leading: Icon(
                _sectionIcons[section['sectionType']] ?? Icons.help_outline,
                color: const Color(0xFF12A1B1),
              ),
              title: Text(
                section['sectionType'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF12A1B1),
                ),
              ),
              subtitle: Text(
                  '${items.length} Questions • ${section['totalPoints']} Points'),
              children: items.map<Widget>((item) {
                return ListTile(
                  title: Text('Answer: ${item['answer']}'),
                  leading: Text(
                    'Q${item['questionNumber']}:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    '${item['points']} pts',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// NEW: Helper widget for the redesigned review "chips".
  Widget _buildReviewInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20.0), // Makes it pill-shaped
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // So it only takes as much space as needed
        children: [
          Icon(icon, color: const Color(0xFF12A1B1), size: 18),
          const SizedBox(width: 8),
          // Flexible ensures text wraps if it's too long
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}