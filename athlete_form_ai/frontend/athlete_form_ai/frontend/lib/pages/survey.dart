import 'package:flutter/material.dart';
import 'upload_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionnairePage extends StatefulWidget {
  @override
  _QuestionnairePageState createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  final _formKey = GlobalKey<FormState>();
  String gender = '';
  String height = '';

  Future<void> _saveInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gender', gender);
    await prefs.setString('height', height);
  }

  void _continue() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await _saveInfo();
      Navigator.push(context, MaterialPageRoute(builder: (_) => UploadPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Athlete Info')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Gender'),
              onSaved: (val) => gender = val ?? '',
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Height (cm)'),
              keyboardType: TextInputType.number,
              onSaved: (val) => height = val ?? '',
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _continue, child: Text('Continue'))
          ]),
        ),
      ),
    );
  }
}
