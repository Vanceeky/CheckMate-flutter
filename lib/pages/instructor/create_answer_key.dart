import 'package:flutter/material.dart';

class CreateAnswerKeyPage extends StatelessWidget {
  const CreateAnswerKeyPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Answer Key', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF20D4C7), Color(0xFF12A1B1)],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(child: Text('Answer Key Creation Form Goes Here', style: TextStyle(fontSize: 18))),
    );
  }
}