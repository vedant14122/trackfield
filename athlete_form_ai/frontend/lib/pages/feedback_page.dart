import 'package:flutter/material.dart';

class FeedbackPage extends StatelessWidget {
  final String feedback;

  FeedbackPage({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feedback')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(child: Text(feedback)),
      ),
    );
  }
}
