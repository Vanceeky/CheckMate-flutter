import 'package:flutter/material.dart';

class ViewResultsPage extends StatelessWidget {
  const ViewResultsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Results', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF28A745), // Use green
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(child: Text('Results Dashboard and Charts Go Here', style: TextStyle(fontSize: 18))),
    );
  }
}